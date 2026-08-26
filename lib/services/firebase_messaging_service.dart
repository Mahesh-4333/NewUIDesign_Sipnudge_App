import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/main.dart'; // To access navigatorKey
import 'package:hydrify/services/api_service.dart';

/// The Android notification channel used for all FCM push notifications.
/// Must match the `android.notification.channel_id` value sent in FCM payloads.
const String _kFcmChannelId = 'sipnudge_custom_sound_v1';
const String _kFcmChannelName = 'Sipnudge Notifications';
const String _kFcmChannelDesc =
    'App push notifications (hydration reminders, support tickets, updates)';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  /// Local notifications plugin — used to:
  /// 1. Create the Android FCM channel on first run (so FCM has a sound channel).
  /// 2. Show a heads-up notification with sound when a FCM arrives in the foreground.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<void> ticketUpdateStream =
      StreamController<void>.broadcast();

  Future<void> init() async {
    try {
      // 1. Request notification permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
        // timeSensitive: true,
      );

      // Configure foreground notification options so sound & banner work even when app is open
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      Console.log(
          tag: "FCM",
          value: 'User granted permission: ${settings.authorizationStatus}');

      // 2. Initialize the local notifications plugin.
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false, // Already requested above via FCM
            requestBadgePermission: false,
            requestSoundPermission: false,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
          ),
        ),
      );

      // 3. On Android — create the FCM notification channel with sound + high importance.
      //    FCM uses this channel when delivering background/terminated notifications.
      if (Platform.isAndroid) {
        await _setupAndroidFcmChannel();
      }

      // Wait for APNS token on iOS before fetching FCM token
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        Console.log(tag: "FCM", value: 'APNS Token: $apnsToken');

        if (apnsToken == null) {
          for (int i = 0; i < 6; i++) {
            await Future.delayed(const Duration(milliseconds: 500));
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              Console.log(
                  tag: "FCM",
                  value: 'APNS Token (after ${(i + 1) * 500}ms): $apnsToken');
              break;
            }
          }
        }

        if (apnsToken == null) {
          Console.log(
              tag: "FCM",
              value:
                  'APNS Token is still null. Skipping FCM token fetch (likely running on an iOS simulator without APNS configuration).');
          return; // Skip getToken() to avoid crashing
        }
      }

      // 3. Retrieve the initial FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        Console.log(tag: "FCM", value: 'FCM Token retrieved: $token');
        await syncTokenToBackend(token);
      }

      // 4. Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        Console.log(tag: "FCM", value: 'FCM Token refreshed: $newToken');
        syncTokenToBackend(newToken);
      }).onError((err) {
        Console.log(
            tag: "FCM", value: 'Error listening to token refresh: $err');
      });

      // 5. Handle notifications when app is terminated and opened via push
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      // 6. Handle notifications when app is in background and opened via push
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // 7. Handle foreground FCM messages (show heads-up banner with sound on Android & iOS)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final isEnabled =
            await SharedPrefsHelper.isFirebaseNotificationEnabled();
        if (!isEnabled) {
          Console.log(
              tag: "FCM",
              value: 'FCM message received but ignored (notifications disabled)');
          return;
        }

        Console.log(
            tag: "FCM",
            value:
                'Foreground message received: ${message.notification?.title}, data: ${message.data}');

        // On Android / iOS, show local notification with sound if FCM arrived in foreground
        if (message.notification != null) {
          _localNotifications.show(
            id: message.hashCode,
            title: message.notification?.title,
            body: message.notification?.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                _kFcmChannelId,
                _kFcmChannelName,
                channelDescription: _kFcmChannelDesc,
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                enableVibration: true,
                sound: RawResourceAndroidNotificationSound('ringtone1'),
                icon: '@mipmap/launcher_icon',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                sound: 'mixkitachievementbell.caf',
              ),
            ),
          );
        }

        if (message.data['type'] == 'ticket_reply' ||
            message.data['type'] == 'ticket_closed') {
          ticketUpdateStream.add(null);
        }
      });
    } catch (e) {
      Console.log(
          tag: "FCM", value: 'Error initializing Firebase Messaging: $e');
    }
  }

  /// Enable or disable Firebase push notifications
  Future<void> setNotificationEnabled(bool enabled) async {
    await SharedPrefsHelper.setFirebaseNotificationEnabled(enabled);
    try {
      if (enabled) {
        await _firebaseMessaging.setAutoInitEnabled(true);
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        Console.log(
            tag: "FCM",
            value: 'User granted permission: ${settings.authorizationStatus}');
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await syncTokenToBackend(token);
        }
      } else {
        await _firebaseMessaging.setAutoInitEnabled(false);
        final userId = await SharedPrefsHelper.getUserId();
        if (userId != null && userId.isNotEmpty) {
          await _apiService.syncUserInfo(userId, {'fcmToken': ''});
        }
        try {
          await _firebaseMessaging.deleteToken();
        } catch (e) {
          Console.log(tag: "FCM", value: 'Error deleting FCM token: $e');
        }
      }
    } catch (e) {
      Console.log(tag: "FCM", value: 'Error setting notification enabled: $e');
    }
  }

  /// Creates (or updates) the Android notification channel that FCM uses.
  /// Must be called before any notification is shown.
  Future<void> _setupAndroidFcmChannel() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Delete old channel first so Android updates channel settings (sound, importance)
    await androidPlugin?.deleteNotificationChannel(channelId: _kFcmChannelId);

    // Channel with custom louder ringtone1 + max importance
    const channel = AndroidNotificationChannel(
      _kFcmChannelId,
      _kFcmChannelName,
      description: _kFcmChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('ringtone1'),
    );

    await androidPlugin?.createNotificationChannel(channel);

    Console.log(
        tag: "FCM",
        value: 'Android FCM notification channel created: $_kFcmChannelId');
  }

  void _handleNotificationClick(RemoteMessage message) {
    Console.log(
        tag: "FCM", value: "Notification clicked with data: ${message.data}");
    if (message.data['type'] == 'ticket_reply') {
      // Small delay to ensure the navigator is fully mounted before pushing
      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey.currentState?.pushNamed('/help_support_ticket');
      });
    }
  }

  Future<void> syncTokenToBackend([String? token]) async {
    try {
      final actualToken = token ?? await _firebaseMessaging.getToken();
      if (actualToken == null) return;

      final userId = await SharedPrefsHelper.getUserId();
      if (userId != null && userId.isNotEmpty) {
        final success =
            await _apiService.syncUserInfo(userId, {'fcmToken': actualToken});
        Console.log(
            tag: "FCM", value: 'Sync FCM token to backend success: $success');
      } else {
        Console.log(tag: "FCM", value: 'No userId found to sync FCM token');
      }
    } catch (e) {
      Console.log(tag: "FCM", value: 'Failed to sync FCM token to backend: $e');
    }
  }
}
