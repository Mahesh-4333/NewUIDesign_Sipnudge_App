// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';

// Widget buildSocialButton({
//   required String iconPath,
//   required String label,
//   required String label1,
//   Color? iconColor,
//   required VoidCallback onPressed,
// }) {
//   return Container(
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
//       boxShadow: [
//         BoxShadow(
//           color: AppColors.black40,
//           offset: Offset(0, 4.h), // vertical offset responsive
//           blurRadius: 6.r, // blur radius responsive
//         ),
//       ],
//     ),
//     child: ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         padding: EdgeInsets.symmetric(
//           horizontal: AppDimensions.dim20.w,
//           vertical: AppDimensions.dim16.h,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           /// Icon
//           Image.asset(
//             iconPath,
//             width: AppDimensions.dim35.w,
//             height: AppDimensions.dim35.h,
//             color: iconColor,
//           ),

//           SizedBox(width: AppDimensions.dim46.w),

//           /// Label
//           Text(
//             label,
//             style: TextStyle(
//               color: AppColors.raisinblack,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontSize: AppFontStyles.fontSize_18.sp,
//             ),
//           ),

//           const Spacer(),

//           /// Connect/Connected Label
//           Text(
//             label1,
//             style: TextStyle(
//               color: AppColors.raisinblack,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontSize: AppFontStyles.fontSize_18.sp,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

//==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

Widget buildSocialButton({
  required String iconPath,
  required String label,
  required String label1,
  Color? iconColor,
  required VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
      boxShadow: [
        BoxShadow(
          color: AppColors.black40,
          offset: Offset(0, 4.h), // vertical offset responsive
          blurRadius: 6.r, // blur radius responsive
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim20.w,
          vertical: AppDimensions.dim16.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// Icon
          Image.asset(
            iconPath,
            width: AppDimensions.dim35.w,
            height: AppDimensions.dim35.h,
            color: iconColor,
          ),

          SizedBox(width: AppDimensions.dim46.w),

          /// Label
          Text(
            label,
            style: TextStyle(
                color: AppColors.raisinblack,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontVariations: [AppFontStyles.boldFontVariation]),
          ),

          const Spacer(),

          /// Connect/Connected Label
          Text(
            label1,
            style: TextStyle(
                color: AppColors.blackforconnect,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontVariations: [AppFontStyles.boldFontVariation]),
          ),
        ],
      ),
    ),
  );
}
