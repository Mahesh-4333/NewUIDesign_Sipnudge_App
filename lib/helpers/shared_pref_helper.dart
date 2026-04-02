import 'package:hydrify/helpers/database_helper.dart';
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
  static const String _keySelectedRingtoneName = 'selected_ringtone_name';
  static const String _keyRingtoneFeedback = 'ringtone_feedback';
  static const String _keyPendingConfigData = 'pending_config_data';
  static const String _keyPendingResetCommand = 'pending_reset_command';

  static const String _keyReminderMode = "reminder_mode";
  static const String _keyAlarmRepeatIndex = "alarm_repeat_index";
  static const String _keyStopWhenFull = "stop_when_full";

  static const String _keyVibrationStrength = "vibration_strength";
  static const String _keyLedIntensity = "led_intensity";
  static const String _keyLedColor = "led_color";
  static const String _keyUvCleaning = "uv_cleaning";
  static const String _keyFavoriteRingtones = 'favorite_ringtones';
  static const String _keyHasRequestedHealthPermission = 'has_requested_health_permission';

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

  static Future<void> setSelectedRingtoneName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedRingtoneName, name);
  }

  static Future<String?> getSelectedRingtoneName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedRingtoneName);
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
  // HEALTH PERMISSION METHODS
  // ----------------------------
  static Future<void> setHasRequestedHealthPermission(bool requested) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRequestedHealthPermission, requested);
  }

  static Future<bool> getHasRequestedHealthPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasRequestedHealthPermission) ?? false;
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

  // Pending Config Data
  static Future<void> setPendingConfigData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingConfigData, data);
  }

  static Future<String?> getPendingConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingConfigData);
  }

  static Future<void> clearPendingConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingConfigData);
  }

  // Pending Reset Command
  static Future<void> setPendingResetCommand(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingResetCommand, data);
  }

  static Future<String?> getPendingResetCommand() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingResetCommand);
  }

  static Future<void> clearPendingResetCommand() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingResetCommand);
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

  /// NEW: Common helper to construct and set the device pending config payload.
  /// It updates preferences if new values are passed, grabs existing values,
  /// constructs the correct payload, and saves it.
  static Future<void> updateAndSaveDeviceConfig({
    int? waterGoal,
    double? vibrationStrength,
    double? ledIntensity,
    bool? ringtoneFeedback, // Maps to reminderState
    bool? stopWhenFull, // Maps to stopOnCompletion
    int? alarmRepeatIndex,
  }) async {
    // 1. Update preferences if new values are provided
    if (waterGoal != null) await setWaterGoal(waterGoal);
    if (ledIntensity != null) await setLedIntensity(ledIntensity);
    if (vibrationStrength != null)
      await setVibrationStrength(vibrationStrength);
    if (stopWhenFull != null) await setStopWhenFull(stopWhenFull);
    if (alarmRepeatIndex != null) await setAlarmRepeatIndex(alarmRepeatIndex);
    if (ringtoneFeedback != null) await setRingtoneFeedBack(ringtoneFeedback);

    // 2. Fetch all values (defaults handle fallbacks)
    final targetWater = await getWaterGoal() ?? 2500;
    final lIntensity = await getLedIntensity();
    final vStrength = await getVibrationStrength();
    final stopOnCompletion = await getStopWhenFull();
    final repIndex = await getAlarmRepeatIndex();
    final rFeedback = await getRingtoneFeedBack();

    // 3. Resolve time (Active time range strictly from Database)
    final dbHelper = DatabaseHelper();
    final user = await dbHelper.getUserInfo();

    int wakeHour = user?.wakeupHour ?? 8;
    int wakeMinute = user?.wakeupMinute ?? 0;
    int bedHour = user?.bedtimeHour ?? 22;
    int bedMinute = user?.bedtimeMinute ?? 0;

    final now = DateTime.now();
    // Quiet time starts at bedtime
    DateTime quietStart =
        DateTime(now.year, now.month, now.day, bedHour, bedMinute);
    // Quiet time ends at waketime
    DateTime quietEnd =
        DateTime(now.year, now.month, now.day, wakeHour, wakeMinute);

    // If quiet time ends before it starts (e.g., bedtime 22:00, waketime 08:00), it ends the next day
    if (quietEnd.isBefore(quietStart)) {
      quietEnd = quietEnd.add(const Duration(days: 1));
    }

    final startEpoch = quietStart.millisecondsSinceEpoch ~/ 1000;
    final endEpoch = quietEnd.millisecondsSinceEpoch ~/ 1000;

    // 4. Construct Payload
    final payload = '0/$startEpoch/$endEpoch|'
        '1/$targetWater|'
        '2/${(lIntensity * 100).toInt()}|'
        '3/${(vStrength * 100).toInt()}|'
        '4/${rFeedback ? 1 : 0}|'
        '5/${stopOnCompletion ? 1 : 0}|'
        '6/$repIndex';

    await setPendingConfigData(payload);
  }
}
