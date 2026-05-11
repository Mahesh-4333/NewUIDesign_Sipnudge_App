import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:intl/intl.dart';

import '../../models/hydration_summary.dart';

class HydrationCubit extends Cubit<HydrationState> {
  final HydrationSync ble;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  HydrationCubit({required this.ble})
      : super(HydrationState(
          entries: [],
          totalDrank: 0,
          goal: 0,
          selectedDate: DateTime.now(),
        )) {
    _init();
  }

  // -------------------- INITIALIZATION --------------------
  Future<void> _init() async {
    try {
      ble.hydrationUpdates.listen((entries) async {
        log("🔔 HydrationCubit received update signal", name: "CUBIT_DEBUG");
        if (entries.isNotEmpty) {
          await markCompletedByEntries(entries);
        }

        await refreshAchievementStats();
      });

      final dailyGoal = await SharedPrefsHelper.getUserGoal() ?? 0;
      final slotsFromDb = await _dbHelper.getAllSlots();

      await refreshAchievementStats();

      double total = slotsFromDb
          .where((e) => e.status == HydrationStatus.completed)
          .fold(0.0, (sum, e) => sum + e.amount);

      final streak = await _dbHelper.getConsistencyStreak();
      final history = await _dbHelper.getTodayHydrationHistory();

      emit(state.copyWith(
        entries: slotsFromDb,
        goal: dailyGoal.round(),
        totalDrank: total.round(),
        consistencyStreak: streak,
        todayHydrationHistory: history,
      ));

      _calculateCurrentSlotStatus();
    } catch (e) {
      log("[Cubit] Failed to load hydration data: $e");
    }
  }

  // -------------------- DAILY GOAL UPDATE --------------------
  Future<void> updateDailyGoal(double newGoal) async {
    await SharedPrefsHelper.setWaterGoal(newGoal.round());
    final updatedSlots = generateDefaultHydrationSlots(newGoal);

    for (final entry in updatedSlots) {
      await _dbHelper.insertOrUpdateSlot(entry);
    }

    emit(state.copyWith(goal: newGoal.round(), entries: updatedSlots));
    _calculateCurrentSlotStatus();
  }

  // -------------------- SLOT STATUS CALCULATION --------------------
  void _calculateCurrentSlotStatus() {
    final now = TimeOfDay.now();
    final nowMinutes = _timeOfDayToMinutes(now);

    HydrationEntry? activeEntry;
    for (final entry in state.entries) {
      final startMin = _timeOfDayToMinutes(entry.startTime);
      final endMin = _timeOfDayToMinutes(entry.endTime);

      if (startMin < endMin) {
        if (nowMinutes >= startMin && nowMinutes < endMin) {
          activeEntry = entry;
          break;
        }
      } else {
        if (nowMinutes >= startMin || nowMinutes < endMin) {
          activeEntry = entry;
          break;
        }
      }
    }

    double consumption = 0.0;
    double percentage = 0.0;

    if (activeEntry != null) {
      consumption = activeEntry.waterDrank.toDouble();

      if (activeEntry.amount > 0) {
        percentage = (consumption / activeEntry.amount) * 100.0;
        percentage = percentage.clamp(0.0, 100.0);
      }
    }

    emit(state.copyWith(
      currentSlotEntry: activeEntry,
      currentSlotConsumption: consumption,
      currentSlotPercentage: percentage,
    ));
  }

  // -------------------- LOAD SLOTS --------------------
  Future<void> loadSlotsFromDb() async {
    try {
      final slotsFromDb = await _dbHelper.getAllSlots();

      if (slotsFromDb.isEmpty) {
        emit(state.copyWith(entries: []));
      } else {
        final total = slotsFromDb
            .where((e) => e.status == HydrationStatus.completed)
            .fold(0.0, (sum, e) => sum + e.amount);

        emit(state.copyWith(entries: slotsFromDb, totalDrank: total.round()));
      }
    } catch (e) {
      log("[Cubit] Failed to load slots from DB: $e");
      emit(state.copyWith(errorMessage: "Failed to load slots from DB."));
    }
  }

  // -------------------- TOGGLE STATUS --------------------
  void toggleStatus(int index) {
    final updated = List<HydrationEntry>.from(state.entries);
    final entry = updated[index];

    updated[index] = entry.copyWith(
      status: entry.status == HydrationStatus.completed
          ? HydrationStatus.pending
          : HydrationStatus.completed,
    );

    final total = updated
        .where((e) => e.status == HydrationStatus.completed)
        .fold(0.0, (sum, e) => sum + e.amount);

    emit(state.copyWith(entries: updated, totalDrank: total.round()));
  }

  // -------------------- DATE UPDATE --------------------
  void updateDate(DateTime newDate) {
    emit(state.copyWith(selectedDate: newDate));

    // updateSlotCompletionStatus();
  }

