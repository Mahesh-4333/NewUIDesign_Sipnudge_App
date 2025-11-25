import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_dimensions.dart';

class SegmentedProgressIndicator extends StatefulWidget {
  final double progress;
  final int segmentCount;
  final double strokeWidth;
  final double gapSize;
  final Gradient gradient;
  final bool isIndeterminate;
  final Duration duration;
  final Widget? child;

  const SegmentedProgressIndicator({
    super.key,
    this.progress = 0.0,
    required this.segmentCount,
    this.strokeWidth = 10,
    this.gapSize = 2,
    required this.gradient,
    this.isIndeterminate = false,
    this.duration = const Duration(seconds: 2),
    this.child,
  });

  @override
  State<SegmentedProgressIndicator> createState() =>
      _SegmentedProgressIndicatorState();
}

class _SegmentedProgressIndicatorState extends State<SegmentedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isIndeterminate) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
      )..repeat();
    }
  }

  @override
  void dispose() {
    if (widget.isIndeterminate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.dim250.w,
      height: AppDimensions.dim250.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: widget.isIndeterminate
                ? _controller
                : const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              return CustomPaint(
                size: Size.square(AppDimensions.dim250.h),
                painter: _SegmentedPainter(
                  progress: widget.isIndeterminate ? 1.0 : widget.progress,
                  segmentCount: widget.segmentCount,
                  strokeWidth: widget.strokeWidth,
                  gapSize: widget.gapSize,
                  gradient: widget.gradient,
                  rotationAngle:
                      widget.isIndeterminate ? _controller.value * 2 * pi : 0,
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _SegmentedPainter extends CustomPainter {
  final double progress;
  final int segmentCount;
  final double strokeWidth;
  final double gapSize;
  final Gradient gradient;
  final double rotationAngle;

  _SegmentedPainter({
    required this.progress,
    required this.segmentCount,
    required this.strokeWidth,
    required this.gapSize,
    required this.gradient,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final segmentAngle = (2 * pi) / segmentCount;
    final sweepAngle = segmentAngle - gapSize * pi / 180;
    final filledSegments = (segmentCount * progress).floor();

    final rotatedGradient = SweepGradient(
      colors: gradient.colors,
      stops: gradient.stops,
      transform: GradientRotation(rotationAngle),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..shader = rotatedGradient.createShader(rect);

    for (int i = 0; i < filledSegments; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
