import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewConfigurationDialog extends StatelessWidget {

  const NewConfigurationDialog({super.key});

  static bool _isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (_isShowing) return;
    _isShowing = true;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'New Configuration',
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: const Center(
            child: Material(
              color: Colors.transparent,
              child: NewConfigurationDialogContent(),
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
  const NewConfigurationDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340.w,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            221, 226, 226, 226), // Light grey matching the image
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
                  AssetsPath.touchBottle,
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
            height: 54.h,
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
            height: 54.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27.h),
              color: Colors.white.withOpacity(0.3),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
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
}
