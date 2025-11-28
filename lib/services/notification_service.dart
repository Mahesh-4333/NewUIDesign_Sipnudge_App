import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/hydration_entry.dart';
import 'package:audioplayers/audioplayers.dart';

typedef NotificationTapCallback = void Function(HydrationSlot slot);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final AudioPlayer _alarmPlayer = AudioPlayer();

  NotificationTapCallback? onNotificationTap;

  Future<void> _startRingtoneLoop(String soundFile) async {
    await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    await _alarmPlayer.play(
      AssetSource("assets/ringtones/$soundFile.mp3"), // adjust your folder
    );
  }

  Future<void> _stopRingtone() async {
    await _alarmPlayer.stop();
  }

  Future<String> _getSelectedRingtoneFile() async {
    final selected = await SharedPrefsHelper.getSelectedRingtone() ?? 0;
    return "ringtone${selected + 1}"; // ringtone1, ringtone2...
  }

  // Future<String> _getSelectedRingtoneFile() async {
  //   final selectedSoundIndex =
  //       await SharedPrefsHelper.getSelectedRingtone() ?? 0;
  //   return "ringtone${selectedSoundIndex + 1}";

  //   // switch (selectedSoundIndex) {
  //   //   case 1:
  //   //     return "ringtone2";
  //   //   case 2:
  //   //     return "ringtone3";
  //   //   case 3:
  //   //     return "ringtone4";
  //   //   case 4:
  //   //     return "ringtone5";
  //   //   case 5:
  //   //     return "ringtone6";
  //   //   case 6:
  //   //     return "ringtone7";
  //   //   case 7:
  //   //     return "ringtone8";
  //   //   case 8:
  //   //     return "ringtone9";
  //   //   case 9:
  //   //     return "ringtone10";
  //   //   default:
  //   //     return "ringtone1";
  //   // }
  // }

  Future<void> init({NotificationTapCallback? onTap}) async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'hydration_category', // Identifier
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

    await _plugin.initialize(initSettings,
        // onDidReceiveNotificationResponse: (details) {
        //   final payload = details.payload;
        //   if (payload != null) {
        //     final slot = HydrationSlot.values[int.parse(payload)];
        //     onNotificationTap?.call(slot);
        //   }
        // },

        // onDidReceiveNotificationResponse: (details) {
        //   final payload = details.payload;
        //   if (payload != null) {
        //     final slotIndex = int.parse(payload);
        //     onNotificationTap?.call(HydrationSlot.values[slotIndex]);
        //   }
        // },

        onDidReceiveNotificationResponse: (details) async {
      final payload = details.payload;
      final actionId = details.actionId;

      // STOP BUTTON PRESSED
      if (actionId != null && actionId.startsWith("STOP_")) {
        final slotIndex = int.parse(actionId.replaceFirst("STOP_", ""));
        await _stopRingtone();
        cancelReminder(HydrationSlot.values[slotIndex]);
        return;
      }

      // 🔥 Normal tap = start ringtone
      if (payload != null) {
        final slotIndex = int.parse(payload);
        final soundFile = await _getSelectedRingtoneFile();
        _startRingtoneLoop(soundFile); // 🔥 start ringtone HERE
        onNotificationTap?.call(HydrationSlot.values[slotIndex]);
      }
    });

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

      // await _plugin.zonedSchedule(
      //   entry.slot.index, // unique ID per slot
      //   "Hydration Reminder",
      //   "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml",
      //   tz.TZDateTime.from(notifyAt, tz.local),
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       //'hydration_channel',
      //       'hydration_unique_channel_${entry.slot.index}', // UNIQUE channel
      //       // 'Hydration Reminders',
      //       // channelDescription: 'Reminds you to drink water on time',
      //       'Hydration Popup',
      //       channelDescription: 'Shows popup hydration reminders',
      //       importance: Importance.max,
      //       priority: Priority.high,
      //       fullScreenIntent:
      //           false, // set true only if you want fullscreen dialog
      //       playSound: true,
      //       groupKey: null, // 🔥 Prevent grouping
      //       setAsGroupSummary: false, // 🔥 Prevent merging
      //       actions: [
      //         AndroidNotificationAction(
      //           'STOP_${entry.slot.index}',
      //           'Stop',
      //           showsUserInterface: false,
      //           cancelNotification: true,
      //         ),
      //       ],
      //     ),
      //     iOS: const DarwinNotificationDetails(),
      //   ),
      //   androidScheduleMode: AndroidScheduleMode.exact,
      //   payload: entry.slot.index.toString(),
      //   matchDateTimeComponents: null,
      // );

      final soundFile = await _getSelectedRingtoneFile();
      // Start looping ringtone
      _startRingtoneLoop(soundFile);
      await _plugin.zonedSchedule(
        entry.slot.index,
        "Hydration Reminder",
        "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml",
        tz.TZDateTime.from(notifyAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel_${entry.slot.index}_$soundFile', // unique per slot
            'Hydration Popup',
            channelDescription: 'Popup hydration reminders',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundFile),
            groupKey: null, // 🚫 no grouping
            setAsGroupSummary: false, // 🚫 no merging
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            ongoing: true, // Notification stays until STOP
            autoCancel: false, // (true only if you want fullscreen popup)

            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'STOP_${entry.slot.index}',
                'STOP',
                icon: DrawableResourceAndroidBitmap('stop_ic'),
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'hydration_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: entry.slot.index.toString(),
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
