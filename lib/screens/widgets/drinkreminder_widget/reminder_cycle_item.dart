import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class ReminderCycleItem extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final TextStyle? titleStyle;
  final Color? chipBackgroundColor;
  final Color? chipBorderColor;
  final TextStyle? chipTextStyle;

  const ReminderCycleItem({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
    this.titleStyle,
    this.chipBackgroundColor,
    this.chipBorderColor,
    this.chipTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radius_12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim10.w,
          vertical: AppDimensions.dim10.h,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: titleStyle ??
                  TextStyle(
                    color: AppColors.white,
                    fontSize: AppFontStyles.fontSize_20.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.fontWeightVariation600],
                  ),
            ),
            Container(
              width: AppDimensions.dim87.w,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.dim10.w,
                vertical: AppDimensions.dim3.h,
              ),
              decoration: BoxDecoration(
                color: chipBackgroundColor ??
                    AppColors.greenwhite20.withOpacity(0.22),
                border: Border.all(
                  color: chipBorderColor ?? AppColors.white,
                  width: AppDimensions.dim1.w,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radius_30.r),
              ),
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: chipTextStyle ??
                      TextStyle(
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.fontWeightVariation600],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}