import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/services/google_calendar_manager.dart';
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
               options: {

      },
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
        if (details.actionId == 'STOP_ACTION') {
    await _plugin.cancel(details.id!);
    return;
  }

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

    final notifyAt = endDateTime.subtract(const Duration(minutes: 10));

    if (notifyAt.isBefore(now)) {
      log(
        "[NotificationService] Skipping reminder for ${entry.slot.label} "
        "because notifyAt=$notifyAt < now=$now",
      );
      continue;
    }

    /// 🔍 CHECK CALENDAR
    final shouldSilence =
        await _shouldSilenceHydrationReminder(notifyAt);

    log(
      "[NotificationService] Scheduling ${shouldSilence ? 'SILENT' : 'NORMAL'} "
      "reminder for ${entry.slot.label} at $notifyAt",
    );

    final title = "Hydration Reminder";
    final body =
        "Only 10 minutes left for ${entry.slot.label} – Drink ${entry.amount} ml";

    if (Platform.isIOS) {
      await _scheduleIOSHydrationNotification(
        id: entry.slot.index,
        notifyAt: notifyAt,
        title: title,
        body: body,
        payload: entry.slot.index.toString(),
        isSilent: shouldSilence, 
      );

      log('[iOS] Notification scheduled (${shouldSilence ? "silent" : "normal"})');
    } else {
      
        /// 🔔 NORMAL ALARM
        final alarmSet =
            await NotificationManager.instance.setReliableAlarm(
          id: entry.slot.index,
          dateTime: notifyAt,
          assetAudioPath: assetPath,
          title: title,
          body: body,
          stopButtonText: 'Drink Water & Stop',
          maxDurationSeconds: 5,
          isSilent: shouldSilence,
        );

        if (!alarmSet) {
          log('Failed to set Android alarm for ${entry.slot.label}');
          continue;
        }
      }
    

    log(
      "[NotificationService] Successfully scheduled for ${entry.slot.label} "
      "at $notifyAt",
    );
  }
}


Future<void> _scheduleIOSHydrationNotification({
  required int id,
  required DateTime notifyAt,
  required String title,
  required String body,
  required String payload,
  required bool isSilent

}) async {
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
        interruptionLevel:isSilent? InterruptionLevel.passive :InterruptionLevel.timeSensitive,
        categoryIdentifier: 'hydration_category',
        
      ),
    ),

    payload: payload, androidScheduleMode: AndroidScheduleMode.alarmClock,
  );
}

Future<bool> _shouldSilenceHydrationReminder(DateTime notifyAt) async {
  try {
    final calendarManager = GoogleCalendarManager();
    return await calendarManager.hasEventDuring(
      notifyAt,
      notifyAt.add(const Duration(minutes: 5)),
    );
  } catch (e) {
    log('[Calendar] Failed to check calendar: $e');
    return false; // fail-safe → normal reminder
  }
}


Future<void> cancelReminder(HydrationSlot slot) async {
  await _plugin.cancel(slot.index);

  if (Platform.isAndroid) {
    await NotificationManager.instance.stopAlarm(slot.index);
  }
}


  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    // Stop ALL alarms
    await NotificationManager.instance
        .stopAlarm(0); // The alarm package's stopAll uses 0
  }




}


