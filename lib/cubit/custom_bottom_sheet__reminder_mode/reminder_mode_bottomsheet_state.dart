// reminder_state.dart
import 'package:equatable/equatable.dart';

class ReminderModeBottonSheetState extends Equatable {
  final bool aiReminder;
  final bool steadySipReminder;

  const ReminderModeBottonSheetState(
      {required this.aiReminder, required this.steadySipReminder});

  factory ReminderModeBottonSheetState.initial() {
    return ReminderModeBottonSheetState(
        aiReminder: false, steadySipReminder: true);
  }

  ReminderModeBottonSheetState copyWith({
    bool? aiReminder,
    bool? steadySipReminder,
  }) {
    return ReminderModeBottonSheetState(
      aiReminder: aiReminder ?? this.aiReminder,
      steadySipReminder: steadySipReminder ?? this.steadySipReminder,
    );
  }

  @override
  List<Object?> get props => [aiReminder, steadySipReminder];
}
