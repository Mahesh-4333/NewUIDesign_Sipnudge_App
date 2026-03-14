import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';

class TopPickCard extends StatelessWidget {
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

  const TopPickCard({
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
        width: 160.w,
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: isSelected
              ? Border.all(color: AppColors.blueWaterIntake, width: 2.w)
              : Border.all(color: Colors.transparent, width: 2.w),
          boxShadow: AppStyle.boxShadowVariation2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              child: Image.asset(
                iconPath,
                width: 40.w,
                height: 40.w,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: 16.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "$subTitle • $duration",
              style: TextStyle(
                color: AppColors.bluegray.withOpacity(0.5),
                fontSize: 12.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (onPlayTap != null) onPlayTap!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: AppColors.blueWaterIntake,
                    size: 28.w,
                  ),
                ),
                SizedBox(width: 8.w),
                // Simplified waveform
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (index) => Container(
                        width: 3.w,
                        height: (10 + (index % 3) * 5).h,
                        decoration: BoxDecoration(
                          color: AppColors.blueWaterIntake.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
