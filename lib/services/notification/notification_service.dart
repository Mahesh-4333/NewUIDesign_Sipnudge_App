import 'package:hydrify/helpers/logger.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/services/google_calendar_manager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_manager.dart';

typedef NotificationTapCallback = void Function(HydrationSlot slot);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  if (details.id != null) {
    Console.log(
        tag: "APP",
        value: "Notification tapped in background/killed state: ${details.id}");
  }
}

class ScheduledNotification {
  final int id;
  final DateTime dateTime;
  final String title;
  final String body;
  final String? payload;

  ScheduledNotification({
    required this.id,
    required this.dateTime,
    required this.title,
    required this.body,
    this.payload,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationTapCallback? onNotificationTap;

  Future<void> init({NotificationTapCallback? onTap}) async {
    tz.initializeTimeZones();

    await NotificationManager.instance.initialize();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Retained iOS Category for the notification action
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'hydration_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'STOP_ACTION',
              'Stop',
              options: {},
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    onNotificationTap = onTap;

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        final payload = details.payload;
        final actionId = details.actionId;
        final notificationId = details.id;

        if (notificationId != null) {
          await NotificationManager.instance.stopAlarm(notificationId);

          await _plugin.cancel(notificationId);
        }
        if (actionId == 'STOP_ACTION' ||
            (actionId != null && actionId.startsWith("STOP"))) {
          return;
        }

        if (payload != null) {
          final slotIndex = int.tryParse(payload);
          if (slotIndex != null &&
              slotIndex >= 0 &&
              slotIndex < HydrationSlot.values.length) {
            onNotificationTap?.call(HydrationSlot.values[slotIndex]);
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final NotificationAppLaunchDetails? launchDetails =
        await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleTapLogic(launchDetails!.notificationResponse!);
    }
  }

  void _handleTapLogic(NotificationResponse details) async {
    if (details.id != null) {
      await NotificationManager.instance.stopAlarm(details.id!);
      await _plugin.cancel(details.id!);
    }

    final payload = details.payload;
    if (payload != null && onNotificationTap != null) {
      final slotIndex = int.tryParse(payload);
      if (slotIndex != null && slotIndex < HydrationSlot.values.length) {
        onNotificationTap!(HydrationSlot.values[slotIndex]);
      }
    }
  }

  /// Schedules a notification that fires at [notifyAt] and then repeats
  /// **every day at the same time forever** — no re-scheduling required.
  ///
  /// Uses [DateTimeComponents.time] so the OS handles the daily repetition
  /// natively on both Android and iOS.
  Future<void> _scheduleDailyRepeatingNotification({
    required int id,
    required DateTime notifyAt,
    required String title,
    required String body,
    required String payload,
    required bool isSilent,
  }) async {
    final tzNotifyAt = tz.TZDateTime.from(notifyAt, tz.local);

    if (Platform.isIOS) {
      final selected = await SharedPrefsHelper.getSelectedRingtone() ?? 0;
      final fileName = "ringtone${selected + 1}.caf";
      Console.log(
          tag: "APP",
          value:
              "[iOS] Daily repeat scheduled id=$id at $notifyAt sound=$fileName silent=$isSilent");

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzNotifyAt,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            sound: fileName,
            presentAlert: true,
            presentSound: !isSilent,
            subtitle: "Swipe to stop the reminder",
            interruptionLevel: isSilent
                ? InterruptionLevel.passive
                : InterruptionLevel.critical,
            categoryIdentifier: 'hydration_category',
            criticalSoundVolume: 0.9,
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        // ✅ Repeats daily at the same time forever
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      // Android — use flutter_local_notifications with daily repeat.
      // Sound file must exist in android/app/src/main/res/raw/.
      final selected = await SharedPrefsHelper.getSelectedRingtone() ?? 0;
      final soundName = "ringtone${selected + 1}";
      Console.log(
          tag: "APP",
          value:
              "[Android] Daily repeat scheduled id=$id at $notifyAt sound=$soundName silent=$isSilent");

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzNotifyAt,
        NotificationDetails(
          android: AndroidNotificationDetails(
            // Unique channel per ringtone so Android picks the right sound.
            'hydration_daily_$soundName',
            'Hydration Reminders',
            channelDescription: 'Daily hydration reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: !isSilent,
            sound: isSilent
                ? null
                : RawResourceAndroidNotificationSound(soundName),
            enableVibration: true,
            category: AndroidNotificationCategory.reminder,
            actions: [
              const AndroidNotificationAction(
                'STOP_ACTION',
                'Drink Water \u0026 Stop',
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: payload,
        // ✅ exactAllowWhileIdle fires even in Doze mode
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // ✅ Repeats daily at the same time forever — no re-schedule needed!
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<bool> _shouldSilenceHydrationReminder(DateTime notifyAt) async {
    try {
      final calendarManager = GoogleCalendarManager();
      return await calendarManager.hasOverlappingEvent(
        notifyAt,
        notifyAt.add(const Duration(minutes: 5)),
      );
    } catch (e) {
      Console.log(tag: "APP", value: '[Calendar] Failed to check calendar: $e');
      return false; // fail-safe → normal reminder
    }
  }

  /// Schedules hydration reminders that repeat **every day at the same time forever**.
  ///
  /// This replaces the old 2-day-ahead loop. A single [zonedSchedule] call with
  /// [matchDateTimeComponents.time] handles indefinite daily repetition natively,
  /// so there is no need to call this again on every app launch.
  ///
  /// Call [cancelAllHydrationReminders] first if you want to reset the schedule.
  Future<void> scheduleHydrationRemindersForFuture(
      List<HydrationEntry> entries) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    final alarmRepeatTimes = [1, 3, 5, 10][alarmRepeatIndex];

    // ✅ No outer dayOffset loop — matchDateTimeComponents.time repeats daily forever.
    for (final entry in entries) {
      final endDateTime = today.add(Duration(
        hours: entry.endTime.hour,
        minutes: entry.endTime.minute,
      ));

      // Start of the last-10-minutes window before the slot ends.
      final baseAlarmTime = endDateTime.subtract(const Duration(minutes: 10));
      final double intervalMinutes = 10.0 / alarmRepeatTimes;

      for (int repeat = 0; repeat < alarmRepeatTimes; repeat++) {
        var notifyAt = baseAlarmTime.add(Duration(
          seconds: (repeat * intervalMinutes * 60).toInt(),
        ));

        // Robustly advance past any already-elapsed time (handles DST edges too).
        while (
            notifyAt.isBefore(now) || notifyAt.difference(now).inSeconds < 5) {
          notifyAt = notifyAt.add(const Duration(days: 1));
        }

        // dayOffset=0 — ID encodes slot+repeat only; daily repeat handles the rest.
        await _scheduleSingleReminder(
          entry: entry,
          notifyAt: notifyAt,
          shouldSilence: false,
          dayOffset: 0,
          repeatIndex: repeat,
        );
      }
    }
  }

  Future<void> _scheduleSingleReminder({
    required HydrationEntry entry,
    required DateTime notifyAt,
    required bool shouldSilence,
    required int dayOffset,
    int repeatIndex = 0,
  }) async {
    final id = _buildNotificationId(entry.slot, dayOffset, repeatIndex);

    final nowDate = DateTime.now();
    final today = DateTime(nowDate.year, nowDate.month, nowDate.day);
    final endDateTime = today.add(Duration(
      hours: entry.endTime.hour,
      minutes: entry.endTime.minute,
    ));

    final remainingMinutes = endDateTime.difference(notifyAt).inMinutes;
    final title = "Hydration Reminder";
    final body =
        "Only ${math.max(0, remainingMinutes)} minutes left for ${entry.slot.label} – Drink ${entry.amount.toInt()} ml";

    final isRingtoneFeedbackEnabled =
        await SharedPrefsHelper.getRingtoneFeedBack();

    if (!shouldSilence) {
      shouldSilence = !isRingtoneFeedbackEnabled;
    }

    // ✅ Unified path: both iOS and Android use daily-repeating zonedSchedule.
    await _scheduleDailyRepeatingNotification(
      id: id,
      notifyAt: notifyAt,
      title: title,
      body: body,
      payload: entry.slot.index.toString(),
      isSilent: shouldSilence,
    );
  }

  Future<void> rescheduleSlotForFuture(
    HydrationEntry updatedEntry,
  ) async {
    // With the daily-repeating system, all IDs use dayOffset=0.
    // Cancel at most 10 repeat IDs (the maximum alarmRepeatTimes).
    // No dayOffset loop needed — other day offsets don't exist anymore.
    for (int repeat = 0; repeat < 10; repeat++) {
      final id = _buildNotificationId(updatedEntry.slot, 0, repeat);
      await _plugin.cancel(id);
    }

    await scheduleHydrationRemindersForFuture([updatedEntry]);
  }

  int _buildNotificationId(
    HydrationSlot slot,
    int dayOffset, [
    int repeatIndex = 0,
  ]) {
    // Unique ID: (DayOffset * 1000) + (SlotIndex * 10) + RepeatIndex
    // This allows up to 10 repeats per slot per day.
    return (dayOffset * 1000) + (slot.index * 10) + repeatIndex;
  }

  Future<void> resetAllHydrationReminders(
    List<HydrationEntry> newEntries,
  ) async {
    await cancelAllHydrationReminders();
    // Small delay so the Android OS fully processes cancelAll() before
    // new zonedSchedule() calls are issued, preventing race-condition skips.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> cancelAllHydrationReminders() async {
    await _plugin.cancelAll();

    // Only dayOffset=0 IDs exist in the daily-repeat system.
    // Use the actual repeat count from prefs so we cancel exactly the IDs that were scheduled.
    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    final alarmRepeatTimes = [1, 3, 5, 10][alarmRepeatIndex];

    for (final slot in HydrationSlot.values) {
      for (int repeat = 0; repeat < alarmRepeatTimes; repeat++) {
        final id = _buildNotificationId(slot, 0, repeat);
        if (Platform.isAndroid) {
          await NotificationManager.instance.stopAlarm(id);
        }
      }
    }
  }

  Future<void> cancelSlotReminders(HydrationSlot slot, int dayOffset) async {
    // Cancel the base reminder
    final baseId = _buildNotificationId(slot, dayOffset);
    await _plugin.cancel(baseId);
    if (Platform.isAndroid) {
      await NotificationManager.instance.stopAlarm(baseId);
    }

    // Cancel only the repeat IDs that were actually scheduled.
    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    final alarmRepeatTimes = [1, 3, 5, 10][alarmRepeatIndex];

    for (int repeat = 0; repeat < alarmRepeatTimes; repeat++) {
      final repeatId = _buildNotificationId(slot, dayOffset, repeat);
      await _plugin.cancel(repeatId);
      if (Platform.isAndroid) {
        await NotificationManager.instance.stopAlarm(repeatId);
      }
    }
  }

  HydrationSlot _slotFromNotificationId(int id) {
    final slotIndex = id % 100;
    return HydrationSlot.values[slotIndex];
  }

  /// Returns the next-7-days scheduled notifications for display purposes.
  ///
  /// Because the underlying triggers are daily-repeating, we compute the
  /// upcoming occurrences across the next 7 days to give the user a meaningful
  /// preview of when their reminders will fire.
  Future<List<ScheduledNotification>> getCalculatedScheduledNotifications(
    List<HydrationEntry> entries,
  ) async {
    final List<ScheduledNotification> scheduled = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    final alarmRepeatTimes = [1, 3, 5, 10][alarmRepeatIndex];
    final double intervalMinutes = 10.0 / alarmRepeatTimes;

    // Preview the next 7 days of occurrences for the list view.
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final baseDay = today.add(Duration(days: dayOffset));

      for (final entry in entries) {
        final endDateTime = baseDay.add(Duration(
          hours: entry.endTime.hour,
          minutes: entry.endTime.minute,
        ));

        final baseAlarmTime = endDateTime.subtract(const Duration(minutes: 10));

        for (int repeat = 0; repeat < alarmRepeatTimes; repeat++) {
          final notifyAt = baseAlarmTime.add(Duration(
            seconds: (repeat * intervalMinutes * 60).toInt(),
          ));

          if (notifyAt.isBefore(now)) continue;

          // All daily-repeating notifications use dayOffset=0 in their actual ID.
          final id = _buildNotificationId(entry.slot, 0, repeat);
          final remainingMinutes = endDateTime.difference(notifyAt).inMinutes;

          scheduled.add(ScheduledNotification(
            id: id,
            dateTime: notifyAt,
            title: "Hydration Reminder",
            body:
                "Only ${math.max(0, remainingMinutes)} minutes left for ${entry.slot.label} – Drink ${entry.amount.toInt()} ml",
            payload: entry.slot.index.toString(),
          ));
        }
      }
    }

    scheduled.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return scheduled;
  }

  /// Retrieves the strictly active scheduled notifications currently registered in the OS.
  /// Maps the pending IDs back to their next projected occurrence time.
  Future<List<ScheduledNotification>> getActiveScheduledNotifications(
    List<HydrationEntry> entries,
  ) async {
    // 1. Ask the OS what is actually scheduled right now
    final pendingRequests = await _plugin.pendingNotificationRequests();
    final activeIds = pendingRequests.map((e) => e.id).toSet();

    // 2. Get the complete projection for the coming days
    final calculated = await getCalculatedScheduledNotifications(entries);

    // 3. Filter down to the first upcoming occurrence for each active ID
    final List<ScheduledNotification> activeOccurrences = [];
    final seenIds = <int>{};

    for (final calc in calculated) {
      if (activeIds.contains(calc.id) && !seenIds.contains(calc.id)) {
        activeOccurrences.add(calc);
        seenIds.add(calc.id);
      }
    }

    // Sort by chronological firing order
    activeOccurrences.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return activeOccurrences;
  }
}
