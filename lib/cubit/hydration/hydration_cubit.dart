import 'package:hydrify/helpers/logger.dart';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
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
        Console.log(tag: "CUBIT_DEBUG", value: "🔔 HydrationCubit received update signal");
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

      emit(state.copyWith(
        entries: slotsFromDb,
        goal: dailyGoal.round(),
        totalDrank: total.round(),
        // currentLevel and levelToIntakeMap are already updated
        // by the call to refreshAchievementStats() above
      ));

      _calculateCurrentSlotStatus();
    } catch (e) {
      Console.log(tag: "APP", value: "[Cubit] Failed to load hydration data: $e");
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
      Console.log(tag: "APP", value: "[Cubit] Failed to load slots from DB: $e");
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
    final currentEntries = List<HydrationEntry>.from(state.entries);

    for (final incoming in newEntries) {
      final index = currentEntries.indexWhere((e) => e.slot == incoming.slot);

      if (index >= 0) {
        final updatedEntry = currentEntries[index].copyWith(
          waterDrank: incoming.waterDrank,
          status: incoming.waterDrank >= currentEntries[index].amount
              ? HydrationStatus.completed
              : HydrationStatus.pending,
        );
        currentEntries[index] = updatedEntry;

        await _dbHelper.insertOrUpdateSlot(updatedEntry);
      }
    }

    final double totalDrankToday =
        currentEntries.fold(0.0, (sum, e) => sum + e.waterDrank);
    final bool isPerfectNow =
        currentEntries.every((e) => e.status == HydrationStatus.completed);

    int updatedLevel = state.currentLevel;
    int? newlyUnlocked;
    if (isPerfectNow) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastLevelUpDate = await SharedPrefsHelper.getLastLevelUpDate();

      if (lastLevelUpDate != todayStr) {
        final todaySummary = HydrationDaySummary(
          date: DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day),
          dayIndex: 0,
          target: state.goal.toDouble(),
          consumed: totalDrankToday,
          isPerfect: true,
        );

        await _dbHelper.bulkUpsert30Days([todaySummary]);
        await SharedPrefsHelper.setLastLevelUpDate(todayStr);
        await refreshAchievementStats();

        if (state.currentLevel > updatedLevel) {
          updatedLevel = state.currentLevel;
          newlyUnlocked = updatedLevel;
        }
      }
    }

    // 4. Emit the updated state
    emit(state.copyWith(
      entries: currentEntries,
      totalDrank: totalDrankToday.round(),
      currentLevel: updatedLevel,
      newlyUnlockedLevel: newlyUnlocked,
    ));

    _calculateCurrentSlotStatus();

    if (newlyUnlocked != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) emit(state.copyWith(newlyUnlockedLevel: null));
      });
    }
  }

  void subscribeToBleUpdates(BleCubit bleCubit) {
    bleCubit.hydrationUpdates.listen((entries) {
      for (final entry in entries) {
        updateSlot(entry);
      }
    });
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


  Future<void> refreshAchievementStats() async {
    try {
      final summaries = await _dbHelper.getHydrationSummariesForRange();
      Console.log(tag: "APP", value: "DEBUG: Total summaries found: ${summaries.length}");

      summaries.sort((a, b) => a.date.compareTo(b.date));

      int currentStreak = 0;
      int badgesUnlocked = 0;
      Map<int, String> levelMap = {};
      DateTime? lastDate;

      for (var day in summaries) {
        if (day.isPerfect) {
          if (lastDate != null) {
            // Normalize both to midnight to be safe
            final d1 = DateTime(lastDate.year, lastDate.month, lastDate.day);
            final d2 = DateTime(day.date.year, day.date.month, day.date.day);
            final difference = d2.difference(d1).inDays;

            Console.log(tag: "APP", value: "DEBUG: Comparing ${d1.toIso8601String()} to ${d2.toIso8601String()} | Diff: $difference");

            if (difference == 1) {
              currentStreak++;
            } else if (difference == 0) {
              Console.log(tag: "APP", value: "DEBUG: Duplicate date detected, skipping increment.");
            } else {
              Console.log(tag: "APP", value: "DEBUG: GAP DETECTED! Streak reset to 1.");
              currentStreak = 1;
            }
          } else {
            currentStreak = 1;
            Console.log(tag: "APP", value: "DEBUG: Starting first streak day.");
          }

          lastDate = day.date;
          Console.log(tag: "APP", value: "DEBUG: Current Streak Count: $currentStreak");

          if (currentStreak == 7) {
            badgesUnlocked++;
            levelMap[badgesUnlocked] = "Level $badgesUnlocked Unlocked";
            Console.log(tag: "APP", value: "DEBUG: 🏆 BADGE UNLOCKED! Total: $badgesUnlocked");
            currentStreak = 0;
            lastDate = null;
          }
        }
      }

      emit(state.copyWith(
        currentLevel: badgesUnlocked,
        levelToIntakeMap: levelMap,
      ));
    } catch (e) {
      Console.log(tag: "APP", value: "ERROR in refreshAchievementStats: $e");
    }
  }
}

// Helper class
class _Interval {
  final int start;
  final int end;
  _Interval(this.start, this.end);
}
