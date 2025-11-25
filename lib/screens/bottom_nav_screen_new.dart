import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/screens/achevements_badge_screen.dart';

import 'package:hydrify/screens/analysis_screen.dart';
import 'package:hydrify/screens/home_screen.dart';
import 'package:hydrify/screens/settings_screen.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';

class BottomNavScreenNew extends StatefulWidget {
  const BottomNavScreenNew({super.key});

  @override
  State<BottomNavScreenNew> createState() => _BottomNavScreenNewState();
}

class _BottomNavScreenNewState extends State<BottomNavScreenNew> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main Screen Content
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
              ),
            ),
            child: BlocBuilder<BottomNavCubit, BottomNavState>(
              builder: (context, state) {
                return _buildScreenContent(state.selectedTab);
              },
            ),
          ),

          // Floating Nav Bar
          Positioned(
            left: AppDimensions.defaultPadding.w,
            right: AppDimensions.defaultPadding.w,
            bottom: AppDimensions.dim28.h,
            child: SizedBox(
              height: AppDimensions.dim88.h,
              child: const AnimatedBottomNavBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenContent(BottomNavTab selectedTab) {
    switch (selectedTab) {
      case BottomNavTab.home:
        return HomeScreen();
      case BottomNavTab.analysis:
        return const AnalysisScreen();
      case BottomNavTab.reports:
        return AchievementsBadgeScreen();
      case BottomNavTab.settings:
        return const SettingScreen();
    }
  }
}
