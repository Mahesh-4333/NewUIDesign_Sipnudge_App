import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/hydration_entry.dart';

typedef NotificationTapCallback = void Function(HydrationSlot slot);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationTapCallback? onNotificationTap;
  Future<void> init({NotificationTapCallback? onTap}) async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    onNotificationTap = onTap;

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          final slot = HydrationSlot.values[int.parse(payload)];
          onNotificationTap?.call(slot);
        }
      },
    );

    // 🔹 iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // 🔹 macOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // 🔹 Android 13+ runtime notification permission
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // Future<void> init({NotificationTapCallback? onTap}) async {
  //   tz.initializeTimeZones();

  //   const androidSettings =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const iosSettings = DarwinInitializationSettings();

  //   const initSettings = InitializationSettings(
  //     android: androidSettings,
  //     iOS: iosSettings,
  //   );

  //   onNotificationTap = onTap;

  //   await _plugin.initialize(
  //     initSettings,
  //     onDidReceiveNotificationResponse: (details) {
  //       final payload = details.payload;
  //       if (payload != null) {
  //         final slot = HydrationSlot.values[int.parse(payload)];
  //         onNotificationTap?.call(slot);
  //       }
  //     },
  //   );

  //   // iOS only
  //   await _plugin
  //       .resolvePlatformSpecificImplementation<
  //           IOSFlutterLocalNotificationsPlugin>()
  //       ?.requestPermissions(alert: true, badge: true, sound: true);
  // }

  /// Schedule a reminder with slot & goal info
  Future<void> scheduleHydrationReminders(List<HydrationEntry> entries) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final entry in entries) {
      final endDateTime = today.add(Duration(
        hours: entry.endTime.hour,
        minutes: entry.endTime.minute,
      ));

      final startDateTime = today.add(Duration(
        hours: entry.startTime.hour,
        minutes: entry.startTime.minute,
      ));

      var notifyAt = endDateTime.subtract(const Duration(minutes: 10));
      log(
          "[NotificationService] Slot: ${entry.slot.label} (${entry.amount}ml)\n"
          "   StartTime = $startDateTime\n"
          "   EndTime   = $endDateTime\n"
          "   NotifyAt  = $notifyAt\n"
          "   Now       = $now",
          name: "NotificationService");

      if (notifyAt.isBefore(now)) {
        notifyAt = now.add(const Duration(minutes: 2));
        log(
            "[NotificationService] Skipping reminder for ${entry.slot.label} "
            "(${entry.amount}ml) because notifyAt=$notifyAt is before now=$now",
            name: "NotificationService");
        // continue;
      }

      log(
        "[NotificationService] Scheduling reminder for ${entry.slot.label} "
        "(${entry.amount}ml) at $notifyAt (current time: $now)",
      );

      await _plugin.zonedSchedule(
        entry.slot.index, // unique ID per slot
        "Hydration Reminder",
        "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml",
        tz.TZDateTime.from(notifyAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Hydration Reminders',
            channelDescription: 'Reminds you to drink water on time',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: entry.slot.index.toString(),
        matchDateTimeComponents: null,
      );

      log(
          "[NotificationService] Successfully scheduled for ${entry.slot.label} "
          "at ${tz.TZDateTime.from(notifyAt, tz.local)}",
          name: "NotificationService");
    }
  }

  Future<void> testNotification() async {
    // final now = DateTime.now();
    // final notifyAt = now.add(const Duration(seconds: 20));

    // await _plugin.zonedSchedule(
    //   9999, // test ID
    //   "Test Notification",
    //   "This is a test notification fired at $notifyAt",
    //   tz.TZDateTime.from(notifyAt, tz.local),
    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'test_channel',
    //       'Test Notifications',
    //       channelDescription: 'Used for testing notifications',
    //       importance: Importance.max,
    //       priority: Priority.high,
    //       playSound: true,
    //     ),
    //     iOS: const DarwinNotificationDetails(),
    //   ),
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    // );
  }

  Future<void> cancelReminder(HydrationSlot slot) async {
    await _plugin.cancel(slot.index);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
