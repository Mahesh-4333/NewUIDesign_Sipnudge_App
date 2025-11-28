import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/models/hydration_entry.dart';

void showHydrationPopup(BuildContext context, HydrationSlot slot, int amount) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          width: AppDimensions.dim399.w,
          height: AppDimensions.dim85.h,
          padding: EdgeInsets.only(
            top: AppDimensions.dim5.h,
            left: AppDimensions.dim16.w,
            right: AppDimensions.dim9.w,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
            border: Border.all(
              color: AppColors.greywith80,
              width: 1.w,
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/images/sipnudgeLogo111.png",
                    width: AppDimensions.dim129.w,
                    height: AppDimensions.dim29.h,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stopButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radius_48.r),
                      ),
                      side: BorderSide(
                        color: AppColors.bluegray,
                        width: 1.w,
                      ),
                      minimumSize: Size(
                        AppDimensions.dim112.w,
                        AppDimensions.dim32.h,
                      ),
                    ),
                    child: Text(
                      "Stop",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: AppDimensions.dim4.h,
                left: AppDimensions.dim8.w,
                right: 0,
                child: Text(
                  "Only 10 minutes left for ${slot.label} – Drink $amount ml",
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: AppFontStyles.fontSize_16.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}

// ================= Notification Screen (Deleted) =================

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   State<NotificationScreen> createState() => _NotificationScreen();
// }

// class _NotificationScreen extends State<NotificationScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Container(
//           width: AppDimensions.dim399.w,
//           height: AppDimensions.dim85.h,
//           padding: EdgeInsets.only(
//             top: AppDimensions.dim5.h,
//             left: AppDimensions.dim16.w,
//             right: AppDimensions.dim9.h,
//           ),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
//             border: Border.all(
//               color: AppColors.greywith80,
//               width: 1.w,
//             ),
//           ),
//           child: Stack(children: [
//             Row(children: [
//               // SizedBox(
//               //   width: AppDimensions.dim10.w,
//               // ),
//               Image.asset(
//                 "assets/images/sipnudgeLogo111.png",
//                 width: AppDimensions.dim129.w,
//                 height: AppDimensions.dim29.h,
//               ),
//               SizedBox(
//                 width: AppDimensions.dim120.w,
//               ),
//               ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.stopButtonColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(AppDimensions.radius_48.r),
//                   ),
//                   side: BorderSide(
//                     color: AppColors.bluegray, // ← Border color added
//                     width: 1.w,
//                   ),
//                   minimumSize: Size(
//                     AppDimensions.dim112.w, // Wider button
//                     AppDimensions.dim32.h, // Shorter button
//                   ),
//                 ),
//                 child: Text("Stop",
//                     style: TextStyle(
//                       color: AppColors.white,
//                       fontSize: AppFontStyles.fontSize_16.sp,
//                       fontFamily: AppFontStyles.urbanistFontFamily,
//                       fontVariations: [
//                         AppFontStyles.boldFontVariation,
//                       ],
//                     )),
//               ),
//             ]),
//             Positioned(
//               bottom: AppDimensions.dim4.h,
//               left: AppDimensions.dim8.h,
//               right: 0,
//               child: Text("Only 10 minutes left for Mid-Morning Goal",
//                   style: TextStyle(
//                     color: AppColors.black,
//                     fontSize: AppFontStyles.fontSize_16.sp,
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [
//                       AppFontStyles.semiBoldFontVariation,
//                     ],
//                   )),
//             )
//           ]),
//         ),
//       ),
//     );
//   }
// }
