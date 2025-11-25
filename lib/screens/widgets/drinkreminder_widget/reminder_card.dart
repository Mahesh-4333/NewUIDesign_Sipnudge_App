// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';

// class ReminderCard extends StatelessWidget {
//   final List<Widget> children;
//   const ReminderCard({super.key, required this.children});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(
//         horizontal: AppDimensions.dim16.w,
//         vertical: AppDimensions.dim10.h,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.white20,
//         borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
//       ),
//       child: Column(children: children),
//     );
//   }
// }

//============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';

class ReminderCard extends StatelessWidget {
  final List<Widget> children;
  const ReminderCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.dim16.w,
        vertical: AppDimensions.dim8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: Color(0xCCC6C6C6)),
        borderRadius: BorderRadius.circular(AppDimensions.radius_50.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10), // shadow color only
            blurRadius: 4.r,
            spreadRadius: 3.r,
            offset: Offset(4.r, 4.r), // even shadow
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
