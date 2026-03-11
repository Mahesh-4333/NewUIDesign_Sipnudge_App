import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/levelreached.dart';
import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

class AchievementsBadgeScreen extends StatefulWidget {
  const AchievementsBadgeScreen({super.key});

  @override
  State<AchievementsBadgeScreen> createState() =>
      _AchievementsBadgeScreenState();
}

class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
  bool? isGuest;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _loading = true;
  List<HydrationDaySummary> _hydrationData = [];
  int _currentLevel = 0;
  int _dailyWaterGoal = 0;

  bool _didAutoRefresh = false;

  @override
  void initState() {
    super.initState();
    _checkGuestUser();
    _loadHydrationData();
  }

  Future<void> _checkGuestUser() async {
    final userEmail = await SharedPrefsHelper.getUserEmail();
    setState(() {
      isGuest = userEmail == "guest_user";
    });
  }

  Future<void> _loadHydrationData() async {
    setState(() => _loading = true);

    final userGoal = await SharedPrefsHelper.getUserGoal();
    final dailyGoalMl = userGoal ?? 1400;

    final fetchedAll = await _dbHelper.getHydrationSummariesForRange();

    fetchedAll.sort((a, b) => a.date.compareTo(b.date));

    int completedDays = 0;

    for (final summary in fetchedAll) {
      final target =
          summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
      if ((summary.consumed / target) * 100 >= 100) {
        completedDays++;
      }
    }

    if (!mounted) return;

    setState(() {
      _hydrationData = fetchedAll;
      _currentLevel = completedDays.clamp(0, 365);
      _dailyWaterGoal = dailyGoalMl;
      _loading = false;
    });
  }

  String _getWaterIntakeForLevel(int level) {
    if (level <= 0 || _hydrationData.isEmpty) return '0.0L';

    int count = 0;
    for (final summary in _hydrationData) {
      final target =
          summary.target > 0 ? summary.target : _dailyWaterGoal.toDouble();
      if ((summary.consumed / target) * 100 >= 100) {
        count++;
        if (count == level) {
          return '${(summary.consumed / 1000).toStringAsFixed(1)}L';
        }
      }
    }
    return '0.0L';
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didAutoRefresh) {
        _didAutoRefresh = true;
        _loadHydrationData();
      }
    });

    if (isGuest == null || _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _buildRegularScreen();
  }

  // ===================== REGULAR SCREEN + GUEST OVERLAY =====================

  Widget _buildRegularScreen() {
    return BlocBuilder<HydrationCubit, HydrationState>(
        builder: (context, state) {
      return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/app_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        const ConcentricCirclesAnimation(),
                        Positioned(
                          left: AppDimensions.dim75.w,
                          top: AppDimensions.dim90.w,
                          child: getCurrentLevelBadge(
                            state.currentLevel.toString(),
                          ),
                        ),
                        Positioned(
                          top: AppDimensions.dim380.h,
                          left: 0,
                          right: 0,
                          child: getCongratulationsText(
                            state.currentLevel.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.padding_20.w,
                          //vertical: AppDimensions.padding_20.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              AppDimensions.radius_24.r,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .1),
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ]
                        ),
                        child: BlocBuilder<HydrationCubit, HydrationState>(
                            builder: (context, state) {
                          return GridView.builder(
                            itemCount: 52,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.2.r,
                              mainAxisSpacing: 24.h,
                            ),
                            itemBuilder: (context, index) {
                              final level = index + 1;
                              final isUnlocked = level <= state.currentLevel;

                              final intakeInfo =
                                  state.levelToIntakeMap[level] ?? '';

                              return GestureDetector(
                                onTap: () {
                                  if (isUnlocked && !isGuest!) {
                                    showLevelUpDialog(
                                        context, level, intakeInfo);
                                  }
                                },
                                child: getLevelBadges(
                                  level.toString(),
                                  isUnlocked,
                                  intakeInfo,
                                ),
                              );
                            },
                          );
                        })),
                  ),
                ],
              ),
            ),

            // ---------------- GUEST BLUR + DIALOG ----------------
            if (isGuest == true) ...[
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: Platform.isIOS
                      ? AppDimensions.dim340.w
                      : AppDimensions.dim380.w,
                  height: Platform.isIOS
                      ? AppDimensions.dim75.h
                      : AppDimensions.dim75.h,
                  margin:
                      EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: Platform.isIOS
                        ? AppDimensions.dim20.w
                        : AppDimensions.dim11.w,
                    vertical: Platform.isIOS
                        ? AppDimensions.dim16.h
                        : AppDimensions.dim13.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius_100.r),
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
          ],
        ),
      );
    });
  }

  Widget getCurrentLevelBadge(String level) {
    final int currentLevelNum = int.tryParse(level) ?? 0;
    final bool hasAchievedAnyLevel = currentLevelNum > 0;
    return SizedBox(
      width: AppDimensions.dim330.w,
      height: AppDimensions.dim320.h,
      child: Stack(
        children: [
          // Show different badge based on unlock status
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(-16.w, 0),
                child: Image.asset(
                  hasAchievedAnyLevel
                      ? "assets/images/goals_new_img.png"
                      : "assets/images/level_lock_img1.png",
                  width: hasAchievedAnyLevel
                      ? AppDimensions.dim330.w
                      : AppDimensions.dim280.w,
                  height: hasAchievedAnyLevel
                      ? AppDimensions.dim320.h
                      : AppDimensions.dim280.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Positioned.fill(
          //   child: Align(
          //     alignment: Alignment.center,
          //     child: Transform.translate(
          //       offset: Offset(-16.w, 0),
          //       child: Image.asset(
          //         isCurrentLevelUnlocked
          //             ? "assets/images/goals_new_img.png" // Unlocked - colored badge
          //             : "assets/images/level_lock_img1.png", // Locked - grey badge
          //         width: isCurrentLevelUnlocked
          //             ? AppDimensions.dim330.w
          //             : AppDimensions.dim280.w,
          //         height: isCurrentLevelUnlocked
          //             ? AppDimensions.dim320.h
          //             : AppDimensions.dim280.h,
          //         fit: BoxFit.contain,
          //       ),
          //     ),
          //   ),
          // ),

          // Show level number only if unlocked
          if (hasAchievedAnyLevel)
            Positioned(
              left: AppDimensions.dim100.w,
              top: AppDimensions.dim105.h,
              child: SizedBox(
                width: AppDimensions.dim100.w,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF16446F),
                      Color(0xFF2569A9),
                      Color(0xFF59ADFB),
                    ],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  blendMode: BlendMode.srcIn,
                  child: Transform.translate(
                    offset: Offset(0, -5.h),
                    child: Text(
                      level,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontStyles.fontSize_80.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        fontFamily: AppFontStyles.poppinsFamily,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget getLevelBadges(String level, bool isUnlocked, String waterIntake) {
    return SizedBox(
      height: isUnlocked ? AppDimensions.dim137.h : AppDimensions.dim1.h,
      width: AppDimensions.dim115.w,
      child: Stack(
        children: [
          // Badge image - locked or unlocked
          Align(
            alignment: Alignment.topCenter,
            child: isUnlocked
                ? Image.asset(
                    "assets/images/goals_levels_img.png",
                    width: AppDimensions.dim107.w,
                    height: AppDimensions.dim111.h,
                  )
                : Padding(
                    padding: EdgeInsets.only(
                        top: AppDimensions.dim22.h), // 🔽 shift down
                    child: Image.asset(
                      "assets/images/level_lock_img1.png",
                      width: AppDimensions.dim70.w,
                      height: AppDimensions.dim70.h,
                    ),
                  ),
          ),

          // Level number - only show on unlocked badges
          if (isUnlocked)
            Positioned.fill(
              child: Align(
                alignment: Platform.isIOS
                    ? const Alignment(0, -0.25)
                    : const Alignment(0, -0.1),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF16446F),
                      Color(0xFF2569A9),
                      Color(0xFF59ADFB),
                    ],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    level,
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.extraBoldFontVariation],
                      fontSize: AppFontStyles.fontSize_28,
                    ),
                  ),
                ),
              ),
            ),

          // Level text and water intake
          Positioned(
            top: isUnlocked ? AppDimensions.dim74.h : AppDimensions.dim75.h,
            left: isUnlocked ? AppDimensions.dim5.w : 0.w,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isUnlocked ? 'Level $level' : 'Level $level',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.bluegray
                        : AppColors.bluegray.withOpacity(0.5),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    fontSize: AppFontStyles.fontSize_14,
                  ),
                ),
                SizedBox(height: AppDimensions.dim4.h),
                Text(
                  isUnlocked ? 'Water Intake: $waterIntake' : '0',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.bluegray
                        : AppColors.bluegray.withOpacity(0.5),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                    fontSize: AppFontStyles.fontSize_10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget getCongratulationsText(String level) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${AppStrings.levelreach} $level!',
            style: TextStyle(
              color: AppColors.bluegray,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontSize: AppFontStyles.fontSize_20.sp,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: AppDimensions.dim10.h),
          BlocBuilder<BleCubit, BleState>(buildWhen: (previous, current) {
            if (previous.currentHydrationValue !=
                current.currentHydrationValue) {
              return true;
            }
            return false;
          }, builder: (context, state) {
            return FutureBuilder<(double, double)>(future: () async {
              final history = await context
                  .read<BottleDataCubit>()
                  .getCurrentDayHistory();

              double waterVolumeConsumed = history;
              double remainingIntakeWater = await WaterConsumptionCalculator
                  .calculateRemainingPercentage(waterVolumeConsumed);

              return (remainingIntakeWater, waterVolumeConsumed);
            }(), builder: (context, snapshot) {
              final (remainingIntakeWater, waterVolumeConsumed) =
                  snapshot.data ?? (0.0, 0.0);

              return Text(
                AppStrings.congratulations(waterVolumeConsumed.toStringAsFixed(0)),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_14.sp,
                ),
              );
            });
          }),

        ],
      ),
    );
  }
}
