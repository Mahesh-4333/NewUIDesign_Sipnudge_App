part of 'preferences_cubit.dart';

class PreferencesState {
  final bool hapticFeedback;
  final bool wakeUpAlarm;
  final bool ledFeedback;
  final String activeTab;
  final bool ringtoneFeedback;

  PreferencesState({
    required this.hapticFeedback,
    required this.wakeUpAlarm,
    required this.ledFeedback,
    required this.activeTab,
    this.ringtoneFeedback = true,
  });

  PreferencesState copyWith({
    bool? hapticFeedback,
    bool? wakeUpAlarm,
    bool? ledFeedback,
    String? activeTab,
    bool? ringtoneFeedback,
  }) {
    return PreferencesState(
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      wakeUpAlarm: wakeUpAlarm ?? this.wakeUpAlarm,
      ledFeedback: ledFeedback ?? this.ledFeedback,
      activeTab: activeTab ?? this.activeTab,
      ringtoneFeedback: ringtoneFeedback ?? this.ringtoneFeedback,
    );
  }
}
