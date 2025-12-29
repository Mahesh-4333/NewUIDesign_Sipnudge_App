import 'dart:developer';
import 'dart:io';

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
    log("Notification tapped in background/killed state: ${details.id}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _scheduleDaysAhead = 10;
  NotificationTapCallback? onNotificationTap;

  Future<void> init({NotificationTapCallback? onTap}) async {
    tz.initializeTimeZones();

    await NotificationManager.instance.initialize();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
    log("=-=-=-=- IOS Reminder set ${fileName}");

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
          // subtitle: "Swipe up to stop the reminder",
          interruptionLevel: isSilent
              ? InterruptionLevel.passive
              : InterruptionLevel.timeSensitive,
          categoryIdentifier: 'hydration_category',
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
      log('[Calendar] Failed to check calendar: $e');
      return false; // fail-safe → normal reminder
    }
  }

  Future<void> scheduleHydrationRemindersForFuture(
    List<HydrationEntry> entries,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int dayOffset = 0; dayOffset < _scheduleDaysAhead; dayOffset++) {
      final baseDay = today.add(Duration(days: dayOffset));

      for (final entry in entries) {
        final endDateTime = baseDay.add(Duration(
          hours: entry.endTime.hour,
          minutes: entry.endTime.minute,
        ));

        final notifyAt = endDateTime.subtract(const Duration(minutes: 10));

        if (notifyAt.isBefore(now)) continue;

        final shouldSilence = false;
        // await _shouldSilenceHydrationReminder(notifyAt);

        await _scheduleSingleReminder(
          entry: entry,
          notifyAt: notifyAt,
          shouldSilence: shouldSilence,
          dayOffset: dayOffset,
        );
      }
    }
  }

  Future<void> _scheduleSingleReminder({
    required HydrationEntry entry,
    required DateTime notifyAt,
    required bool shouldSilence,
    required int dayOffset,
  }) async {
    final id = _buildNotificationId(entry.slot, dayOffset);

    final title = "Hydration Reminder";
    final body =
        "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml";

    bool isRingtoneFeedbackEnabled =
        await SharedPrefsHelper.getRingtoneFeedBack();

    if (shouldSilence == false) {
      // Google says not to silence , then use the value of isRingtoneFeedbackEnabled
      shouldSilence = !isRingtoneFeedbackEnabled;
    }

    if (isRingtoneFeedbackEnabled) {
      shouldSilence = false;
    }
    if (Platform.isIOS) {
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
    for (int dayOffset = 0; dayOffset < _scheduleDaysAhead; dayOffset++) {
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
    int dayOffset,
  ) {
    return (dayOffset * 100) + slot.index;
  }

  Future<void> resetAllHydrationReminders(
    List<HydrationEntry> newEntries,
  ) async {
    await cancelAllHydrationReminders();
    await scheduleHydrationRemindersForFuture(newEntries);
  }

  Future<void> cancelAllHydrationReminders() async {
    await _plugin.cancelAll();

    for (int dayOffset = 0; dayOffset < _scheduleDaysAhead; dayOffset++) {
      for (final slot in HydrationSlot.values) {
        final id = _buildNotificationId(slot, dayOffset);

        if (Platform.isAndroid) {
          await NotificationManager.instance.stopAlarm(id);
        }
      }
    }
  }

  HydrationSlot _slotFromNotificationId(int id) {
    final slotIndex = id % 100;
    return HydrationSlot.values[slotIndex];
  }
}
