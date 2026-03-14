import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h, top: 24.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.bluegray,
          fontSize: 12.sp,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontWeight: FontWeight.w600,
          fontVariations: [AppFontStyles.boldFontVariation],
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
