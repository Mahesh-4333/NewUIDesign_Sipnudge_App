import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/constants/assets_path.dart';

class RingtoneListItem extends StatelessWidget {
  final String title;
  final String subTitle;
  final String duration;
  final String iconPath;
  final bool isSelected;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onFavoriteTap;

  const RingtoneListItem({
    super.key,
    required this.title,
    required this.subTitle,
    required this.duration,
    required this.iconPath,
    this.isSelected = false,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onPlayTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: isSelected
              ? Border.all(color: AppColors.blueWaterIntake, width: 2.w)
              : Border.all(color: Colors.transparent, width: 2.w),
          boxShadow: AppStyle.boxShadowVariation2,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              child: Image.asset(
                iconPath,
                width: 50.w,
                height: 50.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation]),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "$duration • $subTitle",
                    style: TextStyle(
                        color: AppColors.greyColorText1,
                        fontSize: 12.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.semiBoldFontVariation]),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (onFavoriteTap != null) onFavoriteTap!();
              },
              behavior: HitTestBehavior.opaque,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? Colors.red
                    : AppColors.bluegray.withOpacity(0.4),
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Image.asset(
              isPlaying ? AssetsPath.play : AssetsPath.playUnselected,
              width: 40.w,
              height: 40.w,
            ),
            SizedBox(width: 25.w),
          ],
        ),
      ),
    );
  }
}
