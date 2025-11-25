// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';

// class ProfileMenuItemWidget extends StatelessWidget {
//   final String iconPath;
//   final String title;
//   final bool isRed;
//   final String iconPathArrow;
//   final VoidCallback onTap;

//   const ProfileMenuItemWidget({
//     super.key,
//     required this.iconPath,
//     required this.title,
//     this.isRed = false,
//     required this.iconPathArrow,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isLogout = title == AppStrings.logout;

//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: AppDimensions.dim16.w,
//           vertical: AppDimensions.dim12.h,
//         ),
//         child: Row(
//           children: [
//             Image.asset(
//               iconPath,
//               width: AppDimensions.dim24.w,
//               height: AppDimensions.dim24.h,
//               fit: BoxFit.contain,
//               color: isLogout ? AppColors.redAccent : AppColors.white,
//               errorBuilder: (_, __, ___) => Icon(
//                 Icons.error,
//                 color: AppColors.redAccent,
//                 size: AppFontStyles.fontSize_22.sp,
//               ),
//             ),
//             SizedBox(width: AppDimensions.dim16.w),
//             Text(
//               title,
//               style: TextStyle(
//                 color: isRed ? AppColors.redAccent : AppColors.white,
//                 fontFamily: AppFontStyles.urbanistFontFamily,
//                 fontVariations: [
//                   FontVariation('wght', AppFontStyles.boldFontVariation.value),
//                 ],
//                 fontSize: AppFontStyles.fontSize_18.sp,
//               ),
//             ),
//             const Spacer(),
//             if (!isRed)
//               Image.asset(
//                 iconPathArrow,
//                 width: AppDimensions.dim9.w,
//                 height: AppDimensions.dim16.h,
//                 color: AppColors.white,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
