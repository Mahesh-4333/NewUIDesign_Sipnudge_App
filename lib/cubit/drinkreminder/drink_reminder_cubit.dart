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

  final List<String> smartSkipOptions = ['3 min', '5 min', '10 min'];
  final List<String> alarmRepeatOptions = ['3 min', '5 min', '10 min'];

  DrinkReminderCubit({required this.hydrationCubit}) : super(const DrinkReminderState()){
    _init();
  }

  void _init() async {
    final mode = await SharedPrefsHelper.getReminderMode();
    if (mode == null) {
      setReminderMode("Static");
    } else {
      setReminderMode(mode == "AI" ? "AI" : "Static");
    }

    final smartSkipIndex = await SharedPrefsHelper.getSmartSkipIndex();
    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    
    emit(state.copyWith(
      smartSkipIndex: smartSkipIndex,
      alarmRepeatIndex: alarmRepeatIndex,
    ));
  }

  Future<void> toggleReminder(bool value) async {
    emit(state.copyWith(reminderEnabled: value));

    final notificationService = NotificationService();

    if (value) {
      await _rescheduleAllReminders();
    } else {
      await notificationService.cancelAllHydrationReminders();
    }
  }

  Future<void> _rescheduleAllReminders() async {
    final notificationService = NotificationService();
    final allSlots = hydrationCubit.state.entries;
    await notificationService.cancelAllHydrationReminders();
    await notificationService.scheduleHydrationRemindersForFuture(allSlots);
  }


  Future<void> _rescheduleAllRemindersRepeat() async {
    final notificationService = NotificationService();
    final allSlots = hydrationCubit.state.entries;
    await notificationService.cancelAllHydrationRemindersRepeat();
    await notificationService.scheduleHydrationRemindersWithRepeats(allSlots);
  }

  void toggleStopWhenFull(bool value) =>
      emit(state.copyWith(stopWhenFull: value));

  void cycleSmartSkip() async {
    final nextIndex = (state.smartSkipIndex + 1) % smartSkipOptions.length;
    emit(state.copyWith(smartSkipIndex: nextIndex));
    await SharedPrefsHelper.setSmartSkipIndex(nextIndex);
    
    if (state.reminderEnabled) {
      await _rescheduleAllRemindersRepeat();
    }
  }

  void cycleAlarmRepeat() async {
    final nextIndex = (state.alarmRepeatIndex + 1) % alarmRepeatOptions.length;
    emit(state.copyWith(alarmRepeatIndex: nextIndex));
    await SharedPrefsHelper.setAlarmRepeatIndex(nextIndex);

    if (state.reminderEnabled) {
      await _rescheduleAllRemindersRepeat();
    }
  }

  void setReminderMode(String mode) => emit(state.copyWith(reminderMode: mode));
  void setTitle(String title) => emit(state.copyWith(title: title));
}
