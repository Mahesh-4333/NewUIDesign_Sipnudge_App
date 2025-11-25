// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/linkaccounts/link_accounts_cubit.dart';
// import 'package:hydrify/cubit/linkaccounts/link_accounts_state.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/link_accounts_widgets/social_media_button_widget.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';

// class LinkAccountsPage extends StatelessWidget {
//   const LinkAccountsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => LinkAccountsCubit(),
//       child: Scaffold(
//         body: Container(
//           width: AppDimensions.dim1.sw, // full screen width
//           height: AppDimensions.dim1.sh, // full screen height
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.gradientStart, AppColors.gradientEnd],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: SafeArea(
//             child: Stack(
//               children: [
//                 /// Page Content
//                 Column(
//                   children: [
//                     /// 🔹 Top user info
//                     Padding(
//                       padding: EdgeInsets.only(
//                         top: AppDimensions.dim40.h,
//                         left: AppDimensions.dim20.w,
//                         right: AppDimensions.dim20.w,
//                       ),
//                       child: Row(
//                         children: [
//                           IconButton(
//                             onPressed: () => Navigator.pop(context),
//                             icon: Icon(
//                               Icons.arrow_back,
//                               color: AppColors.black,
//                               size: AppFontStyles.fontSize_30.sp,
//                             ),
//                           ),
//                           SizedBox(width: 70.w),
//                           Text(
//                             AppStrings.linkaccounts,
//                             style: TextStyle(
//                               color: AppColors.white,
//                               fontSize: AppFontStyles.fontSize_24.sp,
//                               fontFamily: AppFontStyles.urbanistFontFamily,
//                               fontVariations: [
//                                 FontVariation(
//                                   'wght',
//                                   AppFontStyles.boldFontVariation.value,
//                                 ),
//                               ],
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     SizedBox(height: AppDimensions.dim50.h),

//                     /// 🔹 Social Buttons
//                     BlocBuilder<LinkAccountsCubit, LinkAccountsState>(
//                       builder: (context, state) {
//                         return Column(
//                           children: [
//                             Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 20.w),
//                               child: buildSocialButton(
//                                 iconPath: 'assets/google_icon.png',
//                                 label: 'Google',
//                                 label1: state.connectedAccounts['Google']!
//                                     ? 'Connected'
//                                     : 'Connect',
//                                 onPressed: () => context
//                                     .read<LinkAccountsCubit>()
//                                     .toggleConnection("Google"),
//                               ),
//                             ),
//                             SizedBox(height: 20.h),
//                             Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 20.w),
//                               child: buildSocialButton(
//                                 iconPath: 'assets/apple_icon.png',
//                                 label: 'Apple',
//                                 label1: state.connectedAccounts['Apple']!
//                                     ? 'Connected'
//                                     : 'Connect',
//                                 iconColor: const Color(0xFFC89DE9),
//                                 onPressed: () => context
//                                     .read<LinkAccountsCubit>()
//                                     .toggleConnection("Apple"),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     ),

//                     const Spacer(),
//                   ],
//                 ),

//                 /// 🔹 Custom Bottom Nav
//                 Positioned(
//                   left: AppDimensions.dim6.w,
//                   right: AppDimensions.dim6.w,
//                   bottom: AppDimensions.dim6.h,
//                   child: BlocBuilder<LinkAccountsCubit, LinkAccountsState>(
//                     builder: (context, state) {
//                       return CustomBottomNavBar(
//                         activeTab: state.activeTab,
//                         onTabSelected: (label) {
//                           context.read<LinkAccountsCubit>().updateTab(label);
//                           NavigationHelper.navigate(context, label);
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/linkaccounts/link_accounts_cubit.dart';
import 'package:hydrify/cubit/linkaccounts/link_accounts_state.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
import 'package:hydrify/screens/widgets/link_accounts_widgets/social_media_button_widget.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';

class LinkAccountsPage extends StatelessWidget {
  const LinkAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LinkAccountsCubit(),
      child: Scaffold(
        body: Container(
          width: AppDimensions.dim1.sw, // full screen width
          height: AppDimensions.dim1.sh, // full screen height
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                /// Page Content
                Column(
                  children: [
                    /// 🔹 Top user info
                    Padding(
                      padding: EdgeInsets.only(
                        top: AppDimensions.dim40.h,
                        left: AppDimensions.dim20.w,
                        right: AppDimensions.dim20.w,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back,
                              color: AppColors.raisinblack,
                              size: AppFontStyles.fontSize_30.sp,
                            ),
                          ),
                          SizedBox(width: 70.w),
                          Text(
                            AppStrings.linkaccounts,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: AppFontStyles.fontSize_24.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimensions.dim50.h),

                    /// 🔹 Social Buttons
                    BlocBuilder<LinkAccountsCubit, LinkAccountsState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: buildSocialButton(
                                iconPath: 'assets/google_icon.png',
                                label: 'Google',
                                label1: state.connectedAccounts['Google']!
                                    ? 'Connected'
                                    : 'Connect',
                                onPressed: () => context
                                    .read<LinkAccountsCubit>()
                                    .toggleConnection("Google"),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: buildSocialButton(
                                iconPath: 'assets/apple_icon.png',
                                label: 'Apple',
                                label1: state.connectedAccounts['Apple']!
                                    ? 'Connected'
                                    : 'Connect',
                                iconColor: const Color(0xFFC89DE9),
                                onPressed: () => context
                                    .read<LinkAccountsCubit>()
                                    .toggleConnection("Apple"),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(),
                  ],
                ),

                /// 🔹 Custom Bottom Nav
                Positioned(
                    left: AppDimensions.dim15.w,
                    bottom: 0,
                    child: AnimatedBottomNavBar())
              ],
            ),
          ),
        ),
      ),
    );
  }
}
