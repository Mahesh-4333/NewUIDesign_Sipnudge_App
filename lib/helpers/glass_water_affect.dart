import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class GlassWaterWidget extends StatefulWidget {
  @override
  State<GlassWaterWidget> createState() => _GlassWaterWidgetState();
}

class _GlassWaterWidgetState extends State<GlassWaterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  double progress = 0.6; // water level (0 to 1)

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          /// 🌊 Water Layer
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              return CustomPaint(
                painter: WaterPainter(
                  progress: progress,
                  wavePhase: controller.value * 2 * pi,
                ),
                child: const SizedBox(
                  width: 220,
                  height: 320,
                ),
              );
            },
          ),

          /// ✨ Glass Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 220,
              height: 320,
              color: Colors.white.withOpacity(0.08),
            ),
          ),

          /// 💡 Light Reflection
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 60,
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          /// 🔲 Glass Border
          Container(
            width: 220,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  WaterPainter({
    required this.progress,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    double waterHeight = size.height * (1 - progress);

    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      double y = waterHeight +
          sin((x / size.width * 2 * pi) + wavePhase) * 10 +
          sin((x / size.width * 4 * pi) + wavePhase * 1.5) * 5;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.shade300,
          Colors.blue.shade700,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) => true;
}
