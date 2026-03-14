import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';

class PreferenceCard extends StatelessWidget {
  final List<Widget> children;

  const PreferenceCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.greywith80.withOpacity(0.2),
          width: 0.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
