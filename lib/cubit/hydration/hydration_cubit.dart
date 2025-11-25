import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/services/notification_service.dart';
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

      final dailyGoal = await SharedPrefsHelper.getUserGoal() ?? 0;
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
      emit(state.copyWith(errorMessage: "Failed to load hydration data."));
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
    await notificationService.cancelReminder(slot);
    await notificationService.scheduleHydrationReminders([updatedEntry]);
    await notificationService.testNotification();
    await _dbHelper.insertOrUpdateSlot(updatedEntry);
    ble.queueHydrationSlots(updated);
  }

  // -------------------- BLE ENTRIES UPDATE --------------------
  Future<void> markCompletedByEntries(List<HydrationEntry> newEntries) async {
    final currentEntries = List<HydrationEntry>.from(state.entries);

    for (final incoming in newEntries) {
      final index = currentEntries.indexWhere((e) => e.slot == incoming.slot);

      if (index >= 0) {
        final updatedEntry = currentEntries[index].copyWith(
          waterDrank: incoming.waterDrank,
          status: HydrationStatus.completed,
        );
        currentEntries[index] = updatedEntry;
        await _dbHelper.insertOrUpdateSlot(updatedEntry);
      } else {
        final newEntry = incoming.copyWith(status: HydrationStatus.completed);
        currentEntries.add(newEntry);
        await _dbHelper.insertOrUpdateSlot(newEntry);
      }
    }

    final total = currentEntries
        .where((e) => e.status == HydrationStatus.completed)
        .fold(0.0, (sum, e) => sum + e.waterDrank);

    emit(state.copyWith(entries: currentEntries, totalDrank: total.round()));
    _calculateCurrentSlotStatus();
  }

  // -------------------- AUTO SLOT COMPLETION --------------------
  // Future<void> updateSlotCompletionStatus() async {
  //   try {
  //     final selectedDate = state.selectedDate;
  //     final startOfDay =
  //         DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  //     final endOfDay = startOfDay.add(const Duration(days: 1));

  //     final history =
  //         await _dbHelper.getBottleDataForDateRange(startOfDay, endOfDay);

  //     if (history.isEmpty) return;

  //     final updatedEntries = <HydrationEntry>[];

  //     for (final entry in state.entries) {
  //       double slotIntake = 0;

  //       for (final record in history) {
  //         final recordTime = record.timestamp;
  //         final recordVolume = record.liquidVolume.toDouble();

  //         final startSlot = DateTime(recordTime.year, recordTime.month,
  //             recordTime.day, entry.startTime.hour, entry.startTime.minute);
  //         final endSlot = DateTime(recordTime.year, recordTime.month,
  //             recordTime.day, entry.endTime.hour, entry.endTime.minute);

  //         bool isInSlot = false;

  //         if (_timeOfDayToMinutes(entry.startTime) <
  //             _timeOfDayToMinutes(entry.endTime)) {
  //           isInSlot =
  //               recordTime.isAfter(startSlot) && recordTime.isBefore(endSlot);
  //         } else {
  //           isInSlot =
  //               recordTime.isAfter(startSlot) || recordTime.isBefore(endSlot);
  //         }

  //         if (isInSlot) {
  //           slotIntake += recordVolume;
  //           log("[DEBUG] Slot ${entry.slot.label}: +${recordVolume}ml at ${recordTime}");
  //         }
  //       }

  //       final newStatus = slotIntake >= entry.amount
  //           ? HydrationStatus.completed
  //           : HydrationStatus.pending;

  //       final updatedEntry = entry.copyWith(
  //         waterDrank: slotIntake.roundToDouble(),
  //         status: newStatus,
  //       );

  //       updatedEntries.add(updatedEntry);
  //       await _dbHelper.insertOrUpdateSlot(updatedEntry);
  //     }

  //     final totalDrank =
  //         updatedEntries.fold(0.0, (sum, e) => sum + e.waterDrank);

  //     emit(state.copyWith(
  //         entries: updatedEntries, totalDrank: totalDrank.round()));
  //     _calculateCurrentSlotStatus();
  //   } catch (e) {
  //     log("[HydrationCubit] Error updating slot completion: $e");
  //   }
  // }

  void subscribeToBleUpdates(BleCubit bleCubit) {
    bleCubit.hydrationUpdates.listen((entries) {
      for (final entry in entries) {
        updateSlot(entry);
      }
    });
  }

  // -------------------- BLE VOLUME LIVE UPDATE --------------------
  // void updateSlotCompletionStatusFromBle({
  //   required DateTime timestamp,
  //   required double consumedVolume,
  // }) async {
  //   try {
  //     final entries = List<HydrationEntry>.from(state.entries);
  //     HydrationEntry? activeEntry;

  //     for (final entry in entries) {
  //       final now = TimeOfDay.fromDateTime(timestamp);

  //       final isWithinSlot = _isTimeInRange(
  //         now,
  //         entry.startTime,
  //         entry.endTime,
  //       );

  //       if (isWithinSlot) {
  //         activeEntry = entry;
  //         break;
  //       }
  //     }

  //     if (activeEntry == null) {
  //       log("[BLE Sync] No active hydration slot found for current time.");
  //       return;
  //     }

  //     final updatedEntry = activeEntry.copyWith(
  //       waterDrank: consumedVolume,
  //       status: consumedVolume >= activeEntry.amount
  //           ? HydrationStatus.completed
  //           : HydrationStatus.pending,
  //     );

  //     final updatedEntries = entries.map((e) {
  //       return e.slot == activeEntry!.slot ? updatedEntry : e;
  //     }).toList();

  //     final totalDrank =
  //         updatedEntries.fold(0.0, (sum, e) => sum + e.waterDrank);

  //     await _dbHelper.insertOrUpdateSlot(updatedEntry);

  //     emit(state.copyWith(
  //       entries: updatedEntries,
  //       totalDrank: totalDrank.round(),
  //     ));

  //     _calculateCurrentSlotStatus();
  //   } catch (e) {
  //     log("[HydrationCubit] Error in BLE live update: $e");
  //   }
  // }

  // bool _isTimeInRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
  //   final nowMin = now.hour * 60 + now.minute;
  //   final startMin = start.hour * 60 + start.minute;
  //   final endMin = end.hour * 60 + end.minute;

  //   if (endMin < startMin) {
  //     return nowMin >= startMin || nowMin <= endMin;
  //   } else {
  //     return nowMin >= startMin && nowMin <= endMin;
  //   }
  // }

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
}

