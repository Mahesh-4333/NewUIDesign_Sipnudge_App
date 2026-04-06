import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/helpers/logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/qr_scanning.dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_gradient_slider_widget.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:provider/provider.dart';

import '../services/google_calendar_manager.dart';

class UserInfoDailyGoalScreen extends StatefulWidget {
  const UserInfoDailyGoalScreen({
    super.key,
    required this.waterGoal,
    required this.isViaSettingsScreen,
  });

  final double waterGoal;
  final bool isViaSettingsScreen;

  @override
  State<UserInfoDailyGoalScreen> createState() =>
      _UserInfoDailyGoalScreenState();
}

class _UserInfoDailyGoalScreenState extends State<UserInfoDailyGoalScreen> {
  late double convertedWaterGoal;
  String unit = "mL";
  String displayWaterGoal = "";
  late double initialSliderValue;
  List<double> tickValues = [];
  double widgetMaxGoal = 0;

  bool isButtonClicked = false;

  @override
  void initState() {
    super.initState();
    convertedWaterGoal = widget.waterGoal;
    _setupDynamicSlider();
    updateDisplayWaterGoal();
  }

  void updateDisplayWaterGoal() {
    if (unit == "L") {
      displayWaterGoal = convertedWaterGoal.toStringAsFixed(1);
    } else {
      displayWaterGoal = convertedWaterGoal.toInt().toString();
    }
  }

