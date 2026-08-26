import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/cubit/data_analytics/data_analytics_cubit.dart';
import 'package:hydrify/screens/data_n_analytics/data_n_analytics_screen.dart';
import 'package:hydrify/screens/widgets/chart_widgets/custom_chart_data_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/drink_types_widget.dart';
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
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const DateFilterWidget(),
                    SizedBox(height: AppDimensions.dim20.h),
                    _buildHabitConsistencyCard(),
                    SizedBox(height: AppDimensions.dim20.h),
                    const CustomChartDataWidget(),
                    SizedBox(height: AppDimensions.dim20.h),
                    const DrinkTypesWidget(),
                    SizedBox(height: AppDimensions.dim20.h),
                    _buildAnalyticsButton(),
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
                AppLocalizations.of(context)?.connectToBottleAnalysis ??
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
              physics: const BouncingScrollPhysics(),
              children: [
                const DateFilterWidget(),
                SizedBox(height: AppDimensions.dim20.h),
                _buildHabitConsistencyCard(),
                SizedBox(height: AppDimensions.dim20.h),
                const CustomChartDataWidget(),
                SizedBox(height: AppDimensions.dim20.h),
                const DrinkTypesWidget(),
                SizedBox(height: AppDimensions.dim20.h),
                _buildAnalyticsButton(),
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

  Widget _buildHabitConsistencyCard() {
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final habit = state.analyticsData?['habitConsistency'];
        final efficiency = habit?['efficiency']?.toString() ?? '0';
        final streak = habit?['streak']?.toString() ?? '0';
        final percentage =
            state.analyticsData?['monthlyIntake']?['percentage'] ?? 0;
        final l10n = AppLocalizations.of(context);
        final tierLabel = percentage >= 80
            ? (l10n?.eliteTier ?? 'Elite Tier')
            : percentage >= 60
                ? (l10n?.good ?? 'Good')
                : (l10n?.improving ?? 'Improving');

        return Container(
          margin:
              EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.dim12.r),
            border: Border.all(color: AppColors.color_136DEC0D),
            boxShadow: [
              BoxShadow(
                color: AppColors.black40,
                offset: const Offset(0, 1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
              vertical: AppDimensions.dim16.h,
              horizontal: AppDimensions.dim24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      l10n?.habitConsistency ?? "Habit Consistency",
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_18,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                        color: AppColors.color_136DEC.withOpacity(.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      tierLabel,
                      style: TextStyle(
                        color: AppColors.color_136DEC,
                        fontSize: AppFontStyles.fontSize_10,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16.h,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildConsistencyWidget(
                        isStreak: false, value: efficiency),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child:
                        _buildConsistencyWidget(isStreak: true, value: streak),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsistencyWidget({
    required String value,
    required bool isStreak,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStreak
              ? (l10n?.streak ?? "Streak")
              : (l10n?.consistency ?? "Consistency"),
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontSize: AppFontStyles.fontSize_14,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.regularFontVariation],
          ),
        ),
        SizedBox(
          height: 4.h,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "$value${isStreak ? "" : "%"}",
              style: TextStyle(
                color: AppColors.color_0F172A,
                fontSize: AppFontStyles.fontSize_24,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
              ),
            ),
            SizedBox(
              width: 8.w,
            ),
            Visibility(
              visible: isStreak,
              replacement: Icon(
                Icons.verified_outlined,
                size: 20.w,
                color: AppColors.color_22C55E,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n?.days ?? "days",
                    style: TextStyle(
                      color: AppColors.color_64748B,
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 24.w,
                    color: AppColors.color_F97316,
                  )
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 4.h,
        ),
        Text(
          isStreak
              ? (l10n?.consecutiveDaysGoal ??
                  "Consecutive days reaching daily goal")
              : (l10n?.followingScheduleVsOffSlot ??
                  "Following schedule vs off-slot drinking"),
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontSize: AppFontStyles.fontSize_10,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.semiBoldFontVariation],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsButton() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: const Color(0xFFDCDCE2), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DataNAnalyticsScreen(),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD0D7DE),
                      width: 1.w,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    AssetsPath.onboardingAnalytics,
                    width: 30.w,
                    height: 30.w,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n?.analytics ?? "Analytics",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 18.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n?.hydrationData ?? "Hydration Data",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xff64748B),
                          fontSize: 13.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 48.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PulseIconPainter({
    required this.color,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.5);
    path.lineTo(w * 0.22, h * 0.5);
    path.lineTo(w * 0.35, h * 0.72);
    path.lineTo(w * 0.52, h * 0.22);
    path.lineTo(w * 0.68, h * 0.78);
    path.lineTo(w * 0.78, h * 0.5);
    path.lineTo(w, h * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
