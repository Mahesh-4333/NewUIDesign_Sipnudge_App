import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';

class BleRetryDialog extends StatelessWidget {
  const BleRetryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Blur
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              context.read<BleCubit>().dismissRetryDialog();
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
        ),

        // Dialog Content
        Center(
          child: Container(
            width: 320.w,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: AppColors.blueWaterIntake.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.blueWaterIntake.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_rounded,
                    color: AppColors.blueWaterIntake,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  "Connection Stuck?",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontFamily: AppFontStyles.museoModernoFontFamily,
                    fontSize: 22.sp,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: 12.h),

                // Description
                Text(
                  "We're having trouble finding your Sipnudge bottle. Refreshing the Bluetooth service might help.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.bluegray.withOpacity(0.8),
                    fontSize: 14.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    height: 1.5,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                ),
                SizedBox(height: 28.h),

                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<BleCubit>().dismissRetryDialog();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Later",
                          style: TextStyle(
                            color: AppColors.bluegray.withOpacity(0.6),
                            fontSize: 16.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.semiBoldFontVariation],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Retry Button
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.blueWaterIntake,
                              AppColors.blueWaterIntake.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blueWaterIntake.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<BleCubit>().reinitialize();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "Refresh BLE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
