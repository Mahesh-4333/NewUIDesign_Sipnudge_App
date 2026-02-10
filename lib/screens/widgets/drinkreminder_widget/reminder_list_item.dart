import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class ReminderListItem extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback onTap;
  final String iconPathArrow;
  final bool showCapsule;
  final TextStyle? titleStyle;
  final TextStyle? trailingStyle;
  final Color? iconColor;

  const ReminderListItem({
    super.key,
    required this.title,
    required this.trailing,
    required this.onTap,
    required this.iconPathArrow,
    this.showCapsule = false,
    this.titleStyle,
    this.trailingStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [
                      AppFontStyles.fontWeightVariation600,
                    ],
                  ),
            ),
            if (showCapsule)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim12.w,
                  vertical: AppDimensions.dim4.h,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.white),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radius_50.r,
                  ),
                ),
                child: Text(
                  trailing,
                  style: trailingStyle ??
                      TextStyle(
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.fontWeightVariation600],
                      ),
                ),
              )
            else
              Row(
                children: [
                  if (trailing.isNotEmpty)
                    Text(
                      trailing,
                      style: trailingStyle ??
                          TextStyle(
                            color: AppColors.white,
                            fontSize: AppFontStyles.fontSize_16.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.fontWeightVariation600
                            ],
                          ),
                    ),
                  SizedBox(width: AppDimensions.dim10.w),
                  Image.asset(
                    iconPathArrow,
                    width: AppDimensions.dim9.w,
                    height: AppDimensions.dim16.h,
                    color: iconColor ?? AppColors.bluegray,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
