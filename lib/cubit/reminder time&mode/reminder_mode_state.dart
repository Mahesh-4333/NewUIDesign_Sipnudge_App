import 'package:equatable/equatable.dart';

class ReminderState extends Equatable {
  final bool aiReminder;
  final bool steadySipReminder;

  const ReminderState({
    required this.aiReminder,
    required this.steadySipReminder,
  });

  ReminderState copyWith({bool? aiReminder, bool? steadySipReminder}) {
    return ReminderState(
      aiReminder: aiReminder ?? this.aiReminder,
      steadySipReminder: steadySipReminder ?? this.steadySipReminder,
    );
  }

  @override
  List<Object?> get props => [aiReminder, steadySipReminder];
}
