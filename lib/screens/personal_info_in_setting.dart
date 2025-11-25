// // personal_info_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/cubit/personal_info_in_profile/personal_info_cubit.dart';

// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/personal_info_in_profile/personal_info_state.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';
// import 'package:hydrify/screens/widgets/personal_info_in_profile/personal_info_manu_item.dart';

// class PersonalInfoScreenInProfile extends StatefulWidget {
//   const PersonalInfoScreenInProfile({super.key});

//   @override
//   State<PersonalInfoScreenInProfile> createState() =>
//       _PersonalInfoScreenInProfileState();
// }

// class _PersonalInfoScreenInProfileState
//     extends State<PersonalInfoScreenInProfile> {
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return BlocProvider(
//       create: (_) => PersonalInfoCubit(),
//       child: Scaffold(
//         body: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.gradientStart, AppColors.gradientEnd],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 _buildHeader(context, size),
//                 SizedBox(height: AppDimensions.dim50.h),
//                 _buildInfoCard(),
//                 const Spacer(),
//                 //_buildBottomNav(size),
//                 Positioned(
//                   left: AppDimensions.dim6.w,
//                   right: AppDimensions.dim6.w,
//                   bottom: AppDimensions.dim6.h,
//                   child: CustomBottomNavBar(
//                     activeTab: 'Home',
//                     onTabSelected: (label) {
//                       NavigationHelper.navigate(context, label);
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

//   Widget _buildHeader(BuildContext context, Size size) {
//     return Padding(
//       padding: EdgeInsets.only(
//         top: AppDimensions.dim40.h,
//         left: AppDimensions.dim20.w,
//         right: AppDimensions.dim20.w,
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: Icon(
//               Icons.arrow_back,
//               color: Colors.black,
//               size: AppFontStyles.fontSize_30.sp,
//             ),
//           ),
//           SizedBox(width: AppDimensions.dim50.w),
//           Text(
//             AppStrings.personalInformation,
//             style: TextStyle(
//               color: AppColors.white,
//               fontSize: AppFontStyles.fontSize_24.sp,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontVariations: [
//                 FontVariation('wght', AppFontStyles.boldFontVariation.value),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return BlocBuilder<PersonalInfoCubit, PersonalInfoState>(
//       builder: (context, state) {
//         return Padding(
//           padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.10), // shadow color only
//                   blurRadius: 2.r,
//                   spreadRadius: 3.r,
//                   offset: Offset(3.5.r, 3.5.r), // even shadow
//                 ),
//               ],
//             ),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: AppColors.white1A,
//                 borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
//               ),
//               child: Column(
//                 children: state.personalInfo.entries
//                     .map(
//                       (e) => MenuItem(
//                         title: e.key,
//                         info: e.value,
//                         iconPathArrow: ("assets/arrow.png"),
//                         onTap: () => _handleNavigation(context, e.key),
//                       ),
//                     )
//                     .toList(),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Widget _buildBottomNav(Size size) {
//   void _handleNavigation(BuildContext context, String title) {
//     switch (title) {
//       case 'Gender':
//       case 'Height':
//       case 'Weight':
//       case 'Age':
//         Navigator.pushNamed(context, '/personalinfo');
//         break;
//       case 'Wake-up Time':
//       case 'Bedtime':
//       case 'Activity Level':
//         Navigator.pushNamed(context, '/lifestyleinfo');
//         break;
//       default:
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('$title screen coming soon!')));
//     }
//   }
// }

//=============================================================================

// personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/personal_info_in_profile/personal_info_cubit.dart';
import 'package:hydrify/cubit/personal_info_in_profile/personal_info_state.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';
import 'package:hydrify/screens/widgets/personal_info_in_profile/personal_info_manu_item.dart';

class PersonalInfoScreenInSetting extends StatefulWidget {
  const PersonalInfoScreenInSetting({super.key});

  @override
  State<PersonalInfoScreenInSetting> createState() =>
      _PersonalInfoScreenInSettingstate();
}

class _PersonalInfoScreenInSettingstate
    extends State<PersonalInfoScreenInSetting> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (_) => PersonalInfoCubit(),
      child: Scaffold(
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
                _buildHeader(context, size),
                SizedBox(height: AppDimensions.dim50.h),
                _buildInfoCard(),
                const Spacer(),
                //_buildBottomNav(size),
                AnimatedBottomNavBar()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size size) {
    return Padding(
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
              color: Colors.black,
              size: AppFontStyles.fontSize_30.sp,
            ),
          ),
          SizedBox(width: AppDimensions.dim50.w),
          Text(
            AppStrings.personalInformation,
            style: TextStyle(
              color: AppColors.white,
              fontSize: AppFontStyles.fontSize_24.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                FontVariation('wght', AppFontStyles.boldFontVariation.value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return BlocBuilder<PersonalInfoCubit, PersonalInfoState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10), // shadow color only
                  blurRadius: 2.r,
                  spreadRadius: 3.r,
                  offset: Offset(3.5.r, 3.5.r), // even shadow
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white1A,
                borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
              ),
              child: Column(
                children: state.personalInfo.entries
                    .map(
                      (e) => MenuItem(
                        title: e.key,
                        info: e.value,
                        iconPathArrow: ("assets/arrow.png"),
                        onTap: () => _handleNavigation(context, e.key),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildBottomNav(Size size) {
  void _handleNavigation(BuildContext context, String title) {
    switch (title) {
      case 'Gender':
      case 'Height':
      case 'Weight':
      case 'Age':
        Navigator.pushNamed(context, '/personalinfo');
        break;
      case 'Wake-up Time':
      case 'Bedtime':
      case 'Activity Level':
        Navigator.pushNamed(context, '/lifestyleinfo');
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title screen coming soon!')));
    }
  }
}
