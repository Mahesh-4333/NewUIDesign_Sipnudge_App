import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/screens/widgets/help&support_widgets/help&support_menu_items.dart';

class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => HelpAndSupportCubit(),
//       child: const _HelpAndSupportView(),
//     );
//   }
// }

// class _HelpAndSupportView extends StatelessWidget {
//   const _HelpAndSupportView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppStrings.helpandsupport,
          style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_AppBar,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                AppFontStyles.boldFontVariation,
              ]),
        ),
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            "assets/images/back_ic.svg",
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/app_background.png"), // your image path
            fit: BoxFit.cover,
          ),
          // gradient: LinearGradient(
          //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Top Header
              // Padding(
              //   padding: EdgeInsets.only(
              //     top: AppDimensions.dim40.h,
              //     left: AppDimensions.dim20.w,
              //     right: AppDimensions.dim20.w,
              //   ),
              //   child: Row(
              //     children: [
              //       SizedBox(
              //         width: AppDimensions.dim40.w,
              //         height: AppDimensions.dim40.h,
              //         child: IconButton(
              //           onPressed: () => Navigator.pop(context),
              //           icon: Icon(
              //             Icons.arrow_back,
              //             color: AppColors.black,
              //             size: AppFontStyles.fontSize_30.sp,
              //           ),
              //         ),
              //       ),
              //       SizedBox(width: AppDimensions.dim80.w),
              //       Text(
              //         AppStrings.helpandsupport,
              //         style: TextStyle(
              //           color: AppColors.bluegray,
              //           fontSize: AppFontStyles.fontSize_24.sp,
              //           fontFamily: AppFontStyles.urbanistFontFamily,
              //           fontVariations: [
              //             FontVariation(
              //               'wght',
              //               AppFontStyles.boldFontVariation.value,
              //             ),
              //           ],
              //           // fontWeight: FontWeight.w700,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              SizedBox(height: AppDimensions.dim30.h),

              // 🔹 Menu Items
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim20.w,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radius_16,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.10,
                        ), // shadow color only
                        blurRadius: 2.r,
                        spreadRadius: 3.r,
                        offset: Offset(3.5.r, 3.5.r), // even shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      HelpMenuItem(
                        title: AppStrings.faq,
                        iconPathArrow: ("assets/arrow.png"),
                        route: "faq",
                      ),
                      HelpMenuItem(
                        title: AppStrings.contactsupport,
                        iconPathArrow: ("assets/arrow.png"),
                        route: "contact_support",
                      ),
                      HelpMenuItem(
                        title: AppStrings.privacyPolicy,
                        iconPathArrow: ("assets/arrow.png"),
                        //route: "/privacypolicy",
                        url: "https://sipnudge.com/policies/privacy-policy",
                      ),
                      HelpMenuItem(
                        title: AppStrings.termsAndConditions,
                        iconPathArrow: ("assets/arrow.png"),
                        //route: "/termsofservices",
                        url: "https://sipnudge.com/policies/terms-of-service",
                      ),
                      HelpMenuItem(
                        title: AppStrings.aboutus,
                        iconPathArrow: ("assets/arrow.png"),
                        //route: "/aboutus",
                        url: "https://sipnudge.com/pages/about-us",
                      ),
                    ],
                  ),
                ),
              ),

              // //SizedBox(height: ),
              // const Spacer(),

              // // 🔹 Bottom Navigation
              // Padding(
              //     padding: EdgeInsets.only(
              //       bottom: AppDimensions.dim5.h,
              //       right: AppDimensions.dim15.w,
              //       left: AppDimensions.dim15.w,
              //     ),
              //     child: AnimatedBottomNavBar()),
            ],
          ),
        ),
      ),
    );
  }
}

//=============================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/help&support/help&support_cubil.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/help&support_widgets/help&support_menu_items.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';

// class HelpAndSupportPage extends StatelessWidget {
//   const HelpAndSupportPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => HelpAndSupportCubit(),
//       child: const _HelpAndSupportView(),
//     );
//   }
// }

// class _HelpAndSupportView extends StatelessWidget {
//   const _HelpAndSupportView();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [AppColors.gradientStart, AppColors.gradientEnd],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // 🔹 Top Header
//               Padding(
//                 padding: EdgeInsets.only(
//                   top: AppDimensions.dim40.h,
//                   left: AppDimensions.dim20.w,
//                   right: AppDimensions.dim20.w,
//                 ),
//                 child: Row(
//                   children: [
//                     SizedBox(
//                       width: AppDimensions.dim40.w,
//                       height: AppDimensions.dim40.h,
//                       child: IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: Icon(
//                           Icons.arrow_back,
//                           color: AppColors.black,
//                           size: AppFontStyles.fontSize_30.sp,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: AppDimensions.dim80.w),
//                     Text(
//                       AppStrings.helpandsupport,
//                       style: TextStyle(
//                         color: AppColors.white,
//                         fontSize: AppFontStyles.fontSize_24.sp,
//                         fontFamily: AppFontStyles.urbanistFontFamily,
//                         fontVariations: [
//                           FontVariation(
//                             'wght',
//                             AppFontStyles.boldFontVariation.value,
//                           ),
//                         ],
//                         // fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: AppDimensions.dim30.h),

//               // 🔹 Menu Items
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: AppDimensions.dim20.w,
//                 ),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppColors.white1A,
//                     borderRadius: BorderRadius.circular(
//                       AppDimensions.radius_16,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(
//                           0.10,
//                         ), // shadow color only
//                         blurRadius: 2.r,
//                         spreadRadius: 3.r,
//                         offset: Offset(3.5.r, 3.5.r), // even shadow
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: const [
//                       HelpMenuItem(
//                         title: AppStrings.faq,
//                         iconPathArrow: ("assets/arrow.png"),
//                         route: "/faq",
//                       ),
//                       HelpMenuItem(
//                         title: AppStrings.contactsupport,
//                         iconPathArrow: ("assets/arrow.png"),
//                         route: "/contact_support",
//                       ),
//                       HelpMenuItem(
//                         title: AppStrings.privacyPolicy,
//                         iconPathArrow: ("assets/arrow.png"),
//                         route: "/privacypolicy",
//                       ),
//                       HelpMenuItem(
//                         title: AppStrings.termsAndConditions,
//                         iconPathArrow: ("assets/arrow.png"),
//                         route: "/termsofservices",
//                       ),
//                       HelpMenuItem(
//                         title: AppStrings.aboutus,
//                         iconPathArrow: ("assets/arrow.png"),
//                         route: "/aboutus",
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               //SizedBox(height: ),
//               const Spacer(),

//               // 🔹 Bottom Navigation
//               Positioned(
//                 left: AppDimensions.dim6.w,
//                 right: AppDimensions.dim6.w,
//                 bottom: AppDimensions.dim6.h,
//                 child: CustomBottomNavBar(
//                   activeTab: 'Home',
//                   onTabSelected: (label) {
//                     NavigationHelper.navigate(context, label);
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//=============================================================================
