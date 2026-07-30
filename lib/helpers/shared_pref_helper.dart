import 'dart:async';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  // Config Update Stream
  static final StreamController<void> configUpdateStream =
      StreamController<void>.broadcast();

  // Existing Keys
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserId = 'user_id';
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
  static const String _keyPendingWifiProvData = 'pending_wifi_prov_data';
  static const String _keyActiveWifiSsid = 'active_wifi_ssid';
  static const String _keyActiveWifiPassword = 'active_wifi_password';
  static const String _keyActiveWifiIp = 'active_wifi_ip';
  static const String _keyActiveWifiPriority = 'active_wifi_priority';

  static const String _keyReminderMode = "reminder_mode";
  static const String _keyAlarmRepeatIndex = "alarm_repeat_index";
  static const String _keyStopWhenFull = "stop_when_full";

  static const String _keyVibrationStrength = "vibration_strength";
  static const String _keyLedIntensity = "led_intensity";
  static const String _keyLedColor = "led_color";
  static const String _keyUvCleaning = "uv_cleaning";
  static const String _keyFavoriteRingtones = 'favorite_ringtones';
  static const String _keyHasRequestedHealthPermission =
      'has_requested_health_permission';
  static const String _keyFlushDelay = 'flush_delay';
  static const String _keyAiHydrationGoalShownDate =
      'ai_hydration_goal_shown_date';
  static const String _keyUnsnoozedSlots = 'unsnoozed_slots';
  static const String _keyUnsnoozedDate = 'unsnoozed_date';
  static const String _keyShutdownApp = 'shutdown_app';
  static const String _keyHasSynced30Days = 'has_synced_30_days';
  static const String _keyUserName = 'user_name';
  static const String _keyLastSummarySyncDate = 'last_summary_sync_date';
  static const String _keyHasShownHomeShowcase = 'has_shown_home_showcase';
  static const String _keyHasShownLocationPrivacy = 'has_shown_location_privacy';
  static const String _keyGhostMode = 'location_ghost_mode';
  static const String _keyFuzzyLocation = 'location_fuzzy';
  static const String _keyUserLatitude = 'user_latitude';
  static const String _keyUserLongitude = 'user_longitude';
  static const String _keyUserType = 'user_type';

  static Future<void> setUserType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserType, type);
    configUpdateStream.add(null);
  }

  static Future<String> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType) ?? 'regular';
  }

  static Future<bool> isPremium() async {
    final type = await getUserType();
    return type == 'premium';
  }

  // ----------------------------
  // APP SHUTDOWN (TRIAL RESTRICTION)
  // ----------------------------
  static Future<void> setAppShutdownStatus(bool shutdown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShutdownApp, shutdown);
  }

  static Future<bool> isAppShutdown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShutdownApp) ?? false;
  }

  // ----------------------------
  // DAILY SUMMARY SYNC FLAG
  // ----------------------------
  /// Returns true if the one-time full 30-day summary sync has already been
  /// completed for this user. After it's done we only push today's data.
  static Future<bool> hasSynced30Days() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSynced30Days) ?? false;
  }

  static Future<void> setHasSynced30Days(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSynced30Days, value);
  }

  // ----------------------------
  // LAST SUMMARY SYNC DATE
  // ----------------------------
  static Future<void> setLastSummarySyncDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSummarySyncDate, date);
  }

  static Future<String?> getLastSummarySyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastSummarySyncDate);
  }

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
  // UNSNOOZED SLOTS PERSISTENCE
  // ----------------------------
  static Future<void> saveUnsnoozedSlot(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    
    // Clear if it's a new day
    final savedDate = prefs.getString(_keyUnsnoozedDate);
    List<String> list = [];
    if (savedDate == today) {
      list = prefs.getStringList(_keyUnsnoozedSlots) ?? [];
    } else {
      await prefs.setString(_keyUnsnoozedDate, today);
    }
    
    if (!list.contains(slotIndex.toString())) {
      list.add(slotIndex.toString());
      await prefs.setStringList(_keyUnsnoozedSlots, list);
    }
  }

  static Future<void> removeUnsnoozedSlot(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyUnsnoozedSlots) ?? [];
    if (list.contains(slotIndex.toString())) {
      list.remove(slotIndex.toString());
      await prefs.setStringList(_keyUnsnoozedSlots, list);
    }
  }

  static Future<Set<int>> getUnsnoozedSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    
    final savedDate = prefs.getString(_keyUnsnoozedDate);
    if (savedDate != today) {
      await prefs.remove(_keyUnsnoozedSlots);
      return {};
    }
    
    final list = prefs.getStringList(_keyUnsnoozedSlots) ?? [];
    return list.map((e) => int.parse(e)).toSet();
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

  static Future<void> setFlushDelay(int delay) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFlushDelay, delay);
  }

  static Future<int> getFlushDelay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFlushDelay) ?? 100;
  }

  static Future<void> setAiHydrationGoalShown(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAiHydrationGoalShownDate, shown);
  }

  static Future<bool> getAiHydrationGoalShown() async {
    final prefs = await SharedPreferences.getInstance();
    var goalHydration =  prefs.getBool(_keyAiHydrationGoalShownDate);
    if(goalHydration == null){
      return true;
    }
    return goalHydration;
  }

  static Future<bool> hasShownHomeShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasShownHomeShowcase) ?? false;
  }

  static Future<void> setHasShownHomeShowcase(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasShownHomeShowcase, value);
  }

  static Future<bool> hasShownLocationPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasShownLocationPrivacy) ?? false;
  }

  static Future<void> setHasShownLocationPrivacy(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasShownLocationPrivacy, value);
  }

  static Future<bool> getGhostMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGhostMode) ?? true;
  }

  static Future<void> setGhostMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGhostMode, value);
  }

  static Future<bool> getFuzzyLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFuzzyLocation) ?? true;
  }

  static Future<void> setFuzzyLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFuzzyLocation, value);
  }

  static Future<double?> getUserLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyUserLatitude);
  }

  static Future<void> setUserLatitude(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUserLatitude, value);
  }

  static Future<double?> getUserLongitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyUserLongitude);
  }

  static Future<void> setUserLongitude(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUserLongitude, value);
  }

  // ----------------------------
  // Existing Methods
  // ----------------------------

  // Save user email
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  // Save / retrieve user display name
  static Future<void> setUserName(String name) async {
    await UserManager().setUserName(name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<void> setWaterGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWaterGoal, goal);
    // configUpdateStream.add(null);
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
    bool triggerStream = true,
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

    int rawWakeHour = user?.wakeupHour ?? 8;
    int wakeMinute = user?.wakeupMinute ?? 0;
    String wakePeriod = user?.wakeupPeriod ?? "AM";

    int rawBedHour = user?.bedtimeHour ?? 10;
    int bedMinute = user?.bedtimeMinute ?? 0;
    String bedPeriod = user?.bedtimePeriod ?? "PM";

    // 12h to 24h conversion for Wakeup
    int wakeHour24 = rawWakeHour;
    if (wakePeriod == "PM" && rawWakeHour != 12) wakeHour24 += 12;
    if (wakePeriod == "AM" && rawWakeHour == 12) wakeHour24 = 0;

    // 12h to 24h conversion for Bedtime
    int bedHour24 = rawBedHour;
    if (bedPeriod == "PM" && rawBedHour != 12) bedHour24 += 12;
    if (bedPeriod == "AM" && rawBedHour == 12) bedHour24 = 0;

    final now = DateTime.now();
    // Quiet time starts at bedtime
    DateTime quietStart = DateTime(
      now.year,
      now.month,
      now.day,
      bedHour24,
      bedMinute,
    );
    // Quiet time ends at waketime
    DateTime quietEnd = DateTime(
      now.year,
      now.month,
      now.day,
      wakeHour24,
      wakeMinute,
    );

    // If quiet time ends before it starts (e.g., bedtime 22:00, waketime 08:00), it ends the next day
    if (quietEnd.isBefore(quietStart)) {
      quietEnd = quietEnd.add(const Duration(days: 1));
    }

    // 4. Construct Payload
    final payload = '0/${bedHour24 < 10 ? '0$bedHour24' : bedHour24}/'
        '${bedMinute < 10 ? '0$bedMinute' : bedMinute}/'
        '${wakeHour24 < 10 ? '0$wakeHour24' : wakeHour24}/'
        '${wakeMinute < 10 ? '0$wakeMinute' : wakeMinute}|'
        '1/$targetWater|'
        '2/${(lIntensity * 100).toInt()}|'
        '3/${(vStrength * 100).toInt()}|'
        '4/${rFeedback ? 1 : 0}|'
        '5/${stopOnCompletion ? 1 : 0}|'
        '6/${[1, 3, 5][repIndex]}';

    Console.log(tag: "pendingConfig_ld", value: payload.toString());
    await setPendingConfigData(payload);

    // Check if this is the very first time the app is configuring
    final prefs = await SharedPreferences.getInstance();
    final isFirstTimeConfig = prefs.getBool('is_first_time_config') ?? true;

    if (isFirstTimeConfig) {
      await prefs.setBool('is_first_time_config', false);
      if (triggerStream) {
        await Future.delayed(Duration(seconds: 4));
        configUpdateStream.add(null);
      }
    } else {
      // Trigger the config update stream to show the UI dialog
      if (triggerStream) {
        configUpdateStream.add(null);
      }
    }
  }

  static Future<void> setPendingWifiProvData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingWifiProvData, data);
  }

  static Future<String?> getPendingWifiProvData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingWifiProvData);
  }

  static Future<void> clearPendingWifiProvData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingWifiProvData);
  }

  static Future<void> setActiveWifiSsid(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveWifiSsid, value);
  }

  static Future<String?> getActiveWifiSsid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveWifiSsid);
  }

  static Future<void> setActiveWifiPassword(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveWifiPassword, value);
  }

  static Future<String?> getActiveWifiPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveWifiPassword);
  }

  static Future<void> setActiveWifiIp(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveWifiIp, value);
  }

  static Future<String?> getActiveWifiIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveWifiIp);
  }

  static Future<void> setActiveWifiPriority(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyActiveWifiPriority, value);
  }

  static Future<int?> getActiveWifiPriority() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyActiveWifiPriority);
  }

  static Future<void> setWifiCredentialsForPriority(int priority, String ssid, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wifi_ssid_$priority', ssid);
    await prefs.setString('wifi_password_$priority', password);
  }

  static Future<String?> getWifiSsidForPriority(int priority) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wifi_ssid_$priority');
  }

  static Future<String?> getWifiPasswordForPriority(int priority) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wifi_password_$priority');
  }

  static Future<void> setIsErasingData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_erasing_data', value);
  }

  static Future<bool> isErasingData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_erasing_data') ?? false;
  }
}
