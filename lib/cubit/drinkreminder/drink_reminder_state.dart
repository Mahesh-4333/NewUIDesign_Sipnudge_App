class DrinkReminderState {
  final bool reminderEnabled;
  final bool stopWhenFull;
  final int alarmRepeatIndex;
  final String reminderMode;
  final String title;
  final bool isSaving;

  const DrinkReminderState({
    this.reminderEnabled = true,
    this.stopWhenFull = true,
    this.alarmRepeatIndex = 0,
    this.reminderMode = 'Static',
    this.title = 'Home',
    this.isSaving = false,
  });

  DrinkReminderState copyWith({
    bool? reminderEnabled,
    bool? stopWhenFull,
    int? alarmRepeatIndex,
    String? reminderMode,
    String? title,
    bool? isSaving,
  }) {
    return DrinkReminderState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      stopWhenFull: stopWhenFull ?? this.stopWhenFull,
      alarmRepeatIndex: alarmRepeatIndex ?? this.alarmRepeatIndex,
      reminderMode: reminderMode ?? this.reminderMode,
      title: title ?? this.title,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
