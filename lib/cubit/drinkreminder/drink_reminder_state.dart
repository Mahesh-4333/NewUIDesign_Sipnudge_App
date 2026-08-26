import 'package:hydrify/constants/app_strings.dart';

class DrinkReminderState {
  final bool reminderEnabled;
  final bool notificationEnabled;
  final bool stopWhenFull;
  final int alarmRepeatIndex;
  final String reminderMode;
  final String title;
  final bool isSaving;
  final String savingMessage;

  const DrinkReminderState({
    this.reminderEnabled = true,
    this.notificationEnabled = true,
    this.stopWhenFull = true,
    this.alarmRepeatIndex = 0,
    this.reminderMode = 'Static',
    this.title = 'Home',
    this.isSaving = false,
    this.savingMessage = AppStrings.savingReminder,
  });

  DrinkReminderState copyWith({
    bool? reminderEnabled,
    bool? notificationEnabled,
    bool? stopWhenFull,
    int? alarmRepeatIndex,
    String? reminderMode,
    String? title,
    bool? isSaving,
    String? savingMessage,
  }) {
    return DrinkReminderState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      stopWhenFull: stopWhenFull ?? this.stopWhenFull,
      alarmRepeatIndex: alarmRepeatIndex ?? this.alarmRepeatIndex,
      reminderMode: reminderMode ?? this.reminderMode,
      title: title ?? this.title,
      isSaving: isSaving ?? this.isSaving,
      savingMessage: savingMessage ?? this.savingMessage,
    );
  }
}
