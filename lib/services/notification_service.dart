import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
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

  final AudioPlayer _alarmPlayer = AudioPlayer();

  NotificationTapCallback? onNotificationTap;

  Future<void> _startRingtoneLoop(String soundFile) async {
    await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    await _alarmPlayer.play(
      AssetSource("ringtones/$soundFile.mp3"), // adjust your folder
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

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channelRingtone1 =
          AndroidNotificationChannel(
        'channel_ringtone1',
        'Channel Ringtone1',
        description: 'Notification for stackfood orders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone1'),
      );

      const AndroidNotificationChannel channelRingtone2 =
          AndroidNotificationChannel(
        'channel_ringtone2',
        'Channel Ringtone2',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone2'),
      );

      const AndroidNotificationChannel channelRingtone3 =
          AndroidNotificationChannel(
        'channel_ringtone3',
        'Channel Ringtone3',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone3'),
      );

      const AndroidNotificationChannel channelRingtone4 =
          AndroidNotificationChannel(
        'channel_ringtone4',
        'Channel Ringtone4',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone4'),
      );

      const AndroidNotificationChannel channelRingtone5 =
          AndroidNotificationChannel(
        'channel_ringtone5',
        'Channel Ringtone5',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone5'),
      );

      const AndroidNotificationChannel channelRingtone6 =
          AndroidNotificationChannel(
        'channel_ringtone6',
        'Channel Ringtone6',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone6'),
      );

      const AndroidNotificationChannel channelRingtone7 =
          AndroidNotificationChannel(
        'channel_ringtone7',
        'Channel Ringtone7',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone7'),
      );

      const AndroidNotificationChannel channelRingtone8 =
          AndroidNotificationChannel(
        'channel_ringtone8',
        'Channel Ringtone8',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone8'),
      );

      const AndroidNotificationChannel channelRingtone9 =
          AndroidNotificationChannel(
        'channel_ringtone9',
        'Channel Ringtone9',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone9'),
      );

      const AndroidNotificationChannel channelRingtone10 =
          AndroidNotificationChannel(
        'channel_ringtone10',
        'Channel Ringtone10',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone10'),
      );

      const AndroidNotificationChannel channelRingtone11 =
          AndroidNotificationChannel(
        'channel_ringtone11',
        'Channel Ringtone11',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone11'),
      );

      const AndroidNotificationChannel channelRingtone12 =
          AndroidNotificationChannel(
        'channel_ringtone12',
        'Channel Ringtone12',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone12'),
      );

      const AndroidNotificationChannel channelRingtone13 =
          AndroidNotificationChannel(
        'channel_ringtone13',
        'Channel Ringtone13',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('ringtone13'),
      );

      // 🔹 Android 13+ runtime notification permission
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channelRingtone1);
        await androidImplementation.createNotificationChannel(channelRingtone2);
        await androidImplementation.createNotificationChannel(channelRingtone3);
        await androidImplementation.createNotificationChannel(channelRingtone4);
        await androidImplementation.createNotificationChannel(channelRingtone5);
        await androidImplementation.createNotificationChannel(channelRingtone6);
        await androidImplementation.createNotificationChannel(channelRingtone7);
        await androidImplementation.createNotificationChannel(channelRingtone8);
        await androidImplementation.createNotificationChannel(channelRingtone9);
        await androidImplementation
            .createNotificationChannel(channelRingtone10);
        await androidImplementation
            .createNotificationChannel(channelRingtone11);
        await androidImplementation
            .createNotificationChannel(channelRingtone12);
        await androidImplementation
            .createNotificationChannel(channelRingtone13);
      }
    }
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
  }

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
      print(soundFile);
      print(entry.slot.index);
      // Start looping ringtone
      // _startRingtoneLoop(soundFile);

      try {
        await _plugin.zonedSchedule(
          entry.slot.index,
          "Hydration Reminder",
          "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml",
          tz.TZDateTime.from(notifyAt, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_$soundFile', // unique per slot
              'Hydration Popup',
              channelDescription: 'Popup hydration reminders',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound(soundFile),
              // groupKey: null, // 🚫 no grouping
              // setAsGroupSummary: false, // 🚫 no merging
              // category: AndroidNotificationCategory.alarm,
              // fullScreenIntent: true,
              // visibility: NotificationVisibility.public,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: entry.slot.index.toString(),
        );
        print(
          "[NotificationService] Successfully scheduled for ${entry.slot.label} "
          "at ${tz.TZDateTime.from(notifyAt, tz.local)}",
        );
      } catch (e) {
        print("Error while scheduling the notification ${e.toString()}");
      }
    }
  }

  Future<void> testNotification() async {
    final soundFile = await _getSelectedRingtoneFile();
    print(soundFile);
    try {
      await _plugin.show(
        6, // test ID
        'channel_2',
        "This is a test notification fired",
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_$soundFile',
            'Test Notifications',
            channelDescription: 'Used for testing notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundFile),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print("Success =====>");
    } catch (e) {
      print("Error =====> ${e.toString()}");
    }

    // // await _plugin.zonedSchedule(
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