  void updateSlot(HydrationEntry updatedEntry) {
    final index = state.entries.indexWhere((e) => e.slot == updatedEntry.slot);
    if (index != -1) {
      final updatedList = List<HydrationEntry>.from(state.entries);
      updatedList[index] = updatedEntry.copyWith(
          amount: updatedEntry.amount,
          waterDrank: updatedEntry.waterDrank,
          status: updatedEntry.waterDrank >= updatedEntry.amount
              ? HydrationStatus.completed
              : HydrationStatus.pending);
      emit(state.copyWith(entries: updatedList));
    }
  }

  // -------------------- BLE CONSUMPTION HANDLER --------------------
  void updateTimeSlot({
    required HydrationSlot slot,
    required TimeOfDay newStart,
    required TimeOfDay newEnd,
  }) async {
    final newStartMin = _timeOfDayToMinutes(newStart);
    final newEndMin = _timeOfDayToMinutes(newEnd);

    if (newStartMin == newEndMin) {
      emit(state.copyWith(
        errorMessage: "Start and end time cannot be the same.",
        successMessage: null,
      ));
      return;
    }

    final newIntervals = _toIntervals(newStartMin, newEndMin);

    for (final entry in state.entries) {
      if (entry.slot == slot) continue;

      final existingIntervals = _toIntervals(
        _timeOfDayToMinutes(entry.startTime),
        _timeOfDayToMinutes(entry.endTime),
      );

      if (_intervalsOverlapAny(newIntervals, existingIntervals)) {
        emit(state.copyWith(
          errorMessage: "Time range overlaps with ${entry.slot.label}.",
          successMessage: null,
        ));
        return;
      }
    }

    final updated = state.entries.map((entry) {
      if (entry.slot == slot) {
        return entry.copyWith(startTime: newStart, endTime: newEnd);
      }
      return entry;
    }).toList();

    emit(state.copyWith(entries: updated));
    _calculateCurrentSlotStatus();

    final updatedEntry = updated.firstWhere((e) => e.slot == slot);
    final notificationService = NotificationService();

    await notificationService.rescheduleSlotForFuture(updatedEntry);

    await _dbHelper.insertOrUpdateSlot(updatedEntry);
    ble.queueHydrationSlots(updated);
  }

  // -------------------- BLE ENTRIES UPDATE --------------------
// -------------------- BLE ENTRIES UPDATE --------------------
  Future<void> markCompletedByEntries(List<HydrationEntry> newEntries) async {
    // If state.entries is empty, it means initialization is still in progress
    // or we have no slots. We should fetch them from DB to avoid ignoring updates.
    List<HydrationEntry> currentEntries =
        List<HydrationEntry>.from(state.entries);
    if (currentEntries.isEmpty) {
      log("[HydrationCubit] State entries empty during sync. Fetching from DB...",
          name: "CUBIT_DEBUG");
      currentEntries = await _dbHelper.getAllSlots();
    }

    final waterGoal = await SharedPrefsHelper.getUserGoal() ?? 0;
    int updateCount = 0;

    for (final incoming in newEntries) {
      final index = currentEntries.indexWhere((e) => e.slot == incoming.slot);

      if (index >= 0) {
        final existing = currentEntries[index];
        final updatedEntry = existing.copyWith(
          waterDrank: incoming.waterDrank,
          offslot: incoming.offslot,
          status: incoming.waterDrank >= incoming.amount
              ? HydrationStatus.completed
              : HydrationStatus.pending,
        );

        currentEntries[index] = updatedEntry;
        await _dbHelper.insertOrUpdateSlot(updatedEntry);
        updateCount++;
      }
    }

    log("[HydrationCubit] Finished processing sync. Updated $updateCount/${newEntries.length} entries.",
        name: "CUBIT_DEBUG");

    // Use the BLE-reported live total if available; fall back to summing entries.
    final double slotSum =
        currentEntries.fold(0.0, (sum, e) => sum + e.waterDrank);
    final double totalDrankToday =
        ble.currentHydrationValue > 0 ? ble.currentHydrationValue : slotSum;

    final bool hasMetGoal =
        waterGoal > 0 && totalDrankToday >= waterGoal.toDouble();

    final int oldLevel = state.currentLevel;
    int? newlyUnlocked;
    if (hasMetGoal) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastLevelUpDate = await SharedPrefsHelper.getLastLevelUpDate();

      if (lastLevelUpDate != todayStr) {
        await SharedPrefsHelper.setLastLevelUpDate(todayStr);

        if (state.currentLevel > oldLevel) {
          newlyUnlocked = state.currentLevel;
        }
      }
    }

    final int streak = await _dbHelper.getConsistencyStreak();
    final history = await _dbHelper.getTodayHydrationHistory();

    // 4. Emit the updated state
    log("[HydrationCubit] Emitting state with ${currentEntries.length} entries and totalDrank $totalDrankToday",
        name: "CUBIT_DEBUG");
    emit(state.copyWith(
      entries: currentEntries,
      totalDrank: totalDrankToday.round(),
      newlyUnlockedLevel: newlyUnlocked,
      consistencyStreak: streak,
      todayHydrationHistory: history,
    ));

