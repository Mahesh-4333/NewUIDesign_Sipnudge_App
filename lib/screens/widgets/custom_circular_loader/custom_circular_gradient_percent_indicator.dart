import 'package:flutter/material.dart';
import 'dart:math';

class CircularGradientPercentIndicator extends StatelessWidget {
  final double startPercent;
  final double endPercent;
  final double strokeWidth;
  final double size;

  final Gradient? gradient;
  final Color? solidColor;
  final Color backgroundColor;

  final bool showStartCap;
  final bool showEndCap;

  final double shadowBlurRadius;
  final Color shadowColor;

  const CircularGradientPercentIndicator({
    super.key,
    required this.startPercent,
    required this.endPercent,
    required this.size,
    required this.backgroundColor,
    this.gradient,
    this.solidColor,
    this.strokeWidth = 20.0,
    this.showStartCap = true,
    this.showEndCap = true,
    this.shadowBlurRadius = 8.0,
    this.shadowColor = const Color(0x55000000),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularGradientPainter(
          startPercent: startPercent,
          endPercent: endPercent,
          strokeWidth: strokeWidth,
          gradient: gradient,
          solidColor: solidColor,
          backgroundColor: backgroundColor,
          showStartCap: showStartCap,
          showEndCap: showEndCap,
          shadowBlurRadius: shadowBlurRadius,
          shadowColor: shadowColor,
        ),
      ),
    );
  }
}

class _CircularGradientPainter extends CustomPainter {
  final double startPercent;
  final double endPercent;
  final double strokeWidth;

  final Gradient? gradient;
  final Color? solidColor;
  final Color backgroundColor;

  final bool showStartCap;
  final bool showEndCap;

  final double shadowBlurRadius;
  final Color shadowColor;

  _CircularGradientPainter({
    required this.startPercent,
    required this.endPercent,
    required this.strokeWidth,
    required this.gradient,
    required this.solidColor,
    required this.backgroundColor,
    required this.showStartCap,
    required this.showEndCap,
    required this.shadowBlurRadius,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * (endPercent - startPercent);

    // Draw inner shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlurRadius)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
        center.translate(0, shadowBlurRadius / 2), radius, shadowPaint);

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      backgroundPaint,
    );

    // Progress Paint
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap =
          showStartCap || showEndCap ? StrokeCap.round : StrokeCap.butt;

    if (gradient != null) {
      progressPaint.shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: gradient!.colors,
        stops: gradient!.stops,
        transform: GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else if (solidColor != null) {
      progressPaint.color = solidColor!;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + 2 * pi * startPercent,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
