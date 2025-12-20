import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:alarm/alarm.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

import 'package:permission_handler/permission_handler.dart';

// --- Global Setup ---

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// --- Notification Response Handler (Handles button taps/notification taps) ---

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  final String? actionId = notificationResponse.actionId;

  final int? id = notificationResponse.id;

  // Logic to handle interactive button taps (from simple notification)

  if (actionId == 'DISMISS_ACTION') {
    debugPrint('Simple Notification dismissed (ID: $id)');
  } else if (actionId == 'SNOOZE_ACTION') {
    debugPrint('Simple Notification snoozed (ID: $id)');
  } else {
    // Regular notification tap

    debugPrint(
        'Notification tapped (Payload: ${notificationResponse.payload}, ID: $id)');
  }
}

// --- Alarm Callback (Executed in a headless background isolate) ---

@pragma('vm:entry-point')
Future<void> alarmRingCallback() async {
  // This runs when the alarm fires, even if the main app is terminated.

  debugPrint('Alarm triggered in background isolate!');
}

// =========================================================================

//                   CORE NOTIFICATION MANAGER CLASS

// =========================================================================

class NotificationManager {
  // Private constructor to prevent direct instantiation

  NotificationManager._();

  static final NotificationManager instance = NotificationManager._();

  /// Initializes both the Alarm and Local Notification packages, and requests permissions.

  Future<void> initialize() async {
    await _requestRequiredPermissions();

    if (Platform.isAndroid) {
      await Alarm.init();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveNotificationResponse,
    );

    debugPrint('Notification Manager Initialized.');
  }

  /// Requests the necessary Android system permissions.

  Future<void> _requestRequiredPermissions() async {
    // Request general notification permission (Android 13+)

    if (Platform.isAndroid) {
      await Permission.notification.request();

      // Request SCHEDULE_EXACT_ALARM (CRITICAL for accurate alarms on Android 12+)

      var exactAlarmStatus = await Permission.scheduleExactAlarm.status;

      if (!exactAlarmStatus.isGranted) {
        debugPrint('Exact Alarm permission not granted. Requesting...');

        var result = await Permission.scheduleExactAlarm.request();

        if (!result.isGranted && result.isPermanentlyDenied) {
          debugPrint(
              'Exact Alarm permission permanently denied. Opening settings.');

          openAppSettings();
        }
      }
    }
  }

  // =========================================================================

  //                         ACTION METHODS

  // =========================================================================

  /// Shows a simple, interactive notification with custom buttons.

  Future<void> showSimpleActionNotification({
    required int id,
    String title = 'Reminder',
    String body = 'Time to check your task list.',
    List<AndroidNotificationAction>? customActions,
  }) async {
    final actions = customActions ??
        <AndroidNotificationAction>[
          const AndroidNotificationAction('DISMISS_ACTION', 'Dismiss'),
          const AndroidNotificationAction('SNOOZE_ACTION', 'Snooze'),
        ];

    const String channelId = 'simple_action_channel';

    const String channelName = 'Simple Action Notifications';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Channel for notifications with interactive buttons.',
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
    );

    NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: 'simple_payload_$id',
    );

    debugPrint('Simple notification ID $id fired.');
  }

  /// Schedules a reliable, looping alarm that rings for a maximum of 5 seconds.

  Future<bool> setReliableAlarm({
    required int id,
    required DateTime dateTime,
    required String assetAudioPath,
    required String title,
    required String body,
    required bool isSilent,
    String stopButtonText = 'Stop Alarm',
    int maxDurationSeconds = 5,
  }) async {
    final notificationSettings = NotificationSettings(
      title: title,
      body: body,
      stopButton: stopButtonText,
    );

    var volumeSettings = VolumeSettings.fade(
      volume: isSilent ? 0.0 : 0.3,
      fadeDuration: const Duration(seconds: 3),
      volumeEnforced: true,
    );

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: assetAudioPath,
      loopAudio: false,
      vibrate: true,
      notificationSettings: notificationSettings,
      volumeSettings: volumeSettings,
      androidFullScreenIntent: false,
      warningNotificationOnKill: false,
    );

    try {
      final result = await Alarm.set(alarmSettings: alarmSettings);

      log('Alarm ID $id set for $dateTime. Success: $result');

      return result;
    } catch (e) {
      log('Error setting reliable alarm: $e');

      return false;
    }
  }

  Future<bool> stopAlarm(int id) async {
    final success = await Alarm.stop(id);

    debugPrint('Alarm ID $id stopped. Success: $success');

    return success;
  }

  /// Checks if any alarm is currently scheduled.

  Future<bool> isAlarmScheduled() async {
    final alarms = await Alarm.getAlarms();

    return alarms.isNotEmpty;
  }
}