  void _setupDynamicSlider() {
    double goalInLiters = widget.waterGoal / 1000;

    double minGoal = (goalInLiters * 0.7).clamp(1.0, 2.5);
    double maxGoal = (goalInLiters * 1.3).clamp(2.5, 5.0);

    minGoal = minGoal > goalInLiters ? goalInLiters * 0.8 : minGoal;
    maxGoal = maxGoal < goalInLiters ? goalInLiters * 1.2 : maxGoal;

    tickValues = [
      minGoal,
      minGoal + (goalInLiters - minGoal) * 0.5,
      goalInLiters,
      goalInLiters + (maxGoal - goalInLiters) * 0.5,
      maxGoal,
    ];

    tickValues = tickValues.map((value) {
      return (value * 10).truncateToDouble() / 10;
    }).toList();

    initialSliderValue = goalInLiters;

    widgetMaxGoal = maxGoal * 1000;

    Console.log(tag: "APP", value: "Dynamic slider setup:");
    Console.log(tag: "APP", value: "Goal: ${goalInLiters}L");
    Console.log(tag: "APP", value: "Tick values: $tickValues");
    Console.log(tag: "APP", value: "Initial slider value: $initialSliderValue");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/app_background.png"), // your image path
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.only(
          top: AppDimensions.dim110.h,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppStrings.yourDailyGoalIs,
              style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_24,
                  fontFamily: AppFontStyles.museoModernoFontFamily,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ]),
            ),
            SizedBox(
              height: AppDimensions.dim117.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayWaterGoal,
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_36,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    shadows: [
                      Shadow(
                        blurRadius: AppDimensions.dim5,
                        color: Colors.black.withOpacity(.2),
                        offset: Offset(0, AppDimensions.dim4),
                      )
                    ],
                  ),
                ),
                Text(
                  " $unit",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_32,
                    fontFamily: AppFontStyles.museoModernoFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                    shadows: [
                      Shadow(
                        blurRadius: AppDimensions.dim5,
                        color: Colors.black.withOpacity(.2),
                        offset: Offset(0, AppDimensions.dim4),
                      )
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: AppDimensions.dim32.h,
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    blurRadius: AppDimensions.radius_5,
                    color: Colors.black.withOpacity(.4),
                    offset: Offset(AppDimensions.dim5, AppDimensions.dim5),
                  )
                ],
              ),
              width: AppDimensions.dim379.w,
              height: AppDimensions.dim79.h,
              child: WaterWaveWidget(
                waveCount: 4,
                // fillPercent: ((convertedWaterGoal / 1000) - tickValues.first) /
                //     (tickValues.last - tickValues.first),
                fillPercent: (((convertedWaterGoal / 1000) - tickValues.first) /
                        (tickValues.last - tickValues.first))
                    .clamp(0.0, 1.0),

                orientation: Axis.horizontal,
                amplitude: 8.0,
                speed: Duration(seconds: 5),
              ),
            ),
            SizedBox(
              height: AppDimensions.dim114.h,
            ),
            Container(
              padding: EdgeInsets.only(
                left: AppDimensions.defaultPadding.w,
                right: AppDimensions.defaultPadding.w,
              ),
              child: CustomGradientSlider(
                tickValues: tickValues,
                initialValue: initialSliderValue,
                onChanged: (val) {
                  setState(() {
                    HapticFeedback.selectionClick();
                    convertedWaterGoal = val * 1000;
                    updateDisplayWaterGoal();

                    print(
                        "Fill percent = ${convertedWaterGoal / (widgetMaxGoal)}");
                  });
                },
              ),
            ),
            SizedBox(
              height: AppDimensions.dim50.h,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (unit == "mL") {
                    // mL → Liters
                    convertedWaterGoal = convertedWaterGoal / 1000;
                    unit = "L";
                  } else {
                    // Liters → mL
                    convertedWaterGoal = convertedWaterGoal * 1000;
                    unit = "mL";
                  }

                  updateDisplayWaterGoal();
                  HapticFeedback.selectionClick();
                });
              },
              child: Container(
                width: AppDimensions.dim92.w,
                height: AppDimensions.dim46.h,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radius_50.r),
                  border: Border.all(
                    color: AppColors.greywith80,
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: AppDimensions.radius_5,
                      offset: Offset(AppDimensions.dim3, AppDimensions.dim3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  unit == "mL" ? "Litres" : "mL",
                  style: TextStyle(
                    color: AppColors.greywith80,
                    fontSize: AppFontStyles.fontSize_16,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: AppDimensions.dim85.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AuthButton(
              text: AppStrings.letsHitHydrationGoals,
              color: AppColors.blueGradient,
              areTwoItems: false,
              onTap: () async {
                Console.log(
                    tag: "APP",
                    value: "isViaSettingsScreen ${widget.isViaSettingsScreen}");
                if (widget.isViaSettingsScreen == false) {
                  // var response = await showGoogleCalendarDialog();
                  // if (response == false) {
                  //   return;
                  // }
                  // if (isButtonClicked == true) {
                  //   return;
                  // }
                }

                setState(() {
                  isButtonClicked = true;
                });
                UiUtilsService.showLoading(context, "Please wait");
                await context
                    .read<UserInfoCubit>()
                    .saveUser(context.read<UserInfoCubit>().state);
                await SharedPrefsHelper.setPersonalInfoSubmitted(true);
                await SharedPrefsHelper.setWaterGoal(
                    convertedWaterGoal.toInt());

                final slots = HydrationHelper.generateHydrationSlots(convertedWaterGoal);
                for (var slot in slots) {
                  Console.log(
                      tag: "APP",
                      value:
                          "Slot: ${slot.slot.label}, Water to drink: ${slot.amount} mL");
                }

                final dbHelper = DatabaseHelper();
                var isSlotAvailableInDb = await dbHelper.getAllSlots();
                if (isSlotAvailableInDb.isEmpty) {
                  await dbHelper.clearHydrationSlots();
                  for (var slot in slots) {
                    await dbHelper.insertOrUpdateSlot(slot);
                  }
                }

                await SharedPrefsHelper.setLastLevelUpDate("");
                await context.read<BleCubit>().queueHydrationSlots(slots);

                // Initialize notification service before scheduling, to ensure plugin is ready and permissions are requested on first launch
                await NotificationService().init();

                UiUtilsService.dismissLoading(context);
                setState(() {
                  isButtonClicked = false;
                });

                // Update entire 30-day historical DB to recalculate 'isPerfect' retroactively
                final existingSummaries =
                    await dbHelper.getHydrationSummariesForRange();
                final List<HydrationDaySummary> updatedSummaries = [];

                for (final summary in existingSummaries) {
                  final bool isPerfectNow =
                      summary.consumed >= convertedWaterGoal;
                  updatedSummaries.add(HydrationDaySummary(
                    date: summary.date,
                    dayIndex: summary.dayIndex,
                    target: convertedWaterGoal,
                    consumed: summary.consumed,
                    isPerfect: isPerfectNow,
                  ));
                }

                await dbHelper.clearHydrationDaySummaries();

                await dbHelper.bulkUpsert30Days(updatedSummaries);

                await context.read<HydrationCubit>().refreshAchievementStats(
                    updateUnlock:
                        context.read<UserInfoCubit>().state.hideAchievement);
                SharedPrefsHelper.updateAndSaveDeviceConfig(
                    waterGoal: convertedWaterGoal.toInt());
                context.read<BottomNavCubit>().showBar();
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => BottomNavScreenNew(),
                    ),
                    (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<bool?> showGoogleCalendarDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Action Required",
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Google Calendar sign-in might be required for smart snooze and calendar sync",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.blueGradient,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
              ),
              const SizedBox(height: 24),
              AuthButton(
                text: "I give my consent",
                color: AppColors.blueGradient,
                areTwoItems: false,
                onTap: () => Navigator.of(context).pop(true),
              )
            ],
          ),
        );
      },
    );
  }
}
