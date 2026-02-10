import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/widgets/custom_toggle_switch.dart';

class ReminderToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeTrackColor;
  final TextStyle? titleStyle;

  const ReminderToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.dim10.w,
        vertical: AppDimensions.dim10.h,
      ),
      //padding: EdgeInsets.symmetric(vertical: AppDimensions.dim8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: Colors.white,
                  fontSize: AppFontStyles.fontSize_20.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
          ),
          CustomToggleSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeTrackColor ?? AppColors.violetBlue,
            inactiveTrackColor: AppColors.tuna,
          )
        ],
      ),
    );
  }
}