import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/bottle_info.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/home_widget_service.dart';

class NewConfigurationDialog extends StatelessWidget {
  const NewConfigurationDialog({super.key});

  static bool _isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (_isShowing) return;
    _isShowing = true;

    final color = await SharedPrefsHelper.getBottleColor() ?? 'black';
    final bottleState = context.read<BottleDataCubit>().state;
    final bottleInfo = BottleInfo.getByColor(
      color,
      currentWater: bottleState.volume,
      waterPercentage: bottleState.volumePercent,
    );

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'New Configuration',
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 340.w,
                decoration: BoxDecoration(
                  // color: Colors.white,
                  borderRadius: BorderRadius.circular(32.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(254, 217, 225, 232),
                      Color.fromARGB(67, 181, 194, 205),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Gradient Section with Bottle Image
                    Container(
                      width: double.infinity,
                      height: 220.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32.r),
                          topRight: Radius.circular(32.r),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // SYSTEM ALERT Label
                          Positioned(
                            top: 16.h,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sensors,
                                  size: 14.sp,
                                  color: const Color(0xFF00A3FF),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  "SYSTEM ALERT",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    color: const Color(0xFF4A6B7C),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Circular Bottle Background
                          Container(
                            width: 150.w,
                            height: 150.w,
                            margin: EdgeInsets.only(top: 20.h),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF6D8C94),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                bottleInfo.imagePath,
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                     NewConfigurationDialogContent(bottleInfo: bottleInfo),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    _isShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Not used directly in widget tree
  }
}

class NewConfigurationDialogContent extends StatelessWidget {
  final BottleInfo bottleInfo;
  const NewConfigurationDialogContent({super.key, required this.bottleInfo});

  String _getTouchAsset() {
    switch (bottleInfo.color.toLowerCase()) {
      case 'red':
        return AssetsPath.onboardingRedTouch;
      case 'black':
        return AssetsPath.onboardingBlackTouch;
      case 'purple':
      default:
        return AssetsPath.onboardingPurpleTouch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340.w,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            190, 226, 226, 226), // Light grey matching the image
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(111, 223, 223, 223).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "New Configuration Detected",
            style: TextStyle(
              fontSize: 18.sp,
              fontVariations: [AppFontStyles.boldFontVariation],
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: const Color(0xFF4A6B7C),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          // Info Container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB).withOpacity(0.5),
              borderRadius: BorderRadius.circular(100.r),
              border:
                  Border.all(color: Colors.white.withOpacity(0.8), width: 1),
            ),
            child: Row(
              children: [
                Image.asset(
                  _getTouchAsset(),
                  width: 40.w,
                  height: 40.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "Touch the bottle cap to activate the bottle and sync new configuration settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF4A6B7C),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Sync Now Button
          Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27.h),
              color: Color(0xFF00A3FF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A3FF).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(27.h),
                onTap: () {
                  Navigator.of(context).pop();
                  _syncConfigurationAndGoal(context, sendToBle: true);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync, color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Sync Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: 16.sp,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Later Button
          Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27.h),
              color: const Color.fromARGB(122, 255, 255, 255).withOpacity(0.3),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27.h),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _syncConfigurationAndGoal(context, sendToBle: false);
                    },
                    child: Center(
                      child: Text(
                        "Later",
                        style: TextStyle(
                          color: AppColors.darkgray,
                          fontSize: 16.sp,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
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

  static Future<void> _syncConfigurationAndGoal(BuildContext context,
      {required bool sendToBle}) async {
    try {
      final bleCubit = context.read<BleCubit>();
      final waterGoal = await SharedPrefsHelper.getWaterGoal();
      final userId = await SharedPrefsHelper.getUserId();
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final dateUtc = "${todayStr}T00:00:00.000Z";

      if (waterGoal != null && waterGoal > 0) {
        if (userId != null && userId.isNotEmpty && userId != "guest_user") {
          try {
            // 1. Direct push to server DailyGoal collection
            await ApiService().syncDailyGoals(userId, [
              {
                'date': todayStr,
                'goal': waterGoal,
              }
            ]);

            // 2. Direct update to server DailySummary target
            final dbHelper = DatabaseHelper();
            final todaySummary = await dbHelper.getSummaryForDate(today);
            final consumed = todaySummary?.consumed ?? 0.0;
            final isPerfect = consumed >= waterGoal;
            await ApiService().updateTodayConsumed(
              userId,
              dateUtc,
              consumed,
              isPerfect,
              target: waterGoal.toDouble(),
              force: false,
            );
          } catch (e) {
            Console.log(
                tag: "CONFIG_DIALOG",
                value: "Error updating server daily goal: $e");
          }
        }

        // 3. Immediately refresh widget
        await HomeWidgetService.updateWidgetData();
      }

      if (sendToBle) {
        await bleCubit.flushPendingConfigurations();
      }

      DatabaseSyncService().syncAll(force: true);
    } catch (e) {
      Console.log(
          tag: "CONFIG_DIALOG",
          value: "Error in _syncConfigurationAndGoal: $e");
    }
  }
}
