// ignore_for_file: prefer_const_constructors

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WaterWaveWidget extends StatefulWidget {
  final int waveCount;
  final double fillPercent;
  final Axis orientation;
  final double amplitude;
  final Duration speed;

  const WaterWaveWidget({
    super.key,
    this.waveCount = 3,
    this.fillPercent = 0.5,
    this.orientation = Axis.horizontal,
    this.amplitude = 10.0,
    this.speed = const Duration(milliseconds: 1000),
  });

  @override
  State<WaterWaveWidget> createState() => _WaterWaveWidgetState();
}

class _WaterWaveWidgetState extends State<WaterWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Duration? _currentSpeed;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.speed;
    _controller = AnimationController(
      vsync: this,
      duration: _currentSpeed!,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant WaterWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.speed != widget.speed) {
      _controller.dispose();
      _controller = AnimationController(
        vsync: this,
        duration: widget.speed,
      )..repeat();
      _currentSpeed = widget.speed;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: widget.fillPercent),
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, animatedFillPercent, child) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(
                  animation: _controller,
                  waveCount: widget.waveCount,
                  fillPercent: animatedFillPercent,
                  orientation: widget.orientation,
                  amplitude: widget.amplitude,
                ),
                child: SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final int waveCount;
  final double fillPercent;
  final Axis orientation;
  final double amplitude;

  _WavePainter({
    required this.animation,
    required this.waveCount,
    required this.fillPercent,
    required this.orientation,
    required this.amplitude,
  });

  final List<Color>? waveColors = [
    Color(0XFF56CDCA),
    Color(0XFF1D8DBB),
    Color(0XFF93DCEC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0XFF93DCEC)
      ..blendMode = BlendMode.multiply;

    final fillBoundary = orientation == Axis.horizontal
        ? size.height * (1.0 - fillPercent)
        : size.width * (1.0 - fillPercent);

    for (int i = 0; i < waveCount; i++) {
      final path = Path();
      final phase = animation.value * 2 * pi * (i + 1);
      final waveHeight = amplitude * (1 + i / waveCount);
      final waveSpeed = 0.5 + i * 0.1;

      if (orientation == Axis.horizontal) {
        path.moveTo(0, size.height);
        for (double x = 0; x <= size.width; x++) {
          final y =
              waveHeight * sin((x / size.width * 2 * pi * waveSpeed) + phase) +
                  fillBoundary;
          path.lineTo(x, y);
        }
        path.lineTo(size.width, size.height);
      } else {
        path.moveTo(0, 0);
        for (double y = 0; y <= size.height; y++) {
          final x =
              waveHeight * sin((y / size.height * 2 * pi * waveSpeed) + phase) +
                  fillBoundary;
          path.lineTo(x, y);
        }
        path.lineTo(0, size.height);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
