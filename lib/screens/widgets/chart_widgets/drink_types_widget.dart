import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/services/api_service.dart';
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

  String _selectedUnit = 'mL';
  StreamSubscription? _configSubscription;
  @override
  void initState() {
    super.initState();
    // Do NOT pass forcePermission: true here — this initState fires even when
    // the Analysis tab is offstage (Offstage widget still builds all children).
    // forcePermission should only be used on an explicit user refresh action.
    _fetchWaterIntake();
    SharedPrefsHelper.getSelectedUnit().then((unit) {
      if (mounted) {
        setState(() {
          _selectedUnit = unit;
        });
      }
    });
    _configSubscription =
        SharedPrefsHelper.configUpdateStream.stream.listen((_) {
      SharedPrefsHelper.getSelectedUnit().then((unit) {
        if (mounted) {
          setState(() {
            _selectedUnit = unit;
          });
        }
      });
    });
    _permissionSubscription = HealthService.onPermissionUpdate.listen((_) {
      _fetchWaterIntake();
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _permissionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchWaterIntake({bool forcePermission = false}) async {
    Console.log(tag: "steps_124", value: _isFetching);
    if (_isFetching) return;
    _isFetching = true;

    try {
      final waterGoalParams = await SharedPrefsHelper.getWaterGoal() ?? 2500;
      double history =
          await context.read<BottleDataCubit>().getCurrentDayHistory();

      if (history == 0) {
        final userId = await SharedPrefsHelper.getUserId();
        final userEmail = await SharedPrefsHelper.getUserEmail();
        if (userId != null && userEmail != "guest_user") {
          final now = DateTime.now();
          final start = DateTime.utc(now.year, now.month, now.day);
          final end = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
          final summaries =
              await ApiService().getDailySummaries(userId, start, end);
          if (summaries != null && summaries.isNotEmpty) {
            final summaryMap = summaries.first;
            history = (summaryMap['consumed'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      int steps = 0;

      bool hasPermission =
          await SharedPrefsHelper.getHasRequestedHealthPermission();
      Console.log(
          tag: "HealthService", value: "Has permission: $hasPermission");

      // On Android, we use pedometer for steps, which has its own permission handling.
      // We still want to call getStepCount() to trigger the pedometer logic.
      if (hasPermission || forcePermission) {
        Console.log(tag: "steps_124", value: "steps_124123");
        steps = await HealthService()
            .getStepCount(forcePermission: forcePermission);
        Console.log(tag: "steps_124", value: steps.toString());

        // Water intake still comes from Health Connect on Android
        // if (Platform.isAndroid && (hasPermission || forcePermission)) {
        //   final waterLiters = await HealthService()
        //       .getWaterIntakeLiters(forcePermission: forcePermission);
        //   healthWaterMl = waterLiters;
        // }
      }

      final userInfo = context.read<UserInfoCubit>().state;
      if (mounted) {
        setState(() {
          _waterIntake = history;
          _waterGoal = waterGoalParams;
          _stepCount = steps;
          _stepGoal = userInfo.stepGoal ?? 1000;
          _isLoading = false;
        });

        if (_stepCount > 0) {
          await SharedPrefsHelper.setAiHydrationGoalShown(true);
        }
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
                color: AppColors.black.withValues(alpha: .25),
                offset: Offset(
                  AppDimensions.dim2,
                  AppDimensions.dim2,
                ),
              )
            ],
            borderRadius: BorderRadius.circular(
              AppDimensions.radius_15,
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
                  AppLocalizations.of(context)?.goalTracking ?? "Goal Tracking",
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
                              ? (_waterIntake / _waterGoal).clamp(0.0, 0.95)
                              : 0,
                          innerProgress: _stepGoal > 0
                              ? (_stepCount / _stepGoal).clamp(0.0, 0.95)
                              : 0,
                          outerTrackColor: const Color(0xFFECECEC),
                          outerGradient: SweepGradient(
                            colors: [
                              const Color(0xFF369FFF),
                              const Color(0xFFC3E0FF),
                            ],
                            stops: const [0.0, 1.0],
                            transform: const GradientRotation(-pi / 2 -
                                0.2), // Extra rotation to cover the start cap
                          ),
                          innerTrackColor: const Color(0xFFECECEC),
                          innerGradient: SweepGradient(
                            colors: [
                              const Color(0xFF00BA88),
                              const Color(0xFFC1FFF5),
                            ],
                            stops: const [0.0, 1.0],
                            transform: const GradientRotation(-pi / 2 -
                                0.2), // Extra rotation to cover the start cap
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
                                  AppLocalizations.of(context)?.dailyGoal ??
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
                              "${HydrationHelper.formatVolume(_waterIntake, _selectedUnit, showUnit: false)}/${HydrationHelper.formatVolume(_waterGoal.toDouble(), _selectedUnit, showUnit: true)}",
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
                                  AppLocalizations.of(context)?.steps ??
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
  final Gradient outerGradient;
  final Color innerTrackColor;
  final Gradient innerGradient;
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
      ..color = Colors.black.withValues(alpha: 0);

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void drawRing(double radius, double progress, Color trackC, Gradient grad,
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
        if (hasBorder) {
          final borderPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 2.0 // Thicker to create border effect
            ..strokeCap = StrokeCap.round
            ..color = Colors.white;
          canvas.drawArc(rect, -pi / 2, sweepAngle, false, borderPaint);
        }

        // 4. Draw gradient progress with flat caps to avoid overlap issues at 1.0
        progressPaint.strokeCap = StrokeCap.butt;
        progressPaint.shader = grad.createShader(rect);
        canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);

        // 5. Draw rounded caps manually for better control
        final capPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = grad.createShader(rect);

        // Draw end cap (faded)
        final endAngle = -pi / 2 + sweepAngle;
        canvas.drawCircle(
          Offset(center.dx + radius * cos(endAngle),
              center.dy + radius * sin(endAngle)),
          strokeWidth / 2,
          capPaint,
        );

        // Draw start cap (solid) last so it stays on top at 100% progress
        canvas.drawCircle(
          Offset(center.dx + radius * cos(-pi / 2),
              center.dy + radius * sin(-pi / 2)),
          strokeWidth / 2,
          capPaint,
        );
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
