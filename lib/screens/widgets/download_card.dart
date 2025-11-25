import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';

class DownloadCard extends StatelessWidget {
  final VoidCallback onTap;

  const DownloadCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10), // shadow color only
            blurRadius: 2.r,
            spreadRadius: 3.r,
            offset: Offset(3.5.r, 3.5.r), // even shadow
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.downloadMyData,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_20.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.fontWeightVariation600],
                      ),
                    ),
                    Spacer(),
                    Image.asset(
                      'assets/arrow.png',
                      width: AppDimensions.dim9.w,
                      height: AppDimensions.dim16.h,
                      color: AppColors.white,
                    ),
                    SizedBox(width: AppDimensions.dim8.w),
                  ],
                ),
                SizedBox(height: AppDimensions.dim8.h),
                Text(
                  AppStrings.requestaCopyOfYourDataYourInformationYourControl,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppFontStyles.fontSize_16.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
