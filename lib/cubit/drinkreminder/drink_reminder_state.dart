class DrinkReminderState {
  final bool reminderEnabled;
  final bool stopWhenFull;
  final int alarmRepeatIndex;
  final String reminderMode;
  final String title;

  const DrinkReminderState({
    this.reminderEnabled = true,
    this.stopWhenFull = true,
    this.alarmRepeatIndex = 0,
    this.reminderMode = 'Static',
    this.title = 'Home',
  });

  DrinkReminderState copyWith({
    bool? reminderEnabled,
    bool? stopWhenFull,
    int? alarmRepeatIndex,
    String? reminderMode,
    String? title,
  }) {
    return DrinkReminderState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      stopWhenFull: stopWhenFull ?? this.stopWhenFull,
      alarmRepeatIndex: alarmRepeatIndex ?? this.alarmRepeatIndex,
      reminderMode: reminderMode ?? this.reminderMode,
      title: title ?? this.title,
    );
  }
}
