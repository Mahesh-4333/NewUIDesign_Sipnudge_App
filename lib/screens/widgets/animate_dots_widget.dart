import 'package:flutter/material.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class AnimatedDots extends StatefulWidget {
  final Color? color;
  final double? fontSize;
  final List<FontVariation>? fontVariations;

  const AnimatedDots({
    super.key,
    this.color,
    this.fontSize,
    this.fontVariations,
  });

  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: 4).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        String dots = '';
        for (int i = 0; i < _animation.value; i++) {
          dots += '.';
        }
        return Text(
          dots.padRight(3),
          style: TextStyle(
            color: widget.color ?? AppColors.black,
            fontSize: widget.fontSize ?? AppFontStyles.fontSize_20,
            fontVariations: widget.fontVariations ??
                [
                  AppFontStyles.semiBoldFontVariation,
                ],
          ),
        );
      },
    );
  }
}
