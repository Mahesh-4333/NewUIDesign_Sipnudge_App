// reminder_option_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class ReminderOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> features;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final Color activeColor;
  final Color activeTrackColor;

  const ReminderOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.features,
    required this.isActive,
    required this.onToggle,
    required this.activeColor,
    required this.activeTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.dim16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
        color: isActive
            ? null
            : AppColors.bottomSheetGradientStart.withOpacity(0.30),
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bottomSheetGradientStart,
                  AppColors.bottomSheetGradientEnd,
                ],
              )
            : null,
        border: Border.all(
          color: isActive ? AppColors.lavender : AppColors.darkLavender,
          width: isActive ? AppDimensions.dim3.w : AppDimensions.dim1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_16.sp,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                      color: AppColors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: AppFontStyles.fontSize_14.sp,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        color: AppColors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                ],
              ),
              SwitchTheme(
                data: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return activeColor;
                    }
                    return AppColors.white;
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return activeTrackColor;
                    }
                    return AppColors.tuna;
                  }),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  trackOutlineColor: WidgetStateProperty.all(Colors.white),
                  trackOutlineWidth: WidgetStateProperty.all(1),
                ),
                child: Switch(value: isActive, onChanged: onToggle),
              ),
            ],
          ),

          Divider(color: AppColors.white46, thickness: 1.5),
          SizedBox(height: AppDimensions.dim12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map(
                  (f) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.dim6.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: AppFontStyles.fontSize_18.sp,
                        ),
                        SizedBox(width: AppDimensions.dim9.w),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontSize: AppFontStyles.fontSize_14.sp,
                              fontVariations: [
                                AppFontStyles.semiBoldFontVariation,
                              ],
                              color: AppColors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
