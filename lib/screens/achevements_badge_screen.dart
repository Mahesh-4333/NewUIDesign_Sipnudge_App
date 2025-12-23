import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
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
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ---------------- BASE ACHIEVEMENTS UI ----------------
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
                          _currentLevel.toString(),
                        ),
                      ),
                      Positioned(
                        top: AppDimensions.dim380.h,
                        left: 0,
                        right: 0,
                        child: getCongratulationsText(
                          _currentLevel.toString(),
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
                    ),
                    child: GridView.builder(
                      itemCount: 365,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2.r,
                        mainAxisSpacing: 24.h,
                      ),
                      itemBuilder: (context, index) {
                        final level = index + 1;
                        final isUnlocked = level <= _currentLevel;
                        final intake = _getWaterIntakeForLevel(level);

                        return GestureDetector(
                          onTap: () {
                            if (isUnlocked && !isGuest!) {
                              showLevelUpDialog(context, level, intake);
                            }
                          },
                          child: getLevelBadges(
                            level.toString(),
                            isUnlocked,
                            intake,
                          ),
                        );
                      },
                    ),
                  ),
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
  }

  Widget getCurrentLevelBadge(String level) {
    final int currentLevelNum = int.tryParse(level) ?? 0;
    final bool isCurrentLevelUnlocked = currentLevelNum <= _currentLevel;

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
                  isCurrentLevelUnlocked
                      ? "assets/images/goals_new_img.png" // Unlocked - colored badge
                      : "assets/images/level_lock_img1.png", // Locked - grey badge
                  width: AppDimensions.dim330.w,
                  height: AppDimensions.dim320.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Show level number only if unlocked
          if (isCurrentLevelUnlocked)
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
          Text(
            AppStrings.congratulations(_dailyWaterGoal),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.fontWeightVariation600],
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

//===========================================================================

// import 'dart:io';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/helpers/database_helper.dart';
// import 'package:hydrify/helpers/shared_pref_helper.dart';
// import 'package:hydrify/models/hydration_summary.dart';
// import 'package:hydrify/screens/levelreached.dart';
// import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// class AchievementsBadgeScreen extends StatefulWidget {
//   const AchievementsBadgeScreen({super.key});

//   @override
//   State<AchievementsBadgeScreen> createState() =>
//       _AchievementsBadgeScreenState();
// }

// class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
//   bool? isGuest;
//   final DatabaseHelper _dbHelper = DatabaseHelper();

//   bool _loading = true;
//   List<HydrationDaySummary> _hydrationData = [];
//   int _currentLevel = 0;
//   int _dailyWaterGoal = 0;

//   @override
//   void initState() {
//     super.initState();
//     _checkGuestUser();
//   }

//   // 🔥 KEY FIX: refresh whenever screen becomes active
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _loadHydrationData();
//   }

//   Future<void> _checkGuestUser() async {
//     final userEmail = await SharedPrefsHelper.getUserEmail();
//     if (!mounted) return;

//     setState(() {
//       isGuest = userEmail == "guest_user";
//     });
//   }

//   Future<void> _loadHydrationData() async {
//     setState(() => _loading = true);

//     final userGoal = await SharedPrefsHelper.getUserGoal();
//     final dailyGoalMl = userGoal ?? 1400;

//     final fetchedAll = await _dbHelper.getHydrationSummariesForRange();

//     fetchedAll.sort((a, b) => a.date.compareTo(b.date));

//     int completedDays = 0;

//     for (final summary in fetchedAll) {
//       final target =
//           summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
//       if ((summary.consumed / target) * 100 >= 100) {
//         completedDays++;
//       }
//     }

//     if (!mounted) return;

//     setState(() {
//       _hydrationData = fetchedAll;
//       _currentLevel = completedDays.clamp(0, 365);
//       _dailyWaterGoal = dailyGoalMl;
//       _loading = false;
//     });
//   }

//   String _getWaterIntakeForLevel(int level) {
//     if (level <= 0 || _hydrationData.isEmpty) return '0.0L';

//     final dailyGoalMl = _dailyWaterGoal > 0 ? _dailyWaterGoal : 1400;
//     int count = 0;

//     for (final summary in _hydrationData) {
//       final target =
//           summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
//       if ((summary.consumed / target) * 100 >= 100) {
//         count++;
//         if (count == level) {
//           return '${(summary.consumed / 1000).toStringAsFixed(1)}L';
//         }
//       }
//     }
//     return '0.0L';
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isGuest == null || _loading) {
//       return Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage("assets/images/app_background.png"),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Center(
//             child: CircularProgressIndicator(color: AppColors.bluegray),
//           ),
//         ),
//       );
//     }

//     if (isGuest!) return _buildGuestScreen();
//     return _buildRegularScreen();
//   }

//   // ---------------- GUEST SCREEN ----------------

//   Widget _buildGuestScreen() {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/images/app_background.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Positioned.fill(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
//               child: Container(color: Colors.black.withOpacity(0.1)),
//             ),
//           ),
//           Center(
//             child: Text(
//               "Connect to Sipnudge bottle to access analysis",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: AppColors.bluegray,
//                 fontFamily: AppFontStyles.museoModernoFontFamily,
//                 fontSize: 16.sp,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- REGULAR SCREEN ----------------

//   Widget _buildRegularScreen() {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       body: Container(
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage("assets/images/app_background.png"),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 children: [
//                   const ConcentricCirclesAnimation(),
//                   Positioned(
//                     left: AppDimensions.dim75.w,
//                     top: AppDimensions.dim90.w,
//                     child: getCurrentLevelBadge(
//                       _currentLevel.toString(),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppDimensions.dim380.h,
//                     left: 0,
//                     right: 0,
//                     child: getCongratulationsText(
//                       _currentLevel.toString(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: AppDimensions.padding_20.w,
//                   //vertical: AppDimensions.padding_20.h,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(
//                     top: Radius.circular(AppDimensions.radius_24.r),
//                   ),
//                 ),
//                 child: GridView.builder(
//                   itemCount: 365,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     childAspectRatio: 1.2.r,
//                     mainAxisSpacing: 24.h,
//                   ),
//                   itemBuilder: (context, index) {
//                     final level = index + 1;
//                     final unlocked = level <= _currentLevel;
//                     final intake = _getWaterIntakeForLevel(level);

//                     return GestureDetector(
//                       onTap: unlocked
//                           ? () => showLevelUpDialog(context, level, intake)
//                           : null,
//                       child: getLevelBadges(
//                         level.toString(),
//                         unlocked,
//                         intake,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget getCurrentLevelBadge(String level) {
//     return SizedBox(
//       width: AppDimensions.dim330.w,
//       height: AppDimensions.dim320.h,
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: Align(
//               alignment: Alignment.center,
//               child: Transform.translate(
//                 offset: Offset(-16.w, 0),
//                 child: Image.asset(
//                   "assets/images/goals_new_img.png",
//                   width: AppDimensions.dim330.w,
//                   height: AppDimensions.dim320.h,
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             left: AppDimensions.dim100.w,
//             top: AppDimensions.dim105.h,
//             child: SizedBox(
//               width: AppDimensions.dim100.w,
//               child: ShaderMask(
//                 shaderCallback: (bounds) => const LinearGradient(
//                   colors: [
//                     Color(0xFF16446F),
//                     Color(0xFF2569A9),
//                     Color(0xFF59ADFB),
//                   ],
//                 ).createShader(
//                   Rect.fromLTWH(0, 0, bounds.width, bounds.height),
//                 ),
//                 blendMode: BlendMode.srcIn,
//                 child: Transform.translate(
//                   offset: Offset(0, -5.h),
//                   child: Text(
//                     level,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: AppFontStyles.fontSize_80.sp,
//                       fontVariations: [AppFontStyles.boldFontVariation],
//                       fontFamily: AppFontStyles.poppinsFamily,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget getLevelBadges(String level, bool isUnlocked, String waterIntake) {
//     return SizedBox(
//       height: isUnlocked ? AppDimensions.dim137.h : AppDimensions.dim1.h,
//       width: AppDimensions.dim115.w,
//       child: Stack(
//         children: [
//           // Badge image - locked or unlocked
//           Align(
//             alignment: Alignment.topCenter,
//             child: isUnlocked
//                 ? Image.asset(
//                     "assets/images/goals_levels_img.png",
//                     width: AppDimensions.dim107.w,
//                     height: AppDimensions.dim111.h,
//                   )
//                 : Padding(
//                     padding: EdgeInsets.only(
//                         top: AppDimensions.dim22.h), // 🔽 shift down
//                     child: Image.asset(
//                       "assets/images/level_lock_img1.png",
//                       width: AppDimensions.dim70.w,
//                       height: AppDimensions.dim70.h,
//                     ),
//                   ),
//           ),

//           // Level number - only show on unlocked badges
//           if (isUnlocked)
//             Positioned.fill(
//               child: Align(
//                 alignment: Platform.isIOS
//                     ? const Alignment(0, -0.25)
//                     : const Alignment(0, -0.1),
//                 child: ShaderMask(
//                   shaderCallback: (bounds) => const LinearGradient(
//                     colors: [
//                       Color(0xFF16446F),
//                       Color(0xFF2569A9),
//                       Color(0xFF59ADFB),
//                     ],
//                   ).createShader(
//                     Rect.fromLTWH(0, 0, bounds.width, bounds.height),
//                   ),
//                   blendMode: BlendMode.srcIn,
//                   child: Text(
//                     level,
//                     style: TextStyle(
//                       color: AppColors.white,
//                       fontFamily: AppFontStyles.urbanistFontFamily,
//                       fontVariations: [AppFontStyles.extraBoldFontVariation],
//                       fontSize: AppFontStyles.fontSize_28,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Level text and water intake
//           Positioned(
//             top: isUnlocked ? AppDimensions.dim74.h : AppDimensions.dim75.h,
//             left: isUnlocked ? AppDimensions.dim5.w : 0.w,
//             right: 0,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Text(
//                   isUnlocked ? 'Level $level' : 'Locked',
//                   style: TextStyle(
//                     color: isUnlocked
//                         ? AppColors.bluegray
//                         : AppColors.bluegray.withOpacity(0.5),
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [AppFontStyles.boldFontVariation],
//                     fontSize: AppFontStyles.fontSize_14,
//                   ),
//                 ),
//                 SizedBox(height: AppDimensions.dim4.h),
//                 Text(
//                   isUnlocked ? 'Water Intake: $waterIntake' : '0',
//                   style: TextStyle(
//                     color: isUnlocked
//                         ? AppColors.bluegray
//                         : AppColors.bluegray.withOpacity(0.5),
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [AppFontStyles.regularFontVariation],
//                     fontSize: AppFontStyles.fontSize_10,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget getCongratulationsText(String level) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             '${AppStrings.levelreach} $level!',
//             style: TextStyle(
//               color: AppColors.bluegray,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontSize: AppFontStyles.fontSize_20.sp,
//               fontVariations: [AppFontStyles.boldFontVariation],
//             ),
//           ),
//           SizedBox(height: AppDimensions.dim10.h),
//           Text(
//             AppStrings.congratulations(_dailyWaterGoal),
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontVariations: [AppFontStyles.fontWeightVariation600],
//               color: AppColors.bluegray,
//               fontSize: AppFontStyles.fontSize_14.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ======================== updated ORIGINAL/OLD CODE ===========================

// // import 'dart:io';
// // import 'dart:ui';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:hydrify/constants/app_colors.dart';
// // import 'package:hydrify/constants/app_dimensions.dart';
// // import 'package:hydrify/constants/app_font_styles.dart';
// // import 'package:hydrify/constants/app_strings.dart';
// // import 'package:hydrify/helpers/database_helper.dart';
// // import 'package:hydrify/helpers/shared_pref_helper.dart';
// // import 'package:hydrify/models/hydration_summary.dart';
// // import 'package:hydrify/screens/levelreached.dart';
// // import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// // class AchievementsBadgeScreen extends StatefulWidget {
// //   const AchievementsBadgeScreen({
// //     super.key,
// //   });

// //   @override
// //   State<AchievementsBadgeScreen> createState() =>
// //       _AchievementsBadgeScreenState();
// // }

// // class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
// //   bool? isGuest;
// //   final DatabaseHelper _dbHelper = DatabaseHelper();
// //   bool _loading = true;
// //   List<HydrationDaySummary> _hydrationData = [];
// //   int _currentLevel = 0;
// //   int _dailyWaterGoal = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkGuestUser();
// //     _loadHydrationData();
// //     //_loadDailyWaterGoal();
// //   }

// //   // Future<void> _loadDailyWaterGoal() async {
// //   //   final goal = await SharedPrefsHelper.getWaterGoal();
// //   //   setState(() {
// //   //     _dailyWaterGoal = goal!;
// //   //   });
// //   // }

// //   Future<void> _checkGuestUser() async {
// //     final userEmail = await SharedPrefsHelper.getUserEmail();
// //     setState(() {
// //       isGuest = userEmail == "guest_user";
// //     });
// //     print('🔍 DEBUG: isGuest = $isGuest, email = $userEmail');
// //   }

// //   Future<void> _loadHydrationData() async {
// //     setState(() {
// //       _loading = true;
// //     });

// //     // Get user's daily water goal from SharedPreferences
// //     final userGoal = await SharedPrefsHelper.getUserGoal();
// //     final dailyGoalMl = userGoal ?? 1400; // Default to 1400ml if not set

// //     print('🔍 DEBUG: User daily goal: ${dailyGoalMl}ml');

// //     // Get last 365 days of hydration data
// //     final List<HydrationDaySummary> fetchedAll =
// //         await _dbHelper.getHydrationSummariesForRange();

// //     // Sort by date ascending
// //     fetchedAll.sort((a, b) => a.date.compareTo(b.date));

// //     // Calculate current level based on days where goal was reached (>= 100%)
// //     int completedDays = 0;
// //     List<String> completedDates = []; // For debugging

// //     for (final summary in fetchedAll) {
// //       // Calculate percentage based on consumed vs target (or user goal)
// //       final targetGoal =
// //           summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
// //       final percentage = (summary.consumed / targetGoal) * 100;

// //       // STRICT CHECK: Only count if percentage is >= 100%
// //       if (percentage >= 100.0) {
// //         completedDays++;
// //         completedDates.add(
// //             '${summary.date.toString().split(' ')[0]} (${percentage.toStringAsFixed(1)}%)');
// //         print(
// //             '🔍 DEBUG: Day ${summary.date.toString().split(' ')[0]} - Consumed: ${summary.consumed}ml, Target: ${targetGoal}ml, ${percentage.toStringAsFixed(1)}% ✅ UNLOCKED');
// //       } else {
// //         print(
// //             '🔍 DEBUG: Day ${summary.date.toString().split(' ')[0]} - Consumed: ${summary.consumed}ml, Target: ${targetGoal}ml, ${percentage.toStringAsFixed(1)}% ❌ LOCKED');
// //       }
// //     }

// //     // Calculate level: 1 completed day = Level 1, maximum 365 levels
// //     final calculatedLevel = completedDays.clamp(0, 365);

// //     if (!mounted) return;
// //     setState(() {
// //       _hydrationData = fetchedAll;
// //       _currentLevel = calculatedLevel;
// //       _dailyWaterGoal = dailyGoalMl;
// //       _loading = false;
// //     });

// //     print('🔍 DEBUG: ========================================');
// //     print('🔍 DEBUG: Total days with data: ${fetchedAll.length}');
// //     print('🔍 DEBUG: Days with 100%+ completion: $completedDays');
// //     print('🔍 DEBUG: Completed dates: $completedDates');
// //     print('🔍 DEBUG: Current Level: $_currentLevel');
// //     print('🔍 DEBUG: Daily Goal: ${dailyGoalMl}ml');
// //     print('🔍 DEBUG: ========================================');
// //   }

// //   // Get water intake amount for each level from actual data
// //   String _getWaterIntakeForLevel(int level) {
// //     if (level <= 0 || _hydrationData.isEmpty) return '0.0L';

// //     // Get user's daily water goal
// //     final dailyGoalMl = _dailyWaterGoal > 0 ? _dailyWaterGoal : 1400;

// //     // Find the day that unlocked this level (Nth day with 100% completion)
// //     int completedCount = 0;
// //     for (final summary in _hydrationData) {
// //       final targetGoal =
// //           summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
// //       final percentage = (summary.consumed / targetGoal) * 100;

// //       // STRICT CHECK: Only count if percentage is >= 100%
// //       if (percentage >= 100.0) {
// //         completedCount++;
// //         if (completedCount == level) {
// //           // Return the consumed amount for this level
// //           return '${(summary.consumed / 1000).toStringAsFixed(1)}L';
// //         }
// //       }
// //     }

// //     // Fallback if not found
// //     return '${(level * 0.5).toStringAsFixed(1)}L';
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Show loading while checking guest status or loading data
// //     if (isGuest == null || _loading) {
// //       return Scaffold(
// //         body: Container(
// //           decoration: BoxDecoration(
// //             image: DecorationImage(
// //               image: AssetImage("assets/images/app_background.png"),
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //           child: Center(
// //             child: CircularProgressIndicator(
// //               color: AppColors.bluegray,
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     // If guest, show blur screen with dialog
// //     if (isGuest!) {
// //       return _buildGuestScreen();
// //     }

// //     // If regular user, show normal achievements screen
// //     return _buildRegularScreen();
// //   }

// //   // Guest user screen with blur and dialog
// //   Widget _buildGuestScreen() {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           // Blurred background content
// //           Container(
// //             width: double.infinity,
// //             decoration: BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/app_background.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //             child: Column(
// //               children: [
// //                 Expanded(
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       image: DecorationImage(
// //                         image: AssetImage("assets/images/app_background.png"),
// //                         fit: BoxFit.cover,
// //                       ),
// //                     ),
// //                     alignment: Alignment.center,
// //                     child: Stack(
// //                       children: [
// //                         Positioned(child: ConcentricCirclesAnimation()),
// //                         Positioned(
// //                           left: AppDimensions.dim75.w,
// //                           top: AppDimensions.dim90.w,
// //                           child: getCurrentLevelBadge("10"),
// //                         ),
// //                         Positioned(
// //                           top: AppDimensions.dim380.h,
// //                           left: 0,
// //                           right: 0,
// //                           child: getCongratulationsText("10"),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: Container(
// //                     alignment: Alignment.center,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFFFFFFF),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: const Color(0x1A000000),
// //                           offset: const Offset(0, -6),
// //                           blurRadius: 44,
// //                           spreadRadius: 0,
// //                         ),
// //                       ],
// //                       borderRadius: BorderRadius.only(
// //                         topLeft: Radius.circular(AppDimensions.radius_24.r),
// //                         topRight: Radius.circular(AppDimensions.radius_24.r),
// //                       ),
// //                     ),
// //                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
// //                     child: GridView.builder(
// //                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// //                       physics: const NeverScrollableScrollPhysics(),
// //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 3,
// //                         childAspectRatio: 1.2.r,
// //                         mainAxisSpacing: 24.h,
// //                         crossAxisSpacing: 0.w,
// //                       ),
// //                       itemCount: 365,
// //                       itemBuilder: (context, index) {
// //                         final level = index + 1;
// //                         return getLevelBadges(level.toString(), false, '???');
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Blur overlay
// //           Positioned.fill(
// //             child: BackdropFilter(
// //               filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
// //               child: Container(
// //                 color: AppColors.black.withOpacity(0.10),
// //               ),
// //             ),
// //           ),

// //           // Dialog box
// //           Center(
// //             child: Container(
// //               width: Platform.isIOS
// //                   ? AppDimensions.dim340.w
// //                   : AppDimensions.dim380.w,
// //               height: Platform.isIOS
// //                   ? AppDimensions.dim75.h
// //                   : AppDimensions.dim75.h,
// //               margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// //               padding: EdgeInsets.symmetric(
// //                 horizontal: Platform.isIOS
// //                     ? AppDimensions.dim20.w
// //                     : AppDimensions.dim11.w,
// //                 vertical: Platform.isIOS
// //                     ? AppDimensions.dim16.h
// //                     : AppDimensions.dim13.h,
// //               ),
// //               decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
// //                 image: DecorationImage(
// //                   image: AssetImage(
// //                     "assets/images/guest_dialog.png",
// //                   ),
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //               child: Text(
// //                 "Connect to Sipnudge bottle to access analysis",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   color: AppColors.bluegray,
// //                   fontFamily: AppFontStyles.museoModernoFontFamily,
// //                   fontSize: AppFontStyles.fontSize_16.sp,
// //                   fontVariations: [AppFontStyles.fontWeightVariation600],
// //                   height: 1.4,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // Regular user screen
// //   Widget _buildRegularScreen() {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: Colors.transparent,
// //         elevation: 0,
// //         actions: [
// //           //Refresh button for testing
// //           // IconButton(
// //           //   icon: Icon(Icons.refresh, color: AppColors.bluegray),
// //           //   onPressed: _loadHydrationData,
// //           //   tooltip: 'Refresh Data',
// //           // ),
// //         ],
// //       ),
// //       extendBodyBehindAppBar: true,
// //       body: Container(
// //         width: double.infinity,
// //         decoration: BoxDecoration(
// //           image: DecorationImage(
// //             image: AssetImage("assets/images/app_background.png"),
// //             fit: BoxFit.cover,
// //           ),
// //         ),
// //         child: Column(
// //           children: [
// //             Expanded(
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   image: DecorationImage(
// //                     image: AssetImage("assets/images/app_background.png"),
// //                     fit: BoxFit.cover,
// //                   ),
// //                 ),
// //                 alignment: Alignment.center,
// //                 child: Stack(
// //                   children: [
// //                     Positioned(child: ConcentricCirclesAnimation()),
// //                     Positioned(
// //                       left: AppDimensions.dim75.w,
// //                       top: AppDimensions.dim90.w,
// //                       child: getCurrentLevelBadge(
// //                         _currentLevel.toString(),
// //                       ),
// //                     ),
// //                     Positioned(
// //                       top: AppDimensions.dim380.h,
// //                       left: 0,
// //                       right: 0,
// //                       child: getCongratulationsText(
// //                         _currentLevel.toString(),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             Expanded(
// //               child: Container(
// //                 alignment: Alignment.center,
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFFFFFFFF),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: const Color(0x1A000000),
// //                       offset: const Offset(0, -6),
// //                       blurRadius: 44,
// //                       spreadRadius: 0,
// //                     ),
// //                   ],
// //                   borderRadius: BorderRadius.only(
// //                     topLeft: Radius.circular(AppDimensions.radius_24.r),
// //                     topRight: Radius.circular(AppDimensions.radius_24.r),
// //                   ),
// //                 ),
// //                 padding: EdgeInsets.all(AppDimensions.padding_20.h),
// //                 child: GridView.builder(
// //                   padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// //                   physics: const BouncingScrollPhysics(),
// //                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                     crossAxisCount: 3,
// //                     childAspectRatio: 1.2.r,
// //                     mainAxisSpacing: 24.h,
// //                     crossAxisSpacing: 0.w,
// //                   ),
// //                   itemCount: 365,
// //                   itemBuilder: (context, index) {
// //                     final level = index + 1;
// //                     final isUnlocked = level <= _currentLevel;
// //                     final intake = _getWaterIntakeForLevel(level);

// //                     return GestureDetector(
// //                       onTap: () {
// //                         if (isUnlocked) {
// //                           // Show level details when tapping unlocked badge
// //                           showLevelUpDialog(context, level, intake);
// //                         }
// //                       },
// //                       child: getLevelBadges(
// //                         level.toString(),
// //                         isUnlocked,
// //                         intake,
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //  =======================================================================

// // =============== Main/Original Code =============================

// // import 'dart:io';
// // import 'dart:ui';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:hydrify/constants/app_colors.dart';
// // import 'package:hydrify/constants/app_dimensions.dart';
// // import 'package:hydrify/constants/app_font_styles.dart';
// // import 'package:hydrify/constants/app_strings.dart';
// // import 'package:hydrify/cubit/level/level_cubit.dart';
// // import 'package:hydrify/cubit/level/level_state.dart';
// // import 'package:hydrify/helpers/shared_pref_helper.dart';
// // import 'package:hydrify/screens/levelreached.dart';
// // import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// // class AchievementsBadgeScreen extends StatefulWidget {
// //   const AchievementsBadgeScreen({
// //     super.key,
// //   });

// //   @override
// //   State<AchievementsBadgeScreen> createState() =>
// //       _AchievementsBadgeScreenState();
// // }

// // class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
// //   bool? isGuest;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkGuestUser();
// //   }

// //   Future<void> _checkGuestUser() async {
// //     final userEmail = await SharedPrefsHelper.getUserEmail();
// //     setState(() {
// //       isGuest = userEmail == "guest_user";
// //     });
// //     print('🔍 DEBUG: isGuest = $isGuest, email = $userEmail');
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Show loading while checking guest status
// //     if (isGuest == null) {
// //       return Scaffold(
// //         body: Container(
// //           decoration: BoxDecoration(
// //             image: DecorationImage(
// //               image: AssetImage("assets/images/app_background.png"),
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //           child: Center(
// //             child: CircularProgressIndicator(
// //               color: AppColors.bluegray,
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     // If guest, show blur screen with dialog
// //     if (isGuest!) {
// //       return _buildGuestScreen();
// //     }

// //     // If regular user, show normal achievements screen
// //     return _buildRegularScreen();
// //   }

// //   // Guest user screen with blur and dialog
// //   Widget _buildGuestScreen() {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           // Blurred background content
// //           Container(
// //             width: double.infinity,
// //             decoration: BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/app_background.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //             child: Column(
// //               children: [
// //                 Expanded(
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       image: DecorationImage(
// //                         image: AssetImage("assets/images/app_background.png"),
// //                         fit: BoxFit.cover,
// //                       ),
// //                     ),
// //                     alignment: Alignment.center,
// //                     child: Stack(
// //                       children: [
// //                         Positioned(child: ConcentricCirclesAnimation()),
// //                         Positioned(
// //                           left: AppDimensions.dim75.w,
// //                           top: AppDimensions.dim90.w,
// //                           child: getCurrentLevelBadge("10"),
// //                         ),
// //                         Positioned(
// //                           top: AppDimensions.dim380.h,
// //                           left: 0,
// //                           right: 0,
// //                           child: getCongratulationsText("10"),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: Container(
// //                     alignment: Alignment.center,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFFFFFFF),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: const Color(0x1A000000),
// //                           offset: const Offset(0, -6),
// //                           blurRadius: 44,
// //                           spreadRadius: 0,
// //                         ),
// //                       ],
// //                       borderRadius: BorderRadius.only(
// //                         topLeft: Radius.circular(AppDimensions.radius_24.r),
// //                         topRight: Radius.circular(AppDimensions.radius_24.r),
// //                       ),
// //                     ),
// //                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
// //                     child: GridView.builder(
// //                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// //                       physics: const NeverScrollableScrollPhysics(),
// //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 3,
// //                         childAspectRatio: 1.2.r,
// //                         mainAxisSpacing: 24.h,
// //                         crossAxisSpacing: 0.w,
// //                       ),
// //                       itemCount: 365,
// //                       itemBuilder: (context, index) {
// //                         final level = index + 1;
// //                         return getLevelBadges(level.toString(), false);
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Blur overlay
// //           Positioned.fill(
// //             child: BackdropFilter(
// //               filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
// //               child: Container(
// //                 color: AppColors.black.withOpacity(0.10),
// //               ),
// //             ),
// //           ),

// //           // Dialog box
// //           Center(
// //             child: Container(
// //               width: Platform.isIOS
// //                   ? AppDimensions.dim340.w
// //                   : AppDimensions.dim380.w,
// //               height: Platform.isIOS
// //                   ? AppDimensions.dim75.h
// //                   : AppDimensions.dim75.h,
// //               margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// //               padding: EdgeInsets.symmetric(
// //                 horizontal: Platform.isIOS
// //                     ? AppDimensions.dim20.w
// //                     : AppDimensions.dim11.w,
// //                 vertical: Platform.isIOS
// //                     ? AppDimensions.dim16.h
// //                     : AppDimensions.dim13.h,
// //               ),
// //               decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
// //                 image: DecorationImage(
// //                   image: AssetImage(
// //                     "assets/images/guest_dialog.png",
// //                   ),
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //               child: Text(
// //                 "Connect to Sipnudge bottle to access analysis",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   color: AppColors.bluegray,
// //                   fontFamily: AppFontStyles.museoModernoFontFamily,
// //                   fontSize: AppFontStyles.fontSize_16.sp,
// //                   fontVariations: [AppFontStyles.fontWeightVariation600],
// //                   height: 1.4,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // Regular user screen
// //   Widget _buildRegularScreen() {
// //     return BlocBuilder<LevelCubit, LevelState>(
// //       builder: (context, state) {
// //         var currentLevel = state.currentLevel;

// //         return Scaffold(
// //           body: Container(
// //             width: double.infinity,
// //             decoration: BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/app_background.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //             child: Column(
// //               children: [
// //                 Expanded(
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       image: DecorationImage(
// //                         image: AssetImage("assets/images/app_background.png"),
// //                         fit: BoxFit.cover,
// //                       ),
// //                     ),
// //                     alignment: Alignment.center,
// //                     child: Stack(
// //                       children: [
// //                         Positioned(child: ConcentricCirclesAnimation()),
// //                         Positioned(
// //                           left: AppDimensions.dim75.w,
// //                           top: AppDimensions.dim90.w,
// //                           child: getCurrentLevelBadge(
// //                             currentLevel.toString(),
// //                           ),
// //                         ),
// //                         Positioned(
// //                           top: AppDimensions.dim380.h,
// //                           left: 0,
// //                           right: 0,
// //                           child: getCongratulationsText(
// //                             currentLevel.toString(),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: Container(
// //                     alignment: Alignment.center,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFFFFFFF),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: const Color(0x1A000000),
// //                           offset: const Offset(0, -6),
// //                           blurRadius: 44,
// //                           spreadRadius: 0,
// //                         ),
// //                       ],
// //                       borderRadius: BorderRadius.only(
// //                         topLeft: Radius.circular(AppDimensions.radius_24.r),
// //                         topRight: Radius.circular(AppDimensions.radius_24.r),
// //                       ),
// //                     ),
// //                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
// //                     child: GridView.builder(
// //                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// //                       physics: const BouncingScrollPhysics(),
// //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 3,
// //                         childAspectRatio: 1.2.r,
// //                         mainAxisSpacing: 24.h,
// //                         crossAxisSpacing: 0.w,
// //                       ),
// //                       itemCount: 365,
// //                       itemBuilder: (context, index) {
// //                         final level = index + 1;
// //                         final isUnlocked = level <= currentLevel;
// //                         return GestureDetector(
// //                           onTap: () {
// //                             if (level > currentLevel) {
// //                               context.read<LevelCubit>().updateLevel(level);
// //                               showLevelUpDialog(
// //                                 context,
// //                                 level,
// //                                 '15.4L',
// //                               );
// //                             }
// //                           },
// //                           child: getLevelBadges(level.toString(), isUnlocked),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget getCurrentLevelBadge(String level) {
// //     return SizedBox(
// //       width: AppDimensions.dim330.w,
// //       height: AppDimensions.dim320.h,
// //       child: Stack(
// //         children: [
// //           Positioned.fill(
// //             child: Align(
// //               alignment: Alignment.center,
// //               child: Transform.translate(
// //                 offset: Offset(-16.w, 0),
// //                 child: Image.asset(
// //                   "assets/images/goals_new_img.png",
// //                   width: AppDimensions.dim330.w,
// //                   height: AppDimensions.dim320.h,
// //                 ),
// //               ),
// //             ),
// //           ),
// //           Positioned(
// //             left: AppDimensions.dim100.w,
// //             top: AppDimensions.dim105.h,
// //             child: SizedBox(
// //               width: AppDimensions.dim100.w,
// //               child: ShaderMask(
// //                 shaderCallback: (bounds) => const LinearGradient(
// //                   colors: [
// //                     Color(0xFF16446F),
// //                     Color(0xFF2569A9),
// //                     Color(0xFF59ADFB),
// //                   ],
// //                 ).createShader(
// //                   Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //                 ),
// //                 blendMode: BlendMode.srcIn,
// //                 child: Transform.translate(
// //                   offset: Offset(0, -5.h),
// //                   child: Text(
// //                     level,
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       fontSize: AppFontStyles.fontSize_80.sp,
// //                       fontVariations: [AppFontStyles.boldFontVariation],
// //                       fontFamily: AppFontStyles.poppinsFamily,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           )
// //         ],
// //       ),
// //     );
// //   }

// //   Widget getLevelBadges(String level, bool isUnlocked) {
// //     return SizedBox(
// //       height: AppDimensions.dim137.h,
// //       width: AppDimensions.dim115.w,
// //       child: Stack(
// //         children: [
// //           Align(
// //             alignment: Alignment.topCenter,
// //             child: isUnlocked
// //                 ? Image.asset(
// //                     "assets/images/goals_levels_img.png",
// //                     width: AppDimensions.dim107.w,
// //                     height: AppDimensions.dim111.h,
// //                   )
// //                 : Image.asset(
// //                     //"assets/images/lock_goals_levels_img.png",
// //                     "assets/images/level_lock_img.png",
// //                     color: AppColors.lightgray,
// //                     width: AppDimensions.dim107.w,
// //                     height: AppDimensions.dim111.h,
// //                   ),
// //           ),
// //           if (isUnlocked)
// //             Positioned.fill(
// //               child: Align(
// //                 alignment: Platform.isIOS
// //                     ? const Alignment(0, -0.25)
// //                     : const Alignment(0, -0.1),
// //                 child: ShaderMask(
// //                   shaderCallback: (bounds) => const LinearGradient(
// //                     colors: [
// //                       Color(0xFF16446F),
// //                       Color(0xFF2569A9),
// //                       Color(0xFF59ADFB),
// //                     ],
// //                   ).createShader(
// //                     Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //                   ),
// //                   blendMode: BlendMode.srcIn,
// //                   child: Text(
// //                     level,
// //                     style: TextStyle(
// //                       color: AppColors.white,
// //                       fontFamily: AppFontStyles.urbanistFontFamily,
// //                       fontVariations: [AppFontStyles.extraBoldFontVariation],
// //                       fontSize: AppFontStyles.fontSize_28,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           Positioned(
// //             top: AppDimensions.dim74.h,
// //             left: isUnlocked ? AppDimensions.dim6.w : -6.w,
// //             right: 0,
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: [
// //                 Text(
// //                   'Level $level',
// //                   style: TextStyle(
// //                     color: AppColors.bluegray,
// //                     fontFamily: AppFontStyles.urbanistFontFamily,
// //                     fontVariations: [AppFontStyles.boldFontVariation],
// //                     fontSize: AppFontStyles.fontSize_14,
// //                   ),
// //                 ),
// //                 SizedBox(height: AppDimensions.dim4.h),
// //                 Text(
// //                   'Weekly Intake: 15.4L',
// //                   style: TextStyle(
// //                     color: AppColors.bluegray,
// //                     fontFamily: AppFontStyles.urbanistFontFamily,
// //                     fontVariations: [AppFontStyles.regularFontVariation],
// //                     fontSize: AppFontStyles.fontSize_10,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget getCongratulationsText(String level) {
// //     return Container(
// //       padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.center,
// //         children: [
// //           Text(
// //             '${AppStrings.levelreach} $level !',
// //             style: TextStyle(
// //               color: AppColors.bluegray,
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontSize: AppFontStyles.fontSize_20.sp,
// //               fontVariations: [AppFontStyles.boldFontVariation],
// //             ),
// //           ),
// //           SizedBox(height: AppDimensions.dim10.h),
// //           Text(
// //             AppStrings.congratulations,
// //             textAlign: TextAlign.center,
// //             style: TextStyle(
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontVariations: [AppFontStyles.fontWeightVariation600],
// //               color: AppColors.bluegray,
// //               fontSize: AppFontStyles.fontSize_14.sp,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// //=============== Work Remaining =============================
// // import 'dart:io';
// // import 'dart:ui';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:hydrify/constants/app_colors.dart';
// // import 'package:hydrify/constants/app_dimensions.dart';
// // import 'package:hydrify/constants/app_font_styles.dart';
// // import 'package:hydrify/constants/app_strings.dart';
// // import 'package:hydrify/cubit/level/level_cubit.dart';
// // import 'package:hydrify/cubit/level/level_state.dart';
// // import 'package:hydrify/helpers/shared_pref_helper.dart';
// // import 'package:hydrify/screens/levelreached.dart';
// // import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// // class AchievementsBadgeScreen extends StatefulWidget {
// //   const AchievementsBadgeScreen({
// //     super.key,
// //   });

// //   @override
// //   State<AchievementsBadgeScreen> createState() =>
// //       _AchievementsBadgeScreenState();
// // }

// // class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
// //   bool? isGuest;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkGuestUser();
// //   }

// //   Future<void> _checkGuestUser() async {
// //     final userEmail = await SharedPrefsHelper.getUserEmail();
// //     setState(() {
// //       isGuest = userEmail == "guest_user";
// //     });
// //     print('🔍 DEBUG: isGuest = $isGuest, email = $userEmail');
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Show loading while checking guest status
// //     if (isGuest == null) {
// //       return Scaffold(
// //         body: Container(
// //           decoration: BoxDecoration(
// //             image: DecorationImage(
// //               image: AssetImage("assets/images/app_background.png"),
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //           child: Center(
// //             child: CircularProgressIndicator(
// //               color: AppColors.bluegray,
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     // If guest, show blur screen with dialog
// //     if (isGuest!) {
// //       return _buildGuestScreen();
// //     }

// //     // If regular user, show normal achievements screen
// //     return _buildRegularScreen();
// //   }

// //   // Guest user screen with blur and dialog
// //   Widget _buildGuestScreen() {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           // Blurred background content
// //           Container(
// //             width: double.infinity,
// //             decoration: BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/app_background.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //             child: Column(
// //               children: [
// //                 Expanded(
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       image: DecorationImage(
// //                         image: AssetImage("assets/images/app_background.png"),
// //                         fit: BoxFit.cover,
// //                       ),
// //                     ),
// //                     alignment: Alignment.center,
// //                     child: Stack(
// //                       children: [
// //                         Positioned(child: ConcentricCirclesAnimation()),
// //                         Positioned(
// //                           left: AppDimensions.dim75.w,
// //                           top: AppDimensions.dim90.w,
// //                           child: getCurrentLevelBadge("10"),
// //                         ),
// //                         Positioned(
// //                           top: AppDimensions.dim380.h,
// //                           left: 0,
// //                           right: 0,
// //                           child: getCongratulationsText("10"),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: Container(
// //                     alignment: Alignment.center,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFFFFFFF),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: const Color(0x1A000000),
// //                           offset: const Offset(0, -6),
// //                           blurRadius: 44,
// //                           spreadRadius: 0,
// //                         ),
// //                       ],
// //                       borderRadius: BorderRadius.only(
// //                         topLeft: Radius.circular(AppDimensions.radius_24.r),
// //                         topRight: Radius.circular(AppDimensions.radius_24.r),
// //                       ),
// //                     ),
// //                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
// //                     child: GridView.builder(
// //                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// //                       physics: const NeverScrollableScrollPhysics(),
// //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 3,
// //                         childAspectRatio: 1.2.r,
// //                         mainAxisSpacing: 24.h,
// //                         crossAxisSpacing: 0.w,
// //                       ),
// //                       itemCount: 10,
// //                       itemBuilder: (context, index) {
// //                         final level = index + 1;
// //                         return getLevelBadges(level.toString(), false, '');
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Blur overlay
// //           Positioned.fill(
// //             child: BackdropFilter(
// //               filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
// //               child: Container(
// //                 color: AppColors.black.withOpacity(0.10),
// //               ),
// //             ),
// //           ),

// //           // Dialog box
// //           Center(
// //             child: Container(
// //               width: Platform.isIOS
// //                   ? AppDimensions.dim340.w
// //                   : AppDimensions.dim380.w,
// //               height: Platform.isIOS
// //                   ? AppDimensions.dim75.h
// //                   : AppDimensions.dim75.h,
// //               margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// //               padding: EdgeInsets.symmetric(
// //                 horizontal: Platform.isIOS
// //                     ? AppDimensions.dim20.w
// //                     : AppDimensions.dim11.w,
// //                 vertical: Platform.isIOS
// //                     ? AppDimensions.dim16.h
// //                     : AppDimensions.dim13.h,
// //               ),
// //               decoration: BoxDecoration(
// //                 borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
// //                 image: DecorationImage(
// //                   image: AssetImage(
// //                     "assets/images/guest_dialog.png",
// //                   ),
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //               child: Text(
// //                 "Connect to Sipnudge bottle to access analysis",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   color: AppColors.bluegray,
// //                   fontFamily: AppFontStyles.museoModernoFontFamily,
// //                   fontSize: AppFontStyles.fontSize_16.sp,
// //                   fontVariations: [AppFontStyles.fontWeightVariation600],
// //                   height: 1.4,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // Regular user screen
// //   Widget _buildRegularScreen() {
// //     return BlocBuilder<LevelCubit, LevelState>(
// //       builder: (context, state) {
// //         var currentLevel = state.currentLevel;

// //         return Scaffold(
// //           body: Container(
// //             width: double.infinity,
// //             decoration: BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/app_background.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //             child: Column(
// //               children: [
// //                 Expanded(
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       image: DecorationImage(
// //                         image: AssetImage("assets/images/app_background.png"),
// //                         fit: BoxFit.cover,
// //                       ),
// //                     ),
// //                     alignment: Alignment.center,
// //                     child: Stack(
// //                       children: [
// //                         Positioned(child: ConcentricCirclesAnimation()),
// //                         Positioned(
// //                           left: AppDimensions.dim75.w,
// //                           top: AppDimensions.dim90.w,
// //                           child: getCurrentLevelBadge(
// //                             currentLevel.toString(),
// //                           ),
// //                         ),
// //                         Positioned(
// //                           top: AppDimensions.dim380.h,
// //                           left: 0,
// //                           right: 0,
// //                           child: getCongratulationsText(
// //                             currentLevel.toString(),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: Container(
// //                     alignment: Alignment.center,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFFFFFFF),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: const Color(0x1A000000),
// //                           offset: const Offset(0, -6),
// //                           blurRadius: 44,
// //                           spreadRadius: 0,
// //                         ),
// //                       ],
// //                       borderRadius: BorderRadius.only(
// //                         topLeft: Radius.circular(AppDimensions.radius_24.r),
// //                         topRight: Radius.circular(AppDimensions.radius_24.r),
// //                       ),
// //                     ),
// //                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
// //                     child: GridView.builder(
// //                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// //                       physics: const BouncingScrollPhysics(),
// //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 3,
// //                         childAspectRatio: 1.2.r,
// //                         mainAxisSpacing: 24.h,
// //                         crossAxisSpacing: 0.w,
// //                       ),
// //                       itemCount: 10,
// //                       itemBuilder: (context, index) {
// //                         final level = index + 1;
// //                         final isUnlocked = level <= currentLevel;
// //                         return GestureDetector(
// //                           onTap: () {
// //                             if (isUnlocked) {
// //                               // Show level details when tapping unlocked badge
// //                               showLevelUpDialog(
// //                                 context,
// //                                 level,
// //                                 _getWaterIntakeForLevel(level),
// //                               );
// //                             }
// //                           },
// //                           child: getLevelBadges(
// //                             level.toString(),
// //                             isUnlocked,
// //                             _getWaterIntakeForLevel(level),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   // Get water intake amount for each level
// //   String _getWaterIntakeForLevel(int level) {
// //     // Define water intake goals for each level
// //     // Adjust these values according to your requirements
// //     switch (level) {
// //       case 1:
// //         return '0.5L';
// //       case 2:
// //         return '1.0L';
// //       case 3:
// //         return '1.5L';
// //       case 4:
// //         return '2.0L';
// //       case 5:
// //         return '2.5L';
// //       case 6:
// //         return '3.0L';
// //       case 7:
// //         return '3.5L';
// //       case 8:
// //         return '4.0L';
// //       case 9:
// //         return '4.5L';
// //       case 10:
// //         return '5.0L';
// //       default:
// //         return '${level * 0.5}L';
// //     }
// //   }

// //   Widget getCurrentLevelBadge(String level) {
// //     return SizedBox(
// //       width: AppDimensions.dim330.w,
// //       height: AppDimensions.dim320.h,
// //       child: Stack(
// //         children: [
// //           Positioned.fill(
// //             child: Align(
// //               alignment: Alignment.center,
// //               child: Transform.translate(
// //                 offset: Offset(-16.w, 0),
// //                 child: Image.asset(
// //                   "assets/images/goals_new_img.png",
// //                   width: AppDimensions.dim330.w,
// //                   height: AppDimensions.dim320.h,
// //                 ),
// //               ),
// //             ),
// //           ),
// //           Positioned(
// //             left: AppDimensions.dim100.w,
// //             top: AppDimensions.dim105.h,
// //             child: SizedBox(
// //               width: AppDimensions.dim100.w,
// //               child: ShaderMask(
// //                 shaderCallback: (bounds) => const LinearGradient(
// //                   colors: [
// //                     Color(0xFF16446F),
// //                     Color(0xFF2569A9),
// //                     Color(0xFF59ADFB),
// //                   ],
// //                 ).createShader(
// //                   Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //                 ),
// //                 blendMode: BlendMode.srcIn,
// //                 child: Transform.translate(
// //                   offset: Offset(0, -5.h),
// //                   child: Text(
// //                     level,
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       fontSize: AppFontStyles.fontSize_80.sp,
// //                       fontVariations: [AppFontStyles.boldFontVariation],
// //                       fontFamily: AppFontStyles.poppinsFamily,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           )
// //         ],
// //       ),
// //     );
// //   }

// //   Widget getLevelBadges(String level, bool isUnlocked, String waterIntake) {
// //     return SizedBox(
// //       height: AppDimensions.dim137.h,
// //       width: AppDimensions.dim115.w,
// //       child: Stack(
// //         children: [
// //           // Badge image - locked (grey) or unlocked (colored)
// //           Align(
// //             alignment: Alignment.topCenter,
// //             child: Image.asset(
// //               isUnlocked
// //                   ? "assets/images/goals_levels_img.png" // Colored badge (unlocked)
// //                   : "assets/images/level_lock_img.png",
// //               color:
// //                   isUnlocked ? null : AppColors.lightgray, // Grey locked badge
// //               width:
// //                   isUnlocked ? AppDimensions.dim107.w : AppDimensions.dim108.w,
// //               height:
// //                   isUnlocked ? AppDimensions.dim106.h : AppDimensions.dim100.h,
// //             ),
// //           ),

// //           // Level number - only show on unlocked badges
// //           if (isUnlocked)
// //             Positioned.fill(
// //               child: Align(
// //                 alignment: Platform.isIOS
// //                     ? const Alignment(0, -0.25)
// //                     : const Alignment(0, -0.1),
// //                 child: ShaderMask(
// //                   shaderCallback: (bounds) => const LinearGradient(
// //                     colors: [
// //                       Color(0xFF16446F),
// //                       Color(0xFF2569A9),
// //                       Color(0xFF59ADFB),
// //                     ],
// //                   ).createShader(
// //                     Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //                   ),
// //                   blendMode: BlendMode.srcIn,
// //                   child: Text(
// //                     level,
// //                     style: TextStyle(
// //                       color: AppColors.white,
// //                       fontFamily: AppFontStyles.urbanistFontFamily,
// //                       fontVariations: [AppFontStyles.extraBoldFontVariation],
// //                       fontSize: AppFontStyles.fontSize_28,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),

// //           // Level text and water intake
// //           Positioned(
// //             top: AppDimensions.dim74.h,
// //             left: isUnlocked ? AppDimensions.dim5.w : -10.w,
// //             right: 0,
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: [
// //                 Text(
// //                   isUnlocked ? 'Level $level' : 'Locked',
// //                   style: TextStyle(
// //                     color: isUnlocked
// //                         ? AppColors.bluegray
// //                         : AppColors.bluegray.withOpacity(0.15),
// //                     fontFamily: AppFontStyles.urbanistFontFamily,
// //                     fontVariations: [AppFontStyles.boldFontVariation],
// //                     fontSize: AppFontStyles.fontSize_14.sp,
// //                   ),
// //                 ),
// //                 SizedBox(height: AppDimensions.dim2.h),
// //                 Text(
// //                   isUnlocked ? 'Weekly Intake: $waterIntake' : '0',
// //                   style: TextStyle(
// //                     color: isUnlocked
// //                         ? AppColors.bluegray
// //                         : AppColors.bluegray.withOpacity(0.15),
// //                     fontFamily: AppFontStyles.urbanistFontFamily,
// //                     fontVariations: [AppFontStyles.regularFontVariation],
// //                     fontSize: AppFontStyles.fontSize_11.sp,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget getCongratulationsText(String level) {
// //     return Container(
// //       padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.center,
// //         children: [
// //           Text(
// //             '${AppStrings.levelreach} $level !',
// //             style: TextStyle(
// //               color: AppColors.bluegray,
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontSize: AppFontStyles.fontSize_20.sp,
// //               fontVariations: [AppFontStyles.boldFontVariation],
// //             ),
// //           ),
// //           SizedBox(height: AppDimensions.dim10.h),
// //           Text(
// //             AppStrings.congratulations,
// //             textAlign: TextAlign.center,
// //             style: TextStyle(
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontVariations: [AppFontStyles.fontWeightVariation600],
// //               color: AppColors.bluegray,
// //               fontSize: AppFontStyles.fontSize_14.sp,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// //=== Previous version of the file:================= --- IGNORE ---

// // import 'dart:io';
// // import 'dart:ui';

// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:hydrify/constants/app_colors.dart';
// // import 'package:hydrify/constants/app_dimensions.dart';
// // import 'package:hydrify/constants/app_font_styles.dart';
// // import 'package:hydrify/constants/app_strings.dart';
// // import 'package:hydrify/helpers/database_helper.dart';
// // import 'package:hydrify/helpers/shared_pref_helper.dart';
// // import 'package:hydrify/models/hydration_summary.dart';
// // import 'package:hydrify/screens/levelreached.dart';
// // import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// // class AchievementsBadgeScreen extends StatefulWidget {
// //   const AchievementsBadgeScreen({super.key});

// //   @override
// //   State<AchievementsBadgeScreen> createState() =>
// //       _AchievementsBadgeScreenState();
// // }

// // class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
// //   bool? isGuest;
// //   final DatabaseHelper _dbHelper = DatabaseHelper();

// //   bool _loading = true;
// //   List<HydrationDaySummary> _hydrationData = [];
// //   int _currentLevel = 0;
// //   int _dailyWaterGoal = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkGuestUser();
// //   }

// //   // 🔥 KEY FIX: refresh whenever screen becomes active
// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     _loadHydrationData();
// //   }

// //   Future<void> _checkGuestUser() async {
// //     final userEmail = await SharedPrefsHelper.getUserEmail();
// //     if (!mounted) return;

// //     setState(() {
// //       isGuest = userEmail == "guest_user";
// //     });
// //   }

// //   Future<void> _loadHydrationData() async {
// //     setState(() => _loading = true);

// //     final userGoal = await SharedPrefsHelper.getUserGoal();
// //     final dailyGoalMl = userGoal ?? 1400;

// //     final fetchedAll = await _dbHelper.getHydrationSummariesForRange();

// //     fetchedAll.sort((a, b) => a.date.compareTo(b.date));

// //     int completedDays = 0;

// //     for (final summary in fetchedAll) {
// //       final target =
// //           summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
// //       if ((summary.consumed / target) * 100 >= 100) {
// //         completedDays++;
// //       }
// //     }

// //     if (!mounted) return;

// //     setState(() {
// //       _hydrationData = fetchedAll;
// //       _currentLevel = completedDays.clamp(0, 365);
// //       _dailyWaterGoal = dailyGoalMl;
// //       _loading = false;
// //     });
// //   }

// //   String _getWaterIntakeForLevel(int level) {
// //     if (level <= 0 || _hydrationData.isEmpty) return '0.0L';

// //     final dailyGoalMl = _dailyWaterGoal > 0 ? _dailyWaterGoal : 1400;
// //     int count = 0;

// //     for (final summary in _hydrationData) {
// //       final target =
// //           summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
// //       if ((summary.consumed / target) * 100 >= 100) {
// //         count++;
// //         if (count == level) {
// //           return '${(summary.consumed / 1000).toStringAsFixed(1)}L';
// //         }
// //       }
// //     }
// //     return '0.0L';
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (isGuest == null || _loading) {
// //       return Scaffold(
// //         body: Container(
// //           decoration: const BoxDecoration(
// //             image: DecorationImage(
// //               image: AssetImage("assets/images/app_background.png"),
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //           child: Center(
// //             child: CircularProgressIndicator(color: AppColors.bluegray),
// //           ),
// //         ),
// //       );
// //     }

// //     if (isGuest!) return _buildGuestScreen();
// //     return _buildRegularScreen();
// //   }

// //   // ---------------- GUEST SCREEN ----------------

// //   Widget _buildGuestScreen() {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           Container(
// //             decoration: const BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage("assets/images/app_background.png"),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //           ),
// //           Positioned.fill(
// //             child: BackdropFilter(
// //               filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
// //               child: Container(color: Colors.black.withOpacity(0.1)),
// //             ),
// //           ),
// //           Center(
// //             child: Text(
// //               "Connect to Sipnudge bottle to access analysis",
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 color: AppColors.bluegray,
// //                 fontFamily: AppFontStyles.museoModernoFontFamily,
// //                 fontSize: 16.sp,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ---------------- REGULAR SCREEN ----------------

// //   Widget _buildRegularScreen() {
// //     return Scaffold(
// //       extendBodyBehindAppBar: true,
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           image: DecorationImage(
// //             image: AssetImage("assets/images/app_background.png"),
// //             fit: BoxFit.cover,
// //           ),
// //         ),
// //         child: Column(
// //           children: [
// //             Expanded(
// //               child: Stack(
// //                 children: [
// //                   const ConcentricCirclesAnimation(),
// //                   Positioned(
// //                     left: AppDimensions.dim75.w,
// //                     top: AppDimensions.dim90.w,
// //                     child: getCurrentLevelBadge(
// //                       _currentLevel.toString(),
// //                     ),
// //                   ),
// //                   Positioned(
// //                     top: AppDimensions.dim380.h,
// //                     left: 0,
// //                     right: 0,
// //                     child: getCongratulationsText(
// //                       _currentLevel.toString(),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Expanded(
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(
// //                   horizontal: AppDimensions.padding_20.w,
// //                   //vertical: AppDimensions.padding_20.h,
// //                 ),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.vertical(
// //                     top: Radius.circular(AppDimensions.radius_24.r),
// //                   ),
// //                 ),
// //                 child: GridView.builder(
// //                   itemCount: 365,
// //                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                     crossAxisCount: 3,
// //                     childAspectRatio: 1.2.r,
// //                     mainAxisSpacing: 24.h,
// //                   ),
// //                   itemBuilder: (context, index) {
// //                     final level = index + 1;
// //                     final unlocked = level <= _currentLevel;
// //                     final intake = _getWaterIntakeForLevel(level);

// //                     return GestureDetector(
// //                       onTap: unlocked
// //                           ? () => showLevelUpDialog(context, level, intake)
// //                           : null,
// //                       child: getLevelBadges(
// //                         level.toString(),
// //                         unlocked,
// //                         intake,
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // Widget getCurrentLevelBadge(String level) {
// //   //   return SizedBox(
// //   //     width: AppDimensions.dim330.w,
// //   //     height: AppDimensions.dim320.h,
// //   //     child: Stack(
// //   //       children: [
// //   //         Positioned.fill(
// //   //           child: Align(
// //   //             alignment: Alignment.center,
// //   //             child: Transform.translate(
// //   //               offset: Offset(-16.w, 0),
// //   //               child: Image.asset(
// //   //                 "assets/images/goals_new_img.png",
// //   //                 width: AppDimensions.dim330.w,
// //   //                 height: AppDimensions.dim320.h,
// //   //               ),
// //   //             ),
// //   //           ),
// //   //         ),
// //   //         Positioned(
// //   //           left: AppDimensions.dim100.w,
// //   //           top: AppDimensions.dim105.h,
// //   //           child: SizedBox(
// //   //             width: AppDimensions.dim100.w,
// //   //             child: ShaderMask(
// //   //               shaderCallback: (bounds) => const LinearGradient(
// //   //                 colors: [
// //   //                   Color(0xFF16446F),
// //   //                   Color(0xFF2569A9),
// //   //                   Color(0xFF59ADFB),
// //   //                 ],
// //   //               ).createShader(
// //   //                 Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //   //               ),
// //   //               blendMode: BlendMode.srcIn,
// //   //               child: Transform.translate(
// //   //                 offset: Offset(0, -5.h),
// //   //                 child: Text(
// //   //                   level,
// //   //                   textAlign: TextAlign.center,
// //   //                   style: TextStyle(
// //   //                     fontSize: AppFontStyles.fontSize_80.sp,
// //   //                     fontVariations: [AppFontStyles.boldFontVariation],
// //   //                     fontFamily: AppFontStyles.poppinsFamily,
// //   //                   ),
// //   //                 ),
// //   //               ),
// //   //             ),
// //   //           ),
// //   //         )
// //   //       ],
// //   //     ),
// //   //   );
// //   // }

// //   Widget getCurrentLevelBadge(String level) {
// //     final int currentLevelNum = int.tryParse(level) ?? 0;
// //     //final bool isCurrentLevelUnlocked = currentLevelNum <= _currentLevel;
// //     final bool isCurrentLevelUnlocked =
// //         currentLevelNum > 0 && currentLevelNum <= _currentLevel;

// //     return SizedBox(
// //       width: AppDimensions.dim330.w,
// //       height: AppDimensions.dim320.h,
// //       child: Stack(
// //         children: [
// //           // Show different badge based on unlock status
// //           Positioned.fill(
// //             child: Align(
// //               alignment: Alignment.center,
// //               child: Transform.translate(
// //                 offset: Offset(-16.w, 0),
// //                 child: Image.asset(
// //                   isCurrentLevelUnlocked
// //                       ? "assets/images/goals_new_img.png" // Unlocked - colored badge
// //                       : "assets/images/level_lock_img1.png", // Locked - grey badge
// //                   width: isCurrentLevelUnlocked
// //                       ? AppDimensions.dim330.w
// //                       : AppDimensions.dim270.w,
// //                   height: isCurrentLevelUnlocked
// //                       ? AppDimensions.dim320.h
// //                       : AppDimensions.dim260.h,
// //                   fit: BoxFit.contain,
// //                 ),
// //               ),
// //             ),
// //           ),

// //           // Show level number only if unlocked
// //           if (isCurrentLevelUnlocked)
// //             Positioned(
// //               left: AppDimensions.dim100.w,
// //               top: AppDimensions.dim105.h,
// //               child: SizedBox(
// //                 width: AppDimensions.dim100.w,
// //                 child: ShaderMask(
// //                   shaderCallback: (bounds) => const LinearGradient(
// //                     colors: [
// //                       Color(0xFF16446F),
// //                       Color(0xFF2569A9),
// //                       Color(0xFF59ADFB),
// //                     ],
// //                   ).createShader(
// //                     Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //                   ),
// //                   blendMode: BlendMode.srcIn,
// //                   child: Transform.translate(
// //                     offset: Offset(0, -5.h),
// //                     child: Text(
// //                       level,
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(
// //                         fontSize: AppFontStyles.fontSize_80.sp,
// //                         fontVariations: [AppFontStyles.boldFontVariation],
// //                         fontFamily: AppFontStyles.poppinsFamily,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget getLevelBadges(String level, bool isUnlocked, String waterIntake) {
// //     return SizedBox(
// //       height: isUnlocked ? AppDimensions.dim137.h : AppDimensions.dim1.h,
// //       width: AppDimensions.dim115.w,
// //       child: Stack(
// //         children: [
// //           // Badge image - locked or unlocked
// //           Align(
// //             alignment: Alignment.topCenter,
// //             child: isUnlocked
// //                 ? Image.asset(
// //                     "assets/images/goals_levels_img.png",
// //                     width: AppDimensions.dim107.w,
// //                     height: AppDimensions.dim111.h,
// //                   )
// //                 : Padding(
// //                     padding: EdgeInsets.only(
// //                         top: AppDimensions.dim22.h), // 🔽 shift down
// //                     child: Image.asset(
// //                       "assets/images/level_lock_img1.png",
// //                       width: AppDimensions.dim70.w,
// //                       height: AppDimensions.dim70.h,
// //                     ),
// //                   ),
// //           ),

// //           // Level number - only show on unlocked badges
// //           if (isUnlocked)
// //             Positioned.fill(
// //               child: Align(
// //                 alignment: Platform.isIOS
// //                     ? const Alignment(0, -0.25)
// //                     : const Alignment(0, -0.1),
// //                 child: ShaderMask(
// //                   shaderCallback: (bounds) => const LinearGradient(
// //                     colors: [
// //                       Color(0xFF16446F),
// //                       Color(0xFF2569A9),
// //                       Color(0xFF59ADFB),
// //                     ],
// //                   ).createShader(
// //                     Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// //                   ),
// //                   blendMode: BlendMode.srcIn,
// //                   child: Text(
// //                     level,
// //                     style: TextStyle(
// //                       color: AppColors.white,
// //                       fontFamily: AppFontStyles.urbanistFontFamily,
// //                       fontVariations: [AppFontStyles.extraBoldFontVariation],
// //                       fontSize: AppFontStyles.fontSize_28,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),

// //           // Level text and water intake
// //           Positioned(
// //             top: isUnlocked ? AppDimensions.dim74.h : AppDimensions.dim75.h,
// //             left: isUnlocked ? AppDimensions.dim5.w : 0.w,
// //             right: 0,
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: [
// //                 Text(
// //                   isUnlocked ? 'Level $level' : 'Level $level',
// //                   style: TextStyle(
// //                     color: isUnlocked
// //                         ? AppColors.bluegray
// //                         : AppColors.bluegray.withOpacity(0.5),
// //                     fontFamily: AppFontStyles.urbanistFontFamily,
// //                     fontVariations: [AppFontStyles.boldFontVariation],
// //                     fontSize: AppFontStyles.fontSize_14,
// //                   ),
// //                 ),
// //                 SizedBox(height: AppDimensions.dim4.h),
// //                 Text(
// //                   isUnlocked ? 'Water Intake: $waterIntake' : '0',
// //                   style: TextStyle(
// //                     color: isUnlocked
// //                         ? AppColors.bluegray
// //                         : AppColors.bluegray.withOpacity(0.5),
// //                     fontFamily: AppFontStyles.urbanistFontFamily,
// //                     fontVariations: [AppFontStyles.regularFontVariation],
// //                     fontSize: AppFontStyles.fontSize_10,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget getCongratulationsText(String level) {
// //     return Container(
// //       padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         crossAxisAlignment: CrossAxisAlignment.center,
// //         children: [
// //           Text(
// //             '${AppStrings.levelreach} $level!',
// //             style: TextStyle(
// //               color: AppColors.bluegray,
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontSize: AppFontStyles.fontSize_20.sp,
// //               fontVariations: [AppFontStyles.boldFontVariation],
// //             ),
// //           ),
// //           SizedBox(height: AppDimensions.dim10.h),
// //           Text(
// //             AppStrings.congratulations(_dailyWaterGoal),
// //             textAlign: TextAlign.center,
// //             style: TextStyle(
// //               fontFamily: AppFontStyles.urbanistFontFamily,
// //               fontVariations: [AppFontStyles.fontWeightVariation600],
// //               color: AppColors.bluegray,
// //               fontSize: AppFontStyles.fontSize_14.sp,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ====================================================================

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_bloc/flutter_bloc.dart';
// // // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // // import 'package:hydrify/constants/app_colors.dart';
// // // import 'package:hydrify/constants/app_dimensions.dart';
// // // import 'package:hydrify/constants/app_font_styles.dart';
// // // import 'package:hydrify/constants/app_strings.dart';
// // // import 'package:hydrify/cubit/level/level_cubit.dart';
// // // import 'package:hydrify/cubit/level/level_state.dart';
// // // import 'package:hydrify/screens/levelreached.dart';
// // // import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// // // class AchievementsBadgeScreen extends StatelessWidget {
// // //   const AchievementsBadgeScreen({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return BlocBuilder<LevelCubit, LevelState>(
// // //       builder: (context, state) {
// // //         var currentLevel = state.currentLevel;

// // //         return Scaffold(
// // //           body: Container(
// // //             width: double.infinity,
// // //             decoration: BoxDecoration(
// // //               image: DecorationImage(
// // //                 image: AssetImage("assets/images/app_background.png"),
// // //                 fit: BoxFit.cover,
// // //               ),
// // //               //color: Color(0XFFFFFFFF),
// // //             ),
// // //             child: Column(
// // //               children: [
// // //                 Expanded(
// // //                   child: Container(
// // //                       decoration: BoxDecoration(
// // //                         image: DecorationImage(
// // //                           image: AssetImage("assets/images/app_background.png"),
// // //                           fit: BoxFit.cover,
// // //                         ),
// // //                         // gradient: LinearGradient(
// // //                         //   begin: Alignment.topCenter,
// // //                         //   end: Alignment.bottomCenter,
// // //                         //   colors: [AppColors.gradientStart, Color(0XFF2E2630)],
// // //                         // ),
// // //                       ),
// // //                       alignment: Alignment.center,
// // //                       child: Stack(
// // //                         children: [
// // //                           Positioned(child: ConcentricCirclesAnimation()),
// // //                           Positioned(
// // //                             left: AppDimensions.dim75.w,
// // //                             top: AppDimensions.dim90.w,
// // //                             child: getCurrentLevelBadge(
// // //                               currentLevel.toString(),
// // //                             ),
// // //                           ),
// // //                           Positioned(
// // //                             top: AppDimensions.dim380.h,
// // //                             left: 0,
// // //                             right: 0,
// // //                             child: getCongratulationsText(
// // //                               currentLevel.toString(),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       )),
// // //                 ),
// // //                 Expanded(
// // //                   child: Container(
// // //                     alignment: Alignment.center,
// // //                     decoration: BoxDecoration(
// // //                       color: const Color(0xFFFFFFFF),
// // //                       boxShadow: [
// // //                         BoxShadow(
// // //                           color: const Color(0x1A000000),
// // //                           offset: const Offset(0, -6),
// // //                           blurRadius: 44,
// // //                           spreadRadius: 0,
// // //                         ),
// // //                       ],
// // //                       borderRadius: BorderRadius.only(
// // //                         topLeft: Radius.circular(AppDimensions.radius_24.r),
// // //                         topRight: Radius.circular(AppDimensions.radius_24.r),
// // //                       ),
// // //                     ),
// // //                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
// // //                     child: GridView.builder(
// // //                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
// // //                       physics: const BouncingScrollPhysics(),
// // //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// // //                         crossAxisCount: 3,
// // //                         childAspectRatio: 1.2.r,
// // //                         mainAxisSpacing: 24.h,
// // //                         crossAxisSpacing: 0.w,
// // //                       ),
// // //                       itemCount: 10,
// // //                       itemBuilder: (context, index) {
// // //                         final level = index + 1;
// // //                         final isUnlocked = level <= currentLevel;
// // //                         return GestureDetector(
// // //                           onTap: () {
// // //                             if (level > currentLevel) {
// // //                               context.read<LevelCubit>().updateLevel(level);
// // //                               showLevelUpDialog(
// // //                                 context,
// // //                                 level,
// // //                                 '15.4L',
// // //                               );
// // //                             }
// // //                           },
// // //                           child: getLevelBadges(level.toString(), isUnlocked),
// // //                         );
// // //                       },
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }

// // //   Widget getCurrentLevelBadge(
// // //     String level,
// // //   ) {
// // //     return SizedBox(
// // //       width: AppDimensions.dim330.w,
// // //       height: AppDimensions.dim320.h,
// // //       child: Stack(children: [
// // //         Positioned.fill(
// // //           child: Align(
// // //             alignment: Alignment.center,
// // //             child: Transform.translate(
// // //               offset:
// // //                   Offset(-16.w, 0), // move slightly left (use +8.w for right)
// // //               child: Image.asset(
// // //                 "assets/images/goals_new_img.png",
// // //                 width: AppDimensions.dim330.w,
// // //                 height: AppDimensions.dim320.h,
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //         Positioned(
// // //           left: AppDimensions.dim100.w,
// // //           top: AppDimensions.dim105.h,
// // //           child: SizedBox(
// // //             width: AppDimensions.dim100.w,
// // //             child: ShaderMask(
// // //               shaderCallback: (bounds) => const LinearGradient(
// // //                 colors: [
// // //                   Color(0xFF16446F),
// // //                   Color(0xFF2569A9),
// // //                   Color(0xFF59ADFB),
// // //                 ],
// // //               ).createShader(
// // //                 Rect.fromLTWH(
// // //                   0,
// // //                   0,
// // //                   bounds.width,
// // //                   bounds.height,
// // //                 ),
// // //               ),
// // //               blendMode: BlendMode.srcIn,
// // //               child: Transform.translate(
// // //                 offset: Offset(0, -5.h),
// // //                 child: Text(
// // //                   level,
// // //                   textAlign: TextAlign.center,
// // //                   style: TextStyle(
// // //                     fontSize: AppFontStyles.fontSize_80.sp,
// // //                     fontVariations: [
// // //                       AppFontStyles.boldFontVariation,
// // //                     ],
// // //                     //fontWeight: FontWeight.w900,
// // //                     fontFamily: AppFontStyles.poppinsFamily,
// // //                     //color: AppColors.white,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //         )
// // //       ]),
// // //     );
// // //   }

// // //   Widget getLevelBadges(String level, bool isUnlocked) {
// // //     return SizedBox(
// // //       height: AppDimensions.dim137.h,
// // //       width: AppDimensions.dim115.w,
// // //       child: Stack(
// // //         children: [
// // //           // Center image (locked or unlocked)
// // //           Align(
// // //             alignment: Alignment.topCenter,
// // //             child: isUnlocked
// // //                 ? Stack(
// // //                     alignment: Alignment.center,
// // //                     children: [
// // //                       Image.asset(
// // //                         "assets/images/goals_levels_img.png",
// // //                         width: AppDimensions.dim107.w,
// // //                         height: AppDimensions.dim111.h,
// // //                       ),
// // //                       ShaderMask(
// // //                         shaderCallback: (bounds) => const LinearGradient(
// // //                           colors: [
// // //                             Color(0xFF16446F),
// // //                             Color(0xFF2569A9),
// // //                             Color(0xFF59ADFB),
// // //                           ],
// // //                         ).createShader(
// // //                           Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// // //                         ),
// // //                         blendMode: BlendMode.srcIn,
// // //                         child: Text(
// // //                           level,
// // //                           style: TextStyle(
// // //                             color: AppColors.white,
// // //                             fontFamily: AppFontStyles.urbanistFontFamily,
// // //                             fontVariations: [
// // //                               AppFontStyles.extraBoldFontVariation
// // //                             ],
// // //                             fontSize: AppFontStyles.fontSize_28,
// // //                           ),
// // //                         ),
// // //                       )
// // //                     ],
// // //                   )
// // //                 : Image.asset(
// // //                     "assets/images/lock_goals_levels_img.png",
// // //                     width: AppDimensions.dim107.w,
// // //                     height: AppDimensions.dim111.h,
// // //                   ),
// // //           ),

// // //           // Center LEVEL NUMBER on unlocked badge
// // //           if (isUnlocked)
// // //             Positioned.fill(
// // //               child: Align(
// // //                 alignment: Alignment(0, -.25.h), // slight upward adjustment
// // //                 child: ShaderMask(
// // //                   shaderCallback: (bounds) => const LinearGradient(
// // //                     colors: [
// // //                       Color(0xFF16446F),
// // //                       Color(0xFF2569A9),
// // //                       Color(0xFF59ADFB),
// // //                     ],
// // //                   ).createShader(
// // //                     Rect.fromLTWH(0, 0, bounds.width, bounds.height),
// // //                   ),
// // //                   blendMode: BlendMode.srcIn,
// // //                   child: Text(
// // //                     level,
// // //                     style: TextStyle(
// // //                       color: AppColors.white,
// // //                       fontFamily: AppFontStyles.urbanistFontFamily,
// // //                       fontVariations: [AppFontStyles.extraBoldFontVariation],
// // //                       fontSize: AppFontStyles.fontSize_28,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),

// // //           // "Level x" text + liter text (centered)
// // //           Positioned(
// // //             top: AppDimensions.dim74.h,
// // //             left: AppDimensions.dim5.w,
// // //             right: 0,
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.center,
// // //               children: [
// // //                 Text(
// // //                   'Level $level',
// // //                   style: TextStyle(
// // //                     color: AppColors.bluegray,
// // //                     fontFamily: AppFontStyles.urbanistFontFamily,
// // //                     fontVariations: [AppFontStyles.boldFontVariation],
// // //                     fontSize: AppFontStyles.fontSize_14,
// // //                   ),
// // //                 ),
// // //                 SizedBox(height: AppDimensions.dim4.h),
// // //                 Text(
// // //                   'Weekly Intake: 15.4L',
// // //                   style: TextStyle(
// // //                     color: AppColors.bluegray,
// // //                     fontFamily: AppFontStyles.urbanistFontFamily,
// // //                     fontVariations: [AppFontStyles.regularFontVariation],
// // //                     fontSize: AppFontStyles.fontSize_10,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget getCongratulationsText(
// // //     String level,
// // //   ) {
// // //     return Container(
// // //       padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
// // //       child: Column(
// // //         mainAxisSize: MainAxisSize.min,
// // //         crossAxisAlignment: CrossAxisAlignment.center,
// // //         children: [
// // //           Text(
// // //             '${AppStrings.levelreach} $level !',
// // //             style: TextStyle(
// // //               color: AppColors.bluegray,
// // //               fontFamily: AppFontStyles.urbanistFontFamily,
// // //               fontSize: AppFontStyles.fontSize_20.sp,
// // //               fontVariations: [AppFontStyles.boldFontVariation],
// // //             ),
// // //           ),
// // //           SizedBox(height: AppDimensions.dim10.h),
// // //           Text(
// // //             AppStrings.congratulations,
// // //             textAlign: TextAlign.center,
// // //             style: TextStyle(
// // //               fontFamily: AppFontStyles.urbanistFontFamily,
// // //               fontVariations: [AppFontStyles.fontWeightVariation600],
// // //               color: AppColors.bluegray,
// // //               fontSize: AppFontStyles.fontSize_14.sp,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
