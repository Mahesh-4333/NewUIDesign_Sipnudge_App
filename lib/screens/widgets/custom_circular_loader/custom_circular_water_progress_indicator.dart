import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';

class CustomCircularWaterProgressIndicator extends StatelessWidget {
  const CustomCircularWaterProgressIndicator({
    super.key,
    required this.height,
    required this.width,
    required this.backgroundColor,
    required this.progressBackgroundColor,
    required this.percentageValue,
    this.progressColor,
    this.center,
    this.boxShadow,
  });

  final double width;
  final double height;
  final Color backgroundColor;
  final Color? progressColor;
  final Color progressBackgroundColor;
  final double percentageValue;
  final Widget? center;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 🔥 FULL BACKGROUND COLOR BEHIND THE INDICATOR (YOUR REQUIREMENT)
        border: Border.all(color: progressBackgroundColor, width: 1),
        boxShadow: boxShadow,
      ),
      padding: EdgeInsets.all(0),
      alignment: Alignment.center,
      child: Container(
        // Background inner circle (optional if you want dual-layer effect)
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: CustomPaint(
          size: Size(width, height),
          painter: _WaterArcPainter(
            percentage: percentageValue,
            baseArcColor: Colors.white,
            progressBackgroundColor: AppColors.white.withValues(alpha: 0.40),
            progressColor: progressColor ?? Color(0XFF1C8DBB),
            strokeWidth: AppDimensions.dim8.w,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _WaterArcPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color baseArcColor;
  final Color progressBackgroundColor;
  final Color progressColor;

  _WaterArcPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.baseArcColor,
    required this.progressBackgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final startAngle = -pi * 0.33;
    final sweepAngle = pi * 1.65;

    final deflatedRect = rect.deflate(strokeWidth / 1.5);

    // --- FULL ELLIPSE BACKGROUND ---
    final ellipseBgPaint = Paint()
      ..color = progressBackgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // --- OUTER SHADOW FOR BACKGROUND ---
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0.r);

    canvas.drawArc(
      deflatedRect,
      0,
      2 * pi,
      false,
      shadowPaint,
    );

    canvas.drawArc(
      deflatedRect,
      0,
      2 * pi,
      false,
      ellipseBgPaint,
    );

    // --- WHITE BASE ARC ---
    final baseArc = Paint()
      ..color = baseArcColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      deflatedRect,
      startAngle,
      sweepAngle,
      false,
      baseArc,
    );

    // --- PROGRESS ARC ---
    final progressArc = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressSweep = sweepAngle * (percentage / 100);

    canvas.drawArc(
      deflatedRect,
      startAngle,
      progressSweep,
      false,
      progressArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}