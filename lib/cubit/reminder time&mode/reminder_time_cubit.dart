import 'package:flutter_bloc/flutter_bloc.dart';
import 'reminder_time_state.dart';

class ReminderTimeCubit extends Cubit<ReminderTimeState> {
  ReminderTimeCubit()
    : super(const ReminderTimeState(selectedInterval: "30 Minutes"));

  void updateInterval(String interval) {
    emit(state.copyWith(selectedInterval: interval));
  }
}
