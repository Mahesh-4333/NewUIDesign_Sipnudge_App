import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydrify/constants/app_colors.dart';

class ConcentricCirclesAnimation extends StatefulWidget {
  final Color baseColor;
  final Color rippleColor;

  const ConcentricCirclesAnimation({
    super.key,
    this.baseColor = AppColors.greyColorText1,
    this.rippleColor = AppColors.blueWaterIntake,
  });

  @override
  State<ConcentricCirclesAnimation> createState() =>
      _ConcentricCirclesAnimationState();
}

class _ConcentricCirclesAnimationState extends State<ConcentricCirclesAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: RippleDotPainter(
          animation: _animation,
          baseColor: widget.baseColor,
          rippleColor: widget.rippleColor,
        ),
      ),
    );
  }
}

class RippleDotPainter extends CustomPainter {
  final Animation<double> animation;
  final Color baseColor;
  final Color rippleColor;

  RippleDotPainter({
    required this.animation,
    required this.baseColor,
    required this.rippleColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    const double spacing = 10.0; // Higher density grid
    const double baseRadius = 1.3;
    const double rippleRadius = 3;
    final double maxDiagonal =
        sqrt(size.width * size.width + size.height * size.height) / 2;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        final double distance = (Offset(x, y) - center).distance;

        // Multi-wave logic with sharper peaks:
        // Using pow(...) makes the peaks (rings) thin and distinct
        final double phase = (distance / 45.0) - (animation.value * 2 * pi);
        final double wavePeak = pow(max(0.0, sin(phase)), 4.0).toDouble();

        // Damping: Waves fade naturally outwards
        final double damping =
            pow(max(0.0, 1.0 - (distance / maxDiagonal)), 1.5).toDouble();

        // Factor determines the highlights of the rings
        final double factor = wavePeak * damping;

        final double radius = baseRadius + (rippleRadius - baseRadius) * factor;

        // Color interpolation between base and ripple colors
        final Color color = Color.lerp(baseColor, rippleColor, factor)!;
        final double opacity = 0.05 + 0.9 * factor;

        if (opacity > 0.01) {
          paint.color = color.withValues(alpha: opacity);
          canvas.drawCircle(Offset(x, y), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
