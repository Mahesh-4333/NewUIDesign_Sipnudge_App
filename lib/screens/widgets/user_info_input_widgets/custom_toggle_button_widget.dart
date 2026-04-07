import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CustomToggleButtonWidget extends StatefulWidget {
  const CustomToggleButtonWidget({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.initialValue,
    required this.onChanged,
    this.toggleType = 1, // 1 = capsule style, 2 = circular toggle style
  });

  final String leftLabel;
  final String rightLabel;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int toggleType;

  @override
  State<CustomToggleButtonWidget> createState() =>
      _CustomToggleButtonWidgetState();
}

class _CustomToggleButtonWidgetState extends State<CustomToggleButtonWidget> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant CustomToggleButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _selectedValue = widget.initialValue;
      });
    }
  }

  void _toggleValue() {
    setState(() {
      _selectedValue = _selectedValue == widget.leftLabel
          ? widget.rightLabel
          : widget.leftLabel;
    });
    widget.onChanged(_selectedValue);
  }

  @override
  Widget build(BuildContext context) {
    return widget.toggleType == 1
        ? _buildCapsuleToggle()
        : _buildCircleSliderToggle();
  }

  Widget _buildCapsuleToggle() {
    bool isLeftSelected = _selectedValue == widget.leftLabel;

    return GestureDetector(
      onTap: _toggleValue,
      child: Container(
        width: AppDimensions.dim184.w,
        height: AppDimensions.dim46.h,
        decoration: BoxDecoration(
          color: AppColors.customRadioUnselectedFillColor,
          borderRadius: BorderRadius.circular(
            AppDimensions.radius_50,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: Offset(0, 4.h),
              blurRadius: 8.r,
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment:
                  isLeftSelected ? Alignment.centerLeft : Alignment.centerRight,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                width: AppDimensions.dim92.w,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF5AD3F0),
                      Color(0xFF0077B6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40.r),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildLabel(widget.leftLabel, isLeftSelected)),
                Expanded(
                    child: _buildLabel(widget.rightLabel, !isLeftSelected)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleSliderToggle() {
    bool isLeftSelected = _selectedValue == widget.leftLabel;

    return GestureDetector(
      onTap: _toggleValue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: AppDimensions.dim98.w,
        height: AppDimensions.dim48.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.lightgray,
            width: AppDimensions.dim1.w,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radius_50),
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.dim4,
              color: Colors.black.withOpacity(.4),
              offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
                  isLeftSelected ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: AppDimensions.dim48.w,
                height: AppDimensions.dim48.w,
                decoration: BoxDecoration(
                  color: AppColors.platinumgray,
                  borderRadius: BorderRadius.circular(AppDimensions.radius_50),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSquareLabel(widget.leftLabel, isSelected: isLeftSelected),
                _buildSquareLabel(widget.rightLabel,
                    isSelected: !isLeftSelected),
                // _buildSquareLabel(widget.leftLabel),
                // _buildSquareLabel(widget.rightLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isSelected) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFontStyles.urbanistFontFamily,
          color: isSelected ? Colors.white : Colors.white70,
          fontVariations: [AppFontStyles.semiBoldFontVariation],
          fontSize: AppFontStyles.fontSize_16,
        ),
      ),
    );
  }

  Widget _buildSquareLabel(String text, {required bool isSelected}) {
    return SizedBox(
      width: AppDimensions.dim48.w,
      height: AppDimensions.dim48.w,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            color: isSelected
                ? AppColors.bluegray
                : AppColors.lightgray, // Toggle text color
            fontVariations: [AppFontStyles.semiBoldFontVariation],
            fontSize: AppFontStyles.fontSize_16,
          ),
        ),
      ),
    );
  }

  // Widget _buildSquareLabel(String text) {
  //   return SizedBox(
  //     width: AppDimensions.dim48.w,
  //     height: AppDimensions.dim48.w,
  //     child: Center(
  //       child: Text(
  //         text,
  //         style: TextStyle(
  //           fontFamily: AppFontStyles.urbanistFontFamily,
  //           color: AppColors.bluegray,
  //           fontVariations: [AppFontStyles.semiBoldFontVariation],
  //           fontSize: AppFontStyles.fontSize_16,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
