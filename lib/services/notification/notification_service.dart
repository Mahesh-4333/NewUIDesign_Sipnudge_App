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
    Console.log(tag: "APP", value: "Notification tapped in background/killed state: ${details.id}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _scheduleDaysAheadRepeat = 2;
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

  Future<String> _getSelectedRingtoneAssetPath() async {
    final selected = await SharedPrefsHelper.getSelectedRingtone() ?? 0;
    final fileName = "ringtone${selected + 1}";
    return "assets/ringtones/$fileName.mp3";
  }

  Future<void> _scheduleIOSHydrationNotification(
      {required int id,
      required DateTime notifyAt,
      required String title,
      required String body,
      required String payload,
      required bool isSilent}) async {
    final selected = await SharedPrefsHelper.getSelectedRingtone() ?? 0;
    final fileName = "ringtone${selected + 1}.caf";
    Console.log(tag: "APP", value: "=-=-=-=- IOS Reminder set ${fileName} isSilent ${isSilent}");

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(notifyAt, tz.local),
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
            criticalSoundVolume: 0.9, // 0.0 to 1.0
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
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

  Future<void> scheduleHydrationRemindersForFuture(
      List<HydrationEntry> entries) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();

    // Get settings
    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();

    // Map index to repeat counts (3, 5, 10 times)
    final alarmRepeatTimes = [1, 3, 5, 10][alarmRepeatIndex];

    for (int dayOffset = 0; dayOffset < _scheduleDaysAheadRepeat; dayOffset++) {
      final baseDay = today.add(Duration(days: dayOffset));

      for (final entry in entries) {
        final endDateTime = baseDay.add(Duration(
          hours: entry.endTime.hour,
          minutes: entry.endTime.minute,
        ));

        // Base 10-minute alarm point (Start of the last 10 minutes)
        final baseAlarmTime =
            endDateTime.subtract(const Duration(minutes: 10));

        if (dayOffset == 0 &&
            stopWhenFull &&
            entry.status == HydrationStatus.completed) {
          continue;
        }

        // Requirement: "when end time is 10:00Pm there is slot reminder set to 9:50 right 
        // and reminder will repeat based on alarm repeat 3,5,10 times in last 10 min."
        
        // Calculate interval to spread repeats across 10 minutes
        // For example, if alarmRepeatTimes is 5, reminders could be every 2 minutes.
        // If 10, every 1 minute. If 3, approx every 3.3 minutes.
        final double intervalMinutes = 10.0 / alarmRepeatTimes;

        for (int repeat = 0; repeat < alarmRepeatTimes; repeat++) {
          final notifyAt = baseAlarmTime.add(Duration(
            seconds: (repeat * intervalMinutes * 60).toInt(),
          ));

          if (notifyAt.isBefore(now)) continue;

          await _scheduleSingleReminder(
            entry: entry,
            notifyAt: notifyAt,
            shouldSilence: false,
            dayOffset: dayOffset,
            repeatIndex: repeat,
          );
        }
      }
    }
  }

  Future<void> _scheduleSingleReminder({
    required HydrationEntry entry,
    required DateTime notifyAt,
    required bool shouldSilence,
    required int dayOffset,
    int repeatIndex = 1111,
  }) async {
    final id = _buildNotificationId(entry.slot, dayOffset, repeatIndex);

    final nowDate = DateTime.now();
    final today = DateTime(nowDate.year, nowDate.month, nowDate.day);
    final endDateTime = today.add(Duration(
      days: dayOffset,
      hours: entry.endTime.hour,
      minutes: entry.endTime.minute,
    ));

    final remainingMinutes = endDateTime.difference(notifyAt).inMinutes;

    final title = "Hydration Reminder";
    final body =
        "Only ${math.max(0, remainingMinutes)} minutes left for ${entry.slot.label} – Drink ${entry.amount} ml";

    bool isRingtoneFeedbackEnabled =
        await SharedPrefsHelper.getRingtoneFeedBack();

    if (shouldSilence == false) {
      // Google says not to silence , then use the value of isRingtoneFeedbackEnabled
      shouldSilence = !isRingtoneFeedbackEnabled;
    }
    if (Platform.isIOS) {
      Console.log(tag: "APP", value: "Should Silence ${shouldSilence}");
      await _scheduleIOSHydrationNotification(
        id: id,
        notifyAt: notifyAt,
        title: title,
        body: body,
        payload: entry.slot.index.toString(),
        isSilent: shouldSilence,
      );
    } else {
      final assetPath = await _getSelectedRingtoneAssetPath();

      await NotificationManager.instance.setReliableAlarm(
        id: id,
        dateTime: notifyAt,
        assetAudioPath: assetPath,
        title: title,
        body: body,
        stopButtonText: 'Drink Water & Stop',
        isSilent: shouldSilence,
      );
    }
  }

  Future<void> rescheduleSlotForFuture(
    HydrationEntry updatedEntry,
  ) async {
    for (int dayOffset = 0; dayOffset < _scheduleDaysAheadRepeat; dayOffset++) {
      final id = _buildNotificationId(updatedEntry.slot, dayOffset);

      await _plugin.cancel(id);

      if (Platform.isAndroid) {
        await NotificationManager.instance.stopAlarm(id);
      }
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
  }

  Future<void> cancelAllHydrationReminders() async {
    await _plugin.cancelAll();

    for (int dayOffset = 0; dayOffset < _scheduleDaysAheadRepeat; dayOffset++) {
      for (final slot in HydrationSlot.values) {
        for (int repeat = 0; repeat < 10; repeat++) {
          final id = _buildNotificationId(slot, dayOffset, repeat);
          if (Platform.isAndroid) {
            await NotificationManager.instance.stopAlarm(id);
          }
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

    // Cancel all repeat reminders (up to 10)
    for (int repeat = 0; repeat < 10; repeat++) {
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
}
