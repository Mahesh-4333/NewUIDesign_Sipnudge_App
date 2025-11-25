// class DrinkReminderState {
//   final bool reminderEnabled;
//   final bool stopWhenFull;
//   final int smartSkipIndex;
//   final int alarmRepeatIndex;
//   final String reminderMode;
//   final String title;

//   const DrinkReminderState({
//     this.reminderEnabled = true,
//     this.stopWhenFull = true,
//     this.smartSkipIndex = 2,
//     this.alarmRepeatIndex = 2,
//     this.reminderMode = 'Static',
//     this.title = 'Home',
//   });

//   DrinkReminderState copyWith({
//     bool? reminderEnabled,
//     bool? stopWhenFull,
//     int? smartSkipIndex,
//     int? alarmRepeatIndex,
//     String? reminderMode,
//     String? title,
//   }) {
//     return DrinkReminderState(
//       reminderEnabled: reminderEnabled ?? this.reminderEnabled,
//       stopWhenFull: stopWhenFull ?? this.stopWhenFull,
//       smartSkipIndex: smartSkipIndex ?? this.smartSkipIndex,
//       alarmRepeatIndex: alarmRepeatIndex ?? this.alarmRepeatIndex,
//       reminderMode: reminderMode ?? this.reminderMode,
//       title: title ?? this.title,
//     );
//   }
// }

// ===========================================================================

class DrinkReminderState {
  final bool reminderEnabled;
  final bool stopWhenFull;
  final int smartSkipIndex;
  final int alarmRepeatIndex;
  final String reminderMode;
  final String title;

  const DrinkReminderState({
    this.reminderEnabled = true,
    this.stopWhenFull = true,
    this.smartSkipIndex = 2,
    this.alarmRepeatIndex = 2,
    this.reminderMode = 'Static',
    this.title = 'Home',
  });

  DrinkReminderState copyWith({
    bool? reminderEnabled,
    bool? stopWhenFull,
    int? smartSkipIndex,
    int? alarmRepeatIndex,
    String? reminderMode,
    String? title,
  }) {
    return DrinkReminderState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      stopWhenFull: stopWhenFull ?? this.stopWhenFull,
      smartSkipIndex: smartSkipIndex ?? this.smartSkipIndex,
      alarmRepeatIndex: alarmRepeatIndex ?? this.alarmRepeatIndex,
      reminderMode: reminderMode ?? this.reminderMode,
      title: title ?? this.title,
    );
  }
}
