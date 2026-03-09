import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  // Existing Keys
  static const String _keyUserEmail = 'user_email';
  static const String _keyWaterGoal = 'water_goal';
  static const _keyUserGoal = 'user_goal';
  static const String _keyPersonalInfoSubmitted = 'personal_info_submitted';
  static const String _keyLastConnectedBleName = 'last_connected_ble_name';
  static const String _keyLastConnectedBleId = 'last_connected_ble_id';
  static const String _keyLastLevelUpDate = 'last_level_up_date';

  static const String _bottleKey = 'selected_bottle';

  static const List<String> _bottles = [
    'purple',
    'black',
    'gray',
    'green',
    'red'
  ];

  // NEW: Ringtone key
  static const String _keySelectedRingtone = 'selected_ringtone';
  static const String _keyRingtoneFeedback = 'ringtone_feedback';

  static const String _keyReminderMode = "reminder_mode";
  static const String _keyAlarmRepeatIndex = "alarm_repeat_index";
  static const String _keyStopWhenFull = "stop_when_full";

  static const String _keyVibrationStrength = "vibration_strength";
  static const String _keyLedIntensity = "led_intensity";
  static const String _keyLedColor = "led_color";
  static const String _keyUvCleaning = "uv_cleaning";
  static const String _keyFavoriteRingtones = 'favorite_ringtones';

  // ----------------------------
  // RINGTONE METHODS (NEW)
  // ----------------------------
  static Future<void> setSelectedRingtone(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedRingtone, index);
  }

  static Future<int?> getSelectedRingtone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedRingtone);
  }

  static Future<void> setRingtoneFeedBack(bool feedback) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRingtoneFeedback, feedback);
  }

  static Future<bool> getRingtoneFeedBack() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRingtoneFeedback) ?? true;
  }

  static Future<void> setFavoriteRingtones(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _keyFavoriteRingtones, ids.map((id) => id.toString()).toList());
  }

  static Future<List<int>> getFavoriteRingtones() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteRingtones);
    if (list == null) return [];
    return list.map((id) => int.parse(id)).toList();
  }

  // ----------------------------
  // Existing Methods
  // ----------------------------

  // Save user email
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<void> setWaterGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWaterGoal, goal);
  }

  static Future<void> setUserGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserGoal, goal);
  }

  static Future<int?> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWaterGoal);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<int?> getUserGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWaterGoal);
  }

  static Future<int?> getUserGoals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserGoal);
  }

  // Personal info submitted
  static Future<void> setPersonalInfoSubmitted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPersonalInfoSubmitted, value);
  }

  static Future<bool> isPersonalInfoSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPersonalInfoSubmitted) ?? false;
  }

  // BLE info
  static Future<void> setLastConnectedBleName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastConnectedBleName, name);
  }

  static Future<void> setLastConnectedBleId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastConnectedBleId, id);
  }

  static Future<String?> getLastConnectedBleName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastConnectedBleName);
  }

  static Future<String?> getLastConnectedBleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastConnectedBleId);
  }

  // Clear all stored values
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> clearLastConnectedDeviceData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyLastConnectedBleName);
    await prefs.remove(_keyLastConnectedBleId);
  }

  /// Get current bottle
  static Future<String> getBottle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bottleKey) ?? 'purple';
  }

  /// Move to next bottle automatically (QR scan)
  // static Future<String> rotateBottle() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final current = prefs.getString(_bottleKey) ?? 'purple';

  //   final index = _bottles.indexOf(current);
  //   final nextIndex = (index + 1) % _bottles.length;
  //   final nextBottle = _bottles[nextIndex];

  //   await prefs.setString(_bottleKey, nextBottle);
  //   return nextBottle;
  // }

  /// 🔥 SET bottle color from QR
  static Future<void> setBottleColor(String color) async {
    final prefs = await SharedPreferences.getInstance();

    // safety: allow only supported bottles
    if (_bottles.contains(color.toLowerCase())) {
      await prefs.setString(_bottleKey, color.toLowerCase());
    }
  }

  /// 🔥 GET bottle color (QR / saved)
  static Future<String> getBottleColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bottleKey) ?? 'purple';
  }

  /// Reset bottle
  static Future<void> resetBottle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bottleKey);
  }

  /// Remider Mode
  static Future<void> setReminderMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderMode, mode);
  }

  static Future<String> getReminderMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReminderMode) ?? "SteadySip";
  }

  static Future<void> setAlarmRepeatIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAlarmRepeatIndex, index);
  }

  static Future<int> getAlarmRepeatIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAlarmRepeatIndex) ??
        0; // Default to 10 mins (index 2)
  }

  static Future<void> setStopWhenFull(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStopWhenFull, value);
  }

  static Future<bool> getStopWhenFull() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStopWhenFull) ?? true;
  }

  // Vibration Strength
  static Future<void> setVibrationStrength(double strength) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVibrationStrength, strength);
  }

  static Future<double> getVibrationStrength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyVibrationStrength) ?? 0.75;
  }

  // LED Intensity
  static Future<void> setLedIntensity(double intensity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLedIntensity, intensity);
  }

  static Future<double> getLedIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyLedIntensity) ?? 0.8;
  }

  // LED Hue (0.0 - 1.0)
  static Future<void> setLedHue(double hue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLedColor, hue);
  }

  static Future<double> getLedHue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyLedColor) ?? 0.6; // Default blue-ish hue
  }

  // UV Cleaning
  static Future<void> setUvCleaning(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUvCleaning, enabled);
  }

  static Future<bool> getUvCleaning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUvCleaning) ?? false;
  }

// =======================================================================

// import 'package:shared_preferences/shared_preferences.dart';

  static Future<void> setLastLevelUpDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLevelUpDate, date);
  }

  /// Retrieves the date string of the last level up to prevent duplicate notifications.
  static Future<String?> getLastLevelUpDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLevelUpDate);
  }
}
