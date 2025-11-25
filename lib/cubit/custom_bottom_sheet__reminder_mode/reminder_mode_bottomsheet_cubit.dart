// reminder_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/custom_bottom_sheet__reminder_mode/reminder_mode_bottomsheet_state.dart';

class Reminder_Mode_BottonSheet_Cubit
    extends Cubit<Reminder_Mode_BottonSheet_State> {
  Reminder_Mode_BottonSheet_Cubit()
      : super(const Reminder_Mode_BottonSheet_State());

  void toggleAiReminder(bool value) {
    emit(state.copyWith(aiReminder: value));
  }

  void toggleSteadySipReminder(bool value) {
    emit(state.copyWith(steadySipReminder: value));
  }
}
