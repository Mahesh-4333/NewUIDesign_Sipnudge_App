import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_manager.dart';

typedef NotificationTapCallback = void Function(HydrationSlot slot);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // REMOVED: final AudioPlayer _alarmPlayer = AudioPlayer();
  // REMOVED: Future<void> _startRingtoneLoop(String soundFile) async {...}
  // REMOVED: Future<void> _stopRingtone() async {...}
  // REMOVED: Future<String> _getSelectedRingtoneFile() async {...}

  NotificationTapCallback? onNotificationTap;

  Future<void> init({NotificationTapCallback? onTap}) async {
    tz.initializeTimeZones();

    // Initialize the new NotificationManager (which handles Alarm.init())
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
              'STOP_ACTION', // iOS action ID
              'Stop', // Button title
              options: {DarwinNotificationActionOption.foreground},
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

        // 🔥 STOP BUTTON PRESSED (Handles both Android Action and iOS Category Action)
        if (actionId != null && actionId.startsWith("STOP")) {
          // The payload or a different identifier is needed here.
          // Since the Alarm package manages the sound, we stop the ALARM ID,
          // which is the same as the notification ID (entry.slot.index).

          if (details.id != null) {
            await NotificationManager.instance.stopAlarm(details.id!);
            cancelReminder(HydrationSlot.values[details.id!]);
          }

          // Note: The notification is cancelled by the Android Action settings.

          // Optionally, if you scheduled a local notification, cancel it here too

          return;
        }

        // 🔹 Normal tap = Trigger the callback
        if (payload != null) {
          final slotIndex = int.parse(payload);
          // NOTE: The Alarm package handles the ringtone. No need to start it here.
          onNotificationTap?.call(HydrationSlot.values[slotIndex]);
        }
      },
    );

    // Permissions are now handled in NotificationManager.instance.initialize()
  }

  Future<String> _getSelectedRingtoneAssetPath() async {
    // Original logic: index 0 -> ringtone1
    final selected = await SharedPrefsHelper.getSelectedRingtone() ?? 0;
    final fileName = "ringtone${selected + 1}";

    // The 'alarm' package expects the path relative to the assets root,
    // not prefixed with 'assets/ringtones/'.
    // It should be 'ringtones/ringtone1.mp3' if your assets folder is set up correctly.
    return "assets/ringtones/$fileName.mp3";
  }

  /// Schedule a reminder with slot & goal info
  Future<void> scheduleHydrationReminders(List<HydrationEntry> entries) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final assetPath = await _getSelectedRingtoneAssetPath();

    for (final entry in entries) {
      final endDateTime = today.add(Duration(
        hours: entry.endTime.hour,
        minutes: entry.endTime.minute,
      ));

      var notifyAt = endDateTime.subtract(const Duration(minutes: 10));

      // Schedule the alarm to ring exactly at notifyAt
      if (notifyAt.isBefore(now)) {
        log(
            "[NotificationService] Skipping reminder for ${entry.slot.label} "
            "(${entry.amount}ml) because notifyAt=$notifyAt is before now=$now",
            name: "NotificationService");
        continue;
      }

      log(
        "[NotificationService] Scheduling ALARM and Notification for ${entry.slot.label} "
        "(${entry.amount}ml) at $notifyAt (current time: $now)",
      );

      final customTitle = "Hydration Reminder";
      final customBody =
          "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml";

      final alarmSet = await NotificationManager.instance.setReliableAlarm(
        id: entry.slot.index,
        dateTime: notifyAt,
        assetAudioPath: assetPath,
        // Pass the custom text
        title: customTitle,
        body: customBody,
        stopButtonText: 'Drink Water & Stop',
        maxDurationSeconds: 5,
      );

      if (!alarmSet) {
        log('Failed to set reliable alarm for ${entry.slot.label}');
        continue;
      }
/*
      // 2. Schedule a simple local notification to display the custom body/title
      // This serves as a backup display and maintains the payload tap logic.
      await _plugin.zonedSchedule(
        entry.slot.index, // unique ID per slot
        "Hydration Reminder", // TITLE (Kept from original)
        "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml", // BODY (Kept from original)
        tz.TZDateTime.from(notifyAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel_${entry.slot.index}',
            'Hydration Popup',
            channelDescription: 'Popup hydration reminders',
            importance: Importance.max,
            priority: Priority.max,
            playSound: false, // The Alarm package handles the sound
            groupKey: null,
            setAsGroupSummary: false,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true, // Let the Alarm package handle this
            visibility: NotificationVisibility.public,
            ongoing: true,
            autoCancel: false,

            // ACTION BUTTONS (Kept from original logic)
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'STOP_ACTION', // Use a generic STOP ID here
                'STOP',
                // icon: DrawableResourceAndroidBitmap('stop_ic'), // Requires resource setup
                showsUserInterface: true,
                cancelNotification: true, // Cancels the *local* notification
              ),
            ],
          ),
          // iOS Category Identifier is needed for the action
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'hydration_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: entry.slot.index.toString(),
      );
*/
      log(
          "[NotificationService] Successfully scheduled for ${entry.slot.label} "
          "at ${tz.TZDateTime.from(notifyAt, tz.local)}",
          name: "NotificationService");
    }
  }

  Future<void> cancelReminder(HydrationSlot slot) async {
    // Cancel the local notification
    await _plugin.cancel(slot.index);
    // Cancel the scheduled alarm from the alarm package
    await NotificationManager.instance.stopAlarm(slot.index);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    // Stop ALL alarms
    await NotificationManager.instance
        .stopAlarm(0); // The alarm package's stopAll uses 0
  }
}
