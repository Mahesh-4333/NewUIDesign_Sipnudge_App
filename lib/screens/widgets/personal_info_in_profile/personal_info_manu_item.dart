// widgets/menu_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class MenuItem extends StatelessWidget {
  final String title;
  final String info;
  final String iconPathArrow;
  final VoidCallback? onTap;
  final bool isRed;

  const MenuItem({
    super.key,
    required this.title,
    required this.info,
    required this.iconPathArrow,
    this.onTap,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.dim16,
          vertical: AppDimensions.dim12,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isRed ? AppColors.redAccent : AppColors.white,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            const Spacer(),
            Text(
              info,
              style: TextStyle(
                color: isRed ? AppColors.redAccent : AppColors.white,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_16.sp,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            SizedBox(width: AppDimensions.dim20.w),
            Image.asset(
              iconPathArrow,
              width: AppDimensions.dim9.w,
              height: AppDimensions.dim16.h,
              color: AppColors.white,
            ),
            SizedBox(width: AppDimensions.dim8.w),
          ],
        ),
      ),
    );
  }
}
