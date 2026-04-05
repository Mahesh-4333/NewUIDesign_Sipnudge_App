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
import 'package:hydrify/screens/widgets/date_filter_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool? isGuest;

  
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
                  bottom: AppDimensions.dim20.w,
                ),
                child: ListView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    DateFilterWidget(),
                    SizedBox(
                      height: AppDimensions.dim25.h,
                    ),
                    CustomChartDataWidget(),
                    SizedBox(
                      height: AppDimensions.dim25.h,
                    ),
                    DrinkTypesWidget(),
                    SizedBox(
                      height: AppDimensions.dim25.h,
                    ),
                    TodayGoalWidget(),
                    SizedBox(
                      height: AppDimensions.dim25.h,
                    ),
                    AnalysisHydrationSlotsWidget(),
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
              children: [
                DateFilterWidget(),
                SizedBox(
                  height: AppDimensions.dim25.h,
                ),
                CustomChartDataWidget(),
                SizedBox(
                  height: AppDimensions.dim25.h,
                ),
                DrinkTypesWidget(),
                SizedBox(
                  height: AppDimensions.dim25.h,
                ),
                TodayGoalWidget(),
                SizedBox(
                  height: AppDimensions.dim25.h,
                ),
                AnalysisHydrationSlotsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
