import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class MenuItemTileWidget extends StatelessWidget {
  final String title;
  final bool isSelected;
  final String number;
  final VoidCallback? onTap;

  const MenuItemTileWidget({
    super.key,
    required this.title,
    this.isSelected = false,
    required this.number,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      //onTap: () => debugPrint("Tapped $title"),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(40.r),

          // 🔵 Selected border
          border: isSelected
              ? Border.all(
                  color: AppColors.bluegray,
                  width: 2.w,
                )
              : Border.all(
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
              number,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            //SizedBox(width: AppDimensions.dim20.w),
            SizedBox(width: AppDimensions.dim8.w),
          ],
        ),
      ),
    );
  }
}
