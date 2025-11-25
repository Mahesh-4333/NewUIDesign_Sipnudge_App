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
import 'package:hydrify/screens/custom_bottom_sheet_interval.dart';
import 'package:hydrify/screens/widgets/reminder_mode_bottomsheet_optionCard.dart';

class ReminderBottomSheet extends StatelessWidget {
  const ReminderBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => Reminder_Mode_BottonSheet_Cubit(),
      child: BlocListener<Reminder_Mode_BottonSheet_Cubit,
          Reminder_Mode_BottonSheet_State>(
        listenWhen: (previous, current) =>
            previous.steadySipReminder != current.steadySipReminder,
        listener: (context, state) {
          if (state.steadySipReminder) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const IntervalBottomSheet(),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(30.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radius_30.r),
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
                      color: AppColors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: AppFontStyles.fontSize_22.sp,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.dim20.h),

              /// AI-Driven Smart Reminder
              // BlocBuilder<Reminder_Mode_BottonSheet_Cubit,
              //     Reminder_Mode_BottonSheet_State>(
              //   builder: (context, state) {
              //     return ReminderOptionCard(
              //       title: AppStrings.aiDrivenSmartReminder,
              //       subtitle: AppStrings.predictiveHydration,
              //       features: const [
              //         AppStrings.adaptsToYourScheduleWeatherAndActivity,
              //         AppStrings.syncsWithGoogleCalender,
              //         AppStrings.smartSnoozeAndPersonalizedTips,
              //       ],
              //       isActive: state.aiReminder,
              //       onToggle: (value) => context
              //           .read<Reminder_Mode_BottonSheet_Cubit>()
              //           .toggleAiReminder(value),
              //       activeColor: AppColors.white,
              //       activeTrackColor: AppColors.violetBlue,
              //     );
              //   },
              // ),

              /// AI-Driven Smart Reminder (Disabled / Coming Soon)
              Stack(
                children: [
                  ReminderOptionCard(
                    title: AppStrings.aiDrivenSmartReminder,
                    subtitle: AppStrings.predictiveHydration,
                    features: const [
                      AppStrings.adaptsToYourScheduleWeatherAndActivity,
                      AppStrings.syncsWithGoogleCalender,
                      AppStrings.smartSnoozeAndPersonalizedTips,
                    ],
                    isActive: false, // keep it always off
                    onToggle: (_) {}, // disable interaction
                    activeColor: AppColors.white,
                    activeTrackColor: AppColors.violetBlue,
                    //comingSoonText: "Coming soon",
                  ),
                  // Overlay for blur & dimming
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          16), // match ReminderOptionCard corners
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          // color: Color(0x855D5D5D),
                          decoration: BoxDecoration(
                            color: Color(0x845D5D5D),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radius_15.r),
                            border: Border.all(
                              color: Color(0x845D5D5D),
                              width: AppDimensions.dim5.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.dim16.h),

              // SizedBox(height: 16.h),

              /// Steady Sip Reminder
              BlocBuilder<Reminder_Mode_BottonSheet_Cubit,
                  Reminder_Mode_BottonSheet_State>(
                builder: (context, state) {
                  return ReminderOptionCard(
                    title: AppStrings.steadySipReminder,
                    features: const [
                      AppStrings.fixedIntervals,
                      AppStrings.simpleHydrationAlerts,
                    ],
                    isActive: state.steadySipReminder,
                    onToggle: (value) => context
                        .read<Reminder_Mode_BottonSheet_Cubit>()
                        .toggleSteadySipReminder(value),
                    activeColor: AppColors.white,
                    activeTrackColor: AppColors.violetBlue,
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