// Helper class
class _Interval {
  final int start;
  final int end;
  _Interval(this.start, this.end);
}

// -------------------- DEPRECATED CODE --------------------

// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrify/cubit/ble/ble_cubit.dart';
// import 'package:hydrify/cubit/hydration/hydration_state.dart';
// import 'package:hydrify/cubit/hydration/hydration_sync.dart';
// import 'package:hydrify/helpers/database_helper.dart';
// import 'package:hydrify/helpers/shared_pref_helper.dart';
// import 'package:hydrify/models/hydration_entry.dart';
// import 'package:hydrify/services/notification_service.dart';
// import 'package:intl/intl.dart';

// class HydrationCubit extends Cubit<HydrationState> {
//   final HydrationSync ble;
//   final DatabaseHelper _dbHelper = DatabaseHelper();

//   HydrationCubit({required this.ble})
//       : super(HydrationState(
//           entries: [],
//           totalDrank: 0,
//           goal: 0,
//           selectedDate: DateTime.now(),
//         )) {
//     _init();
//   }

//   Future<void> _init() async {
//     try {
//       // Listen to BLE hydration updates
//       ble.hydrationUpdates.listen((entries) async {
//         await markCompletedByEntries(entries);
//         await updateSlotCompletionStatus();
//       });

//       final dailyGoal = await SharedPrefsHelper.getUserGoal() ?? 0;
//       log("[Cubit] Daily goal: $dailyGoal");

//       final slotsFromDb = await _dbHelper.getAllSlots();
//       log("[Cubit] Loaded ${slotsFromDb.length} slots from DB");
//       for (var s in slotsFromDb) {
//         log("  Slot: ${s.slot.label}, amount: ${s.amount}, status: ${s.status}");
//       }

//       double total = slotsFromDb
//           .where((e) => e.status == HydrationStatus.completed)
//           .fold(0.0, (sum, e) => sum + e.amount);

//       emit(state.copyWith(
//         entries: slotsFromDb,
//         goal: dailyGoal.round(),
//         totalDrank: total.round(),
//       ));

//       _calculateCurrentSlotStatus();
//     } catch (e) {
//       log("[Cubit] Failed to load hydration data: $e");
//       emit(state.copyWith(errorMessage: "Failed to load hydration data."));
//     }
//   }

//   /// ✅ Update the daily goal and regenerate slots
//   Future<void> updateDailyGoal(double newGoal) async {
//     await SharedPrefsHelper.setWaterGoal(
//         newGoal.round()); // ✅ correct method name
//     final updatedSlots = generateDefaultHydrationSlots(newGoal);

//     for (final entry in updatedSlots) {
//       await _dbHelper.insertOrUpdateSlot(entry);
//     }

//     emit(state.copyWith(goal: newGoal.round(), entries: updatedSlots));
//     _calculateCurrentSlotStatus();
//   }

//   /// Recalculate which slot is currently active and its completion %
//   void _calculateCurrentSlotStatus() {
//     final now = TimeOfDay.now();
//     final nowMinutes = _timeOfDayToMinutes(now);

//     HydrationEntry? activeEntry;
//     for (final entry in state.entries) {
//       final startMin = _timeOfDayToMinutes(entry.startTime);
//       final endMin = _timeOfDayToMinutes(entry.endTime);

//       if (startMin < endMin) {
//         if (nowMinutes >= startMin && nowMinutes < endMin) {
//           activeEntry = entry;
//           break;
//         }
//       } else {
//         if (nowMinutes >= startMin || nowMinutes < endMin) {
//           activeEntry = entry;
//           break;
//         }
//       }
//     }

//     double consumption = 0.0;
//     double percentage = 0.0;

//     if (activeEntry != null) {
//       consumption = activeEntry.waterDrank.toDouble();

//       if (activeEntry.amount > 0) {
//         percentage = (consumption / activeEntry.amount) * 100.0;
//         percentage = percentage.clamp(0.0, 100.0);
//       }
//     }

//     emit(state.copyWith(
//       currentSlotEntry: activeEntry,
//       currentSlotConsumption: consumption,
//       currentSlotPercentage: percentage,
//     ));
//   }

//   Future<void> loadSlotsFromDb() async {
//     try {
//       final slotsFromDb = await _dbHelper.getAllSlots();
//       log("[Cubit] _loadSlotsFromDb: Loaded ${slotsFromDb.length} slots");

