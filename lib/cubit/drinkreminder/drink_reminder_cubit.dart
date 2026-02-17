import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/services/notification/notification_service.dart';

class DrinkReminderCubit extends Cubit<DrinkReminderState> {
  final HydrationCubit hydrationCubit;

  final List<String> alarmRepeatOptions = ['1 Times', '3 Times', '5 Times', '10 Times'];
  DrinkReminderCubit({required this.hydrationCubit}) : super(const DrinkReminderState()){
    _init();
    // _setupHydrationListener();
  }

  // void _setupHydrationListener() {
  //   hydrationCubit.stream.listen((hydrationState) {
  //     if (state.stopWhenFull && state.reminderEnabled) {
  //       // Find if any entry just reached 100% or more
  //       // For simplicity and correctness, we can just reschedule
  //       // which will skip all completed entries for today.
  //       if (state.reminderMode == "AI") {
  //          _rescheduleAllReminders();
  //       } else {
  //          _rescheduleAllRemindersRepeat();
  //       }
  //     }
  //   });
  // }

  void _init() async {
    final mode = await SharedPrefsHelper.getReminderMode();
    if (mode == null) {
      setReminderMode("Static");
    } else {
      setReminderMode(mode == "AI" ? "AI" : "Static");
    }

    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();
    
    emit(state.copyWith(
      alarmRepeatIndex: alarmRepeatIndex,
      stopWhenFull: stopWhenFull,
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
    await notificationService.cancelAllHydrationReminders();
    await notificationService.scheduleHydrationRemindersForFuture(allSlots);
  }

  Future<void> toggleStopWhenFull(bool value) async {
    emit(state.copyWith(stopWhenFull: value));
    await SharedPrefsHelper.setStopWhenFull(value);

    final notificationService = NotificationService();

    if (value) {
      // If enabled, check if current slot is already completed and cancel reminders
      final currentSlot = hydrationCubit.state.currentSlotEntry;
      if (currentSlot != null && currentSlot.status == HydrationStatus.completed) {
        await notificationService.cancelSlotReminders(currentSlot.slot, 0); // 0 for today
      }
    }

    // Reschedule to ensure scheduling logic respects the new setting
    if (state.reminderEnabled) {
      if (state.reminderMode == "AI") {
        await _rescheduleAllReminders();
      } else {
        await _rescheduleAllRemindersRepeat();
      }
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
