import 'dart:developer';

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
      // Listen to BLE hydration updates
      ble.hydrationUpdates.listen((entries) async {
        await markCompletedByEntries(entries);
        // await updateSlotCompletionStatus();
      });

      final dailyGoal =
          await SharedPrefsHelper.getUserGoal() ?? 0;
      log("[Cubit] Daily goal: $dailyGoal");

      final slotsFromDb = await _dbHelper.getAllSlots();
      log("[Cubit] Loaded ${slotsFromDb.length} slots from DB");

      double total = slotsFromDb
          .where((e) => e.status == HydrationStatus.completed)
          .fold(0.0, (sum, e) => sum + e.amount);

      emit(state.copyWith(
        entries: slotsFromDb,
        goal: dailyGoal.round(),
        totalDrank: total.round(),
      ));

      _calculateCurrentSlotStatus();
    } catch (e) {
      log("[Cubit] Failed to load hydration data: $e");
      emit(state.copyWith(
          errorMessage: "Failed to load hydration data."));
    }
  }

  // -------------------- DAILY GOAL UPDATE --------------------
  Future<void> updateDailyGoal(double newGoal) async {
    await SharedPrefsHelper.setWaterGoal(newGoal.round());
    final updatedSlots = generateDefaultHydrationSlots(newGoal);

    for (final entry in updatedSlots) {
      await _dbHelper.insertOrUpdateSlot(entry);
    }

    emit(state.copyWith(
        goal: newGoal.round(), entries: updatedSlots));
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

        emit(state.copyWith(
            entries: slotsFromDb, totalDrank: total.round()));
      }
    } catch (e) {
      log("[Cubit] Failed to load slots from DB: $e");
      emit(state.copyWith(
          errorMessage: "Failed to load slots from DB."));
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

    emit(state.copyWith(
        entries: updated, totalDrank: total.round()));
  }

  // -------------------- DATE UPDATE --------------------
  void updateDate(DateTime newDate) {
    emit(state.copyWith(selectedDate: newDate));

    // updateSlotCompletionStatus();
  }

  void updateSlot(HydrationEntry updatedEntry) {
    final index = state.entries
        .indexWhere((e) => e.slot == updatedEntry.slot);
    if (index != -1) {
      final updatedList =
          List<HydrationEntry>.from(state.entries);
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

      if (_intervalsOverlapAny(
          newIntervals, existingIntervals)) {
        emit(state.copyWith(
          errorMessage:
              "Time range overlaps with ${entry.slot.label}.",
          successMessage: null,
        ));
        return;
      }
    }

    final updated = state.entries.map((entry) {
      if (entry.slot == slot) {
        return entry.copyWith(
            startTime: newStart, endTime: newEnd);
      }
      return entry;
    }).toList();

    emit(state.copyWith(entries: updated));
    _calculateCurrentSlotStatus();

    final updatedEntry =
        updated.firstWhere((e) => e.slot == slot);
    final notificationService = NotificationService();

    await notificationService
        .rescheduleSlotForFuture(updatedEntry);

    await _dbHelper.insertOrUpdateSlot(updatedEntry);
    ble.queueHydrationSlots(updated);
  }

  // -------------------- BLE ENTRIES UPDATE --------------------
  Future<void> markCompletedByEntries(
      List<HydrationEntry> newEntries) async {
    final currentEntries =
        List<HydrationEntry>.from(state.entries);

    for (final incoming in newEntries) {
      final index = currentEntries
          .indexWhere((e) => e.slot == incoming.slot);

      if (index >= 0) {
        final updatedEntry = currentEntries[index].copyWith(
          waterDrank: incoming.waterDrank,
          status: HydrationStatus.completed,
        );
        currentEntries[index] = updatedEntry;
        await _dbHelper.insertOrUpdateSlot(updatedEntry);
      } else {
        final newEntry =
            incoming.copyWith(status: HydrationStatus.completed);
        currentEntries.add(newEntry);
        await _dbHelper.insertOrUpdateSlot(newEntry);
      }
    }

    final total = currentEntries
        .where((e) => e.status == HydrationStatus.completed)
        .fold(0.0, (sum, e) => sum + e.waterDrank);

    emit(state.copyWith(
        entries: currentEntries, totalDrank: total.round()));
    _calculateCurrentSlotStatus();
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
    emit(state.copyWith(
        errorMessage: null, successMessage: null));
  }

  int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  List<_Interval> _toIntervals(int startMin, int endMin) {
    if (startMin < endMin) {
      return [_Interval(startMin, endMin)];
    } else {
      return [_Interval(startMin, 1440), _Interval(0, endMin)];
    }
  }

  List<HydrationEntry> generateDefaultHydrationSlots(
      double dailyGoalMl) {
    return [
      HydrationEntry(
        slot: HydrationSlot.wakeup,
        startTime: const TimeOfDay(hour: 6, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 0),
        amount: dailyGoalMl * 0.25,
      ),
      HydrationEntry(
        slot: HydrationSlot.breakfast,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 30),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.midMorning,
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.lunch,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.midAfternoon,
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.evening,
        startTime: const TimeOfDay(hour: 17, minute: 0),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        amount: dailyGoalMl * 0.125,
      ),
      HydrationEntry(
        slot: HydrationSlot.afterDinner,
        startTime: const TimeOfDay(hour: 19, minute: 0),
        endTime: const TimeOfDay(hour: 22, minute: 0),
        amount: dailyGoalMl * 0.125,
      ),
    ];
  }

  bool _intervalsOverlapAny(
      List<_Interval> aList, List<_Interval> bList) {
    for (final a in aList) {
      for (final b in bList) {
        if (_intervalsOverlap(a.start, a.end, b.start, b.end))
          return true;
      }
    }
    return false;
  }

  bool _intervalsOverlap(int s1, int e1, int s2, int e2) {
    return s1 < e2 && e1 > s2;
  }
}

// Helper class
class _Interval {
  final int start;
  final int end;
  _Interval(this.start, this.end);
}
