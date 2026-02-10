import 'package:flutter/material.dart';

class CustomToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  final double width;
  final double height;

  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final Color activeBorderColor;
  final Color inactiveBorderColor;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 52,
    this.height = 30,
    this.activeTrackColor = const Color(0xFF5B4FFF), // violet/blue
    this.inactiveTrackColor = const Color(0xFF3A4F5C), // bluish grey
    this.thumbColor = Colors.white,
    this.activeBorderColor = const Color(0xFF2CFF00), // neon green ring
    this.inactiveBorderColor = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    final double thumbSize = height - 6;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? activeTrackColor : inactiveTrackColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: value ? activeBorderColor : inactiveBorderColor,
                width: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
