import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/widgets/custom_anim_toggle.dart';

class CustomToggleTile extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleTile({
    super.key,
    required this.title,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: 18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    description!,
                    style: TextStyle(
                      color: AppColors.bluegray.withOpacity(0.6),
                      fontSize: 12.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.semiBoldFontVariation]
                    ),
                  ),
                ],
              ],
            ),
          ),
          AnimatedToggle(value: value, onChanged: (bool value) {
            onChanged(value);
          },),
        ],
      ),
    );
  }
}