//       if (slotsFromDb.isEmpty) {
//         emit(state.copyWith(entries: []));
//       } else {
//         final total = slotsFromDb
//             .where((e) => e.status == HydrationStatus.completed)
//             .fold(0.0, (sum, e) => sum + e.amount);

//         emit(state.copyWith(entries: slotsFromDb, totalDrank: total.round()));
//       }
//     } catch (e) {
//       log("[Cubit] Failed to load slots from DB: $e");
//       emit(state.copyWith(errorMessage: "Failed to load slots from DB."));
//     }
//   }

//   void toggleStatus(int index) {
//     final updated = List<HydrationEntry>.from(state.entries);
//     final entry = updated[index];

//     updated[index] = entry.copyWith(
//       status: entry.status == HydrationStatus.completed
//           ? HydrationStatus.pending
//           : HydrationStatus.completed,
//     );

//     final total = updated
//         .where((e) => e.status == HydrationStatus.completed)
//         .fold(0.0, (sum, e) => sum + e.amount);

//     emit(state.copyWith(
//         entries: updated,
//         totalDrank: total.round(),
//         errorMessage: null,
//         successMessage: null));
//   }

//   void updateDate(DateTime newDate) {
//     emit(state.copyWith(
//         selectedDate: newDate, errorMessage: null, successMessage: null));
//     updateSlotCompletionStatus();
//   }

//   /// ✅ Update specific time slot & re-schedule notification
  // void updateTimeSlot({
  //   required HydrationSlot slot,
  //   required TimeOfDay newStart,
  //   required TimeOfDay newEnd,
  // }) async {
  //   final newStartMin = _timeOfDayToMinutes(newStart);
  //   final newEndMin = _timeOfDayToMinutes(newEnd);

  //   if (newStartMin == newEndMin) {
  //     emit(state.copyWith(
  //       errorMessage: "Start and end time cannot be the same.",
  //       successMessage: null,
  //     ));
  //     return;
  //   }

  //   final newIntervals = _toIntervals(newStartMin, newEndMin);

  //   for (final entry in state.entries) {
  //     if (entry.slot == slot) continue;

  //     final existingIntervals = _toIntervals(
  //       _timeOfDayToMinutes(entry.startTime),
  //       _timeOfDayToMinutes(entry.endTime),
  //     );

  //     if (_intervalsOverlapAny(newIntervals, existingIntervals)) {
  //       emit(state.copyWith(
  //         errorMessage: "Time range overlaps with ${entry.slot.label}.",
  //         successMessage: null,
  //       ));
  //       return;
  //     }
  //   }

  //   final updated = state.entries.map((entry) {
  //     if (entry.slot == slot) {
  //       return entry.copyWith(startTime: newStart, endTime: newEnd);
  //     }
  //     return entry;
  //   }).toList();

  //   emit(state.copyWith(entries: updated));
  //   _calculateCurrentSlotStatus();

  //   final updatedEntry = updated.firstWhere((e) => e.slot == slot);
  //   final notificationService = NotificationService();
  //   await notificationService.cancelReminder(slot);
  //   await notificationService.scheduleHydrationReminders([updatedEntry]);
  //   await notificationService.testNotification();
  //   await _dbHelper.insertOrUpdateSlot(updatedEntry);
  //   ble.queueHydrationSlots(updated);
  // }

//   /// ✅ BLE incoming hydration updates
//   Future<void> markCompletedByEntries(List<HydrationEntry> newEntries) async {
//     final currentEntries = List<HydrationEntry>.from(state.entries);

//     for (final incoming in newEntries) {
//       final index = currentEntries.indexWhere((e) => e.slot == incoming.slot);

//       if (index >= 0) {
//         final updatedEntry = currentEntries[index].copyWith(
//           waterDrank: incoming.waterDrank,
//           status: HydrationStatus.completed,
//         );
//         currentEntries[index] = updatedEntry;
//         await _dbHelper.insertOrUpdateSlot(updatedEntry);
//       } else {
//         final newEntry = incoming.copyWith(status: HydrationStatus.completed);
//         currentEntries.add(newEntry);
//         await _dbHelper.insertOrUpdateSlot(newEntry);
//       }
//     }

//     final total = currentEntries
//         .where((e) => e.status == HydrationStatus.completed)
//         .fold(0.0, (sum, e) => sum + e.waterDrank);

//     emit(state.copyWith(
//       entries: currentEntries,
//       totalDrank: total.round(),
//       errorMessage: null,
//       successMessage: "${newEntries.length} slot(s) marked as completed!",
//     ));

//     _calculateCurrentSlotStatus();
//   }

//   /// ✅ Automatically check slot completion from bottle data
//   Future<void> updateSlotCompletionStatus() async {
//     try {
//       final selectedDate = state.selectedDate;
//       final startOfDay =
//           DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//       final endOfDay = startOfDay.add(const Duration(days: 1));

//       final history =
//           await _dbHelper.getBottleDataForDateRange(startOfDay, endOfDay);

//       if (history.isEmpty) return;

//       final updatedEntries = <HydrationEntry>[];

//       for (final entry in state.entries) {
//         double slotIntake = 0;

//         for (final record in history) {
//           final recordTime = record.timestamp;
//           final recordVolume = record.liquidVolume.toDouble();

//           final startSlot = DateTime(recordTime.year, recordTime.month,
//               recordTime.day, entry.startTime.hour, entry.startTime.minute);
//           final endSlot = DateTime(recordTime.year, recordTime.month,
//               recordTime.day, entry.endTime.hour, entry.endTime.minute);

