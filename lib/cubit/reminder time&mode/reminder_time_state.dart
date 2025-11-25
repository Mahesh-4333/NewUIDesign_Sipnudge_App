import 'package:equatable/equatable.dart';

class ReminderTimeState extends Equatable {
  final String selectedInterval;

  const ReminderTimeState({required this.selectedInterval});

  ReminderTimeState copyWith({String? selectedInterval}) {
    return ReminderTimeState(
      selectedInterval: selectedInterval ?? this.selectedInterval,
    );
  }

  @override
  List<Object?> get props => [selectedInterval];
}
