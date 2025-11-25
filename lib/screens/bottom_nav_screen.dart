// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';

// import 'package:hydrify/screens/analysis_screen.dart';
// import 'package:hydrify/screens/home_screen.dart';
// import 'package:hydrify/screens/settings_screen.dart';
// import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

// class BottomNavScreen extends StatefulWidget {
//   const BottomNavScreen({super.key});

//   @override
//   State<BottomNavScreen> createState() => _BottomNavScreenState();
// }

// class _BottomNavScreenState extends State<BottomNavScreen>
//     with SingleTickerProviderStateMixin {
//   late PersistentTabController _tabController;

//   @override
//   void initState() {
//     _tabController = PersistentTabController(initialIndex: 1);
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PersistentTabView(
//       controller: _tabController,
//       navBarHeight: AppDimensions.navBarHeight.h,
//       backgroundColor: Colors.transparent,
//       navBarBuilder: (navBarConfig) {
//         return Style1BottomNavBar(
//           navBarConfig: navBarConfig,
//           navBarDecoration: NavBarDecoration(
//             color: Colors.transparent,
//             padding: EdgeInsets.zero,
//           ),
//         );
//       },
//       tabs: [
//         PersistentTabConfig(
//           screen: AnalysisScreen(),
//           item: ItemConfig(
//             icon: SvgPicture.asset(
//               "assets/images/analysis_ic.svg",
//             ),
//             activeForegroundColor: Colors.white,
//             textStyle: TextStyle(
//               color: AppColors.white,
//               fontSize: AppFontStyles.fontSize_14,
//               fontVariations: [
//                 AppFontStyles.boldFontVariation,
//               ],
//             ),
//             title: AppStrings.analysis,
//           ),
//         ),
//         PersistentTabConfig(
//           screen: HomeScreen(),
//           item: ItemConfig(
//             textStyle: TextStyle(
//               color: AppColors.white,
//               fontSize: AppFontStyles.fontSize_14,
//               fontVariations: [
//                 AppFontStyles.boldFontVariation,
//               ],
//             ),
//             activeForegroundColor: Colors.white,
//             icon: SvgPicture.asset(
//               "assets/images/home_ic.svg",
//             ),
//             title: AppStrings.home,
//           ),
//         ),
//         PersistentTabConfig(
//           screen: SettingsScreen(),
//           item: ItemConfig(
//             textStyle: TextStyle(
//               color: AppColors.white,
//               fontSize: AppFontStyles.fontSize_14,
//               fontVariations: [
//                 AppFontStyles.boldFontVariation,
//               ],
//             ),
//             activeForegroundColor: Colors.white,
//             icon: SvgPicture.asset("assets/images/settings_ic.svg"),
//             title: AppStrings.setting,
//           ),
//         ),
//       ],
//     );
//   }
// }
