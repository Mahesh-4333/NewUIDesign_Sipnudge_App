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
import 'package:hydrify/screens/widgets/ai_schedule_personalization_dialog.dart';
import 'package:hydrify/screens/calendar/calendar_screen.dart';

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
        listener: (context, state) {},
        child: Container(
          padding: EdgeInsets.only(
              left: AppDimensions.dim30.w,
              right: AppDimensions.dim30.w,
              bottom: AppDimensions.dim30.h,
              top: AppDimensions.dim30.h),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            // image: DecorationImage(
            //   image: AssetImage(
            //       "assets/images/app_background.png"), // your image path
            //   fit: BoxFit.cover,
            // ),
            color: AppColors.white,
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
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Disable interaction
                      GestureDetector(
                        onTap: () {
                          if (!state.aiReminder) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) =>
                                  AISchedulePersonalizationDialog(
                                onContinueWithGoogle: () {
                                  GoogleCalendarManager()
                                      .ensureSignedIn()
                                      .then((value) async {
                                    if (value) {
                                      await SharedPrefsHelper.setReminderMode(
                                          "AI");
                                      if (context.mounted) {
                                        context
                                            .read<DrinkReminderCubit>()
                                            .setReminderMode("AI");
                                        context
                                            .read<
                                                ReminderModeBottonSheetCubit>()
                                            .toggleAiReminder(value);
                                        context
                                            .read<
                                                ReminderModeBottonSheetCubit>()
                                            .toggleSteadySipReminder(false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "AI-Driven Smart Reminder enabled successfully!",
                                              style: TextStyle(
                                                fontFamily: AppFontStyles
                                                    .urbanistFontFamily,
                                                fontSize: AppFontStyles
                                                    .fontSize_12.sp,
                                                fontVariations: [
                                                  AppFontStyles
                                                      .fontWeightVariation600,
                                                ],
                                                color: AppColors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                AppColors.blueWaterIntake,
                                          ),
                                        );
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CalendarScreen()));
                                      }
                                    }
                                  });
                                },
                              ),
                            );
                          } else {
                            // If already active, toggle off
                            SharedPrefsHelper.setReminderMode("");
                            context
                                .read<ReminderModeBottonSheetCubit>()
                                .toggleAiReminder(false);
                          }
                        },
                        child: AbsorbPointer(
                            absorbing: true, // makes it non-clickable
                            child: ReminderOptionCard(
                              title: AppStrings.aiDrivenSmartReminder,
                              subtitle: AppStrings.predictiveHydration,
                              features: const [
                                AppStrings
                                    .adaptsToYourScheduleWeatherAndActivity,
                                AppStrings.syncsWithGoogleCalendar,
                                AppStrings.smartSnoozeAndPersonalizedTips,
                              ],
                              isActive: state.aiReminder,
                              onToggle: (value) async {
                                // This is now handled by GestureDetector
                              },
                              activeColor: AppColors.white,
                              activeTrackColor: AppColors.switchReminderColor,
                            )),
                      ),

                      // // Blur overlay
                      // Positioned.fill(
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(16), // match your card radius
                      //     child: BackdropFilter(
                      //       filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      //       child: Container(
                      //         color: Colors.black.withOpacity(0.2),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // // Center Text
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      //   decoration: BoxDecoration(
                      //     color: Colors.black.withOpacity(0.7),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: const Text(
                      //     "Coming Soon",
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                    ],
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
                    subtitle: AppStrings.steadySipSeriousResult,
                    features: const [
                      AppStrings.fixedIntervals,
                      AppStrings.simpleHydrationAlerts,
                    ],
                    isActive: state.steadySipReminder,
                    onToggle: (value) async {
                      if (value) {
                        await SharedPrefsHelper.setReminderMode("SteadySip");
                        context
                            .read<DrinkReminderCubit>()
                            .setReminderMode("Static");
                        context
                            .read<ReminderModeBottonSheetCubit>()
                            .toggleSteadySipReminder(value);
                        context
                            .read<ReminderModeBottonSheetCubit>()
                            .toggleAiReminder(false);
                      } else {
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
