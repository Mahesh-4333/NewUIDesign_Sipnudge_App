import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';

class TodayGoalWidget extends StatelessWidget {
  const TodayGoalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationState>(
      builder: (context, state) {
        final double intakeMl = state.totalDrank.toDouble();
        final double goalMl = state.goal.toDouble() > 0 ? state.goal.toDouble() : 2500;
        final double progress = (intakeMl / goalMl).clamp(0.0, 1.0);
        final int percentage = (progress * 100).toInt();

        return Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(AppDimensions.dim20.w),
          margin: EdgeInsets.only(
            left: AppDimensions.defaultPadding.w,
            right: AppDimensions.defaultPadding.w,
            bottom: AppDimensions.dim80.h,
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
            border: Border.all(color: AppColors.greywith80),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Goal",
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_20,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: AppDimensions.dim4.h),
              Text(
                "All logs with Slots and off slots",
                style: TextStyle(
                  color: Color(0xFF6B7280), // Gray color for subtitle
                  fontSize: AppFontStyles.fontSize_14,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.regularFontVariation],
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
                        size: Size(AppDimensions.dim220.w, AppDimensions.dim220.w),
                        painter: _SingleProgressPainter(
                          progress: progress,
                          trackColor: Color(0xFFF3F4F6), // Light grey track like the mockup
                          gradient: LinearGradient(
                            colors: [Color(0xFF6AA7FB), Color(0xFF1358E2)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          strokeWidth: 16.w,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${(intakeMl / 1000).toStringAsFixed(1)}L",
                            style: TextStyle(
                              color: AppColors.bluegray,
                              fontSize: 40.sp,
                              fontFamily: AppFontStyles.museoModernoFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(height: AppDimensions.dim4.h),
                          Text(
                            "$percentage% OF GOAL",
                            style: TextStyle(
                              color: AppColors.bluegray,
                              fontSize: AppFontStyles.fontSize_14,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.fontWeightVariation600],
                            ),
                          ),
                          SizedBox(height: AppDimensions.dim4.h),
                          Text(
                            "ACHIEVED",
                            style: TextStyle(
                              color: Color(0xFFEAB308), // Gold/Yellow
                              fontSize: AppFontStyles.fontSize_14,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.fontWeightVariation600],
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
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.dim24.w,
                    vertical: AppDimensions.dim12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radius_30.r),
                    border: Border.all(color: Color(0xFFE5E7EB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        color: AppColors.bluegray,
                        size: 24.w,
                      ),
                      SizedBox(width: AppDimensions.dim8.w),
                      Text.rich(
                        TextSpan(
                          text: "Consistency Streak: ",
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_16,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.regularFontVariation],
                          ),
                          children: [
                            TextSpan(
                              text: "12 Days", // Placeholder
                              style: TextStyle(
                                fontVariations: [AppFontStyles.boldFontVariation],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.dim10.h),
            ],
          ),
        );
      },
    );
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
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

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
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, borderPaint);

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