//           bool isInSlot = false;

//           if (_timeOfDayToMinutes(entry.startTime) <
//               _timeOfDayToMinutes(entry.endTime)) {
//             isInSlot =
//                 recordTime.isAfter(startSlot) && recordTime.isBefore(endSlot);
//           } else {
//             isInSlot =
//                 recordTime.isAfter(startSlot) || recordTime.isBefore(endSlot);
//           }

//           if (isInSlot) {
//             slotIntake += recordVolume;
//             log("[DEBUG] Slot ${entry.slot.label}: +${recordVolume}ml at ${recordTime}");
//           }
//           log("[DEBUG] Slot ${entry.slot.label}: Total intake = $slotIntake ml");
//         }

//         final newStatus = slotIntake >= entry.amount
//             ? HydrationStatus.completed
//             : HydrationStatus.pending;

//         final updatedEntry = entry.copyWith(
//           waterDrank: slotIntake.roundToDouble(),
//           status: newStatus,
//         );

//         updatedEntries.add(updatedEntry);
//         await _dbHelper.insertOrUpdateSlot(updatedEntry);
//       }

//       final totalDrank = updatedEntries
//           .where((e) => e.status == HydrationStatus.completed)
//           .fold(0.0, (sum, e) => sum + e.waterDrank);

//       emit(state.copyWith(
//           entries: updatedEntries, totalDrank: totalDrank.round()));
//       _calculateCurrentSlotStatus();
//     } catch (e) {
//       log("[HydrationCubit] Error updating slot completion: $e");
//     }
//   }

//   void clearMessages() {
//     emit(state.copyWith(errorMessage: null, successMessage: null));
//   }

//   int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

//   List<_Interval> _toIntervals(int startMin, int endMin) {
//     if (startMin < endMin) {
//       return [_Interval(startMin, endMin)];
//     } else {
//       return [_Interval(startMin, 1440), _Interval(0, endMin)];
//     }
//   }

//   /// ✅ Updated default slot generation with correct percentages
//   List<HydrationEntry> generateDefaultHydrationSlots(double dailyGoalMl) {
//     return [
//       HydrationEntry(
//         slot: HydrationSlot.wakeup,
//         startTime: const TimeOfDay(hour: 6, minute: 0),
//         endTime: const TimeOfDay(hour: 8, minute: 0),
//         amount: dailyGoalMl * 0.25,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.breakfast,
//         startTime: const TimeOfDay(hour: 8, minute: 0),
//         endTime: const TimeOfDay(hour: 9, minute: 30),
//         amount: dailyGoalMl * 0.125,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.midMorning,
//         startTime: const TimeOfDay(hour: 9, minute: 30),
//         endTime: const TimeOfDay(hour: 11, minute: 30),
//         amount: dailyGoalMl * 0.125,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.lunch,
//         startTime: const TimeOfDay(hour: 12, minute: 0),
//         endTime: const TimeOfDay(hour: 14, minute: 0),
//         amount: dailyGoalMl * 0.125,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.midAfternoon,
//         startTime: const TimeOfDay(hour: 15, minute: 0),
//         endTime: const TimeOfDay(hour: 17, minute: 0),
//         amount: dailyGoalMl * 0.125,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.evening,
//         startTime: const TimeOfDay(hour: 17, minute: 0),
//         endTime: const TimeOfDay(hour: 19, minute: 0),
//         amount: dailyGoalMl * 0.125,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.afterDinner,
//         startTime: const TimeOfDay(hour: 19, minute: 0),
//         endTime: const TimeOfDay(hour: 22, minute: 0),
//         amount: dailyGoalMl * 0.125,
//       ),
//     ];
//   }

//   bool _intervalsOverlapAny(List<_Interval> aList, List<_Interval> bList) {
//     for (final a in aList) {
//       for (final b in bList) {
//         if (_intervalsOverlap(a.start, a.end, b.start, b.end)) return true;
//       }
//     }
//     return false;
//   }

//   bool _intervalsOverlap(int s1, int e1, int s2, int e2) {
//     return s1 < e2 && e1 > s2;
//   }
// }

// class _Interval {
//   final int start;
//   final int end;
//   _Interval(this.start, this.end);
// }

// -----------------------------------------------------------------------------

// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrify/cubit/ble/ble_cubit.dart';
// import 'package:hydrify/cubit/hydration/hydration_sync.dart';
// import 'package:hydrify/helpers/database_helper.dart';
// import 'package:hydrify/helpers/shared_pref_helper.dart';
// import 'package:hydrify/models/hydration_entry.dart';
// import 'package:hydrify/services/notification_service.dart';
// import 'package:intl/intl.dart';

// part 'hydration_state.dart';

// class HydrationCubit extends Cubit<HydrationState> {
//   final HydrationSync ble;
//   final DatabaseHelper _dbHelper = DatabaseHelper();

//   HydrationCubit({required this.ble})
//       : super(HydrationState(
//           entries: [],
//           totalDrank: 0,
//           goal: 0,
//           selectedDate: DateTime.now(),
//         )) {
//     _init();
//   }

//   Future<void> _init() async {
//     try {
//       // Listen to BLE hydration updates
//       ble.hydrationUpdates.listen((entries) async {
//         await markCompletedByEntries(entries);
//         await updateSlotCompletionStatus();
//       });

