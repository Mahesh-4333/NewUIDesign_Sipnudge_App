import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AnimatedToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<AnimatedToggle> createState() => _GradientToggleState();
}

class _GradientToggleState extends State<AnimatedToggle>
    with SingleTickerProviderStateMixin {
  late bool _value;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.value;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: _value ? 1 : 0,
    );
  }

  void _toggle() {
    if (_value) {
      _controller.reverse();
    } else {
      _controller.forward();
    }

    setState(() => _value = !_value);
    widget.onChanged(_value);
  }

  @override
  void didUpdateWidget(covariant AnimatedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
      _value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: SizedBox(
        width: 52.w,
        height: 30.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Grey Track
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.r),
                color: Colors.grey.shade300,
              ),
            ),

            // Animated Gradient Fade
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.r),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF24B58A),
                      Color(0xFF3784EB),
                      Color(0xFF0667E9),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment:
              _value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}