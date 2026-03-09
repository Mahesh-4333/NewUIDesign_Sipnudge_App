import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CategoryHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final Color? color;
  final double? titleSize;
  final VoidCallback? onActionTap;

  const CategoryHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap, this.color, this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                color: color ??  AppColors.bluegray,
                fontSize: titleSize ?? 15.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation]),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: TextStyle(
                  color: AppColors.bluegray.withOpacity(0.6),
                  fontSize: 14.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
