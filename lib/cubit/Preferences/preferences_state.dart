part of 'preferences_cubit.dart';

class PreferencesState {
  final bool hapticFeedback;
  final bool wakeUpAlarm;
  final bool ledFeedback;
  final String activeTab;
  final bool ringtoneFeedback;
  final double vibrationStrength;
  final double ledIntensity;
  final double ledHue;
  final bool uvCleaning;
  final DateTime? lastResetDate;

  PreferencesState({
    required this.hapticFeedback,
    required this.wakeUpAlarm,
    required this.ledFeedback,
    required this.activeTab,
    this.ringtoneFeedback = true,
    this.vibrationStrength = 0.75,
    this.ledIntensity = 0.8,
    this.ledHue = 0.6,
    this.uvCleaning = false,
    this.lastResetDate,
  });

  PreferencesState copyWith({
    bool? hapticFeedback,
    bool? wakeUpAlarm,
    bool? ledFeedback,
    String? activeTab,
    bool? ringtoneFeedback,
    double? vibrationStrength,
    double? ledIntensity,
    double? ledHue,
    bool? uvCleaning,
    DateTime? lastResetDate,
  }) {
    return PreferencesState(
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      wakeUpAlarm: wakeUpAlarm ?? this.wakeUpAlarm,
      ledFeedback: ledFeedback ?? this.ledFeedback,
      activeTab: activeTab ?? this.activeTab,
      ringtoneFeedback: ringtoneFeedback ?? this.ringtoneFeedback,
      vibrationStrength: vibrationStrength ?? this.vibrationStrength,
      ledIntensity: ledIntensity ?? this.ledIntensity,
      ledHue: ledHue ?? this.ledHue,
      uvCleaning: uvCleaning ?? this.uvCleaning,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
