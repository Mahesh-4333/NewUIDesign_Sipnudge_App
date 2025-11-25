import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/account&security/account&security_cubit.dart';
import 'package:hydrify/cubit/account&security/account&security_state.dart';
import 'package:hydrify/screens/widgets/account&security_widgets/toggle_state_widget.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';

// import 'package:flutterapp1/widgets/account&security_widgets/toggle_state_widget.dart';

class AccountAndSecurityPage extends StatelessWidget {
  const AccountAndSecurityPage({super.key});

  @override
  // Widget build(BuildContext context) {
  //   return BlocProvider(
  //     create: (_) => AccountSecurityCubit(),
  //     child: const _AccountAndSecurityView(),
  //   );
  // }
// }

// class _AccountAndSecurityView extends StatelessWidget {
//   const _AccountAndSecurityView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header
              Padding(
                padding: EdgeInsets.only(
                  top: AppDimensions.dim40.h,
                  left: AppDimensions.dim20.w,
                  right: AppDimensions.dim20.w,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppDimensions.dim40.w,
                      height: AppDimensions.dim40.w,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.black,
                          size: AppFontStyles.fontSize_30,
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.dim50.w),
                    Text(
                      AppStrings.accountandsecurity,
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

              // Toggle Container
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim20.w,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDimensions.dim16.h,
                    horizontal: AppDimensions.dim20.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white1A,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radius_16.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(
                          0.10,
                        ), // shadow color only
                        blurRadius: AppDimensions.radius_2.r,
                        spreadRadius: AppDimensions.radius_3.r,
                        offset: Offset(
                          AppDimensions.radius_3.r,
                          AppDimensions.radius_3.r,
                        ), // even shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<AccountSecurityCubit, AccountSecurityState>(
                        builder: (context, state) {
                          return ToggleTile(
                            title: AppStrings.biomatricsID,
                            value: state.biometricsEnabled,
                            onChanged: (val) => context
                                .read<AccountSecurityCubit>()
                                .toggleBiometrics(val),
                          );
                        },
                      ),
                      SizedBox(height: AppDimensions.dim12.h),
                      BlocBuilder<AccountSecurityCubit, AccountSecurityState>(
                        builder: (context, state) {
                          return ToggleTile(
                            title: AppStrings.faceID,
                            value: state.faceIdEnabled,
                            onChanged: (val) => context
                                .read<AccountSecurityCubit>()
                                .toggleFaceId(val),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppDimensions.dim20.h),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.dim120.w,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        //color: Color(0xFFEA966F),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radius_100.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.25),
                            offset: Offset(
                              AppDimensions.radius_3.r,
                              AppDimensions.radius_3.r,
                            ),
                            blurRadius: AppDimensions.radius_4.r,
                          ),
                        ],
                      ),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          //backgroundColor: Colors.transparent,
                          backgroundColor: AppColors.firebrick.withOpacity(
                            0.42,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.dim5.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radius_100.r,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.deleteaccount,
                          style: TextStyle(
                            fontSize: AppFontStyles.fontSize_20,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation,
                            ],
                            color: AppColors.lightSalmon,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),

                  ///SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.all(AppDimensions.dim10.w),
                    child: Text(
                      AppStrings.accountremove,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontStyles.fontSize_12.sp,
                        fontVariations: [AppFontStyles.regularFontVariation],
                        color: AppColors.white,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),

              AnimatedBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/account&security/account&security_cubit.dart';
// import 'package:hydrify/cubit/account&security/account&security_state.dart';
// import 'package:hydrify/cubit/profile_screen_in_setting/profile_cubit.dart';
// import 'package:hydrify/cubit/profile_screen_in_setting/profile_state.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/account&security_widgets/toggle_state_widget.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';
// // import 'package:flutterapp1/widgets/account&security_widgets/toggle_state_widget.dart';

// class AccountAndSecurityPage extends StatelessWidget {
//   const AccountAndSecurityPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => AccountSecurityCubit(),
//       child: const _AccountAndSecurityView(),
//     );
//   }
// }

// class _AccountAndSecurityView extends StatelessWidget {
//   const _AccountAndSecurityView();

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
//               // Top Header
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
//                       height: AppDimensions.dim40.w,
//                       child: IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: Icon(
//                           Icons.arrow_back,
//                           color: AppColors.black,
//                           size: AppFontStyles.fontSize_30,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: AppDimensions.dim50.w),
//                     Text(
//                       AppStrings.accountandsecurity,
//                       style: TextStyle(
//                         color: AppColors.white,
//                         fontSize: AppFontStyles.fontSize_24.sp,
//                         fontFamily: AppFontStyles.urbanistFontFamily,
//                         fontVariations: [AppFontStyles.boldFontVariation],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: AppDimensions.dim50.h),

//               // Toggle Container
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: AppDimensions.dim20.w,
//                 ),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                     vertical: AppDimensions.dim16.h,
//                     horizontal: AppDimensions.dim20.w,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.white1A,
//                     borderRadius: BorderRadius.circular(
//                       AppDimensions.radius_16.r,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.black.withOpacity(
//                           0.10,
//                         ), // shadow color only
//                         blurRadius: AppDimensions.radius_2.r,
//                         spreadRadius: AppDimensions.radius_3.r,
//                         offset: Offset(
//                           AppDimensions.radius_3.r,
//                           AppDimensions.radius_3.r,
//                         ), // even shadow
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       BlocBuilder<AccountSecurityCubit, AccountSecurityState>(
//                         builder: (context, state) {
//                           return ToggleTile(
//                             title: AppStrings.biomatricsID,
//                             value: state.biometricsEnabled,
//                             onChanged: (val) => context
//                                 .read<AccountSecurityCubit>()
//                                 .toggleBiometrics(val),
//                           );
//                         },
//                       ),
//                       SizedBox(height: AppDimensions.dim12.h),
//                       BlocBuilder<AccountSecurityCubit, AccountSecurityState>(
//                         builder: (context, state) {
//                           return ToggleTile(
//                             title: AppStrings.faceID,
//                             value: state.faceIdEnabled,
//                             onChanged: (val) => context
//                                 .read<AccountSecurityCubit>()
//                                 .toggleFaceId(val),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               SizedBox(height: AppDimensions.dim20.h),

//               Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: AppDimensions.dim120.w,
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         //color: Color(0xFFEA966F),
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radius_100.r,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.black.withOpacity(0.25),
//                             offset: Offset(
//                               AppDimensions.radius_3.r,
//                               AppDimensions.radius_3.r,
//                             ),
//                             blurRadius: AppDimensions.radius_4.r,
//                           ),
//                         ],
//                       ),
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {},
//                         style: ElevatedButton.styleFrom(
//                           //backgroundColor: Colors.transparent,
//                           backgroundColor: AppColors.firebrick.withOpacity(
//                             0.42,
//                           ),
//                           padding: EdgeInsets.symmetric(
//                             vertical: AppDimensions.dim5.h,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(
//                               AppDimensions.radius_100.r,
//                             ),
//                           ),
//                         ),
//                         child: Text(
//                           AppStrings.deleteaccount,
//                           style: TextStyle(
//                             fontSize: AppFontStyles.fontSize_20,
//                             fontVariations: [
//                               AppFontStyles.semiBoldFontVariation,
//                             ],
//                             color: AppColors.lightSalmon,
//                             fontFamily: AppFontStyles.urbanistFontFamily,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   ///SizedBox(height: 8.h),
//                   Padding(
//                     padding: EdgeInsets.all(AppDimensions.dim10.w),
//                     child: Text(
//                       AppStrings.accountremove,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: AppFontStyles.fontSize_12.sp,
//                         fontVariations: [AppFontStyles.regularFontVariation],
//                         color: AppColors.white,
//                         fontFamily: AppFontStyles.urbanistFontFamily,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Spacer(),

//               Positioned(
//                 left: AppDimensions.dim6.w,
//                 right: AppDimensions.dim6.w,
//                 bottom: AppDimensions.dim6.w,
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

//==============================================================================
