import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';
import 'package:hydrify/services/notification/notification_service.dart';

class DrinkReminderCubit extends Cubit<DrinkReminderState> {
  final HydrationCubit hydrationCubit;
  final BottleDataCubit bottleDataCubit;

  final List<String> alarmRepeatOptions = ['1 Times', '3 Times', '5 Times'];
  DrinkReminderCubit(
      {required this.hydrationCubit, required this.bottleDataCubit})
      : super(const DrinkReminderState()) {
    _init();
  }

  void _init() async {
    final mode = await SharedPrefsHelper.getReminderMode();
    if (mode == null) {
      setReminderMode("Static");
    } else {
      setReminderMode(mode == "AI" ? "AI" : "Static");
    }

    final alarmRepeatIndex = await SharedPrefsHelper.getAlarmRepeatIndex();
    final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();
    final notificationEnabled =
        await SharedPrefsHelper.isFirebaseNotificationEnabled();

    emit(state.copyWith(
      alarmRepeatIndex: alarmRepeatIndex,
      stopWhenFull: stopWhenFull,
      notificationEnabled: notificationEnabled,
    ));
  }

  Future<void> toggleNotification(bool value) async {
    emit(state.copyWith(
      notificationEnabled: value,
      isSaving: true,
      savingMessage: AppStrings.savingNotificationConfig,
    ));

    // Slight delay to show the saving animation
    await Future.delayed(const Duration(seconds: 2));

    await FirebaseMessagingService().setNotificationEnabled(value);

    emit(state.copyWith(isSaving: false));
  }

  Future<void> toggleReminder(bool value) async {
    emit(state.copyWith(
      reminderEnabled: value,
      isSaving: true,
      savingMessage: AppStrings.savingReminder,
    ));

    // Slight delay to show the saving animation
    await Future.delayed(const Duration(seconds: 2));

    final notificationService = NotificationService();

    if (value) {
      await _rescheduleAllReminders();
    } else {
      await notificationService.cancelAllHydrationReminders();
    }

    emit(state.copyWith(isSaving: false));

    await SharedPrefsHelper.updateAndSaveDeviceConfig();
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
    emit(state.copyWith(
      stopWhenFull: value,
      isSaving: true,
      savingMessage: AppStrings.savingReminder,
    ));
    // Slight delay to show the saving animation
    await Future.delayed(const Duration(seconds: 2));

    await SharedPrefsHelper.setStopWhenFull(value);

    final notificationService = NotificationService();

    if (value) {
      final history = await bottleDataCubit.getCurrentDayHistory();
      final completionPercent =
          await WaterConsumptionCalculator.calculateCompletionPercentage(
              history);

      if (completionPercent >= 100) {
        notificationService.cancelAllHydrationReminders();
        emit(state.copyWith(isSaving: false));
        return; // No need to reschedule
      }
    }

    // // Reschedule to ensure scheduling logic respects the new setting
    // if (state.reminderEnabled) {
    //   if (state.reminderMode == "AI") {
    //     await _rescheduleAllReminders();
    //   } else {
    //     await _rescheduleAllRemindersRepeat();
    //   }
    // }

    emit(state.copyWith(isSaving: false));
    await SharedPrefsHelper.updateAndSaveDeviceConfig();
  }

  void cycleAlarmRepeat() async {
    final nextIndex = (state.alarmRepeatIndex + 1) % alarmRepeatOptions.length;
    emit(state.copyWith(
      alarmRepeatIndex: nextIndex,
      isSaving: true,
      savingMessage: AppStrings.savingReminder,
    ));

    // Slight delay to show the saving animation
    await Future.delayed(const Duration(seconds: 2));

    await SharedPrefsHelper.setAlarmRepeatIndex(nextIndex);

    if (state.reminderEnabled) {
      await _rescheduleAllRemindersRepeat();
    }

    emit(state.copyWith(isSaving: false));

    await SharedPrefsHelper.updateAndSaveDeviceConfig();
  }

  void setReminderMode(String mode) => emit(state.copyWith(reminderMode: mode));
  void setTitle(String title) => emit(state.copyWith(title: title));
}
