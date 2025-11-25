// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';

// class DrinkReminderCubit extends Cubit<DrinkReminderState> {
//   DrinkReminderCubit() : super(const DrinkReminderState());

//   final List<String> smartSkipOptions = ['3 mins', '5 mins', '10 mins'];
//   final List<String> alarmRepeatOptions = ['3 Times', '5 Times', '10 Times'];

//   void toggleReminder(bool value) =>
//       emit(state.copyWith(reminderEnabled: value));
//   void toggleStopWhenFull(bool value) =>
//       emit(state.copyWith(stopWhenFull: value));

//   void cycleSmartSkip() {
//     final nextIndex = (state.smartSkipIndex + 1) % smartSkipOptions.length;
//     emit(state.copyWith(smartSkipIndex: nextIndex));
//   }

//   void cycleAlarmRepeat() {
//     final nextIndex = (state.alarmRepeatIndex + 1) % alarmRepeatOptions.length;
//     emit(state.copyWith(alarmRepeatIndex: nextIndex));
//   }

//   void setReminderMode(String mode) => emit(state.copyWith(reminderMode: mode));
//   void setTitle(String title) => emit(state.copyWith(title: title));
// }

// ===========================================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';

class DrinkReminderCubit extends Cubit<DrinkReminderState> {
  DrinkReminderCubit() : super(const DrinkReminderState());

  final List<String> smartSkipOptions = ['3 mins', '5 mins', '10 mins'];
  final List<String> alarmRepeatOptions = ['3 Times', '5 Times', '10 Times'];

  void toggleReminder(bool value) =>
      emit(state.copyWith(reminderEnabled: value));
  void toggleStopWhenFull(bool value) =>
      emit(state.copyWith(stopWhenFull: value));

  void cycleSmartSkip() {
    final nextIndex = (state.smartSkipIndex + 1) % smartSkipOptions.length;
    emit(state.copyWith(smartSkipIndex: nextIndex));
  }

  void cycleAlarmRepeat() {
    final nextIndex = (state.alarmRepeatIndex + 1) % alarmRepeatOptions.length;
    emit(state.copyWith(alarmRepeatIndex: nextIndex));
  }

  void setReminderMode(String mode) => emit(state.copyWith(reminderMode: mode));
  void setTitle(String title) => emit(state.copyWith(title: title));
}
