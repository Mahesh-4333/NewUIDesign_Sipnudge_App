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

  @override
  void initState() {
    super.initState();
    _checkGuestUser();
  }

  // 🔥 KEY FIX: refresh whenever screen becomes active
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHydrationData();
  }

  Future<void> _checkGuestUser() async {
    final userEmail = await SharedPrefsHelper.getUserEmail();
    if (!mounted) return;

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

    final dailyGoalMl = _dailyWaterGoal > 0 ? _dailyWaterGoal : 1400;
    int count = 0;

    for (final summary in _hydrationData) {
      final target =
          summary.target > 0 ? summary.target : dailyGoalMl.toDouble();
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
    if (isGuest == null || _loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/app_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.bluegray),
          ),
        ),
      );
    }

    if (isGuest!) return _buildGuestScreen();
    return _buildRegularScreen();
  }

  // ---------------- GUEST SCREEN ----------------

  Widget _buildGuestScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/app_background.png"),
                fit: BoxFit.cover,
              ),
<<<<<<< HEAD
              //color: Color(0XFFFFFFFF),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              "assets/images/app_background.png"),
                          fit: BoxFit.cover,
                        ),
                        // gradient: LinearGradient(
                        //   begin: Alignment.topCenter,
                        //   end: Alignment.bottomCenter,
                        //   colors: [AppColors.gradientStart, Color(0XFF2E2630)],
                        // ),
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          Positioned(
                              child:
                                  ConcentricCirclesAnimation()),
                          Positioned(
                            left: AppDimensions.dim75.w,
                            top: AppDimensions.dim90.w,
                            child: getCurrentLevelBadge(
                              currentLevel.toString(),
                            ),
                          ),
                          Positioned(
                            top: AppDimensions.dim380.h,
                            left: 0,
                            right: 0,
                            child: getCongratulationsText(
                              currentLevel.toString(),
                            ),
                          ),
                        ],
                      )),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x1A000000),
                          offset: const Offset(0, -6),
                          blurRadius: 44,
                          spreadRadius: 0,
                        ),
                      ],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            AppDimensions.radius_24.r),
                        topRight: Radius.circular(
                            AppDimensions.radius_24.r),
                      ),
                    ),
                    padding: EdgeInsets.all(
                        AppDimensions.padding_20.h),
                    child: GridView.builder(
                      padding: EdgeInsets.only(
                          bottom: AppDimensions.dim100.h),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2.r,
                        mainAxisSpacing: 24.h,
                        crossAxisSpacing: 0.w,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final level = index + 1;
                        final isUnlocked = level <= currentLevel;
                        return GestureDetector(
                          onTap: () {
                            if (level > currentLevel) {
                              context
                                  .read<LevelCubit>()
                                  .updateLevel(level);
                              showLevelUpDialog(
                                context,
                                level,
                                '15.4L',
                              );
                            }
                          },
                          child: getLevelBadges(
                              level.toString(), isUnlocked),
                        );
                      },
                    ),
                  ),
                ),
              ],