//       final dailyGoal = await SharedPrefsHelper.getUserGoal() ?? 0;
//       log("[Cubit] Daily goal: $dailyGoal");

//       final slotsFromDb = await _dbHelper.getAllSlots();
//       log("[Cubit] Loaded ${slotsFromDb.length} slots from DB");
//       for (var s in slotsFromDb) {
//         log("  Slot: ${s.slot.label}, amount: ${s.amount}, status: ${s.status}");
//       }

//       // int total = slotsFromDb
//       //     .where((e) => e.status == HydrationStatus.completed)
//       //     .fold(0, (sum, e) => sum + e.amount);
//       double total = slotsFromDb
//           .where((e) => e.status == HydrationStatus.completed)
//           .fold(0.0, (sum, e) => sum + e.amount);

//       emit(state.copyWith(
//         entries: slotsFromDb,
//         goal: dailyGoal,
//         totalDrank: total.round(),
//       ));

//       _calculateCurrentSlotStatus();
//     } catch (e) {
//       log("[Cubit] Failed to load hydration data: $e");
//       emit(state.copyWith(errorMessage: "Failed to load hydration data."));
//     }
//   }

//   /// Recalculate which slot is currently active and its completion %
//   void _calculateCurrentSlotStatus() {
//     final now = TimeOfDay.now();
//     final nowMinutes = _timeOfDayToMinutes(now);

//     HydrationEntry? activeEntry;
//     for (final entry in state.entries) {
//       final startMin = _timeOfDayToMinutes(entry.startTime);
//       final endMin = _timeOfDayToMinutes(entry.endTime);

//       if (startMin < endMin) {
//         if (nowMinutes >= startMin && nowMinutes < endMin) {
//           activeEntry = entry;
//           break;
//         }
//       } else {
//         if (nowMinutes >= startMin || nowMinutes < endMin) {
//           activeEntry = entry;
//           break;
//         }
//       }
//     }

//     double consumption = 0.0;
//     double percentage = 0.0;

//     if (activeEntry != null) {
//       consumption = activeEntry.waterDrank.toDouble();

//       if (activeEntry.amount > 0) {
//         percentage = (consumption / activeEntry.amount) * 100.0;
//         percentage = percentage.clamp(0.0, 100.0);
//       }
//     }

//     emit(state.copyWith(
//       currentSlotEntry: activeEntry,
//       currentSlotConsumption: consumption,
//       currentSlotPercentage: percentage,
//     ));
//   }

//   Future<void> loadSlotsFromDb() async {
//     try {
//       final slotsFromDb = await _dbHelper.getAllSlots();
//       log("[Cubit] _loadSlotsFromDb: Loaded ${slotsFromDb.length} slots");

//       if (slotsFromDb.isEmpty) {
//         emit(state.copyWith(entries: []));
//       } else {
//         // final total = slotsFromDb
//         //     .where((e) => e.status == HydrationStatus.completed)
//         //     .fold(0, (sum, e) => sum + e.amount);
//         final total = slotsFromDb
//             .where((e) => e.status == HydrationStatus.completed)
//             .fold(0.0, (sum, e) => sum + e.amount);

//         emit(state.copyWith(entries: slotsFromDb, totalDrank: total.round()));
//       }
//     } catch (e) {
//       log("[Cubit] Failed to load slots from DB: $e");
//       emit(state.copyWith(errorMessage: "Failed to load slots from DB."));
//     }
//   }

//   void toggleStatus(int index) {
//     final updated = List<HydrationEntry>.from(state.entries);
//     final entry = updated[index];

//     updated[index] = entry.copyWith(
//       status: entry.status == HydrationStatus.completed
//           ? HydrationStatus.pending
//           : HydrationStatus.completed,
//     );

//     final total = updated
//         .where((e) => e.status == HydrationStatus.completed)
//         .fold(0.0, (sum, e) => sum + e.amount);

//     emit(state.copyWith(
//         entries: updated,
//         totalDrank: total.round(),
//         errorMessage: null,
//         successMessage: null));
//   }

//   void updateDate(DateTime newDate) {
//     emit(state.copyWith(
//         selectedDate: newDate, errorMessage: null, successMessage: null));

//     // 🔁 Also update slot completion whenever date changes
//     updateSlotCompletionStatus();
//   }

//   void updateTimeSlot({
//     required HydrationSlot slot,
//     required TimeOfDay newStart,
//     required TimeOfDay newEnd,
//   }) async {
//     final newStartMin = _timeOfDayToMinutes(newStart);
//     final newEndMin = _timeOfDayToMinutes(newEnd);

//     if (newStartMin == newEndMin) {
//       emit(state.copyWith(
//         errorMessage: "Start and end time cannot be the same.",
//         successMessage: null,
//       ));
//       return;
//     }

//     final newIntervals = _toIntervals(newStartMin, newEndMin);

//     for (final entry in state.entries) {
//       if (entry.slot == slot) continue;

//       final existingIntervals = _toIntervals(
//         _timeOfDayToMinutes(entry.startTime),
//         _timeOfDayToMinutes(entry.endTime),
//       );

//       if (_intervalsOverlapAny(newIntervals, existingIntervals)) {
//         emit(state.copyWith(
//           errorMessage: "Time range overlaps with ${entry.slot.label}.",
//           successMessage: null,
//         ));
//         return;
//       }
//     }

