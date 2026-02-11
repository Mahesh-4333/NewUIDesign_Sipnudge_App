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
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/notification/notification_service.dart';

class DrinkReminderCubit extends Cubit<DrinkReminderState> {
  final HydrationCubit hydrationCubit;

  DrinkReminderCubit({required this.hydrationCubit}) : super(const DrinkReminderState()){
    SharedPrefsHelper.getReminderMode().then((value) {
      if(value == null){
        setReminderMode("Static");
      }
      setReminderMode(value == "AI" ? "AI" : "Static");
    });
  }

  final List<String> smartSkipOptions = ['3 mins', '5 mins', '10 mins'];
  final List<String> alarmRepeatOptions = ['3 Times', '5 Times', '10 Times'];

  Future<void> toggleReminder(bool value) async {
    emit(state.copyWith(reminderEnabled: value));

    final notificationService = NotificationService();

    if (value) {
      final allSlots = hydrationCubit.state.entries;
      for (final entry in allSlots) {
        await notificationService.rescheduleSlotForFuture(entry);
      }
    } else {
      await notificationService.cancelAllHydrationReminders();
    }
  }

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
