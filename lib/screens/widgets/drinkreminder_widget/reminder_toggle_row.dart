// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';

// // import 'package:flutterapp1/helpers/custom_toggle_switch.dart';

// class ReminderToggleRow extends StatelessWidget {
//   final String title;
//   final bool value;
//   final ValueChanged<bool> onChanged;

//   const ReminderToggleRow({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: AppDimensions.dim10.w,
//         vertical: AppDimensions.dim10.h,
//       ),
//       //padding: EdgeInsets.symmetric(vertical: AppDimensions.dim8.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: AppFontStyles.fontSize_20.sp,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontVariations: [AppFontStyles.fontWeightVariation600],
//             ),
//           ),
//           SwitchTheme(
//             data: SwitchThemeData(
//               thumbColor: WidgetStateProperty.all(AppColors.white),
//               trackColor: WidgetStateProperty.resolveWith((states) {
//                 if (states.contains(WidgetState.selected)) {
//                   return AppColors.violetBlue;
//                 }
//                 return AppColors.tuna;
//               }),
//               trackOutlineColor: WidgetStateProperty.all(
//                 Colors.white,
//               ), // 👈 White border
//               trackOutlineWidth: WidgetStateProperty.all(
//                 1.5,
//               ), // 👈 Border thickness
//               splashRadius: 0,
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             child: Switch(value: value, onChanged: onChanged),
//           ),
//         ],
//       ),
//     );
//   }
// }

// //============================================================================

// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:hydrify/constants/app_colors.dart';
// // import 'package:hydrify/constants/app_dimensions.dart';
// // import 'package:hydrify/constants/app_font_styles.dart';

// // class ReminderToggleRow extends StatelessWidget {
// //   final String title;
// //   final bool value;
// //   final ValueChanged<bool> onChanged;

// //   const ReminderToggleRow({
// //     super.key,
// //     required this.title,
// //     required this.value,
// //     required this.onChanged,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: EdgeInsets.symmetric(vertical: AppDimensions.dim8.h),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Text(
// //             title,
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: AppFontStyles.fontSize_20.sp,
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontVariations: [
// //                 FontVariation(
// //                   'wght',
// //                   AppFontStyles.semiBoldFontVariation.value,
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Switch(
// //             value: value,
// //             onChanged: onChanged,
// //             activeColor: AppColors.white,
// //             activeTrackColor: AppColors.violetBlue,
// //             inactiveTrackColor: AppColors.white,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// //============================================================================
