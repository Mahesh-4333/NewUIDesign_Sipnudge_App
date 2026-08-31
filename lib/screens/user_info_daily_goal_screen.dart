import 'dart:ui';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/l10n/app_localizations.dart';

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
import 'package:hydrify/screens/onboarding/environmental_harmony_location_screen.dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/home_widget_service.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:math' as math;

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
      _UserInfoDailyGoalScreenNewState();
}

class _UserInfoDailyGoalScreenNewState extends State<UserInfoDailyGoalScreen> {
  late double convertedWaterGoal;
  String unit = "mL";
  bool isButtonClicked = false;

  @override
  void initState() {
    super.initState();
    convertedWaterGoal = widget.waterGoal;
    _loadSavedUnit();
  }

  void _loadSavedUnit() async {
    final savedUnit = await SharedPrefsHelper.getSelectedUnit();
    setState(() {
      unit = savedUnit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        width: double.maxFinite,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
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
              AppLocalizations.of(context)?.yourDailyGoal ?? "Your Daily goal",
              style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: 24.sp,
                  fontFamily: AppFontStyles.museoModernoFontFamily,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ]),
            ),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)?.rotateBezelToAdjustVolume ?? "Rotate bezel to adjust volume",
              style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ]),
            ),
            SizedBox(height: 20.h),
            _buildUnitSelectionRow(),
            SizedBox(height: 25.h),

            // The Gauge Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (convertedWaterGoal > 500) {
                        convertedWaterGoal -= 50;
                        HapticFeedback.selectionClick();
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Image.asset(
                        AssetsPath.leftArrow,
                        width: 24.sp,
                        height: 22.sp,
                      ),
                      SizedBox(height: 8.h),
                      Image.asset(
                        AssetsPath.dicreaseAi,
                        width: 44.sp,
                        height: 44.sp,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 15.w),

                // Gauge with Glassmorphism Overlay
                Expanded(
                  child: SizedBox(
                    width: 290.w,
                    height: 290.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The Visual Gauge
                        Container(
                          width: 290.w,
                          height: 290.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Color(0xff00A3FF).withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 10,
                                  blurStyle: BlurStyle.normal),
                            ],
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.26),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: IgnorePointer(
                                    child: SizedBox(
                                      width: 270.w,
                                      height: 270.w,
                                      child: SfRadialGauge(
                                        enableLoadingAnimation: true,
                                        axes: <RadialAxis>[
                                          RadialAxis(
                                            minimum: 500,
                                            maximum: 10000,
                                            startAngle: 270,
                                            endAngle: 270,
                                            showLabels: false,
                                            showTicks: true,
                                            interval: 500,
                                            minorTicksPerInterval: 4,
                                            tickOffset: 0.10,
                                            ticksPosition:
                                                ElementsPosition.outside,
                                            offsetUnit: GaugeSizeUnit.factor,
                                            majorTickStyle: MajorTickStyle(
                                                length: 7,
                                                thickness: 3,
                                                color: const Color(0xff6F7883)),
                                            minorTickStyle: MinorTickStyle(
                                                length: 3,
                                                thickness: 1,
                                                color: AppColors.greyColor
                                                    .withValues(alpha: 0.5)),
                                            axisLineStyle: AxisLineStyle(
                                              thickness: 0.12,
                                              thicknessUnit:
                                                  GaugeSizeUnit.factor,
                                              color: Colors.grey
                                                  .withValues(alpha: 0.2),
                                            ),
                                            pointers: <GaugePointer>[
                                              RangePointer(
                                                value: convertedWaterGoal,
                                                width: 0.12,
                                                sizeUnit: GaugeSizeUnit.factor,
                                                color: const Color(0xff1d8dbb),
                                                cornerStyle:
                                                    CornerStyle.bothCurve,
                                                enableAnimation: true,
                                                animationDuration: 1200,
                                                animationType:
                                                    AnimationType.easeOutBack,
                                              ),
                                              MarkerPointer(
                                                value: convertedWaterGoal,
                                                enableDragging: false,
                                                enableAnimation: false,
                                                markerHeight: 38.w,
                                                markerWidth: 38.w,
                                                markerType: MarkerType.circle,
                                                color: Colors.white
                                                    .withValues(alpha: 0.8),
                                                borderWidth: 1,
                                                borderColor:
                                                    const Color(0xff1C8DBB),
                                                elevation: 5,
                                              ),
                                            ],
                                            annotations: <GaugeAnnotation>[
                                              GaugeAnnotation(
                                                widget: Container(
                                                  width: 170.w,
                                                  height: 170.w,
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                    border: Border.all(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.6),
                                                        width: 1),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        AppLocalizations.of(context)?.newGoal ?? "NEW GOAL",
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .color_414755,
                                                          fontSize: 12.sp,
                                                          letterSpacing: 1.2,
                                                          fontFamily: AppFontStyles
                                                              .urbanistFontFamily,
                                                          fontVariations: [
                                                            AppFontStyles
                                                                .boldFontVariation
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: 5.h),
                                                      Text(
                                                        HydrationHelper.formatVolume(convertedWaterGoal, unit),
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .raisinblack,
                                                          fontSize: 30.sp,
                                                          fontFamily: AppFontStyles
                                                              .urbanistFontFamily,
                                                          fontVariations: [
                                                            AppFontStyles
                                                                .boldFontVariation
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        AppLocalizations.of(context)?.unitPerDay(unit) ?? "$unit / day",
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .color_414755,
                                                          fontSize: 14.sp,
                                                          fontFamily: AppFontStyles
                                                              .urbanistFontFamily,
                                                          fontVariations: [
                                                            AppFontStyles
                                                                .boldFontVariation
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                positionFactor: 0.0,
                                                angle: 90,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // The Interaction Overlay
                        Positioned.fill(
                          child: LayoutBuilder(builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) => _updateGoalFromOffset(
                                  details.localPosition, constraints.biggest),
                              onPanUpdate: (details) => _updateGoalFromOffset(
                                  details.localPosition, constraints.biggest),
                              onPanEnd: (_) => HapticFeedback.selectionClick(),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 15.w),

                // Plus button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (convertedWaterGoal < 10000) {
                        convertedWaterGoal += 50;
                        HapticFeedback.selectionClick();
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Image.asset(
                        AssetsPath.rightArrow,
                        color: AppColors.lightSkyBlue,
                        width: 24.sp,
                        height: 22.sp,
                      ),
                      SizedBox(height: 8.h),
                      Image.asset(
                        AssetsPath.increaseAi,
                        width: 40.sp,
                        height: 40.sp,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 50.h),

            Text(
              AppLocalizations.of(context)?.targetCalibration ?? "Target Calibration",
              style: TextStyle(
                color: AppColors.raisinblack,
                fontSize: 22.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)?.adjustDailyIntakeGoal ?? "Adjust your daily intake goal based on precision metrics.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.color_414755,
                  fontSize: 14.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation]),
            ),

            SizedBox(height: 25.h),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.lightSkyBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(90.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                color: AppColors.lightSkyBlue, size: 16.sp),
                            SizedBox(width: 5.w),
                            Text(
                              AppLocalizations.of(context)?.avgIntake ?? "Avg Intake",
                              style: TextStyle(
                                  color: AppColors.lightSkyBlue,
                                  fontSize: 12.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation
                                  ]),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          HydrationHelper.formatVolume(widget.waterGoal, unit, showUnit: true),
                          style: TextStyle(
                            color: AppColors.raisinblack,
                            fontSize: 18.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.lightSkyBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(90.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                (convertedWaterGoal - widget.waterGoal) >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color:
                                    (convertedWaterGoal - widget.waterGoal) >= 0
                                        ? Colors.green
                                        : Colors.red,
                                size: 16.sp),
                            SizedBox(width: 5.w),
                            Text(
                              (convertedWaterGoal - widget.waterGoal) >= 0
                                  ? (AppLocalizations.of(context)?.increase ?? "Increase")
                                  : (AppLocalizations.of(context)?.decrease ?? "Decrease"),
                              style: TextStyle(
                                  color: AppColors.lightSkyBlue,
                                  fontSize: 12.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation
                                  ]),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "${(convertedWaterGoal - widget.waterGoal) >= 0 ? "+" : "-"}${HydrationHelper.formatVolume((convertedWaterGoal - widget.waterGoal).abs(), unit, showUnit: true)}",
                          style: TextStyle(
                            color: AppColors.raisinblack,
                            fontSize: 18.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 25.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 0.w),
              decoration: BoxDecoration(
                color: const Color(0xffE1F5FE).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(
                  color: const Color(0xffB3E5FC),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
              child: Row(
                children: [
                  Image.asset(
                    AssetsPath.healthTip,
                    height: 60.h,
                    width: 60.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.hydrationTipMetabolism ?? "Drinking water before meals can boost \nyour metabolism by up to 30%.",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color:
                                const Color(0xff003D51).withValues(alpha: 0.7),
                            fontSize: 13.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 40.w), // Offset icon
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: AppDimensions.dim85.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AuthButton(
              text: AppLocalizations.of(context)?.letsHitHydrationGoals ??
                  AppStrings.letsHitHydrationGoals,
              color: AppColors.blueGradient,
              areTwoItems: false,
              onTap: () async {
                Console.log(
                    tag: "APP",
                    value: "isViaSettingsScreen ${widget.isViaSettingsScreen}");

                setState(() {
                  isButtonClicked = true;
                });

                final userInfoCubit = context.read<UserInfoCubit>();
                final bleCubit = context.read<BleCubit>();
                final hydrationCubit = context.read<HydrationCubit>();
                final bottomNavCubit = context.read<BottomNavCubit>();
                final navigator = Navigator.of(context, rootNavigator: true);

                UiUtilsService.showLoading(context, AppLocalizations.of(context)?.pleaseWait ?? "Please wait");
                final goalInt = convertedWaterGoal.toInt();
                await userInfoCubit.saveUser(userInfoCubit.state);
                await SharedPrefsHelper.setPersonalInfoSubmitted(true);
                await SharedPrefsHelper.setWaterGoal(goalInt);
                await SharedPrefsHelper.setUserGoal(goalInt);
                await DatabaseHelper().saveDailyWaterGoal(
                    DateTime.now(), goalInt);
                context
                    .read<HydrationCubit>()
                    .setGoal(goalInt);

                final slots =
                    HydrationHelper.generateHydrationSlots(convertedWaterGoal);
                for (var slot in slots) {
                  Console.log(
                      tag: "APP",
                      value:
                          "Slot: ${slot.slot.label}, Water to drink: ${slot.amount} mL");
                }

                final dbHelper = DatabaseHelper();
                final existingSlotsInDb = await dbHelper.getAllSlots();

                // Build a map of existing slots to preserve waterDrank values
                final existingSlotMap = {
                  for (var s in existingSlotsInDb) s.slot: s
                };

                // Always clear and re-insert all 7 slots to avoid partial saves
                await dbHelper.clearHydrationSlots();
                final List<HydrationEntry> updatedSlots = [];
                for (var newSlot in slots) {
                  final existing = existingSlotMap[newSlot.slot];
                  // Preserve waterDrank, startTime & endTime if this slot already existed
                  final slotToSave = existing != null
                      ? existing.copyWith(
                          amount: newSlot.amount,
                          startTime: existing.startTime,
                          endTime: existing.endTime,
                        )
                      : newSlot;
                  await dbHelper.insertOrUpdateSlot(slotToSave);
                  updatedSlots.add(slotToSave);
                }
                await bleCubit.queueHydrationSlots(updatedSlots);

                await SharedPrefsHelper.setLastLevelUpDate("");

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

                // Directly update server dailygoals collection and today's summary target
                final userId = await SharedPrefsHelper.getUserId();
                final today = DateTime.now();
                final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                final dateUtc = "${todayStr}T00:00:00.000Z";

                if (userId != null && userId.isNotEmpty && userId != "guest_user") {
                  try {
                    // 1. Direct push to server DailyGoal collection
                    await ApiService().syncDailyGoals(userId, [
                      {
                        'date': todayStr,
                        'goal': goalInt,
                      }
                    ]);

                    // 2. Direct update to server DailySummary target
                    final todaySummary = await dbHelper.getSummaryForDate(today);
                    final consumed = todaySummary?.consumed ?? 0.0;
                    final isPerfect = consumed >= goalInt;
                    await ApiService().updateTodayConsumed(
                      userId,
                      dateUtc,
                      consumed,
                      isPerfect,
                      target: convertedWaterGoal,
                      force: true,
                    );
                  } catch (e) {
                    Console.log(tag: "DAILY_GOAL_SUBMIT", value: "Error updating server goal: $e");
                  }
                }

                // Immediately update local & native widget so widget target matches the app instantly
                await HomeWidgetService.updateWidgetData();

                if (!context.mounted) return;
                UiUtilsService.dismissLoading(context);
                setState(() {
                  isButtonClicked = false;
                });

                await hydrationCubit.refreshAchievementStats(
                    updateUnlock: userInfoCubit.state.hideAchievement);

                final bool hasShownShowcase =
                    await SharedPrefsHelper.hasShownHomeShowcase();
                if (hasShownShowcase || widget.isViaSettingsScreen) {
                  await SharedPrefsHelper.updateAndSaveDeviceConfig(
                      waterGoal: goalInt);
                }
                bottomNavCubit.showBar();

                DatabaseSyncService().syncAll(force: true);
                if (widget.isViaSettingsScreen) {
                  navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const BottomNavScreenNew(),
                      ),
                      (route) => false);
                } else {
                  navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const EnvironmentalHarmonyLocationScreen(),
                      ),
                      (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateGoalFromOffset(Offset position, Size size) {
    Console.log(tag: "_updateGoalFromOffset_position", value: position);
    Console.log(tag: "_updateGoalFromOffset_size", value: size);
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Angle clockwise from right (Syncfusion convention), in degrees
    double angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    // startAngle is 270 (top). Convert gauge angle fraction:
    // fraction = (angle - startAngle + 360) % 360 / 360
    final double fraction = ((angle - 270 + 360) % 360) / 360;

    // Map fraction to water value
    double rawValue = 500 + fraction * 9500;
    double snapped = (rawValue / 50).round() * 50.0;
    snapped = snapped.clamp(500.0, 10000.0);

    if (snapped != convertedWaterGoal) {
      setState(() {
        convertedWaterGoal = snapped;
      });
    }
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
                AppLocalizations.of(context)?.actionRequired ?? "Action Required",
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
                AppLocalizations.of(context)?.googleCalendarSignInRequired ?? "Google Calendar sign-in might be required for smart snooze and calendar sync",
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
                text: AppLocalizations.of(context)?.iGiveMyConsent ?? "I give my consent",
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

  Widget _buildUnitSelectionRow() {
    final List<String> units = ["mL", "L", "US Oz", "UK Oz"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: units.map((u) {
        final isSelected = unit == u;
        return GestureDetector(
          onTap: () {
            setState(() {
              unit = u;
            });
            SharedPrefsHelper.setSelectedUnit(u);
            HapticFeedback.selectionClick();
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff1C8DBB) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                width: 1.w,
              ),
            ),
            child: Text(
              u,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.bluegray,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: 14.sp,
                fontVariations: [
                  isSelected
                      ? AppFontStyles.boldFontVariation
                      : AppFontStyles.semiBoldFontVariation
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
