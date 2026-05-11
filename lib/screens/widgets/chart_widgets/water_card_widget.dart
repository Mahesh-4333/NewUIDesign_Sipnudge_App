import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class WaterCardWidget extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const WaterCardWidget({
    super.key,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        margin:
            EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
          color: Colors.white,
          border: Border.all(color: AppColors.greywith80, width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "Add Water" Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7FE).withOpacity(0.5),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: AppColors.bluegray.withOpacity(0.1)),
              ),
              child: Text(
                "Add Water",
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: 20.sp,
                  height: 1.0,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
            // Toggle Icon Circle
            !isExpanded
                ? Image.asset(AssetsPath.awGlass, height: 45.w, width: 45.w)
                : Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.blueWaterIntake, width: 2.w),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.blueWaterIntake,
                      size: 24.w,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
