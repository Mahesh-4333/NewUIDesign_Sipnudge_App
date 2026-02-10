import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_cubit.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';
import 'package:hydrify/helpers/dialog_manager_helper.dart';
import 'package:hydrify/screens/custom_bttom_sheet_rm.dart';
import 'package:hydrify/screens/water_intake_timeline/water_intake_timeline_screen.dart';

// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_card.dart';
import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_cycle_item.dart';
import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_list_item.dart';
import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_toggle_row.dart';

class DrinkReminderPage extends StatelessWidget {
  const DrinkReminderPage({super.key});

  void _showReminderMode(BuildContext context) async {
    context.read<BottomNavCubit>().hideBar();
    await DialogManager().showTrackedModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ReminderBottomSheet(),
        );
      },
    );

    // ignore: use_build_context_synchronously
    context.read<BottomNavCubit>().showBar();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _appBarWidget(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/app_background.png"), // your image path
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: AppDimensions.dim28.h),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.dim28.w,
                    ),
                    child: BlocBuilder<DrinkReminderCubit, DrinkReminderState>(
                      builder: (context, state) {
                        final cubit = context.read<DrinkReminderCubit>();
                        return Column(
                          children: [
                            ReminderCard(
                              children: [
                                // reminder enable/disable
                                buildReminderToggleRow(state, cubit),

                                // reminder mode
                                buildReminderListItem(state, context),
                              ],
                            ),
                            SizedBox(height: AppDimensions.dim16.h),

                            //--------------------------------------//
                            ReminderCard(
                              children: [
                                // Smart Skip
                                _buildSmartSkip(cubit, state),

                                // Alarm Repeat
                                _buildAlarmRepeat(cubit, state),

                                // Stop When 100%
                                _buildStopWhen(state, cubit),
                              ],
                            ),
                            SizedBox(height: AppDimensions.dim16.h),

                            //-–––––––––––––––––––––––––––––––––––//
                            // Reminder Setting
                            ReminderCard(
                              children: [
                                _reminderSettingTitle(),
                                Divider(
                                  color: AppColors.bluegray,
                                  thickness: AppFontStyles.fontSize_1.sp,
                                ),
                                // Water Intake TimeLine
                                _buildWaterIntakeTimeline(context),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    //);
  }

  ReminderToggleRow _buildStopWhen(
      DrinkReminderState state, DrinkReminderCubit cubit) {
    return ReminderToggleRow(
      title: AppStrings.stopWhen100,
      value: state.stopWhenFull,
      onChanged: cubit.toggleStopWhenFull,
      titleStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_20.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      activeTrackColor: AppColors.switchReminderColor,
    );
  }

  ReminderCycleItem _buildAlarmRepeat(
      DrinkReminderCubit cubit, DrinkReminderState state) {
    return ReminderCycleItem(
      title: AppStrings.alarmRepeat,
      value: cubit.alarmRepeatOptions[state.alarmRepeatIndex],
      onTap: cubit.cycleAlarmRepeat,
      titleStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_20.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      chipBackgroundColor: Colors.transparent,
      chipBorderColor: AppColors.lightBlue400,
      chipTextStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_16.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.boldFontVariation],
      ),
    );
  }

  ReminderCycleItem _buildSmartSkip(
      DrinkReminderCubit cubit, DrinkReminderState state) {
    return ReminderCycleItem(
      title: AppStrings.smartSkip,
      value: cubit.smartSkipOptions[state.smartSkipIndex],
      onTap: cubit.cycleSmartSkip,
      titleStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_20.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      chipBackgroundColor: Colors.transparent,
      chipBorderColor: AppColors.lightBlue400,
      chipTextStyle: TextStyle(
        color: AppColors.bluegray,
        fontWeight: FontWeight.w600,
        fontSize: AppFontStyles.fontSize_16.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.boldFontVariation],
      ),
    );
  }

  AppBar _appBarWidget(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        AppStrings.drinkreminder,
        style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_AppBar,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              AppFontStyles.boldFontVariation,
            ]),
      ),
      leadingWidth: AppDimensions.dim85.w,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: SvgPicture.asset(
          "assets/images/back_ic.svg",
        ),
      ),
    );
  }

  Padding _reminderSettingTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.dim10.w,
        vertical: AppDimensions.dim10.h,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          AppStrings.remindersetting,
          style: TextStyle(
            fontSize: AppFontStyles.fontSize_20.sp,
            color: AppColors.bluegray,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              AppFontStyles.boldFontVariation,
            ],
          ),
        ),
      ),
    );
  }

  ReminderListItem _buildWaterIntakeTimeline(BuildContext context) {
    return ReminderListItem(
      title: AppStrings.waterintaketimeline,
      trailing: '',
      onTap: () {
        final navigator = Navigator.of(context);

        navigator.push(
          MaterialPageRoute(
            builder: (_) => WaterIntakeTimelineScreen(),
          ),
        );
      },
      iconPathArrow: ("assets/arrow.png"),
      titleStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_20.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      iconColor: AppColors.bluegray,
    );
  }

  ReminderListItem buildReminderListItem(
      DrinkReminderState state, BuildContext context) {
    return ReminderListItem(
      title: AppStrings.reminderMode,
      trailing: state.reminderMode,
      onTap: () => _showReminderMode(context),
      iconPathArrow: ("assets/arrow.png"),
      titleStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_20.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      trailingStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_16.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      iconColor: AppColors.bluegray,
    );
  }

  ReminderToggleRow buildReminderToggleRow(
      DrinkReminderState state, DrinkReminderCubit cubit) {
    return ReminderToggleRow(
      title: AppStrings.reminder,
      value: state.reminderEnabled,
      onChanged: cubit.toggleReminder,
      titleStyle: TextStyle(
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_20.sp,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.fontWeightVariation600],
      ),
      activeTrackColor: AppColors.switchReminderColor,
    );
  }
}
