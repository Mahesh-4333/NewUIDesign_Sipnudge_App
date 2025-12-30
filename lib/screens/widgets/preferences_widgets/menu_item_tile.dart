import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class MenuItemTile extends StatelessWidget {
  final String title;
  final String info;
  final String iconpatharrow;
  final VoidCallback? onTap;

  const MenuItemTile({
    super.key,
    required this.title,
    required this.info,
    required this.iconpatharrow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppDimensions.dim55.h,
        padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.dim20.w, vertical: AppDimensions.dim12.h),
        margin: EdgeInsets.only(bottom: AppDimensions.dim10.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radius_40.r),
          border: Border.all(
            color: AppColors.greywith80,
            width: 1.w,
          ),

          // ☁ Soft shadow like mockup
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.25),
              blurRadius: 4.r,
              offset: Offset(2.r, 2.r),
            )
          ],
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            const Spacer(),
            Text(
              info,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_16.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            SizedBox(width: AppDimensions.dim20.w),
            Image.asset(
              iconpatharrow,
              width: AppDimensions.dim9.w,
              height: AppDimensions.dim16.h,
              color: AppColors.bluegray,
            ),
            SizedBox(width: AppDimensions.dim8.w),
          ],
        ),
      ),
    );
  }
}
