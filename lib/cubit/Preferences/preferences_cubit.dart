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

    emit(state.copyWith(
      ringtoneFeedback: ringtoneStatus,
      vibrationStrength: vibStrength,
      ledIntensity: ledIntens,
      ledHue: lHue,
      uvCleaning: uvClean,
      ledFeedback: ledFeed,
    ));
  }

  void toggleHapticFeedback(bool value) =>
      emit(state.copyWith(hapticFeedback: value));

  void toggleWakeUpAlarm(bool value) =>
      emit(state.copyWith(wakeUpAlarm: value));

  void toggleLedFeedback(bool value) {
    SharedPrefsHelper.updateAndSaveDeviceConfig(stopWhenFull: value);
    emit(state.copyWith(ledFeedback: value));
  }

  void updateVibrationStrength(double value) {
    SharedPrefsHelper.updateAndSaveDeviceConfig(vibrationStrength: value);
    emit(state.copyWith(vibrationStrength: value));
  }

  void updateLedIntensity(double value) {
    SharedPrefsHelper.updateAndSaveDeviceConfig(ledIntensity: value);
    emit(state.copyWith(ledIntensity: value));
  }

  void updateLedHue(double value) {
    SharedPrefsHelper.setLedHue(value);
    emit(state.copyWith(ledHue: value));
  }

  void toggleUvCleaning(bool value) {
    SharedPrefsHelper.setUvCleaning(value);
    emit(state.copyWith(uvCleaning: value));
  }

  void toggleRingtoneFeedback(bool value) async {
    var allSlots = await DatabaseHelper().getAllSlots();
    NotificationService().resetAllHydrationReminders(allSlots);
    SharedPrefsHelper.updateAndSaveDeviceConfig(ringtoneFeedback: value);
    emit(state.copyWith(ringtoneFeedback: value));
  }

  void updateActiveTab(String label) => emit(state.copyWith(activeTab: label));
}
