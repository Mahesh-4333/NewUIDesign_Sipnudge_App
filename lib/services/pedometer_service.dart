import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  static const String _keyStoredTodaySteps = 'pedometer_stored_today_steps';
  static const String _keyLastStepsSinceBoot =
      'pedometer_last_steps_since_boot';
  static const String _keyLastResetDate = 'pedometer_last_reset_date';

  StreamSubscription<StepCount>? _subscription;
  int _todaySteps = 0;
  bool _isInitialized = false;

  // Stream to notify listeners when steps update
  static final StreamController<int> _stepUpdateController =
      StreamController<int>.broadcast();
  static Stream<int> get onStepUpdate => _stepUpdateController.stream;

  int get todaySteps => _todaySteps;

  Future<void> initialize() async {
    if (_isInitialized || !Platform.isAndroid) return;

    Console.log(tag: "PedometerService", value: "Initializing...");
    await _loadStoredData();
    await _startListening();
    _isInitialized = true;
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayDateString();
      final lastDate = prefs.getString(_keyLastResetDate);

      if (lastDate != today) {
        // New day, reset daily steps
        _todaySteps = 0;
        await prefs.setInt(_keyStoredTodaySteps, 0);
        await prefs.setString(_keyLastResetDate, today);
        // We don't know the last_steps_since_boot yet until first stream event
      } else {
        _todaySteps = prefs.getInt(_keyStoredTodaySteps) ?? 0;
      }
      Console.log(
          tag: "PedometerService",
          value: "Loaded steps: $_todaySteps for date: $today");
    } catch (e) {
      Console.log(tag: "PedometerService", value: "Error loading data: $e");
    }
  }

  Future<void> _startListening() async {
    if (await Permission.activityRecognition.isGranted) {
      Console.log(
          tag: "PedometerService", value: "Starting pedometer stream...");
      _subscription?.cancel();
      _subscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        onDone: () => Console.log(
            tag: "PedometerService", value: "Pedometer stream closed"),
      );
    } else {
      Console.log(
          tag: "PedometerService",
          value: "Cannot start listening: Permission not granted");
    }
  }

  void _onStepCount(StepCount event) async {
    try {
      final currentStepsSinceBoot = event.steps;
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayDateString();
      final lastDate = prefs.getString(_keyLastResetDate);

      // Get the last known boot steps. If null or 0, this is likely the first event.
      final lastStepsSinceBoot = prefs.getInt(_keyLastStepsSinceBoot) ?? 0;

      if (lastDate != today) {
        // Day transition occurred
        Console.log(tag: "PedometerService", value: "New day detected: $today");
        _todaySteps = 0;
        await prefs.setString(_keyLastResetDate, today);
        await prefs.setInt(_keyStoredTodaySteps, 0);
        // Set today's baseline to current boot steps
        await prefs.setInt(_keyLastStepsSinceBoot, currentStepsSinceBoot);
      } else {
        if (lastStepsSinceBoot == 0) {
          // First time seeing steps today, set baseline and don't add anything yet
          Console.log(
              tag: "PedometerService",
              value: "Setting initial baseline: $currentStepsSinceBoot");
          await prefs.setInt(_keyLastStepsSinceBoot, currentStepsSinceBoot);
        } else if (currentStepsSinceBoot >= lastStepsSinceBoot) {
          final diff = currentStepsSinceBoot - lastStepsSinceBoot;
          _todaySteps += diff;
          Console.log(
              tag: "PedometerService",
              value: "Added $diff steps. New total: $_todaySteps");
        } else {
          // Reboot detected (current steps < last known steps since boot)
          Console.log(
              tag: "PedometerService",
              value:
                  "Reboot detected. Current: $currentStepsSinceBoot, Last: $lastStepsSinceBoot");
          _todaySteps += currentStepsSinceBoot;
        }
      }

      await prefs.setInt(_keyStoredTodaySteps, _todaySteps);
      await prefs.setInt(_keyLastStepsSinceBoot, currentStepsSinceBoot);

      // Notify listeners
      _stepUpdateController.add(_todaySteps);

      Console.log(
          tag: "PedometerService",
          value:
              "Updated steps: $_todaySteps (Stream total: $currentStepsSinceBoot)");
    } catch (e) {
      Console.log(tag: "PedometerService", value: "Error in _onStepCount: $e");
    }
  }

  void _onStepCountError(error) {
    Console.log(tag: "PedometerService", value: "Pedometer Error: $error");
  }

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<int> getTodaySteps() async {
    if (!Platform.isAndroid) return 0;

    // Ensure we are initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Check for permissions
    if (await Permission.activityRecognition.isGranted) {
      // Return current local state
      return _todaySteps;
    } else {
      Console.log(
          tag: "PedometerService",
          value: "Activity Recognition permission not granted");
      return 0;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}
