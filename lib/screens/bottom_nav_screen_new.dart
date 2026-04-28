import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/screens/achevements_badge_screen.dart';
import 'package:hydrify/screens/analysis_screen.dart';
import 'package:hydrify/screens/drink_reminder_page.dart';
import 'package:hydrify/screens/home_screen.dart';
import 'package:hydrify/screens/settings_screen.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/widgets/health_permission_dialog.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:hydrify/screens/water_intake_timeline/water_intake_timeline_screen.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';
import 'package:hydrify/screens/widgets/new_configuration_dialog.dart';

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

  StreamSubscription<void>? _configSubscription;

  @override
  void initState() {
    super.initState();
    _configSubscription = SharedPrefsHelper.configUpdateStream.stream.listen((_) {
      if (mounted) {
        NewConfigurationDialog.show(context);
      }
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

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
        extendBody: false,
        bottomNavigationBar: SizedBox(height: 0, width: 0,),
        body: Stack(
          children: [
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
              child: MultiBlocListener(
                listeners: [
                  BlocListener<HydrationCubit, HydrationState>(
                    listenWhen: (prev, curr) {
                      Console.log(
                          tag: "newlyUnlockedLevel123",
                          value:
                              "${curr.newlyUnlockedLevel} :: ${prev.newlyUnlockedLevel}");
                      if (curr.newlyUnlockedLevel != null &&
                          prev.newlyUnlockedLevel != curr.newlyUnlockedLevel) {
                        return true;
                      }
                      return false;
                    },
                    listener: (context, hydrationState) {
                      // _showLevelUpSnackbar(context, hydrationState.newlyUnlockedLevel!);
                    },
                  ),
                  BlocListener<BottomNavCubit, BottomNavState>(
                    listenWhen: (prev, curr) =>
                        prev.selectedTab != curr.selectedTab,
                    listener: (context, state) {
                      Console.log(
                          tag: "_currentTabSelected", value: state.selectedTab);
                      if (state.selectedTab == BottomNavTab.analysis) {
                        _checkAndShowHealthDialog(context);
                      }
                    },
                  ),
                  BlocListener<BleCubit, BleState>(
                    listenWhen: (prev, curr) =>
                        curr.commandSentTimestamp != prev.commandSentTimestamp &&
                        curr.lastCommandSent != null,
                    listener: (context, state) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(state.message),
                      //     behavior: SnackBarBehavior.floating,
                      //     backgroundColor: Colors.green.shade700,
                      //   ),
                      // );
                    },
                  ),
                ],
                child: BlocBuilder<BottomNavCubit, BottomNavState>(
                  builder: (context, state) {
                    return _buildTabNavigators(state.selectedTab);
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0.h,
              child: SafeArea(
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
            )
          ],
        ),
      ),
    );
  }

  void _showLevelUpSnackbar(BuildContext context, int level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: EdgeInsets.all(AppDimensions.padding_15.w),
          decoration: BoxDecoration(
            color: AppColors.bluegray,
            borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge Icon
              Image.asset(
                "assets/images/goals_new_img.png",
                width: AppDimensions.dim40.w,
                height: AppDimensions.dim40.h,
              ),
              SizedBox(width: AppDimensions.dim12.w),
              // Text Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Achievement Unlocked!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      "Congratulations! You've reached Level $level",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndShowHealthDialog(BuildContext context) async {
    final userEmail = await SharedPrefsHelper.getUserEmail();
    final isGuest = userEmail == "guest_user";

    if (!isGuest) {
      final alreadyRequested =
          await SharedPrefsHelper.getHasRequestedHealthPermission();
      Console.log(tag: 'Health Permission', value: alreadyRequested);
      if (!alreadyRequested) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => HealthPermissionDialog(
            onCancel: () => Navigator.pop(dialogContext),
            onAllow: () async {
              Navigator.pop(dialogContext);
              // Request health permissions via HealthService
              final success = await HealthService().requestAuthorization();
              Console.log(
                  tag: 'Health Permission_124', value: success.toString());

              // Mark as requested regardless of outcome to avoid repeated prompts
              await SharedPrefsHelper.setHasRequestedHealthPermission(true);
              if (success) {
                Console.log(tag: 'Health Permission', value: 'Granted');
              } else {
                Console.log(
                    tag: 'Health Permission', value: 'Denied or Cancelled');
              }
            },
          ),
        );
      }
    }
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
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent, // 🔥 MOST IMPORTANT
        ),
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
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => child,
              transitionsBuilder: (_, __, ___, child) => child,
            );
          },
        ),
      ),
    );
  }
}
