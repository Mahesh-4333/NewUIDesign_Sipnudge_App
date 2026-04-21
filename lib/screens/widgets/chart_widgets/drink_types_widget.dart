import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/widgets/common/animated_refresh_icon.dart';

import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import '../../../constants/app_dimensions.dart';

class DrinkTypesWidget extends StatefulWidget {
  const DrinkTypesWidget({super.key});

  @override
  State<DrinkTypesWidget> createState() => _DrinkTypesWidgetState();
}

class _DrinkTypesWidgetState extends State<DrinkTypesWidget>
    with AutomaticKeepAliveClientMixin {
  double _waterIntake = 0.0;
  int _waterGoal = 1;
  int _stepCount = 0;
  int _stepGoal = 1000;
  bool _isLoading = true;
  bool _isFetching = false;
  StreamSubscription? _permissionSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchWaterIntake(forcePermission: true);
    _permissionSubscription = HealthService.onPermissionUpdate.listen((_) {
      _fetchWaterIntake();
    });
  }

  @override
  void dispose() {
    _permissionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchWaterIntake({bool forcePermission = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final waterGoalParams = await SharedPrefsHelper.getWaterGoal() ?? 2500;
      final history =
          await context.read<BottleDataCubit>().getCurrentDayHistory();

      int steps = 0;
      double healthWaterMl = 0.0;
      bool hasPermission =
          await SharedPrefsHelper.getHasRequestedHealthPermission();
      Console.log(
          tag: "HealthService", value: "Has permission: $hasPermission");

      // On Android, we use pedometer for steps, which has its own permission handling.
      // We still want to call getStepCount() to trigger the pedometer logic.
      if (hasPermission || forcePermission) {
        steps = await HealthService()
            .getStepCount(forcePermission: forcePermission);
        Console.log(tag: "steps_124", value: steps.toString());

        // Water intake still comes from Health Connect on Android
        if (Platform.isAndroid && (hasPermission || forcePermission)) {
          final waterLiters = await HealthService()
              .getWaterIntakeLiters(forcePermission: forcePermission);
          healthWaterMl = waterLiters;
        }
      }

      final userInfo = context.read<UserInfoCubit>().state;
      if (mounted) {
        setState(() {
          _waterIntake =
              Platform.isAndroid ? max(history, healthWaterMl) : history;
          _waterGoal = waterGoalParams;
          _stepCount = steps;
          _stepGoal = userInfo.stepGoal ?? 1000;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Refresh water/steps when HydrationCubit receives updates from BLE
    return BlocListener<HydrationCubit, HydrationState>(
      listenWhen: (previous, current) =>
          previous.totalDrank != current.totalDrank ||
          previous.entries != current.entries,
      listener: (context, state) {
        _fetchWaterIntake();
      },
      child: Container(
        width: double.maxFinite,
        padding:
            EdgeInsets.only(left: 10.w, right: 10.w, top: 10.h, bottom: 35.h),
        margin: EdgeInsets.only(
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
        ),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: AppDimensions.radius_4,
                color: AppColors.black.withOpacity(.25),
                offset: Offset(
                  AppDimensions.dim2,
                  AppDimensions.dim2,
                ),
              )
            ],
            borderRadius: BorderRadius.circular(
              AppDimensions.radius_10.w,
            ),
            color: Color(0XFFFFFFFF),
            border: Border.all(color: AppColors.greywith80)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Goal Tracking",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                AnimatedRefreshIcon(
                  onRefresh: () async {
                    VibrationHelper.lightTap();
                    await _fetchWaterIntake(forcePermission: true);
                  },
                ),
              ],
            ),
            SizedBox(
              height: 5.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: AppDimensions.dim120.w,
                  height: AppDimensions.dim120.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner background (grey) for water
                      CustomPaint(
                        size: Size(
                            AppDimensions.dim110.w, AppDimensions.dim110.w),
                        painter: _DoubleProgressPainter(
                          outerProgress: _waterGoal > 0
                              ? (_waterIntake / _waterGoal).clamp(0.0, 1.0)
                              : 0,
                          innerProgress: _stepGoal > 0
                              ? (_stepCount / _stepGoal).clamp(0.0, 1.0)
                              : 0,
                          outerTrackColor: Color(0xFFECECEC),
                          outerGradient: LinearGradient(
                            colors: [Color(0xFF369FFF), Color(0xFFC8E2FB)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          innerTrackColor: Color(0xFFECECEC),
                          innerGradient: LinearGradient(
                            colors: [Color(0xFF00BA88), Color(0xFFFFFFFF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          strokeWidth: 12.w,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Water Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  AssetsPath.goalWaterIcon,
                                  width: 30.w,
                                  height: 30.w,
                                ),
                                SizedBox(
                                  width: AppDimensions.dim8.w,
                                ),
                                Text(
                                  "Goal",
                                  style: TextStyle(
                                    color: AppColors.switchReminderColor,
                                    fontSize: 18.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "${(_waterIntake).toStringAsFixed(0)}/${(_waterGoal).toStringAsFixed(0)} ml",
                              style: TextStyle(
                                color: AppColors.switchReminderColor,
                                fontSize: AppFontStyles.fontSize_16,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.semiBoldFontVariation
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: AppDimensions.dim15.h,
                        ),
                        // Steps Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  AssetsPath.goalStepsIcon,
                                  width: 30.w,
                                  height: 25.w,
                                ),
                                SizedBox(
                                  width: AppDimensions.dim8.w,
                                ),
                                Text(
                                  "Steps",
                                  style: TextStyle(
                                    color: AppColors.switchReminderColor,
                                    fontSize: 18.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            _isLoading
                                ? SizedBox(
                                    width: AppDimensions.dim16.w,
                                    height: AppDimensions.dim16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFEF4444)),
                                    ),
                                  )
                                : Text(
                                    "$_stepCount/$_stepGoal",
                                    style: TextStyle(
                                      color: AppColors.switchReminderColor,
                                      fontSize: AppFontStyles.fontSize_16,
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation
                                      ],
                                    ),
                                  ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DoubleProgressPainter extends CustomPainter {
  final double outerProgress;
  final double innerProgress;
  final Color outerTrackColor;
  final LinearGradient outerGradient;
  final Color innerTrackColor;
  final LinearGradient innerGradient;
  final double strokeWidth;

  _DoubleProgressPainter({
    required this.outerProgress,
    required this.innerProgress,
    required this.outerTrackColor,
    required this.outerGradient,
    required this.innerTrackColor,
    required this.innerGradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - strokeWidth / 2;
    // Spacing between inner and outer ring
    final innerRadius = outerRadius - strokeWidth - 8.0;

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void drawRing(
        double radius, double progress, Color trackC, LinearGradient grad,
        {bool hasBorder = false}) {
      final rect = Rect.fromCircle(center: center, radius: radius);

      // 1. Draw track
      trackPaint.color = trackC;
      canvas.drawCircle(center, radius, trackPaint);

      if (progress > 0) {
        final sweepAngle = 2 * pi * progress;
        // 2. Draw shadow
        final shadowRect = Rect.fromCircle(
          center: center.translate(0, 3), // offset shadow slightly down
          radius: radius,
        );
        canvas.drawArc(shadowRect, -pi / 2, sweepAngle, false, shadowPaint);

        // 3. Draw white border if required
        //if (hasBorder) {
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2.0 // Thicker to create border effect
          ..strokeCap = StrokeCap.round
          ..color = Colors.white;
        canvas.drawArc(rect, -pi / 2, sweepAngle, false, borderPaint);
        //}

        // 4. Draw gradient progress
        progressPaint.shader = grad.createShader(rect);
        canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
      }
    }

    // Draw Inner Ring (Steps)
    drawRing(innerRadius, innerProgress, innerTrackColor, innerGradient);

    // Draw Outer Ring (Water), enabling the border
    drawRing(outerRadius, outerProgress, outerTrackColor, outerGradient,
        hasBorder: true);
  }

  @override
  bool shouldRepaint(covariant _DoubleProgressPainter oldDelegate) {
    return oldDelegate.outerProgress != outerProgress ||
        oldDelegate.innerProgress != innerProgress;
  }
}
