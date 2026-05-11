import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/widgets/chart_widgets/custom_chart_data_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/drink_types_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/today_goal_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/analysis_hydration_slots_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/food_scanner_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/water_card_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/log_hydration_widget.dart';
import 'package:hydrify/screens/widgets/date_filter_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool? isGuest;
  bool isLoggingActive = false;

  @override
  void initState() {
    super.initState();
    _checkGuestUser();
  }

  Future<void> _checkGuestUser() async {
    final userEmail = await SharedPrefsHelper.getUserEmail();
    setState(() {
      isGuest = userEmail == "guest_user";
    });
    print('🔍 DEBUG Analysis: isGuest = $isGuest, email = $userEmail');
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking guest status
    if (isGuest == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/app_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.bluegray,
            ),
          ),
        ),
      );
    }

    // If guest, show blur screen with dialog
    if (isGuest!) {
      return _buildGuestScreen();
    }

    // If regular user, show normal analysis screen
    return _buildRegularScreen();
  }

  // Guest user screen with blur and dialog
  Widget _buildGuestScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background content
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/app_background.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(
                  top: AppDimensions.defaultPadding.w,
                  bottom: AppDimensions.dim200.h,
                ),
                child: ListView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    if (!isLoggingActive) ...[
                      const DateFilterWidget(),
                      SizedBox(height: AppDimensions.dim25.h),
                    ],
                    WaterCardWidget(
                      isExpanded: isLoggingActive,
                      onTap: () {
                        setState(() {
                          isLoggingActive = !isLoggingActive;
                        });
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        layoutBuilder: (Widget? currentChild,
                            List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: isLoggingActive
                            ? Column(
                                key: const ValueKey('logging'),
                                children: [
                                  SizedBox(height: AppDimensions.dim20.h),
                                  const LogHydrationWidget(),
                                ],
                              )
                            : Column(
                                key: const ValueKey('dashboard'),
                                children: [
                                  SizedBox(height: AppDimensions.dim25.h),
                                  const CustomChartDataWidget(),
                                  SizedBox(height: AppDimensions.dim25.h),
                                  const DrinkTypesWidget(),
                                  SizedBox(height: AppDimensions.dim25.h),
                                  const TodayGoalWidget(),
                                  SizedBox(height: AppDimensions.dim25.h),
                                  const AnalysisHydrationSlotsWidget(),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: AppColors.black.withOpacity(0.10),
              ),
            ),
          ),

          // Dialog box
          Center(
            child: Container(
              width: Platform.isIOS
                  ? AppDimensions.dim340.w
                  : AppDimensions.dim380.w,
              height: Platform.isIOS
                  ? AppDimensions.dim75.h
                  : AppDimensions.dim75.h,
              margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
              padding: EdgeInsets.symmetric(
                horizontal: Platform.isIOS
                    ? AppDimensions.dim20.w
                    : AppDimensions.dim11.w,
                vertical: Platform.isIOS
                    ? AppDimensions.dim16.h
                    : AppDimensions.dim13.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/guest_dialog.png",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Text(
                "Connect to Sipnudge bottle to access analysis",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontFamily: AppFontStyles.museoModernoFontFamily,
                  fontSize: AppFontStyles.fontSize_16.sp,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Regular user screen
  Widget _buildRegularScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              top: AppDimensions.defaultPadding.w,
              bottom: AppDimensions.dim20.w,
            ),
            child: ListView(
              cacheExtent: 1000,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: !isLoggingActive
                      ? Column(
                          children: [
                            const DateFilterWidget(),
                            SizedBox(height: AppDimensions.dim25.h),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                WaterCardWidget(
                  isExpanded: isLoggingActive,
                  onTap: () {
                    setState(() {
                      isLoggingActive = !isLoggingActive;
                    });
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    reverseDuration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    // transitionBuilder:
                    //     (Widget child, Animation<double> animation) {
                    //   final isOpening =
                    //       child.key == const ValueKey('logging_reg');

                    //   return SlideTransition(
                    //     position: Tween<Offset>(
                    //       begin:
                    //           isOpening ? const Offset(0, -0.01) : Offset.zero,
                    //       end: Offset.zero,
                    //     ).animate(animation),
                    //     child: FadeTransition(
                    //       opacity: animation,
                    //       child: child,
                    //     ),
                    //   );
                    // },
                    // layoutBuilder:
                    //     (Widget? currentChild, List<Widget> previousChildren) {
                    //   return Stack(
                    //     alignment: Alignment.topCenter,
                    //     children: <Widget>[
                    //       ...previousChildren,
                    //       if (currentChild != null) currentChild,
                    //     ],
                    //   );
                    // },
                    child: isLoggingActive
                        ? Column(
                            key: const ValueKey('logging_reg'),
                            children: [
                              SizedBox(height: AppDimensions.dim20.h),
                              const LogHydrationWidget(),
                            ],
                          )
                        : Column(
                            key: const ValueKey('dashboard_reg'),
                            children: [
                              SizedBox(height: AppDimensions.dim25.h),
                              const CustomChartDataWidget(),
                              SizedBox(height: AppDimensions.dim25.h),
                              const DrinkTypesWidget(),
                              SizedBox(height: AppDimensions.dim25.h),
                              const TodayGoalWidget(),
                              SizedBox(height: AppDimensions.dim25.h),
                              const FoodScannerWidget(),
                              SizedBox(height: AppDimensions.dim25.h),
                              const AnalysisHydrationSlotsWidget(),
                            ],
                          ),
                  ),
                ),
                SizedBox(
                  height: AppDimensions.dim120.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
