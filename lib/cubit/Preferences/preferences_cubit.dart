import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/notification/notification_service.dart';

part 'preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit()
      : super(
          PreferencesState(
            hapticFeedback: true,
            wakeUpAlarm: true,
            ledFeedback: true,
            ringtoneFeedback: true,
            activeTab: 'Home',
          ),
        ) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final bool ringtoneStatus = await SharedPrefsHelper.getRingtoneFeedBack();
    final double vibStrength = await SharedPrefsHelper.getVibrationStrength();
    final double ledIntens = await SharedPrefsHelper.getLedIntensity();
    final double lHue = await SharedPrefsHelper.getLedHue();
    final bool uvClean = await SharedPrefsHelper.getUvCleaning();
    final bool ledFeed =
        await SharedPrefsHelper.getStopWhenFull(); // Assuming this for now
    final DateTime? resetDate = await DatabaseHelper().getLastResetDate();

    final bool isHapticOn = vibStrength > 0.0;
    final String hapticLabel = switch (vibStrength) {
      <= 0.0 => 'Off',
      >= 0.85 => 'High',
      _ => 'Medium',
    };

    final String ledLabel = switch (ledIntens) {
      <= 0.2 => 'Dim',
      >= 0.85 => 'Bright',
      _ => 'Medium',
    };

    emit(state.copyWith(
      ringtoneFeedback: ringtoneStatus,
      vibrationStrength: vibStrength,
      hapticFeedback: isHapticOn,
      hapticIntensity: hapticLabel,
      ledBrightness: ledLabel,
      ledIntensity: ledIntens,
      ledHue: lHue,
      uvCleaning: uvClean,
      ledFeedback: ledFeed,
      lastResetDate: resetDate,
    ));
  }

  Future<void> updateLastResetDate() async {
    final now = DateTime.now();
    await DatabaseHelper().saveLastResetDate(now);
    emit(state.copyWith(lastResetDate: now));
  }

  void toggleHapticFeedback(bool value) {
    if (value) {
      setHapticIntensity('Medium');
    } else {
      setHapticIntensity('Off');
    }
  }

  void toggleWakeUpAlarm(bool value) =>
      emit(state.copyWith(wakeUpAlarm: value));

  void toggleLedFeedback(bool value) {
    SharedPrefsHelper.updateAndSaveDeviceConfig(stopWhenFull: value);
    emit(state.copyWith(ledFeedback: value));
  }

  void updateVibrationStrength(double value) {
    emit(state.copyWith(vibrationStrength: value));
  }

  void saveVibrationStrength(double value) {
    SharedPrefsHelper.updateAndSaveDeviceConfig(vibrationStrength: value);
  }

  void updateLedIntensity(double value) {
    emit(state.copyWith(ledIntensity: value));
  }

  void saveLedIntensity(double value) {
    SharedPrefsHelper.updateAndSaveDeviceConfig(ledIntensity: value);
  }

  void updateLedHue(double value) {
    SharedPrefsHelper.setLedHue(value);
    emit(state.copyWith(ledHue: value));
  }

  void toggleUvCleaning(bool value) {
    SharedPrefsHelper.setUvCleaning(value);
    emit(state.copyWith(uvCleaning: value));
  }

  /// Map haptic intensity label → float and persist
  /// Off: 0.0 (0%), Medium: 0.75 (75%), High: 1.0 (100%)
  void setHapticIntensity(String label) {
    final double strength = switch (label) {
      'Off' => 0.0,
      'High' => 1.0,
      _ => 0.75, // Medium
    };
    final bool isHapticOn = strength > 0.0;
    SharedPrefsHelper.updateAndSaveDeviceConfig(vibrationStrength: strength);
    emit(state.copyWith(
      hapticFeedback: isHapticOn,
      hapticIntensity: label,
      vibrationStrength: strength,
    ));
  }

  /// Map LED brightness label → float and persist
  void setLedBrightness(String label) {
    final double intensity = switch (label) {
      'Dim' => 0.1,
      'Bright' => 1.0,
      _ => 0.7, // Medium
    };
    SharedPrefsHelper.updateAndSaveDeviceConfig(ledIntensity: intensity);
    emit(state.copyWith(
      ledBrightness: label,
      ledIntensity: intensity,
    ));
  }

  /// Store UV speed choice
  void setUvSpeed(String label) {
    emit(state.copyWith(uvSpeed: label));
  }

  void toggleRingtoneFeedback(bool value) async {
    var allSlots = await DatabaseHelper().getAllSlots();
    NotificationService().resetAllHydrationReminders(allSlots);
    SharedPrefsHelper.updateAndSaveDeviceConfig(ringtoneFeedback: value);
    emit(state.copyWith(ringtoneFeedback: value));
  }

  void updateActiveTab(String label) => emit(state.copyWith(activeTab: label));
}
