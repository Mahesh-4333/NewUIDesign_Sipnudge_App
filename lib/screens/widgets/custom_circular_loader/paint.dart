import 'dart:math' show pi, cos, sin;

import 'package:flutter/material.dart';

enum SpinnerDirection {
  clockwise,
  antiClockwise,
}

extension NumToRadians on num {
  double toRadians() {
    return toDouble() * (pi / 180.0);
  }

  double toDegree() {
    return toDouble() * (180 / pi);
  }
}

class ProgressPainter extends CustomPainter {
  final double rotationAngle;
  final double strokeWidth;
  final Color progressColor;
  final Color progressEndColor;
  final int gradientSteps;
  final SpinnerDirection spinnerDirection;

  ProgressPainter({
    this.rotationAngle = 0,
    this.strokeWidth = 20,
    required this.progressColor,
    required this.progressEndColor,
    this.gradientSteps = 8,
    required this.spinnerDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var centerX = size.width / 2;
    var centerY = size.height / 2;
    var radius = size.width / 2;

    List<Color> gradientColors = generateGradientColors(
      progressColor,
      progressEndColor,
      steps: gradientSteps,
    );

    double startAngle = 0;
    double sweepAngle = 360;

    var rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width,
      height: size.height,
    );

    var shader = SweepGradient(
      startAngle: startAngle.toRadians(),
      endAngle: (startAngle + sweepAngle).toRadians(),
      colors: gradientColors,
    ).createShader(rect);

    var paint = Paint()
      ..strokeWidth = strokeWidth
      ..shader = shader
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    var startCapPosition = Offset(
      centerX + radius * cos(startAngle.toRadians()),
      centerY + radius * sin(startAngle.toRadians()),
    );

    var startCapPaint = Paint()..color = gradientColors.first;

    canvas.save();
    canvas.translate(centerX, centerY);

// Apply rotation based on animation
    double rotationRadians = rotationAngle.toRadians();
    if (spinnerDirection == SpinnerDirection.antiClockwise) {
      rotationRadians = -rotationRadians;
    }
    canvas.rotate(rotationRadians);
    canvas.translate(-centerX, -centerY);

    canvas.drawArc(
      rect,
      0.toRadians(),
      sweepAngle.toRadians(),
      false,
      paint,
    );

    double endAngle = 0 + sweepAngle;
    var endCapX = centerX + radius * cos(endAngle.toRadians());
    var endCapY = centerY + radius * sin(endAngle.toRadians());
    var endCapPosition = Offset(endCapX, endCapY);

    var endCapPaint = Paint()..color = gradientColors.last;

    canvas.drawCircle(endCapPosition, strokeWidth / 2, endCapPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return rotationAngle != oldDelegate.rotationAngle;
  }

  List<Color> generateGradientColors(Color startColor, Color endColor,
      {int steps = 8}) {
    List<Color> colors = [];
    double holdEndFraction = 0.20;

    for (int i = 0; i < steps; i++) {
      double t = i / (steps - 1);
      if (t > (1.0 - holdEndFraction)) {
        colors.add(endColor);
      } else {
        double adjustedT = t / (1.0 - holdEndFraction);
        final color =
            Color.lerp(startColor, endColor, adjustedT.clamp(0.0, 1.0));
        if (color != null) {
          colors.add(color);
        }
      }
    }

    return colors;
  }
}
