import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/custom_bottom_sheet__reminder_mode/reminder_mode_bottomsheet_cubit.dart';
import 'package:hydrify/cubit/custom_bottom_sheet__reminder_mode/reminder_mode_bottomsheet_state.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/custom_bottom_sheet_interval.dart';
import 'package:hydrify/screens/widgets/reminder_mode_bottomsheet_optionCard.dart';
import 'package:hydrify/services/google_calendar_manager.dart';

class ReminderBottomSheet extends StatelessWidget {
  const ReminderBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReminderModeBottonSheetCubit(),
      child: BlocListener<ReminderModeBottonSheetCubit,
          ReminderModeBottonSheetState>(
        listenWhen: (previous, current) =>
            previous.steadySipReminder != current.steadySipReminder,
        listener: (context, state) {

        },
        child: Container(
          padding: EdgeInsets.only(
              left: AppDimensions.dim30.w,
              right: AppDimensions.dim30.w,
              bottom: AppDimensions.dim100.h,
              top: AppDimensions.dim30.h),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            image: DecorationImage(
              image: AssetImage(
                  "assets/images/app_background.png"), // your image path
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.reminderMode,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_24.sp,
                      fontVariations: [
                        AppFontStyles.fontWeightVariation600,
                      ],
                      color: AppColors.bluegray,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: AppFontStyles.fontSize_22.sp,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.dim20.h),

              /// AI-Driven Smart Reminder
              BlocBuilder<ReminderModeBottonSheetCubit,
                  ReminderModeBottonSheetState>(
                builder: (context, state) {
                  debugPrint("AI Reminder: ${state.aiReminder}");
                  return ReminderOptionCard(
                    title: AppStrings.aiDrivenSmartReminder,
                    subtitle: AppStrings.predictiveHydration,
                    features: const [
                      AppStrings.adaptsToYourScheduleWeatherAndActivity,
                      AppStrings.syncsWithGoogleCalender,
                      AppStrings.smartSnoozeAndPersonalizedTips,
                    ],
                    isActive: state.aiReminder,
                    onToggle: (value) async {
                      if(value){
                        GoogleCalendarManager().ensureSignedIn().then((value) async {
                          if(value){
                            await SharedPrefsHelper.setReminderMode("AI");
                            context.read<DrinkReminderCubit>().setReminderMode("AI");
                            if(value){
                              context
                                  .read<ReminderModeBottonSheetCubit>()
                                  .toggleAiReminder(value);
                              context
                                  .read<ReminderModeBottonSheetCubit>()
                                  .toggleSteadySipReminder(false);
                            }
                          }
                        });
                      }else{
                        await SharedPrefsHelper.setReminderMode("");
                        context
                            .read<ReminderModeBottonSheetCubit>()
                            .toggleAiReminder(false);
                      }

                    },
                    activeColor: AppColors.white,
                    activeTrackColor: AppColors.switchReminderColor,
                  );
                },
              ),

              SizedBox(height: AppDimensions.dim16.h),

              /// Steady Sip Reminder
              BlocBuilder<ReminderModeBottonSheetCubit,
                  ReminderModeBottonSheetState>(
                builder: (context, state) {
                  return ReminderOptionCard(
                    title: AppStrings.steadySipReminder,
                    features: const [
                      AppStrings.fixedIntervals,
                      AppStrings.simpleHydrationAlerts,
                    ],
                    isActive: state.steadySipReminder,
                    onToggle: (value) async {
                      if(value){
                        await SharedPrefsHelper.setReminderMode("SteadySip");
                        context.read<DrinkReminderCubit>().setReminderMode("Static");
                        context
                            .read<ReminderModeBottonSheetCubit>()
                            .toggleSteadySipReminder(value);
                        context
                            .read<ReminderModeBottonSheetCubit>()
                            .toggleAiReminder(false);
                      }else{
                        await SharedPrefsHelper.setReminderMode("");
                        context
                            .read<ReminderModeBottonSheetCubit>()
                            .toggleSteadySipReminder(value);
                      }
                    },
                    activeColor: AppColors.white,
                    activeTrackColor: AppColors.switchReminderColor,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

