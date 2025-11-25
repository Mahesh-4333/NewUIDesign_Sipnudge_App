// reminder_state.dart
import 'package:equatable/equatable.dart';

class Reminder_Mode_BottonSheet_State extends Equatable {
  final bool aiReminder;
  final bool steadySipReminder;

  const Reminder_Mode_BottonSheet_State({
    this.aiReminder = false,
    this.steadySipReminder = false,
  });

  Reminder_Mode_BottonSheet_State copyWith({
    bool? aiReminder,
    bool? steadySipReminder,
  }) {
    return Reminder_Mode_BottonSheet_State(
      aiReminder: aiReminder ?? this.aiReminder,
      steadySipReminder: steadySipReminder ?? this.steadySipReminder,
    );
  }

  @override
  List<Object?> get props => [aiReminder, steadySipReminder];
}