    _calculateCurrentSlotStatus();
  }

  void subscribeToBleUpdates(BleCubit bleCubit) {
    bleCubit.hydrationUpdates.listen((entries) async {
      for (final entry in entries) {
        updateSlot(entry);
      }
      await refreshTodayHistory();
    });
  }

  Future<void> refreshTodayHistory() async {
    final history = await _dbHelper.getTodayHydrationHistory();
    emit(state.copyWith(todayHydrationHistory: history));
  }

  Future<void> clearTodayHistory() async {
    await _dbHelper.clearTodayHydrationHistory();
    await refreshTodayHistory();
  }

  // -------------------- HELPERS --------------------
  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  List<_Interval> _toIntervals(int startMin, int endMin) {
    if (startMin < endMin) {
      return [_Interval(startMin, endMin)];
    } else {
      return [_Interval(startMin, 1440), _Interval(0, endMin)];
    }
  }

  List<HydrationEntry> generateDefaultHydrationSlots(double dailyGoalMl) {
    return [
      HydrationEntry(
        slot: HydrationSlot.wakeup,
        startTime: const TimeOfDay(hour: 7, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 0),
        amount: dailyGoalMl * 0.25,
      ),
      HydrationEntry(
        slot: HydrationSlot.breakfast,
        startTime: const TimeOfDay(hour: 8, minute: 30),
        endTime: const TimeOfDay(hour: 9, minute: 30),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.midMorning,
        startTime: const TimeOfDay(hour: 11, minute: 00),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.lunch,
        startTime: const TimeOfDay(hour: 13, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.midAfternoon,
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 30),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.evening,
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.afterDinner,
        startTime: const TimeOfDay(hour: 20, minute: 30),
        endTime: const TimeOfDay(hour: 21, minute: 30),
        amount: dailyGoalMl * 0.125,
      ),
    ];
  }

  bool _intervalsOverlapAny(List<_Interval> aList, List<_Interval> bList) {
    for (final a in aList) {
      for (final b in bList) {
        if (_intervalsOverlap(a.start, a.end, b.start, b.end)) return true;
      }
    }
    return false;
  }

  bool _intervalsOverlap(int s1, int e1, int s2, int e2) {
    return s1 < e2 && e1 > s2;
  }

  void showError(String message) {
    emit(state.copyWith(errorMessage: message, successMessage: null));
  }

  void setNewlyUnlockedLevelToNull() {
    emit(state.copyWith(newlyUnlockedLevel: null));
  }

  Future<void> refreshAchievementStats({bool updateUnlock = true}) async {
    try {
      final summaries = await _dbHelper.getHydrationSummariesForRange();
      log("DEBUG: Total summaries found: ${summaries.length}");

      summaries.sort((a, b) => a.date.compareTo(b.date));

      int badgesUnlocked = 0;
      Map<int, String> levelMap = {};
      Map<int, String> exactLevelMap = {};
      // Use a set to de-duplicate same calendar day (handles DB duplicates)
      final Set<String> seenDates = {};

      for (var day in summaries) {
        if (day.isPerfect) {
          final dateKey = DateFormat('yyyy-MM-dd').format(day.date);
          if (!seenDates.contains(dateKey)) {
            seenDates.add(dateKey);
            badgesUnlocked++;
            final litres = (day.consumed / 1000).toStringAsFixed(1);
            levelMap[badgesUnlocked] = '${litres}L';
            exactLevelMap[badgesUnlocked] = day.consumed.toStringAsFixed(0);
            Console.log(
                tag: "DEBUG: 🏆 Level $badgesUnlocked unlocked! ",
                value: "($dateKey, ${day.consumed.toStringAsFixed(0)}L)");
          } else {
            log("DEBUG: Duplicate date $dateKey — skipping.");
          }
        }
      }

      final streak = await _dbHelper.getConsistencyStreak();

      if (updateUnlock) {
        emit(state.copyWith(
            currentLevel: badgesUnlocked,
            newlyUnlockedLevel: badgesUnlocked,
            consistencyStreak: streak,
            levelToIntakeMap: levelMap,
            exactLevelToIntakeMap: exactLevelMap));
      } else {
        emit(state.copyWith(
            currentLevel: badgesUnlocked,
            consistencyStreak: streak,
            levelToIntakeMap: levelMap,
            exactLevelToIntakeMap: exactLevelMap));
      }
    } catch (e) {
      log("ERROR in refreshAchievementStats: $e");
    }
  }

  void setGoal(int goal) {
    emit(state.copyWith(goal: goal));
  }

  Future<void> resetUI() async {
    emit(state.copyWith(
        entries: [],
        totalDrank: 0,
        goal: 0,
        currentSlotConsumption: 0,
        currentSlotPercentage: 0,
        currentSlotEntry: null,
        newlyUnlockedLevel: null,
        levelToIntakeMap: {},
        exactLevelToIntakeMap: {},
        clearNewlyUnlockedLevel: true));
  }
}

// Helper class
class _Interval {
  final int start;
  final int end;
  _Interval(this.start, this.end);
}
