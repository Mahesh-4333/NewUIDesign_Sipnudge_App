import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class AnimatedNudgeButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String text;
  final double? horizontalPadding;
  final double? verticalPadding;

  const AnimatedNudgeButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.text = 'Nudge',
    this.horizontalPadding,
    this.verticalPadding,
  });

  @override
  State<AnimatedNudgeButton> createState() => _AnimatedNudgeButtonState();
}

class _AnimatedNudgeButtonState extends State<AnimatedNudgeButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation (press down + bounce back)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Ripple animation (expanding circle)
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Shake animation (vibration effect)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    // Pulse animation (glow effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Color animation (blue to green to blue)
    _colorAnimation = ColorTween(
      begin: const Color(0xFF0083FF),
      end: const Color(0xFF00C853),
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.isLoading) return;

    // Trigger all animations
    _scaleController.forward(from: 0.0);
    _rippleController.forward(from: 0.0);
    _shakeController.forward(from: 0.0);
    _pulseController.forward(from: 0.0);

    // Call the callback
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleController,
          _rippleController,
          _shakeController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Ripple effect
              if (_rippleController.isAnimating)
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1.0 + (_rippleAnimation.value * 0.5),
                    child: Opacity(
                      opacity: 1.0 - _rippleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0083FF).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main button with shake + scale
              Transform.translate(
                offset: Offset(
                  sin(_shakeAnimation.value * 4 * pi) * 3 *
                      (1.0 - _shakeAnimation.value),
                  0,
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.horizontalPadding ?? 22.w,
                      vertical: widget.verticalPadding ?? 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: _colorAnimation.value ?? const Color(0xFF0083FF),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: (_colorAnimation.value ?? const Color(0xFF0083FF))
                              .withOpacity(0.3 + (_pulseAnimation.value * 0.3)),
                          blurRadius: 6 + (_pulseAnimation.value * 8),
                          offset: Offset(0, 2 + (_pulseAnimation.value * 2)),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        // Shake icon
                        Transform.rotate(
                          angle: sin(_shakeAnimation.value * 6 * pi) * 0.3 *
                              (1.0 - _shakeAnimation.value),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 14.w,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          widget.isLoading ? 'Sending...' : widget.text,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
