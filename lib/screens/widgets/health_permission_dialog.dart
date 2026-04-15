import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class HealthPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onCancel;

  const HealthPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: Container(
        padding: EdgeInsets.all(AppDimensions.padding_25.w),
        decoration: BoxDecoration(
          color: AppColors.bluegray, 
          borderRadius: BorderRadius.circular(AppDimensions.radius_20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Health Permissions',
              style: TextStyle(
                color: AppColors.white,
                fontFamily: AppFontStyles.museoModernoFontFamily,
                fontSize: AppFontStyles.fontSize_20,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            SizedBox(height: AppDimensions.dim16.h),
            Text(
              'Sipnudge needs access to your water intake and step count to provide personalized hydration insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.9),
                fontFamily: AppFontStyles.lexendFontFamily,
                fontSize: AppFontStyles.fontSize_14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppDimensions.dim24.h),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: 'Cancel',
                    onPressed: onCancel,
                    isPrimary: false,
                  ),
                ),
                SizedBox(width: AppDimensions.dim12.w),
                Expanded(
                  child: _buildButton(
                    text: 'Allow',
                    onPressed: onAllow,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.white : Colors.transparent,
        foregroundColor: isPrimary ? AppColors.bluegray : AppColors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.dim12.h,
        ),
        side: isPrimary ? null : const BorderSide(color: AppColors.white, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFontStyles.museoModernoFontFamily,
          fontSize: AppFontStyles.fontSize_14,
          fontVariations: [AppFontStyles.fontWeightVariation600],
        ),
      ),
    );
  }
}
