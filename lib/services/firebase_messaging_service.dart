import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/main.dart'; // To access navigatorKey
import 'package:hydrify/services/api_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    try {
      // 1. Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Console.log(tag: "FCM", value: 'User granted permission: ${settings.authorizationStatus}');

      // Wait for APNS token on iOS before fetching FCM token
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        Console.log(tag: "FCM", value: 'APNS Token: $apnsToken');
        
        // Sometimes getAPNSToken returns null immediately, we can wait a bit or try again,
        // but typically awaiting it is enough to resolve the 'apns-token-not-set' error.
        if (apnsToken == null) {
           await Future.delayed(const Duration(seconds: 3));
           apnsToken = await _firebaseMessaging.getAPNSToken();
           Console.log(tag: "FCM", value: 'APNS Token (after delay): $apnsToken');
        }

        // If it's STILL null, we are likely on an iOS simulator which does not support APNS natively.
        if (apnsToken == null) {
          Console.log(tag: "FCM", value: 'APNS Token is still null. Skipping FCM token fetch (likely running on an iOS simulator without APNS configuration).');
          return; // Skip getToken() to avoid crashing
        }
      }

      // 2. Retrieve the initial FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        Console.log(tag: "FCM", value: 'FCM Token retrieved: $token');
        await syncTokenToBackend(token);
      }

      // 3. Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        Console.log(tag: "FCM", value: 'FCM Token refreshed: $newToken');
        syncTokenToBackend(newToken);
      }).onError((err) {
        Console.log(tag: "FCM", value: 'Error listening to token refresh: $err');
      });

      // 4. Handle notifications when app is terminated and opened via push
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      // 5. Handle notifications when app is in background and opened via push
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // 6. Handle foreground notifications (optional, if we want to show a local alert)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        Console.log(tag: "FCM", value: 'Foreground message received: ${message.notification?.title}');
        // We could show a local snackbar or flutter_local_notifications here
      });

    } catch (e) {
      Console.log(tag: "FCM", value: 'Error initializing Firebase Messaging: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    Console.log(tag: "FCM", value: "Notification clicked with data: ${message.data}");
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
        final success = await _apiService.syncUserInfo(userId, {'fcmToken': actualToken});
        Console.log(tag: "FCM", value: 'Sync FCM token to backend success: $success');
      } else {
        Console.log(tag: "FCM", value: 'No userId found to sync FCM token');
      }
    } catch (e) {
      Console.log(tag: "FCM", value: 'Failed to sync FCM token to backend: $e');
    }
  }
}
