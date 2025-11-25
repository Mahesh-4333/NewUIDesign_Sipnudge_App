import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:hydrify/constants/app_font_styles.dart';

class WaterLevelIndicator extends StatefulWidget {
  final double percentage;
  final double width;
  final double height;
  final Duration duration;

  const WaterLevelIndicator({super.key, 
    required this.percentage,
    this.width = 100,
    this.height = 200,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<WaterLevelIndicator> createState() => _WaterLevelIndicatorState();
}

class _WaterLevelIndicatorState extends State<WaterLevelIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _percentageAnimation;
  late AnimationController _waveController;
  late double _oldPercentage;

  @override
  void initState() {
    super.initState();
    _oldPercentage = widget.percentage;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _percentageAnimation = Tween<double>(
      begin: _oldPercentage,
      end: widget.percentage,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didUpdateWidget(WaterLevelIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _oldPercentage = oldWidget.percentage;
      _percentageAnimation = Tween<double>(
        begin: _oldPercentage,
        end: widget.percentage,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Color _getFillColor(double percentage) {
    if (percentage <= 30) return Colors.red;
    if (percentage <= 70) return Color(0xFFFFD700);
    return Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_percentageAnimation, _waveController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: CapsulePainter(
                fillColor: _getFillColor(_percentageAnimation.value),
                percentage: _percentageAnimation.value,
                wavePhase: _waveController.value * 2 * math.pi,
              ),
            ),
            Text(
              '${_percentageAnimation.value.toInt()}%',
              style: TextStyle(
                color: Colors.black,
                fontSize: AppFontStyles.fontSize_18,
                fontVariations: [
                  AppFontStyles.boldFontVariation,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CapsulePainter extends CustomPainter {
  final Color fillColor;
  final double percentage;
  final double wavePhase;
  final double borderSpacing = 3.0;
  final double borderWidth = 2.0;

  CapsulePainter({
    required this.fillColor,
    required this.percentage,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(size.width / 2),
        ),
      );

    canvas.drawPath(
      outerPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    final innerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(borderSpacing, borderSpacing,
              size.width - 2 * borderSpacing, size.height - 2 * borderSpacing),
          Radius.circular((size.width - 2 * borderSpacing) / 2),
        ),
      );

    canvas.drawPath(
      innerPath,
      Paint()
        ..color = fillColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    canvas.clipPath(innerPath);
    final fillHeight = size.height * (1 - percentage / 100);

    final wave2 = createWavePath(size, fillHeight, wavePhase + math.pi);
    canvas.drawPath(
      wave2.shift(Offset(0, 2)),
      Paint()..color = fillColor.withOpacity(0.6),
    );

    final wave1 = createWavePath(size, fillHeight, wavePhase);
    canvas.drawPath(
      wave1,
      Paint()..color = fillColor,
    );
  }

  Path createWavePath(Size size, double fillHeight, double phaseShift) {
    final path = Path();
    path.moveTo(0, fillHeight);

    final waveHeight = 8.0;
    final frequency = 2 * math.pi / size.width;

    for (var x = 0.0; x <= size.width; x++) {
      path.lineTo(
        x,
        fillHeight + math.sin(frequency * x + phaseShift) * waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(CapsulePainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.wavePhase != wavePhase;
}
