import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/google_event.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/schedule_timeline_item.dart';
import 'package:hydrify/services/google_calendar_manager.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

part 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final GoogleCalendarManager _calendarManager = GoogleCalendarManager();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Initialize with a default state
  CalendarCubit()
      : super(CalendarState(
          selectedDate: DateTime.now(),
          displayedMonth: DateTime.now(),
        ));

  Future<void> init(DateTime initialDate) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    await _loadDataForDate(initialDate, displayedMonth: initialDate);
  }

  /// Called when the user taps a specific day on the calendar
  Future<void> selectDate(DateTime newDate) async {
    emit(state.copyWith(isSyncing: true, selectedDate: newDate));
    await _loadDataForDate(newDate, displayedMonth: state.displayedMonth);
  }

  Future<void> changeMonthNYear(DateTime newMonthNYear) async {
    final normalizedDate = DateTime(newMonthNYear.year, newMonthNYear.month, 1);
    log("Changing month to: $normalizedDate");
    emit(state.copyWith(
      displayedMonthNYear: normalizedDate,
      selectedDate: normalizedDate,
      isSyncing: true,
    ));

    await _loadDataForDate(normalizedDate, displayedMonth: normalizedDate);
  }

  Future<void> syncGoogleCalendar() async {
    emit(state.copyWith(isSyncing: true, status: CalendarStatus.loading));
    await _loadDataForDate(state.selectedDate,
        displayedMonth: state.displayedMonth);
  }

  Future<void> goToToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final currentSelected = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );

    log("=-=-=-=-=-=- Current Selected ${currentSelected.toString()} =-=-=-=-=-=-=-");
    if (!currentSelected.isAtSameMomentAs(today)) {
      log("=-=-=-=- Navigating to Today: $today =-=-=-=-=");

      emit(state.copyWith(
        status: CalendarStatus.loading,
        isSyncing: true,
        selectedDate: today,
        displayedMonthNYear: today,
      ));

      await _loadDataForDate(today, displayedMonth: today);
    } else {
      log("Already on today's date.");
    }
  }

  /// Toggles the snooze state of a specific reminder
  void toggleSnooze(String goalId) {
    // final currentState = state;
    // if (currentState is CalendarLoaded) {
    //   final updatedSchedule = currentState.dailySchedule.map((item) {
    //     if (item.entry.id == goalId) {
    //       final updatedGoal =
    //           item.goal.copyWith(isSnoozed: !item.goal.isSnoozed);
    //       return ScheduleTimelineItem(
    //           goal: updatedGoal, overlappingEvents: item.overlappingEvents);
    //     }
    //     return item;
    //   }).toList();

    //   emit(currentState.copyWith(dailySchedule: updatedSchedule));

    //   // TODO: Update the snooze status in your local database so it doesn't fire
    //   // _hydrationRepo.updateSnoozeStatus(goalId, isSnoozed);
    // }
  }

  // --- PRIVATE HELPER METHODS ---

// Helper function to convert TimeOfDay to a full DateTime for the selected date
  DateTime _timeOfDayToDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _loadDataForDate(DateTime targetDate,
      {required DateTime displayedMonth}) async {
    log("--- Calendar Load Started ---");
    log("Target Date: $targetDate");
    log("Displayed Month: $displayedMonth");

    try {
      final startOfDay =
          DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      log("Fetched start ${startOfDay} end {$endOfDay} Google Events");
      final rawEvents =
          await _calendarManager.fetchEventsForRange(startOfDay, endOfDay);
      final googleEvents = _parseRawEvents(rawEvents);
      log("Fetched ${googleEvents.length} Google Events");

      final hydrationSlots = await _databaseHelper.getAllSlots();
      log("Fetched ${hydrationSlots.length} Hydration Slots");

      final unsnoozedSlotIndices = await SharedPrefsHelper.getUnsnoozedSlots();
      final Set<HydrationSlot> unsilenced = unsnoozedSlotIndices
          .map((idx) => HydrationSlot.values[idx])
          .toSet();

      final List<ScheduleTimelineItem> timeline = [];

      final now = DateTime.now();
      final isToday = targetDate.year == now.year &&
          targetDate.month == now.month &&
          targetDate.day == now.day;

      for (final entry in hydrationSlots) {
        final slotStartDateTime = _timeOfDayToDateTime(targetDate, entry.startTime);
        final slotEndDateTime = _timeOfDayToDateTime(targetDate, entry.endTime);

        final overlapping = googleEvents.where((event) {
          // Check if the event overlaps with the entire hydration slot duration
          return event.startTime.isBefore(slotEndDateTime) &&
              event.endTime.isAfter(slotStartDateTime);
        }).toList();

        if (isToday) {
          final isManuallyUnsilenced = unsilenced.contains(entry.slot);
          final shouldSilence = overlapping.isNotEmpty && !isManuallyUnsilenced;

          // Dynamically update the notification to be silent if there's an overlap today
          // but respect the manual 'unsilenced' state if the user chose to unmute.
          await NotificationService()
              .updateSlotSilenceState(entry, shouldSilence);
        }

        timeline.add(ScheduleTimelineItem(
          entry: entry,
          overlappingEvents: overlapping.take(3).toList(),
        ));
      }

      final daysWithEvents =
          googleEvents.isNotEmpty ? [startOfDay] : <DateTime>[];

      log("Emitting Loaded State: SelectedDate=${targetDate.toIso8601String()}");

      emit(state.copyWith(
        status: CalendarStatus.loaded,
        selectedDate: targetDate,
        displayedMonthNYear: displayedMonth,
        dailySchedule: timeline,
        selectedDayEvents: googleEvents,
        isSyncing: false,
        unsilencedSlots: unsilenced,
      ));
      log("--- Load Complete ---");
    } catch (e, stacktrace) {
      log("Error in _loadDataForDate: $e");
      log("Stacktrace: $stacktrace");
      emit(state.copyWith(
        status: CalendarStatus.error,
        errorMessage: "Failed to load schedule: $e",
        isSyncing: false,
      ));
    }
  }

  void unsnoozeSlot(HydrationEntry entry) async {
    // Persist to shared prefs
    await SharedPrefsHelper.saveUnsnoozedSlot(entry.slot.index);
    
    final updatedUnsilenced = Set<HydrationSlot>.from(state.unsilencedSlots);
    updatedUnsilenced.add(entry.slot);
    emit(state.copyWith(unsilencedSlots: updatedUnsilenced));
    // Re-trigger load to refresh UI after unsilencing
    _loadDataForDate(state.selectedDate, displayedMonth: state.displayedMonth);
  }

  List<GoogleEvent> _parseRawEvents(List<Map<String, dynamic>> rawData) {
    return rawData.map((data) {
      final startRaw = data['start'];
      final endRaw = data['end'];

      DateTime startTime = DateTime.now();
      DateTime endTime = DateTime.now();

      if (startRaw['dateTime'] != null) {
        startTime = DateTime.parse(startRaw['dateTime']).toLocal();
        endTime = DateTime.parse(endRaw['dateTime']).toLocal();
      } else if (startRaw['date'] != null) {
        startTime = DateTime.parse(startRaw['date']).toLocal();
        endTime = DateTime.parse(endRaw['date']).toLocal();
      }

      return GoogleEvent(
        id: data['id'] ?? '',
        title: data['summary'] ?? 'Busy',
        location: data['location'],
        startTime: startTime,
        endTime: endTime,
      );
    }).toList();
  }

  Future<List<HydrationEntry>> _getSlots() async {
    return await _databaseHelper.getAllSlots();
  }
}
