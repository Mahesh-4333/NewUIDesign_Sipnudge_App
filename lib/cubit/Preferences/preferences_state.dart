part of 'preferences_cubit.dart';

class PreferencesState {
  final bool hapticFeedback;
  final bool wakeUpAlarm;
  final bool ledFeedback;
  final String activeTab;
  // 🔥 Add this
  final bool ringtoneFeedback;

  PreferencesState({
    required this.hapticFeedback,
    required this.wakeUpAlarm,
    required this.ledFeedback,
    required this.activeTab,
    this.ringtoneFeedback = true, // 🔥 Default value
  });

  PreferencesState copyWith({
    bool? hapticFeedback,
    bool? wakeUpAlarm,
    bool? ledFeedback,
    String? activeTab,
    bool? ringtoneFeedback, // 🔥 NEW PARAMETER
  }) {
    return PreferencesState(
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      wakeUpAlarm: wakeUpAlarm ?? this.wakeUpAlarm,
      ledFeedback: ledFeedback ?? this.ledFeedback,
      activeTab: activeTab ?? this.activeTab,
      ringtoneFeedback:
          ringtoneFeedback ?? this.ringtoneFeedback, // 🔥 NEW LINE
    );
  }
}

// =======================================================================

// part of 'preferences_cubit.dart';

// class PreferencesState {
//   final bool hapticFeedback;
//   final bool wakeUpAlarm;
//   final bool ledFeedback;
//   final String activeTab;

//   PreferencesState({
//     required this.hapticFeedback,
//     required this.wakeUpAlarm,
//     required this.ledFeedback,
//     required this.activeTab,
//   });

//   PreferencesState copyWith({
//     bool? hapticFeedback,
//     bool? wakeUpAlarm,
//     bool? ledFeedback,
//     String? activeTab,
//   }) {
//     return PreferencesState(
//       hapticFeedback: hapticFeedback ?? this.hapticFeedback,
//       wakeUpAlarm: wakeUpAlarm ?? this.wakeUpAlarm,
//       ledFeedback: ledFeedback ?? this.ledFeedback,
//       activeTab: activeTab ?? this.activeTab,
//     );
//   }
// }

// =======================================================================
