import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/services/ai_hydration_engine.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:hydrify/helpers/logger.dart';

class AiHydrationGoalDialog extends StatelessWidget {
  final AiHydrationResult result;
  final int previousDayGoal;

  const AiHydrationGoalDialog({
    super.key,
    required this.result,
    required this.previousDayGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: Color(0xff82bcea).withValues(alpha: 0.2)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Transform.scale(
          scale: 0.95,
          child: Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40.r)),
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF96D6F4), // More prominent blue at the top right
                    Color(0xFFE0EFF4), // So
                    Color(0xFFE0EFF4), // Soft transition
                    Color(0xFFD8EFF3), // Bottom left
                    Color(0xFFe0edf0), // Bottom left
                  ],
                  stops: [0.0, 0.2, 0.4, 1.0, 0.9],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(40.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Stack(
                  children: [
                    Positioned(
                      top: -100.w,
                      right: -100.w,
                      child: Container(
                        width: 200.w,
                        height: 200.h,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 40.h),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF96D6F4),
                              blurRadius: 30,
                              offset: const Offset(-30, 5),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              "AI Goal Update",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: 30.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // Main Goal Value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _formatNumber(result.totalGoalMl.toInt()),
                                  style: TextStyle(
                                    color: AppColors.blueWaterIntake,
                                    fontSize: 54.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.extraBoldFontVariation
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "mL",
                                  style: TextStyle(
                                    color: Color(0xff00629D),
                                    fontSize: 22.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),

                            // Comparison Badge
                            if (result.totalGoalMl > previousDayGoal)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFD5E3FC),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                        color: AppColors.greyColorText1
                                            .withValues(alpha: 0.4),
                                        width: 1.8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.trending_up,
                                        color: const Color(0xFF10B981),
                                        size: 18.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "+${(result.totalGoalMl - previousDayGoal).toInt()} mL from yesterday",
                                      style: TextStyle(
                                        color: AppColors.bluegray,
                                        fontSize: 13.sp,
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontVariations: [
                                          AppFontStyles.boldFontVariation
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 20.h),

                            // Base Needs Card (Wide)
                            _buildBaseNeedsCard(),
                            SizedBox(height: 20.h),

                            // Grid Section (2x2)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    path: AssetsPath.aiSteps,
                                    iconColor: const Color(0xFFFB7185),
                                    label: "Steps",
                                    value:
                                        "${(result.steps / 1000).toStringAsFixed(1)}k",
                                    adjustment:
                                        "+${result.stepsAdjMl.toInt()}mL",
                                    adjColor: const Color(0xFF0D9488),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _buildMetricCard(
                                    path: AssetsPath.aiTemp,
                                    iconColor: const Color(0xFFEF4444),
                                    label: "Temp",
                                    value: "${result.temperatureC.toInt()}°C",
                                    adjustment:
                                        "+${result.tempAdjMl.toInt()}mL",
                                    adjColor: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    path: AssetsPath.caffiene,
                                    iconColor: const Color(0xFF6366F1),
                                    label: "Caffeine",
                                    value:
                                        "${(result.caffeineMg / 60).toInt()} Cups",
                                    adjustment:
                                        "+${result.caffeineAdjMl.toInt()}mL",
                                    adjColor: const Color(0xFF0D9488),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _buildMetricCard(
                                    path: AssetsPath.foodWater,
                                    iconColor: const Color(0xFFFBBF24),
                                    label: "Food Water",
                                    value: "Est.",
                                    adjustment:
                                        "-${result.foodWaterMl.toInt()}mL",
                                    adjColor: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 40.h),

                            // Action Buttons
                            _buildButton(
                              label: "Accept New Goal",
                              onPressed: () async {
                                final goal = result.totalGoalMl.toInt();
                                Navigator.of(context).pop(false);
                                try {
                                  await SharedPrefsHelper.setAiHydrationGoalShown(false);
                                  await SharedPrefsHelper.setWaterGoal(goal);
                                  await DatabaseHelper().saveDailyWaterGoal(DateTime.now(), goal);
                                  await SharedPrefsHelper.updateAndSaveDeviceConfig(waterGoal: goal);
                                } catch (e) {
                                  Console.log(tag: "AI_GOAL_DIALOG", value: "Error accepting new goal: $e");
                                }
                              },
                              isPrimary: true,
                            ),
                            SizedBox(height: 16.h),
                            _buildButton(
                              label: "Keep Current Goal",
                              onPressed: () async {
                                Navigator.of(context).pop(true);
                                try {
                                  await SharedPrefsHelper.setAiHydrationGoalShown(false);
                                } catch (e) {
                                  Console.log(tag: "AI_GOAL_DIALOG", value: "Error keeping current goal: $e");
                                }
                              },
                              isPrimary: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBaseNeedsCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(100.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(AssetsPath.user, height: 50.h, width: 50.w),
          SizedBox(width: 30.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Base Needs",
                  style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation]),
                ),
                Text(
                  "Weight & Age",
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(result.baseGoalMl.toInt()),
                style: TextStyle(
                  color: const Color(0xFF00629D),
                  fontSize: 20.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                "mL",
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ],
          ),
          SizedBox(
            width: 4.w,
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String path,
    required Color iconColor,
    required String label,
    required String value,
    required String adjustment,
    required Color adjColor,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: AppStyle.boxShadowVariation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(path, height: 50.h, width: 50.w),
          SizedBox(height: 16.h),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 14.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              Text(
                adjustment,
                style: TextStyle(
                  color: adjColor,
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    if (!isPrimary) {
      return GestureDetector(
        onTap: onPressed,
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 52.h,
          borderRadius: 24.r,
          blur: 15,
          alignment: Alignment.center,
          border: 1.3,
          linearGradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFe0ebef).withOpacity(0.5),
                Color(0xFFe0ebef).withOpacity(0.3),
              ],
              stops: [
                0.1,
                1,
              ]),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFffffff).withOpacity(0.5),
              Color((0xFFFFFFFF)).withOpacity(0.5),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF475569),
              fontSize: 18.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00A3FF), Color(0xFF00A3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A3FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