//     final updated = state.entries.map((entry) {
//       if (entry.slot == slot) {
//         return entry.copyWith(startTime: newStart, endTime: newEnd);
//       }
//       return entry;
//     }).toList();

//     emit(state.copyWith(entries: updated));

//     _calculateCurrentSlotStatus();

//     final updatedEntry = updated.firstWhere((e) => e.slot == slot);
//     final notificationService = NotificationService();
//     await notificationService.cancelReminder(slot);
//     await notificationService.scheduleHydrationReminders([updatedEntry]);
//     await notificationService.testNotification();
//     await _dbHelper.insertOrUpdateSlot(updatedEntry);
//     ble.queueHydrationSlots(updated);
//   }

//   /// Called when BLE sends new hydration entries
//   Future<void> markCompletedByEntries(List<HydrationEntry> newEntries) async {
//     final currentEntries = List<HydrationEntry>.from(state.entries);

//     for (final incoming in newEntries) {
//       final index = currentEntries.indexWhere((e) => e.slot == incoming.slot);

//       if (index >= 0) {
//         final updatedEntry = currentEntries[index].copyWith(
//           waterDrank: incoming.waterDrank,
//           status: HydrationStatus.completed,
//         );
//         currentEntries[index] = updatedEntry;
//         await _dbHelper.insertOrUpdateSlot(updatedEntry);
//       } else {
//         final newEntry = incoming.copyWith(status: HydrationStatus.completed);
//         currentEntries.add(newEntry);
//         await _dbHelper.insertOrUpdateSlot(newEntry);
//       }
//     }

//     final total = currentEntries
//         .where((e) => e.status == HydrationStatus.completed)
//         .fold(0.0, (sum, e) => sum + e.waterDrank);

//     emit(state.copyWith(
//       entries: currentEntries,
//       totalDrank: total.round(),
//       errorMessage: null,
//       successMessage: "${newEntries.length} slot(s) marked as completed!",
//     ));

//     _calculateCurrentSlotStatus();
//   }

//   /// 🔁 NEW METHOD: auto-check completion based on water intake history
//   Future<void> updateSlotCompletionStatus() async {
//     try {
//       final selectedDate = state.selectedDate;
//       final startOfDay =
//           DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
//       final endOfDay = startOfDay.add(const Duration(days: 1));

//       // Fetch all bottle data for this day
//       final history =
//           await _dbHelper.getBottleDataForDateRange(startOfDay, endOfDay);

//       if (history.isEmpty) return;

//       final updatedEntries = <HydrationEntry>[];

//       for (final entry in state.entries) {
//         double slotIntake = 0;

//         for (final record in history) {
//           final recordTime = record.timestamp;
//           final recordVolume = record.liquidVolume.toDouble();

//           final startSlot = DateTime(recordTime.year, recordTime.month,
//               recordTime.day, entry.startTime.hour, entry.startTime.minute);
//           final endSlot = DateTime(recordTime.year, recordTime.month,
//               recordTime.day, entry.endTime.hour, entry.endTime.minute);

//           bool isInSlot = false;

//           if (_timeOfDayToMinutes(entry.startTime) <
//               _timeOfDayToMinutes(entry.endTime)) {
//             isInSlot =
//                 recordTime.isAfter(startSlot) && recordTime.isBefore(endSlot);
//           } else {
//             isInSlot =
//                 recordTime.isAfter(startSlot) || recordTime.isBefore(endSlot);
//           }

//           if (isInSlot) {
//             slotIntake += recordVolume;
//           }
//         }

//         final newStatus = slotIntake >= entry.amount
//             ? HydrationStatus.completed
//             : HydrationStatus.pending;

//         final updatedEntry = entry.copyWith(
//           waterDrank: slotIntake.round().toDouble(),
//           status: newStatus,
//         );

//         updatedEntries.add(updatedEntry);
//         await _dbHelper.insertOrUpdateSlot(updatedEntry);
//       }

//       final totalDrank = updatedEntries
//           .where((e) => e.status == HydrationStatus.completed)
//           .fold(0.0, (sum, e) => sum + e.waterDrank);

//       emit(state.copyWith(
//           entries: updatedEntries, totalDrank: totalDrank.round()));
//       _calculateCurrentSlotStatus();
//     } catch (e) {
//       log("[HydrationCubit] Error updating slot completion: $e");
//     }
//   }

//   void clearMessages() {
//     emit(state.copyWith(errorMessage: null, successMessage: null));
//   }

//   int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

//   /// Convert wrapping intervals (handles midnight overlap)
//   List<_Interval> _toIntervals(int startMin, int endMin) {
//     if (startMin < endMin) {
//       return [_Interval(startMin, endMin)];
//     } else {
//       return [_Interval(startMin, 1440), _Interval(0, endMin)];
//     }
//   }

