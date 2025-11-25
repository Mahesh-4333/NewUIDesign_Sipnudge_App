import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';

class CustomCircularProgressIndicator extends StatelessWidget {
  const CustomCircularProgressIndicator(
      {super.key,
      required this.height,
      required this.width,
      required this.backgroundColor,
      required this.progressBackgroundColor,
      required this.percentageValue,
      this.progressColor,
      this.linearGradient,
      this.center,
      this.lineWidth,
      this.boxShadow,
      this.needsInnerShadow = false,
      this.radius,
      this.backgroundNeedsGradient = false});

  final double width;
  final double height;
  final Color backgroundColor;
  final Color? progressColor;
  final Color progressBackgroundColor;
  final LinearGradient? linearGradient;
  final double percentageValue;
  final Widget? center;
  final double? radius;
  final double? lineWidth;
  final bool needsInnerShadow;
  final List<BoxShadow>? boxShadow;
  final bool backgroundNeedsGradient;

  @override
  Widget build(BuildContext context) {
    final stroke = lineWidth ?? AppDimensions.dim6.w;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: boxShadow,
        gradient: backgroundNeedsGradient
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.mediumgray, AppColors.mediumgray],
              )
            : null,
      ),
      padding: EdgeInsets.all(AppDimensions.dim2.w),
      alignment: Alignment.center,
      child: SizedBox(
        width: width - AppDimensions.dim2.w,
        height: height - AppDimensions.dim2.w,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percentageValue / 100),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          builder: (context, progress, child) {
            return CustomPaint(
              painter: _EllipseArcPainter(
                progress: progress,
                strokeWidth: stroke,
                backgroundColor: progressBackgroundColor,
                progressColor: progressColor,
                gradient: linearGradient,
              ),
              child: Center(child: center),
            );
          },
        ),
      ),
    );
  }
}

class _EllipseArcPainter extends CustomPainter {
  final double progress; // 0–1
  final double strokeWidth;
  final Color backgroundColor;
  final LinearGradient? gradient;
  final Color? progressColor;

  _EllipseArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradient,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    /// Make arc round-capped and matching CircularPercentIndicator
    final Paint backgroundArc = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint progressArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      progressArc.shader = gradient!.createShader(rect);
    } else if (progressColor != null) {
      progressArc.color = progressColor!;
    }

    /// EXACT same arc open top like image
    const startAngle = -120 * pi / 180; // arc opens at top
    const totalAngle = -300 * pi / 180; // 300° like screenshot

    // background full arc
    canvas.drawArc(
      rect.deflate(strokeWidth / 1),
      startAngle,
      totalAngle,
      false,
      backgroundArc,
    );

    // // progress sweep
    // final double progressAngle = totalAngle * progress;

    // canvas.drawArc(
    //   rect.deflate(strokeWidth / 1),
    //   startAngle,
    //   progressAngle,
    //   false,
    //   progressArc,
    // );
    // progress sweep
    final double progressAngle = totalAngle * progress;

    /// Draw white border OUTSIDE the progress arc
    final Paint progressBorderArc = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.2 // slightly thicker to show outside
      ..strokeCap = StrokeCap.round;

    /// Draw border first
    canvas.drawArc(
      rect.deflate(strokeWidth / 1), // slightly inner to compensate thickness
      startAngle,
      progressAngle,
      false,
      progressBorderArc,
    );

    /// Now draw actual green progress arc (on top)
    canvas.drawArc(
      rect.deflate(strokeWidth / 1),
      startAngle,
      progressAngle,
      false,
      progressArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
