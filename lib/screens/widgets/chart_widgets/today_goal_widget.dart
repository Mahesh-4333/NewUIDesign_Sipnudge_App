import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

class TodayGoalWidget extends StatefulWidget {
  const TodayGoalWidget({super.key});

  @override
  State<TodayGoalWidget> createState() => _TodayGoalWidgetState();
}

class _TodayGoalWidgetState extends State<TodayGoalWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<BottleDataCubit, BottleDataState>(
        builder: (context, stateble) {
      return BlocBuilder<HydrationCubit, HydrationState>(
        builder: (context, state) {
          return FutureBuilder<List<dynamic>>(
            future: Future.wait([
              SharedPrefsHelper.getWaterGoal(),
              context.read<BottleDataCubit>().getCurrentDayHistory(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                // Using a placeholder SizedBox to prevent layout jump when data loads
                return SizedBox(height: 410.h);
              }
              final double waterGoalFromPrefs =
                  (snapshot.data![0] ?? 2500).toDouble();
              final double intakeMl = (snapshot.data![1] as num).toDouble();
              final double goalMl = waterGoalFromPrefs;
              final double progress = (intakeMl / goalMl).clamp(0.0, 1.0);
              final int percentage = (progress * 100).toInt();

              return Container(
                width: double.maxFinite,
                padding: EdgeInsets.all(AppDimensions.dim20.w),
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
                    AppDimensions.radius_15,
                  ),
                  color: Color(0XFFFFFFFF),
                  border: Border.all(color: AppColors.greywith80),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...[
                            Text(
                              AppLocalizations.of(context)?.todaysGoal ?? "Today's Goal",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_20,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            SizedBox(height: AppDimensions.dim4.h),
                            Text(
                              "All logs with Slots and off slots",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                // Gray color for subtitle
                                fontSize: AppFontStyles.fontSize_14,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.regularFontVariation
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    SizedBox(height: AppDimensions.dim32.h),
                    Center(
                      child: SizedBox(
                        width: AppDimensions.dim220.w,
                        height: AppDimensions.dim220.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size(AppDimensions.dim220.w,
                                  AppDimensions.dim220.w),
                              painter: _SingleProgressPainter(
                                progress: progress,
                                trackColor: Color(0xFFF3F4F6),
                                // Light grey track like the mockup
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.blueWaterIntake,
                                    AppColors.blueWaterIntake
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                strokeWidth: 12.w,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${(intakeMl).toStringAsFixed(0)}mL",
                                  style: TextStyle(
                                    color: AppColors.bluegray,
                                    fontSize: 30.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.extraBoldFontVariation
                                    ],
                                  ),
                                ),
                                SizedBox(height: AppDimensions.dim4.h),
                                Text(
                                  "$percentage% OF GOAL",
                                  style: TextStyle(
                                    color: AppColors.bluegray,
                                    fontSize: AppFontStyles.fontSize_14,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.fontWeightVariation600
                                    ],
                                  ),
                                ),
                                SizedBox(height: AppDimensions.dim4.h),
                                Text(
                                  "ACHIEVED",
                                  style: TextStyle(
                                    color: Color(0xFFEAB308), // Gold/Yellow
                                    fontSize: AppFontStyles.fontSize_14,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
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
                    ),
                    SizedBox(height: AppDimensions.dim40.h),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radius_30.r),
                          border:
                              Border.all(color: Color(0xFFE5E7EB), width: 1.5),
                          boxShadow: AppStyle.boxShadowVariation3,
                        ),
                        child: Container(
                          padding: EdgeInsets.only(
                              // horizontal: AppDimensions.dim30.w,
                              bottom: 4.h,
                              top: 4.h,
                              right: 30.w,
                              left: 5.w),
                          decoration: BoxDecoration(
                            color: Color(0x52b6dcff),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radius_30.r),
                            // border:
                            // Border.all(color: Color(0xFFE5E7EB), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop_outlined,
                                color: AppColors.blueWaterIntake,
                                size: 35.w,
                              ),
                              SizedBox(width: AppDimensions.dim35.w),
                              Text.rich(
                                textAlign: TextAlign.center,
                                TextSpan(
                                  text: "TODAY'S REFFILS",
                                  style: TextStyle(
                                    color: AppColors.bluegray,
                                    fontSize: AppFontStyles.fontSize_15,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "\n${stateble.refills ?? 0} refills",
                                      style: TextStyle(
                                        fontSize: AppFontStyles.fontSize_15,
                                        fontVariations: [
                                          AppFontStyles.extraBoldFontVariation
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.dim10.h),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }
}

class _SingleProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final LinearGradient gradient;
  final double strokeWidth;

  _SingleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final Paint shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // final Paint borderPaint = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = strokeWidth + 6.0
    //   ..strokeCap = StrokeCap.round
    //   ..color = Colors.white;

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw track
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, trackPaint);

    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;

      // 2. Draw shadow
      final shadowRect = Rect.fromCircle(
        center: center.translate(0, 4),
        radius: radius,
      );
      canvas.drawArc(shadowRect, -pi / 2, sweepAngle, false, shadowPaint);

      // 3. Draw white border
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, shadowPaint);

      // 4. Draw gradient progress
      progressPaint.shader = gradient.createShader(rect);
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SingleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
