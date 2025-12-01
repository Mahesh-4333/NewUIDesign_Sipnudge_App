import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/level/level_cubit.dart';
import 'package:hydrify/cubit/level/level_state.dart';
import 'package:hydrify/screens/levelreached.dart';
import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

class AchievementsBadgeScreen extends StatelessWidget {
  const AchievementsBadgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LevelCubit, LevelState>(
      builder: (context, state) {
        var currentLevel = state.currentLevel;

        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/app_background.png"),
                fit: BoxFit.cover,
              ),
              //color: Color(0XFFFFFFFF),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/app_background.png"),
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
                          Positioned(child: ConcentricCirclesAnimation()),
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
                        topLeft: Radius.circular(AppDimensions.radius_24.r),
                        topRight: Radius.circular(AppDimensions.radius_24.r),
                      ),
                    ),
                    padding: EdgeInsets.all(AppDimensions.padding_20.h),
                    child: GridView.builder(
                      padding: EdgeInsets.only(bottom: AppDimensions.dim100.h),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                              context.read<LevelCubit>().updateLevel(level);
                              showLevelUpDialog(
                                context,
                                level,
                                '15.4L',
                              );
                            }
                          },
                          child: getLevelBadges(level.toString(), isUnlocked),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getCurrentLevelBadge(
    String level,
  ) {
    return SizedBox(
      width: AppDimensions.dim330.w,
      height: AppDimensions.dim320.h,
      child: Stack(children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset:
                  Offset(-16.w, 0), // move slightly left (use +8.w for right)
              child: Image.asset(
                "assets/images/goals_new_img.png",
                width: AppDimensions.dim330.w,
                height: AppDimensions.dim320.h,
              ),
            ),
          ),
        ),
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
                Rect.fromLTWH(
                  0,
                  0,
                  bounds.width,
                  bounds.height,
                ),
              ),
              blendMode: BlendMode.srcIn,
              child: Transform.translate(
                offset: Offset(0, -5.h),
                child: Text(
                  level,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontStyles.fontSize_80.sp,
                    fontVariations: [
                      AppFontStyles.boldFontVariation,
                    ],
                    //fontWeight: FontWeight.w900,
                    fontFamily: AppFontStyles.poppinsFamily,
                    //color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        )
      ]),
    );
  }

  Widget getLevelBadges(String level, bool isUnlocked) {
    return SizedBox(
      height: AppDimensions.dim137.h,
      width: AppDimensions.dim115.w,
      child: Stack(
        children: [
          // Center image (locked or unlocked)
          Align(
            alignment: Alignment.topCenter,
            child: isUnlocked
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        "assets/images/goals_levels_img.png",
                        width: AppDimensions.dim107.w,
                        height: AppDimensions.dim111.h,
                      ),
                      ShaderMask(
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
                            fontVariations: [
                              AppFontStyles.extraBoldFontVariation
                            ],
                            fontSize: AppFontStyles.fontSize_28,
                          ),
                        ),
                      )
                    ],
                  )
                : Image.asset(
                    "assets/images/lock_goals_levels_img.png",
                    width: AppDimensions.dim107.w,
                    height: AppDimensions.dim111.h,
                  ),
          ),

          // Center LEVEL NUMBER on unlocked badge
          // if (isUnlocked)
          //   Positioned.fill(
          //     child: Align(
          //       alignment: Alignment(0, -0.3), // slight upward adjustment
          //       child: ShaderMask(
          //         shaderCallback: (bounds) => const LinearGradient(
          //           colors: [
          //             Color(0xFF16446F),
          //             Color(0xFF2569A9),
          //             Color(0xFF59ADFB),
          //           ],
          //         ).createShader(
          //           Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          //         ),
          //         blendMode: BlendMode.srcIn,
          //         child: Text(
          //           level,
          //           style: TextStyle(
          //             color: AppColors.white,
          //             fontFamily: AppFontStyles.urbanistFontFamily,
          //             fontVariations: [AppFontStyles.extraBoldFontVariation],
          //             fontSize: AppFontStyles.fontSize_28,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),

          // "Level x" text + liter text (centered)
          Positioned(
            top: AppDimensions.dim74.h,
            left: AppDimensions.dim5.w,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Level $level',
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    fontSize: AppFontStyles.fontSize_14,
                  ),
                ),
                SizedBox(height: AppDimensions.dim4.h),
                Text(
                  'Weekly Intake: 15.4L',
                  style: TextStyle(
                    color: AppColors.bluegray,
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

  Widget getCongratulationsText(
    String level,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${AppStrings.levelreach} $level !',
            style: TextStyle(
              color: AppColors.bluegray,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontSize: AppFontStyles.fontSize_20.sp,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: AppDimensions.dim10.h),
          Text(
            AppStrings.congratulations,
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
