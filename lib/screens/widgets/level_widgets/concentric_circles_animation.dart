// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:hydrify/constants/app_colors.dart';

// class ConcentricCirclesAnimation extends StatefulWidget {
//   const ConcentricCirclesAnimation({super.key});

//   @override
//   State<ConcentricCirclesAnimation> createState() =>
//       _ConcentricCirclesAnimationState();
// }

// class _ConcentricCirclesAnimationState extends State<ConcentricCirclesAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     )..repeat();

//     _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox.expand(
//       child: CustomPaint(
//         painter: ConcentricCirclePainter(animation: _animation),
//       ),
//     );
//   }
// }

// class ConcentricCirclePainter extends CustomPainter {
//   final Animation<double> animation;

//   ConcentricCirclePainter({required this.animation})
//       : super(repaint: animation);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;

//     final Offset center = Offset(size.width / 2, size.height / 2);
//     final double maxRadius = min(size.width, size.height) / 1.8;
//     const int circleCount = 12;

//     for (int i = 0; i < circleCount; i++) {
//       final double offset = (i + animation.value) % circleCount;
//       final radius = (offset / circleCount) * maxRadius;

//       final color = Color.lerp(
//         AppColors.sandstorm,
//         AppColors.violapurple,
//         offset / circleCount,
//       )!;

//       paint.color = color.withOpacity(1 - (offset / circleCount));
//       canvas.drawCircle(center, radius, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

//========================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hydrify/constants/app_colors.dart';

class ConcentricCirclesAnimation extends StatefulWidget {
  const ConcentricCirclesAnimation({super.key});

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
      duration: const Duration(milliseconds: 500),
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
        painter: ConcentricCirclePainter(animation: _animation),
      ),
    );
  }
}

class ConcentricCirclePainter extends CustomPainter {
  final Animation<double> animation;

  ConcentricCirclePainter({required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = min(size.width, size.height) / 1.8;
    const int circleCount = 12;

    for (int i = 0; i < circleCount; i++) {
      final double offset = (i + animation.value) % circleCount;
      final radius = (offset / circleCount) * maxRadius;

      final color = Color.lerp(
        AppColors.sandstorm,
        AppColors.violapurple,
        offset / circleCount,
      )!;

      paint.color = color.withOpacity(1 - (offset / circleCount));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
