import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/screens/achevements_badge_screen.dart';
import 'package:hydrify/screens/analysis_screen.dart';
import 'package:hydrify/screens/drink_reminder_page.dart';
import 'package:hydrify/screens/home_screen.dart';
import 'package:hydrify/screens/settings_screen.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/water_intake_timeline_screen.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';

class BottomNavScreenNew extends StatefulWidget {
  const BottomNavScreenNew({super.key});

  @override
  State<BottomNavScreenNew> createState() => _BottomNavScreenNewState();
}

class _BottomNavScreenNewState extends State<BottomNavScreenNew> {
  // One navigator key per tab
  final Map<BottomNavTab, GlobalKey<NavigatorState>> _navigatorKeys = {
    BottomNavTab.home: GlobalKey<NavigatorState>(),
    BottomNavTab.analysis: GlobalKey<NavigatorState>(),
    BottomNavTab.reports: GlobalKey<NavigatorState>(),
    BottomNavTab.settings: GlobalKey<NavigatorState>(),
  };

  Future<bool> _onWillPop() async {
    final selectedTab = context.read<BottomNavCubit>().state.selectedTab;
    final currentNavigator = _navigatorKeys[selectedTab]!.currentState;

    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false; // don't pop the whole app
    }

    // If current tab's stack is at root, allow system back (exit / previous screen)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppDimensions.defaultPadding.w,
              right: AppDimensions.defaultPadding.w,
              bottom: AppDimensions.dim28.h,
            ),
            child: SizedBox(
              height: AppDimensions.dim88.h,
              child: const AnimatedBottomNavBar(),
            ),
          ),
        ),
        body: Container(
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
              return _buildTabNavigators(state.selectedTab);
            },
          ),
        ),
      ),
    );
  }

  /// Builds all tab Navigators and shows only the selected one using Offstage.
  Widget _buildTabNavigators(BottomNavTab selectedTab) {
    return Stack(
      children: [
        _buildOffstageNavigator(
          tab: BottomNavTab.home,
          selectedTab: selectedTab,
          child: HomeScreen(),
        ),
        _buildOffstageNavigator(
          tab: BottomNavTab.analysis,
          selectedTab: selectedTab,
          child: const AnalysisScreen(),
        ),
        _buildOffstageNavigator(
          tab: BottomNavTab.reports,
          selectedTab: selectedTab,
          child: AchievementsBadgeScreen(),
        ),
        _buildOffstageNavigator(
          tab: BottomNavTab.settings,
          selectedTab: selectedTab,
          child: const SettingScreen(),
        ),
      ],
    );
  }

  Widget _buildOffstageNavigator({
    required BottomNavTab tab,
    required BottomNavTab selectedTab,
    required Widget child,
  }) {
    final navigatorKey = _navigatorKeys[tab]!;

    return Offstage(
      offstage: selectedTab != tab,
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          if (tab == BottomNavTab.settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (_) => const SettingScreen(),
                  settings: settings,
                );
              case '/personalinfo':
                return MaterialPageRoute(
                  builder: (_) => UserInfoInputScreen(fromSettings: true),
                  settings: settings,
                );
              case '/drinkreminder':
                return MaterialPageRoute(
                  builder: (_) => const DrinkReminderPage(),
                  settings: settings,
                );

              case '/waterintaketimeline':
                return MaterialPageRoute(
                  builder: (_) => const WaterIntakeTimelineScreen(),
                  settings: settings,
                );
              // add other setting routes here...
            }
          }
          // You can expand this later with named routes if needed
          return MaterialPageRoute(
            builder: (_) => child,
            settings: settings,
          );
        },
      ),
    );
  }
}
