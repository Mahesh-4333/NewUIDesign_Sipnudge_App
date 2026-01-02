import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    emit(state.copyWith(ringtoneFeedback: ringtoneStatus));
  }

  void toggleHapticFeedback(bool value) =>
      emit(state.copyWith(hapticFeedback: value));

  void toggleWakeUpAlarm(bool value) =>
      emit(state.copyWith(wakeUpAlarm: value));

  void toggleLedFeedback(bool value) =>
      emit(state.copyWith(ledFeedback: value));

  void toggleRingtoneFeedback(bool value) async {
    var allSlots = await DatabaseHelper().getAllSlots();
    NotificationService().resetAllHydrationReminders(allSlots);
    SharedPrefsHelper.setRingtoneFeedBack(value);
    emit(state.copyWith(ringtoneFeedback: value));
  }

  void updateActiveTab(String label) => emit(state.copyWith(activeTab: label));
}