//   List<HydrationEntry> generateDefaultHydrationSlots(double dailyGoalMl) {
//     return [
//       HydrationEntry(
//         slot: HydrationSlot.wakeup,
//         startTime: const TimeOfDay(hour: 6, minute: 0),
//         endTime: const TimeOfDay(hour: 8, minute: 0),
//         amount: dailyGoalMl * HydrationSlot.wakeup.percentage,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.breakfast,
//         startTime: const TimeOfDay(hour: 8, minute: 0),
//         endTime: const TimeOfDay(hour: 9, minute: 30),
//         amount: dailyGoalMl * HydrationSlot.breakfast.percentage,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.midMorning,
//         startTime: const TimeOfDay(hour: 9, minute: 30),
//         endTime: const TimeOfDay(hour: 11, minute: 30),
//         amount: dailyGoalMl * HydrationSlot.midMorning.percentage,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.lunch,
//         startTime: const TimeOfDay(hour: 12, minute: 0),
//         endTime: const TimeOfDay(hour: 14, minute: 0),
//         amount: dailyGoalMl * HydrationSlot.lunch.percentage,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.midAfternoon,
//         startTime: const TimeOfDay(hour: 15, minute: 0),
//         endTime: const TimeOfDay(hour: 17, minute: 0),
//         amount: dailyGoalMl * HydrationSlot.midAfternoon.percentage,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.evening,
//         startTime: const TimeOfDay(hour: 17, minute: 0),
//         endTime: const TimeOfDay(hour: 19, minute: 0),
//         amount: dailyGoalMl * HydrationSlot.evening.percentage,
//       ),
//       HydrationEntry(
//         slot: HydrationSlot.afterDinner,
//         startTime: const TimeOfDay(hour: 19, minute: 0),
//         endTime: const TimeOfDay(hour: 22, minute: 0),
//         amount: dailyGoalMl * HydrationSlot.afterDinner.percentage,
//       ),
//     ];
//   }

//   bool _intervalsOverlapAny(List<_Interval> aList, List<_Interval> bList) {
//     for (final a in aList) {
//       for (final b in bList) {
//         if (_intervalsOverlap(a.start, a.end, b.start, b.end)) return true;
//       }
//     }
//     return false;
//   }

//   bool _intervalsOverlap(int s1, int e1, int s2, int e2) {
//     return s1 < e2 && e1 > s2;
//   }
// }

// class _Interval {
//   final int start;
//   final int end;
//   _Interval(this.start, this.end);
// }

// -----------------------------------------------------------------------------

// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrify/cubit/ble/ble_cubit.dart';
// import 'package:hydrify/cubit/hydration/hydration_sync.dart';
// import 'package:hydrify/helpers/database_helper.dart';
// import 'package:hydrify/helpers/shared_pref_helper.dart';
// import 'package:hydrify/models/hydration_entry.dart';
// import 'package:hydrify/services/notification_service.dart';
// import 'package:intl/intl.dart';

// part 'hydration_state.dart';

// class HydrationCubit extends Cubit<HydrationState> {
//   final HydrationSync ble;

//   final DatabaseHelper _dbHelper = DatabaseHelper();

//   HydrationCubit({required this.ble})
//       : super(HydrationState(
//           entries: [],
//           totalDrank: 0,
//           goal: 0,
//           selectedDate: DateTime.now(),
//         )) {
//     _init();
//   }

//   void _calculateCurrentSlotStatus() {
//     final now = TimeOfDay.now();
//     final nowMinutes = _timeOfDayToMinutes(now);

//     HydrationEntry? activeEntry;
//     for (final entry in state.entries) {
//       final startMin = _timeOfDayToMinutes(entry.startTime);
//       final endMin = _timeOfDayToMinutes(entry.endTime);

//       if (startMin < endMin) {
//         if (nowMinutes >= startMin && nowMinutes < endMin) {
//           activeEntry = entry;
//           break;
//         }
//       } else {
//         if (nowMinutes >= startMin || nowMinutes < endMin) {
//           activeEntry = entry;
//           break;
//         }
//       }
//     }

//     double consumption = 0.0;
//     double percentage = 0.0;

//     if (activeEntry != null) {
//       consumption = activeEntry.waterDrank.toDouble();

//       if (activeEntry.amount > 0) {
//         percentage = (consumption / activeEntry.amount) * 100.0;
//         percentage = percentage.clamp(0.0, 100.0);
//       }
//     }

//     emit(state.copyWith(
//       currentSlotEntry: activeEntry,
//       currentSlotConsumption: consumption,
//       currentSlotPercentage: percentage,
//     ));
//   }

//   Future<void> _init() async {
//     try {
//       ble.hydrationUpdates.listen((entries) {
//         markCompletedByEntries(entries);
//       });
//       final dailyGoal = await SharedPrefsHelper.getUserGoal() ?? 0;
//       log("[Cubit] Daily goal: $dailyGoal");

//       final slotsFromDb = await _dbHelper.getAllSlots();
//       log("[Cubit] Loaded ${slotsFromDb.length} slots from DB");
//       for (var s in slotsFromDb) {
//         log("  Slot: ${s.slot.label}, amount: ${s.amount}, status: ${s.status}");
//       }

//       int total = slotsFromDb
//           .where((e) => e.status == HydrationStatus.completed)
//           .fold(0, (sum, e) => sum + e.amount);

//       emit(state.copyWith(
//         entries: slotsFromDb,
//         goal: dailyGoal,
//         totalDrank: total,
//       ));
//       _calculateCurrentSlotStatus();
//     } catch (e) {
//       log("[Cubit] Failed to load hydration data: $e");
//       emit(state.copyWith(errorMessage: "Failed to load hydration data."));
//     }
//   }

//   Future<void> loadSlotsFromDb() async {
//     try {
//       final slotsFromDb = await _dbHelper.getAllSlots();
//       log("[Cubit] _loadSlotsFromDb: Loaded ${slotsFromDb.length} slots");
//       for (var s in slotsFromDb) {
//         log("  Slot: ${s.slot.label}, amount: ${s.amount}, status: ${s.status}");
//       }

