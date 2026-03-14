import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class ColorGradientSlider extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  const ColorGradientSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: AppColors.bluegray,
                fontSize: 11.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation]),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 13.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.pink,
                        Colors.red,
                      ],
                    ),
                  ),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 8.h,
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: AppColors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.2),
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 10.r,
                        elevation: 4,
                      ),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: value,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 14.r,
                height: 14.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      HSVColor.fromAHSV(1.0, value * 360, 1.0, 1.0).toColor(),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 4.r,
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
