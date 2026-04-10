import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrify/helpers/logger.dart';

class TimezoneChangeDetector extends ChangeNotifier {
  static final TimezoneChangeDetector _instance =
      TimezoneChangeDetector._internal();
  factory TimezoneChangeDetector() => _instance;
  TimezoneChangeDetector._internal();

  String? _storedTimezone;
  String? _currentTimezone;
  bool _isInitialized = false;
  bool _isFirstInstall = false;

  String? get storedTimezone => _storedTimezone;
  String? get currentTimezone => _currentTimezone;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _storedTimezone = prefs.getString('stored_timezone');
    _currentTimezone = (await FlutterTimezone.getLocalTimezone()).identifier;

    if (_storedTimezone == null) {
      _isFirstInstall = true;
      await _saveTimezone(_currentTimezone!);
      Console.log(
          tag: "TimezoneDetector",
          value: "First install - Saved timezone: $_currentTimezone");
    }

    _isInitialized = true;
    Console.log(
        tag: "TimezoneDetector",
        value:
            "Initialized - Stored: $_storedTimezone, Current: $_currentTimezone");
  }

  Future<bool> hasTimezoneChanged() async {
    if (!_isInitialized) {
      await init();
      return false;
    }

    if (_isFirstInstall) {
      return false;
    }

    final newTimezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    _currentTimezone = newTimezone;
    Console.log(
        tag: "TimezoneDetector",
        value: "$_currentTimezone $newTimezone");

    final hasChanged = _storedTimezone != newTimezone;

    if (hasChanged) {
      Console.log(
          tag: "TimezoneDetector",
          value: "Timezone changed from $_storedTimezone to $newTimezone");
    }

    return hasChanged;
  }

  Future<void> updateTimezone() async {
    final newTimezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    await _saveTimezone(newTimezone);
    _storedTimezone = newTimezone;
    _currentTimezone = newTimezone;

    Console.log(
        tag: "TimezoneDetector", value: "Timezone updated to $newTimezone");
    notifyListeners();
  }

  Future<void> _saveTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_timezone', timezone);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stored_timezone');
    _storedTimezone = null;
    _isInitialized = false;
  }
}
