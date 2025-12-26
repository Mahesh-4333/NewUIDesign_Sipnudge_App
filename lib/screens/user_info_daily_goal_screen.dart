import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_gradient_slider_widget.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:provider/provider.dart';

import '../services/google_calendar_manager.dart';

class UserInfoDailyGoalScreen extends StatefulWidget {
  const UserInfoDailyGoalScreen({
    super.key,
    required this.waterGoal,
  });

  final double waterGoal;
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
      // convertedWaterGoal is currently in Liters
      displayWaterGoal = convertedWaterGoal.toStringAsFixed(1);
    } else {
      // convertedWaterGoal is currently in mL
      displayWaterGoal = convertedWaterGoal.toInt().toString();
    }
  }

  // void updateDisplayWaterGoal() {
  //   if (unit.toLowerCase() == 'l' ||
  //       unit.toLowerCase() == 'litres' ||
  //       unit.toLowerCase() == 'liters') {
  //     displayWaterGoal = (convertedWaterGoal / 1000).toStringAsFixed(1);
  //   } else {
  //     displayWaterGoal = convertedWaterGoal.toInt().toString();
  //   }
  // }

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

    log("Dynamic slider setup:");
    log("Goal: ${goalInLiters}L");
    log("Tick values: $tickValues");
    log("Initial slider value: $initialSliderValue");
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
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
          // ),
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
        height: AppDimensions.dim60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AuthButton(
                text: AppStrings.letsHitHydrationGoals,
                color: AppColors.blueGradient,
                areTwoItems: false,
                onTap: () async {
                  var response = await showGoogleCalendarDialog();
                  if (response == false) {
                    return;
                  }
                  if (isButtonClicked == true) {
                    return;
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

                  final slots = generateHydrationSlots(convertedWaterGoal);
                  for (var slot in slots) {
                    log("Slot: ${slot.slot.label}, Water to drink: ${slot.amount} mL");
                  }

                  final dbHelper = DatabaseHelper();
                  await dbHelper.clearHydrationSlots();
                  for (var slot in slots) {
                    await dbHelper.insertOrUpdateSlot(
                      slot,
                    );
                  }
                  await context.read<BleCubit>().queueHydrationSlots(slots);
                  await NotificationService().resetAllHydrationReminders(slots);
                  UiUtilsService.dismissLoading(
                    context,
                  );
                  setState(() {
                    isButtonClicked = false;
                  });
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavScreenNew(),
                      ),
                      (route) => false);
                }),
          ],
        ),
      ),
    );
  }

  List<HydrationEntry> generateHydrationSlots(double dailyGoal) {
    final slotPercentages = {
      HydrationSlot.wakeup: 0.25,
      HydrationSlot.breakfast: 0.125,
      HydrationSlot.midMorning: 0.125,
      HydrationSlot.lunch: 0.125,
      HydrationSlot.midAfternoon: 0.125,
      HydrationSlot.evening: 0.125,
      HydrationSlot.afterDinner: 0.125,
    };

    final slotTimes = {
      HydrationSlot.wakeup: TimeOfDayRange(
          start: TimeOfDay(hour: 7, minute: 0),
          end: TimeOfDay(hour: 8, minute: 0)),
      HydrationSlot.breakfast: TimeOfDayRange(
          start: TimeOfDay(hour: 8, minute: 30),
          end: TimeOfDay(hour: 9, minute: 30)),
      HydrationSlot.midMorning: TimeOfDayRange(
          start: TimeOfDay(hour: 11, minute: 0),
          end: TimeOfDay(hour: 11, minute: 30)),
      HydrationSlot.lunch: TimeOfDayRange(
          start: TimeOfDay(hour: 13, minute: 0),
          end: TimeOfDay(hour: 14, minute: 0)),
      HydrationSlot.midAfternoon: TimeOfDayRange(
          start: TimeOfDay(hour: 16, minute: 0),
          end: TimeOfDay(hour: 16, minute: 30)),
      HydrationSlot.evening: TimeOfDayRange(
          start: TimeOfDay(hour: 18, minute: 0),
          end: TimeOfDay(hour: 19, minute: 0)),
      HydrationSlot.afterDinner: TimeOfDayRange(
          start: TimeOfDay(hour: 20, minute: 30),
          end: TimeOfDay(hour: 21, minute: 30)),
    };

    List<HydrationEntry> slots = [];

    slotPercentages.forEach((slot, percent) {
      final amount = (dailyGoal * percent).round();
      final times = slotTimes[slot]!;
      slots.add(HydrationEntry(
        slot: slot,
        startTime: times.start,
        endTime: times.end,
        amount: amount.round().toDouble(),
        waterDrank: 0, // initially 0
        status: HydrationStatus.pending,
      ));
    });

    return slots;
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
                onTap: () => Navigator.pop(context, true),
              )
            ],
          ),
        );
      },
    );
  }
}
