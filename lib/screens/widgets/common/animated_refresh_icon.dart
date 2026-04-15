import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/assets_path.dart';

class AnimatedRefreshIcon extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final double? size;

  const AnimatedRefreshIcon({
    super.key,
    required this.onRefresh,
    this.size,
  });

  @override
  State<AnimatedRefreshIcon> createState() => _AnimatedRefreshIconState();
}

class _AnimatedRefreshIconState extends State<AnimatedRefreshIcon>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Prevent overlapping refresh calls
        if (_rotateController.isAnimating) return;

        _scaleController.forward();
        _rotateController.repeat();

        // Ensure a minimum animation visibility of 1.5s
        final minDelay = Future.delayed(const Duration(milliseconds: 1500));

        try {
          await widget.onRefresh();
        } finally {
          await minDelay;
          if (mounted) {
            _rotateController.stop();
            _scaleController.reverse();
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: RotationTransition(
            turns: _rotateController,
            child: Image.asset(
              AssetsPath.refreshIcon,
              width: widget.size ?? 20.w,
              height: widget.size ?? 20.w,
            ),
          ),
        ),
      ),
    );
  }
}
