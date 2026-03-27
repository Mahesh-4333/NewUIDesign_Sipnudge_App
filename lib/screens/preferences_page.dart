import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/Preferences/preferences_cubit.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/ringtone_screen.dart';
import 'package:hydrify/screens/user_info_daily_goal_screen.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/color_gradient_slider.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/custom_slider_tile.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/custom_toggle_tile.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/menu_item_tile.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/preference_card.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/section_header.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/erase_data_dialog.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:intl/intl.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PreferencesCubit(),
      child: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, state) {
          final cubit = context.read<PreferencesCubit>();

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0.0,
              scrolledUnderElevation: 0.0,
              forceMaterialTransparency: true,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                AppStrings.preferences,
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
            ),
            body: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/app_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      const SectionHeader(title: AppStrings.general),
                      FutureBuilder<int?>(
                        future: SharedPrefsHelper.getWaterGoal(),
                        builder: (context, snapshot) {
                          int goal = snapshot.data ?? 2500;
                          String formattedGoal = "${goal.toString()} mL";

                          return MenuItemTile(
                            title: AppStrings.waterIntakeGoal,
                            info: formattedGoal,
                            iconpatharrow: "assets/arrow.png",
                            onTap: () {
                              context.read<BottomNavCubit>().hideBar();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserInfoDailyGoalScreen(
                                    waterGoal: goal.toDouble(),
                                    isViaSettingsScreen: true,
                                  ),
                                ),
                              ).then((_) {
                                context.read<BottomNavCubit>().showBar();
                              });
                            },
                          );
                        },
                      ),
                      const SectionHeader(title: AppStrings.alerts),
                      PreferenceCard(
                        children: [
                          CustomToggleTile(
                            title: AppStrings.ringtoneFeedback,
                            description: AppStrings.playAudioWhenTargetIsMet,
                            value: state.ringtoneFeedback,
                            onChanged: (value) {
                              cubit.toggleRingtoneFeedback(value);
                            },
                          ),
                          Divider(
                              height: 1,
                              indent: 20.w,
                              endIndent: 20.w,
                              color: AppColors.stonegray.withOpacity(0.1)),
                          MenuItemTile(
                            title: AppStrings.ringtone,
                            info: "",
                            hideDecoration: true,
                            iconpatharrow: "assets/arrow.png",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RingtoneScreen()),
                              ).then((value) async {
                                var allSlots =
                                    await DatabaseHelper().getAllSlots();
                                NotificationService()
                                    .resetAllHydrationReminders(allSlots);
                              });
                            },
                          ),
                        ],
                      ),
                      const SectionHeader(title: AppStrings.hapticsAndVisuals),
                      PreferenceCard(
                        children: [
                          CustomSliderTile(
                            title: AppStrings.vibrationStrength,
                            value: state.vibrationStrength,
                            suffix: "%",
                            sliderPadding: EdgeInsets.only(right: 30.w),
                            onChanged: (v) => cubit.updateVibrationStrength(v),
                          ),
                          Divider(
                              height: 1,
                              indent: 20.w,
                              endIndent: 20.w,
                              color: AppColors.stonegray.withOpacity(0.1)),
                          CustomToggleTile(
                            title: AppStrings.ledIndicator,
                            description:
                                AppStrings.pulseBaseLightDuringHydration,
                            value: state.ledFeedback,
                            onChanged: (v) => cubit.toggleLedFeedback(v),
                          ),
                          ColorGradientSlider(
                            title: AppStrings.selectColorOfLed,
                            value: state.ledHue,
                            onChanged: (v) => cubit.updateLedHue(v),
                          ),
                          CustomSliderTile(
                            title: AppStrings.intensityOfLed,
                            value: state.ledIntensity,
                            suffix: "%",
                            hideRightText: true,
                            gradientColors: [
                              HSVColor.fromAHSV(
                                      1.0, state.ledHue * 360, 0.1, 0.95)
                                  .toColor(),
                              HSVColor.fromAHSV(
                                      1.0, state.ledHue * 360, 0.6, 0.9)
                                  .toColor(),
                              HSVColor.fromAHSV(
                                      1.0, state.ledHue * 360, 1.0, 1.0)
                                  .toColor(),
                            ],
                            sliderPadding: EdgeInsets.only(right: 30.w),
                            thumbColor: HSVColor.fromAHSV(
                                    1.0, state.ledHue * 360, 1.0, 1.0)
                                .toColor(),
                            onChanged: (v) => cubit.updateLedIntensity(v),
                          ),
                          Divider(
                              height: 1,
                              indent: 20.w,
                              endIndent: 20.w,
                              color: AppColors.stonegray.withOpacity(0.1)),
                          CustomToggleTile(
                            title: AppStrings.uvCleaning,
                            value: state.uvCleaning,
                            onChanged: (v) => cubit.toggleUvCleaning(v),
                          ),
                        ],
                      ),
                      SizedBox(height: 32.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 25.w),
                            height: 54.h,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(27.r),
                              border: Border.all(
                                color: const Color(0xffE53935),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xffE53935).withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (innerContext) {
                                    return EraseDataDialog(
                                      onErase: () async {
                                        try {
                                          final bottleDataCubit =
                                              context.read<BottleDataCubit>();
                                          await bottleDataCubit
                                              .clearAllBottleData();

                                          final hydrationCubit =
                                              context.read<HydrationCubit>();
                                          await hydrationCubit.resetUI();
                                          await hydrationCubit
                                              .refreshAchievementStats();

                                          final bleCubit =
                                              context.read<BleCubit>();
                                          await bleCubit.clearData();

                                          Fluttertoast.showToast(
                                              msg: "Local data cleared.");
                                        } catch (e) {
                                          Fluttertoast.showToast(
                                              msg:
                                                  "Error clearing local data: $e");
                                          return;
                                        }

                                        final bleCubit =
                                            context.read<BleCubit>();
                                        await bleCubit.forgetDevice();

                                        Fluttertoast.showToast(
                                            msg:
                                                "Tracking restarted. Connect your device again.");
                                      },
                                    );
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27.r),
                                ),
                              ),
                              child: Text(
                                "RESET ALL TRACKINGS",
                                style: TextStyle(
                                    color: const Color(0xffE53935),
                                    fontSize: 16.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontWeight: FontWeight.w500,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Center(
                        child: FutureBuilder<DateTime?>(
                          future: DatabaseHelper().getLastSyncDate(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return const SizedBox();
                            }
                            final time = snapshot.data!;
                            final diff = DateTime.now().difference(time);
                            String timeAgo = "";
                            if (diff.inMinutes < 1) {
                              timeAgo = "Just now";
                            } else if (diff.inMinutes < 60) {
                              timeAgo = "${diff.inMinutes} minutes ago";
                            } else {
                              timeAgo = DateFormat('h:mm a').format(time);
                            }

                            return Text(
                              "${AppStrings.lastSynced} $timeAgo",
                              style: TextStyle(
                                color: AppColors.bluegray.withOpacity(0.5),
                                fontSize: 13.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