//       if (slotsFromDb.isEmpty) {
//         emit(state.copyWith(entries: []));
//       } else {
//         final total = slotsFromDb
//             .where((e) => e.status == HydrationStatus.completed)
//             .fold(0, (sum, e) => sum + e.amount);

//         emit(state.copyWith(entries: slotsFromDb, totalDrank: total));
//       }
//     } catch (e) {
//       log("[Cubit] Failed to load slots from DB: $e");
//       emit(state.copyWith(errorMessage: "Failed to load slots from DB."));
//     }
//   }

//   void toggleStatus(int index) {
//     final updated = List<HydrationEntry>.from(state.entries);
//     final entry = updated[index];

//     updated[index] = entry.copyWith(
//       status: entry.status == HydrationStatus.completed
//           ? HydrationStatus.pending
//           : HydrationStatus.completed,
//     );

//     final total = updated
//         .where((e) => e.status == HydrationStatus.completed)
//         .fold(0, (sum, e) => sum + e.amount);

//     emit(state.copyWith(
//         entries: updated,
//         totalDrank: total,
//         errorMessage: null,
//         successMessage: null));
//   }

//   void updateDate(DateTime newDate) {
//     emit(state.copyWith(
//         selectedDate: newDate, errorMessage: null, successMessage: null));
//   }

//   void updateTimeSlot({
//     required HydrationSlot slot,
//     required TimeOfDay newStart,
//     required TimeOfDay newEnd,
//   }) async {
//     final newStartMin = _timeOfDayToMinutes(newStart);
//     final newEndMin = _timeOfDayToMinutes(newEnd);

//     if (newStartMin == newEndMin) {
//       emit(state.copyWith(
//         errorMessage: "Start and end time cannot be the same.",
//         successMessage: null,
//       ));
//       return;
//     }

//     final newIntervals = _toIntervals(newStartMin, newEndMin);

//     for (final entry in state.entries) {
//       if (entry.slot == slot) continue;

//       final existingIntervals = _toIntervals(
//         _timeOfDayToMinutes(entry.startTime),
//         _timeOfDayToMinutes(entry.endTime),
//       );

//       if (_intervalsOverlapAny(newIntervals, existingIntervals)) {
//         emit(state.copyWith(
//           errorMessage: "Time range overlaps with ${entry.slot.label}.",
//           successMessage: null,
//         ));
//         return;
//       }
//     }

//     final updated = state.entries.map((entry) {
//       if (entry.slot == slot) {
//         return entry.copyWith(startTime: newStart, endTime: newEnd);
//       }
//       return entry;
//     }).toList();

//     emit(state.copyWith(entries: updated));

//     _calculateCurrentSlotStatus();

//     final updatedEntry = updated.firstWhere((e) => e.slot == slot);
//     final notificationService = NotificationService();
//     await notificationService.cancelReminder(slot);
//     await notificationService.scheduleHydrationReminders([updatedEntry]);
//     await notificationService.testNotification();
//     await _dbHelper.insertOrUpdateSlot(updatedEntry);
//     ble.queueHydrationSlots(updated);
//   }

//   Future<void> markCompletedByEntries(List<HydrationEntry> newEntries) async {
//     final currentEntries = List<HydrationEntry>.from(state.entries);

//     for (final incoming in newEntries) {
//       final index = currentEntries.indexWhere((e) => e.slot == incoming.slot);

//       if (index >= 0) {
//         final updatedEntry = currentEntries[index].copyWith(
//           waterDrank: incoming.waterDrank,
//           status: HydrationStatus.completed,
//         );

//         currentEntries[index] = updatedEntry;

//         await _dbHelper.insertOrUpdateSlot(updatedEntry);
//       } else {
//         final newEntry = incoming.copyWith(status: HydrationStatus.completed);

//         currentEntries.add(newEntry);

//         await _dbHelper.insertOrUpdateSlot(newEntry);
//       }
//     }
//     final total = currentEntries
//         .where((e) => e.status == HydrationStatus.completed)
//         .fold(0, (sum, e) => sum + e.waterDrank);

//     emit(state.copyWith(
//       entries: currentEntries,
//       totalDrank: total,
//       errorMessage: null,
//       successMessage: "${newEntries.length} slot(s) marked as completed!",
//     ));

//     _calculateCurrentSlotStatus();
//   }

//   void clearMessages() {
//     emit(state.copyWith(errorMessage: null, successMessage: null));
//   }

//   int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

//   /// Convert a possibly-wrapping range [startMin, endMin) to one or two intervals
//   /// If start < end -> single interval [start,end)
//   /// If start > end -> wraps midnight -> return [start,1440) and [0,end)
//   List<_Interval> _toIntervals(int startMin, int endMin) {
//     if (startMin < endMin) {
//       return [_Interval(startMin, endMin)];
//     } else {
//       // wrap-around
//       return [
//         _Interval(startMin, 1440),
//         _Interval(0, endMin),
//       ];
//     }
//   }

//   bool _intervalsOverlapAny(List<_Interval> aList, List<_Interval> bList) {
//     for (final a in aList) {
//       for (final b in bList) {
//         if (_intervalsOverlap(a.start, a.end, b.start, b.end)) return true;
//       }
//     }
//     return false;
//   }

//   bool _intervalsOverlap(int s1, int e1, int s2, int e2) {
//     return s1 < e2 && e1 > s2;
//   }
// }

// class _Interval {
//   final int start;
//   final int end;
//   _Interval(this.start, this.end);
// }
