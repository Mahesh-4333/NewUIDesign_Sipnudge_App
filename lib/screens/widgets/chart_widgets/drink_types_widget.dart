import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

import '../../../constants/app_dimensions.dart';

class DrinkTypesWidget extends StatefulWidget {
  const DrinkTypesWidget({super.key});

  @override
  State<DrinkTypesWidget> createState() => _DrinkTypesWidgetState();
}

class _DrinkTypesWidgetState extends State<DrinkTypesWidget> {
  double _waterIntake = 0.0;
  int _waterGoal = 1;
  int _stepCount = 0;
  int _stepGoal = 1000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWaterIntake();
  }

  Future<void> _fetchWaterIntake() async {
    try {
      final waterGoalParams = await SharedPrefsHelper.getWaterGoal() ?? 2500;
      final history =
          await context.read<BottleDataCubit>().getCurrentDayHistory();

      final steps = await HealthService().getStepCount();
      setState(() {
        _waterIntake = history;
        _waterGoal = waterGoalParams;
        _stepCount = steps;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(AppDimensions.defaultPadding.w),
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
              ],
            ),
            SizedBox(
              height: AppDimensions.dim20.h,
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
                        size: Size(AppDimensions.dim110.w, AppDimensions.dim110.w),
                        painter: _DoubleProgressPainter(
                          outerProgress: _waterGoal > 0 ? (_waterIntake / _waterGoal).clamp(0.0, 1.0) : 0,
                          innerProgress: _stepGoal > 0 ? (_stepCount / _stepGoal).clamp(0.0, 1.0) : 0,
                          outerTrackColor: Color(0xFFE2EFFD),
                          outerGradient: LinearGradient(
                            colors: [Color(0xFF1F76C3) , Color(0xFFC1E2FF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          innerTrackColor: Color(0xFFFEE2E2),
                          innerGradient: LinearGradient(
                            colors: [Color(0xFFDC2626) , Color(0xFFF87171)],
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
                                Image.asset(AssetsPath.goalWaterIcon, width: 30.w, height: 30.w,),
                                SizedBox(
                                  width: AppDimensions.dim8.w,
                                ),
                                Text(
                                  "Water",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: AppFontStyles.fontSize_16,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.fontWeightVariation600
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "${(_waterIntake / 1000).toStringAsFixed(1)}L/${(_waterGoal / 1000).toStringAsFixed(1)}L",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: AppFontStyles.fontSize_16,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.fontWeightVariation600
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
                                Image.asset(AssetsPath.goalStepsIcon, width: 30.w, height: 25.w,),
                                SizedBox(
                                  width: AppDimensions.dim8.w,
                                ),
                                Text(
                                  "Steps",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: AppFontStyles.fontSize_16,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.fontWeightVariation600
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
                                      color: Colors.black,
                                      fontSize: AppFontStyles.fontSize_16,
                                      fontFamily: AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.fontWeightVariation600
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
    final innerRadius = outerRadius - strokeWidth - 6.0;

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

    void drawRing(double radius, double progress, Color trackC, LinearGradient grad, {bool hasBorder = false}) {
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
            ..strokeWidth = strokeWidth + 3.0 // Thicker to create border effect
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
    drawRing(outerRadius, outerProgress, outerTrackColor, outerGradient, hasBorder: true);
  }

  @override
  bool shouldRepaint(covariant _DoubleProgressPainter oldDelegate) {
    return oldDelegate.outerProgress != outerProgress ||
        oldDelegate.innerProgress != innerProgress;
  }
}