>>>>>>> origin/develop
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          Center(
            child: Text(
              "Connect to Sipnudge bottle to access analysis",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.bluegray,
                fontFamily: AppFontStyles.museoModernoFontFamily,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- REGULAR SCREEN ----------------

  Widget _buildRegularScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
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
                    top: Radius.circular(AppDimensions.radius_24.r),
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
                    final unlocked = level <= _currentLevel;
                    final intake = _getWaterIntakeForLevel(level);

                    return GestureDetector(
                      onTap: unlocked
                          ? () => showLevelUpDialog(context, level, intake)
                          : null,
                      child: getLevelBadges(
                        level.toString(),
                        unlocked,
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
    );
  }

  // Widget getCurrentLevelBadge(String level) {
  //   return SizedBox(
  //     width: AppDimensions.dim330.w,
  //     height: AppDimensions.dim320.h,
  //     child: Stack(
  //       children: [
  //         Positioned.fill(
  //           child: Align(
  //             alignment: Alignment.center,
  //             child: Transform.translate(
  //               offset: Offset(-16.w, 0),
  //               child: Image.asset(
  //                 "assets/images/goals_new_img.png",
  //                 width: AppDimensions.dim330.w,
  //                 height: AppDimensions.dim320.h,
  //               ),
  //             ),
  //           ),
  //         ),
  //         Positioned(
  //           left: AppDimensions.dim100.w,
  //           top: AppDimensions.dim105.h,
  //           child: SizedBox(
  //             width: AppDimensions.dim100.w,
  //             child: ShaderMask(
  //               shaderCallback: (bounds) => const LinearGradient(
  //                 colors: [
  //                   Color(0xFF16446F),
  //                   Color(0xFF2569A9),
  //                   Color(0xFF59ADFB),
  //                 ],
  //               ).createShader(
  //                 Rect.fromLTWH(0, 0, bounds.width, bounds.height),
  //               ),
  //               blendMode: BlendMode.srcIn,
  //               child: Transform.translate(
  //                 offset: Offset(0, -5.h),
  //                 child: Text(
  //                   level,
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     fontSize: AppFontStyles.fontSize_80.sp,
  //                     fontVariations: [AppFontStyles.boldFontVariation],
  //                     fontFamily: AppFontStyles.poppinsFamily,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  Widget getCurrentLevelBadge(String level) {
    final int currentLevelNum = int.tryParse(level) ?? 0;
    //final bool isCurrentLevelUnlocked = currentLevelNum <= _currentLevel;
    final bool isCurrentLevelUnlocked =
        currentLevelNum > 0 && currentLevelNum <= _currentLevel;

    return SizedBox(
      width: AppDimensions.dim330.w,
      height: AppDimensions.dim320.h,
<<<<<<< HEAD
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
                  width: isCurrentLevelUnlocked
                      ? AppDimensions.dim330.w
                      : AppDimensions.dim270.w,
                  height: isCurrentLevelUnlocked
                      ? AppDimensions.dim320.h
                      : AppDimensions.dim260.h,
                  fit: BoxFit.contain,
                ),
      child: Stack(children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(-16.w,
                  0), // move slightly left (use +8.w for right)
              child: Image.asset(
                "assets/images/goals_new_img.png",
                width: AppDimensions.dim330.w,
                height: AppDimensions.dim320.h,
>>>>>>> origin/develop
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
                : Image.asset(
                    "assets/images/lock_goals_levels_img.png",
                    width: AppDimensions.dim107.w,
                    height: AppDimensions.dim111.h,
                  ),
          ),

          // Level number - only show on unlocked badges
          if (isUnlocked)
            Positioned.fill(
              child: Align(
                alignment: Alignment(0, -0.1), // slight upward adjustment
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                    colors: [
                      Color(0xFF16446F),
                      Color(0xFF2569A9),
                      Color(0xFF59ADFB),
                    ],
                  ).createShader(
                    Rect.fromLTWH(
                        0, 0, bounds.width, bounds.height),
                  ),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    level,
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily:
                          AppFontStyles.urbanistFontFamily,
                      fontVariations: [
                        AppFontStyles.extraBoldFontVariation
                      ],
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
                    fontVariations: [
                      AppFontStyles.boldFontVariation
                    ],
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
                    fontVariations: [
                      AppFontStyles.regularFontVariation
                    ],
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
      padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim20.w),
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
              fontVariations: [
                AppFontStyles.fontWeightVariation600
              ],
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/level/level_cubit.dart';
// import 'package:hydrify/cubit/level/level_state.dart';
// import 'package:hydrify/screens/levelreached.dart';
// import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

// class AchievementsBadgeScreen extends StatelessWidget {
//   const AchievementsBadgeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<LevelCubit, LevelState>(
//       builder: (context, state) {
//         var currentLevel = state.currentLevel;

//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             decoration: BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/images/app_background.png"),
//                 fit: BoxFit.cover,
//               ),
//               //color: Color(0XFFFFFFFF),
//             ),
//             child: Column(
//               children: [
//                 Expanded(
//                   child: Container(
//                       decoration: BoxDecoration(
//                         image: DecorationImage(
//                           image: AssetImage("assets/images/app_background.png"),
//                           fit: BoxFit.cover,
//                         ),
//                         // gradient: LinearGradient(
//                         //   begin: Alignment.topCenter,
//                         //   end: Alignment.bottomCenter,
//                         //   colors: [AppColors.gradientStart, Color(0XFF2E2630)],
//                         // ),
//                       ),
//                       alignment: Alignment.center,
//                       child: Stack(
//                         children: [
//                           Positioned(child: ConcentricCirclesAnimation()),
//                           Positioned(
//                             left: AppDimensions.dim75.w,
//                             top: AppDimensions.dim90.w,
//                             child: getCurrentLevelBadge(
//                               currentLevel.toString(),
//                             ),
//                           ),
//                           Positioned(
//                             top: AppDimensions.dim380.h,
//                             left: 0,
//                             right: 0,
//                             child: getCongratulationsText(
//                               currentLevel.toString(),
//                             ),
//                           ),
//                         ],
//                       )),
//                 ),
//                 Expanded(
//                   child: Container(
//                     alignment: Alignment.center,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFFFFF),
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0x1A000000),
//                           offset: const Offset(0, -6),
//                           blurRadius: 44,
//                           spreadRadius: 0,
//                         ),
//                       ],
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(AppDimensions.radius_24.r),
//                         topRight: Radius.circular(AppDimensions.radius_24.r),
//                       ),
//                     ),
//                     padding: EdgeInsets.all(AppDimensions.padding_20.h),
//                     child: GridView.builder(
//                       padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
//                       physics: const BouncingScrollPhysics(),
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 3,
//                         childAspectRatio: 1.2.r,
//                         mainAxisSpacing: 24.h,
//                         crossAxisSpacing: 0.w,
//                       ),
//                       itemCount: 10,
//                       itemBuilder: (context, index) {
//                         final level = index + 1;
//                         final isUnlocked = level <= currentLevel;
//                         return GestureDetector(
//                           onTap: () {
//                             if (level > currentLevel) {
//                               context.read<LevelCubit>().updateLevel(level);
//                               showLevelUpDialog(
//                                 context,
//                                 level,
//                                 '15.4L',
//                               );
//                             }
//                           },
//                           child: getLevelBadges(level.toString(), isUnlocked),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget getCurrentLevelBadge(
//     String level,
//   ) {
//     return SizedBox(
//       width: AppDimensions.dim330.w,
//       height: AppDimensions.dim320.h,
//       child: Stack(children: [
//         Positioned.fill(
//           child: Align(
//             alignment: Alignment.center,
//             child: Transform.translate(
//               offset:
//                   Offset(-16.w, 0), // move slightly left (use +8.w for right)
//               child: Image.asset(
//                 "assets/images/goals_new_img.png",
//                 width: AppDimensions.dim330.w,
//                 height: AppDimensions.dim320.h,
//               ),
//             ),
//           ),
//         ),
//         Positioned(
//           left: AppDimensions.dim100.w,
//           top: AppDimensions.dim105.h,
//           child: SizedBox(
//             width: AppDimensions.dim100.w,
//             child: ShaderMask(
//               shaderCallback: (bounds) => const LinearGradient(
//                 colors: [
//                   Color(0xFF16446F),
//                   Color(0xFF2569A9),
//                   Color(0xFF59ADFB),
//                 ],
//               ).createShader(
//                 Rect.fromLTWH(
//                   0,
//                   0,
//                   bounds.width,
//                   bounds.height,
//                 ),
//               ),
//               blendMode: BlendMode.srcIn,
//               child: Transform.translate(
//                 offset: Offset(0, -5.h),
//                 child: Text(
//                   level,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: AppFontStyles.fontSize_80.sp,
//                     fontVariations: [
//                       AppFontStyles.boldFontVariation,
//                     ],
//                     //fontWeight: FontWeight.w900,
//                     fontFamily: AppFontStyles.poppinsFamily,
//                     //color: AppColors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         )
//       ]),
//     );
//   }

//   Widget getLevelBadges(String level, bool isUnlocked) {
//     return SizedBox(
//       height: AppDimensions.dim137.h,
//       width: AppDimensions.dim115.w,
//       child: Stack(
//         children: [
//           // Center image (locked or unlocked)
//           Align(
//             alignment: Alignment.topCenter,
//             child: isUnlocked
//                 ? Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       Image.asset(
//                         "assets/images/goals_levels_img.png",
//                         width: AppDimensions.dim107.w,
//                         height: AppDimensions.dim111.h,
//                       ),
//                       ShaderMask(
//                         shaderCallback: (bounds) => const LinearGradient(
//                           colors: [
//                             Color(0xFF16446F),
//                             Color(0xFF2569A9),
//                             Color(0xFF59ADFB),
//                           ],
//                         ).createShader(
//                           Rect.fromLTWH(0, 0, bounds.width, bounds.height),
//                         ),
//                         blendMode: BlendMode.srcIn,
//                         child: Text(
//                           level,
//                           style: TextStyle(
//                             color: AppColors.white,
//                             fontFamily: AppFontStyles.urbanistFontFamily,
//                             fontVariations: [
//                               AppFontStyles.extraBoldFontVariation
//                             ],
//                             fontSize: AppFontStyles.fontSize_28,
//                           ),
//                         ),
//                       )
//                     ],
//                   )
//                 : Image.asset(
//                     "assets/images/lock_goals_levels_img.png",
//                     width: AppDimensions.dim107.w,
//                     height: AppDimensions.dim111.h,
//                   ),
//           ),

//           // Center LEVEL NUMBER on unlocked badge
//           if (isUnlocked)
//             Positioned.fill(
//               child: Align(
//                 alignment: Alignment(0, -.25.h), // slight upward adjustment
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

//           // "Level x" text + liter text (centered)
//           Positioned(
//             top: AppDimensions.dim74.h,
//             left: AppDimensions.dim5.w,
//             right: 0,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Text(
//                   'Level $level',
//                   style: TextStyle(
//                     color: AppColors.bluegray,
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [AppFontStyles.boldFontVariation],
//                     fontSize: AppFontStyles.fontSize_14,
//                   ),
//                 ),
//                 SizedBox(height: AppDimensions.dim4.h),
//                 Text(
//                   'Weekly Intake: 15.4L',
//                   style: TextStyle(
//                     color: AppColors.bluegray,
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

//   Widget getCongratulationsText(
//     String level,
//   ) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             '${AppStrings.levelreach} $level !',
//             style: TextStyle(
//               color: AppColors.bluegray,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontSize: AppFontStyles.fontSize_20.sp,
//               fontVariations: [AppFontStyles.boldFontVariation],
//             ),
//           ),
//           SizedBox(height: AppDimensions.dim10.h),
//           Text(
//             AppStrings.congratulations,
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
