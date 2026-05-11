import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class AISchedulePersonalizationDialog extends StatelessWidget {
  final VoidCallback onContinueWithGoogle;

  const AISchedulePersonalizationDialog({
    super.key,
    required this.onContinueWithGoogle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              decoration: BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.white,
                    Color(0xffDBEAFE),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Top Icon
                  Image.asset(
                    AssetsPath.syncCalendar,
                    height: 100.h,
                  ),
                  SizedBox(height: 24.h),

                  /// Title
                  Text(
                    "Personalizing your\nschedule",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 28.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      color: AppColors.bluegray,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  /// Subtitle
                  Text(
                    "Sync your meetings to optimize hydration windows around your busy day.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 14.sp,
                      color: AppColors.color_64748B,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  /// Features
                  _buildFeatureCard(
                    icon: AssetsPath.meetingOverlap,
                    title: "Identify meeting overlaps",
                    subtitle:
                        "Automatically detect back-to-back calls where you miss your intake goals.",
                  ),
                  SizedBox(height: 16.h),
                  _buildFeatureCard(
                    icon: AssetsPath.hyderationSlot,
                    title: "Automated hydration slots",
                    subtitle:
                        "Smart-scheduling places reminders in the gaps between your appointments.",
                  ),
                  SizedBox(height: 32.h),

                  /// Google Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onContinueWithGoogle();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.color_CBD5E1),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/google_ic.svg',
                            height: 24.h,
                          ),
                          Expanded(
                            child: Text(
                              "Continue with Google",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.color_0F172A,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  /// Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: 14.sp,
                          color: AppColors.color_64748B,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text("·",
                            style: TextStyle(color: AppColors.color_64748B)),
                      ),
                      Text(
                        "Terms of Service",
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: 14.sp,
                          color: AppColors.color_64748B,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8.w,
              top: 8.h,
              child: IconButton(
                icon: Icon(Icons.close,
                    color: AppColors.color_64748B, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      {required String icon, required String title, required String subtitle}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 246, 250, 255),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.color_F1F5F9),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluegray.withValues(alpha: 0.7),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(icon, height: 40.h),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.color_4C6C9A,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: 12.sp,
                    color: AppColors.color_64748B,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                    height: 1.4,
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
