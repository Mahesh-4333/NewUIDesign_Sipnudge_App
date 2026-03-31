import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/screens/auth/local_auth_screen.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutBottomSheet extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  const LogoutBottomSheet({super.key, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🔹 Blur background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: Colors.black.withOpacity(0)),
        ),

        /// 🔹 Bottom Sheet UI
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              //color: AppColors.white,
              image: DecorationImage(
                image: AssetImage(
                  "assets/images/logout_bottomsheet2.png",
                ),
                // your image path
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radius_30.r)),
              border: Border.all(
                color: Color(0xFFD0CBCB), // change to your preferred color
                width: 1.w, // border thickness
              ),
            ),
            padding: EdgeInsets.only(
              top: AppDimensions.dim15.h,
              left: AppDimensions.dim30.w,
              right: AppDimensions.dim30.w,
              bottom: AppDimensions.dim30.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.logout,
                  style: TextStyle(
                    fontSize: AppFontStyles.fontSize_24.sp,
                    color: AppColors.brightReddishPink,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: AppDimensions.dim48.h),
                Text(
                  AppStrings.areYouSureYouWantToLogout,
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.fontWeightVariation600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.dim48.h),
                Row(
                  children: [
                    /// ❌ Cancel Button (No Border)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radius_30),
                            boxShadow: [
                              BoxShadow(
                                  offset: Offset(4, 4),
                                  blurRadius: AppDimensions.radius_4,
                                  color: Color(0x25000000)),
                            ]),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.paleblue,
                            side: BorderSide.none, // 🔹 Removed border
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radius_46.r),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.dim14.h),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              color: AppColors.eerieBlack,
                              fontSize: AppFontStyles.fontSize_16.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: AppDimensions.dim12.h),

                    /// ✅ Yes, Logout Button (With White Border)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radius_30),
                            boxShadow: [
                              BoxShadow(
                                  offset: Offset(4.r, 4.r),
                                  blurRadius: AppDimensions.radius_4,
                                  color: Color(0x25000000)),
                            ]),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            // shadowColor: Color(0x25000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radius_46.r),
                              side: BorderSide(
                                // color: AppColors.white, // 🔹 White border
                                color: Colors.white,
                                width: AppDimensions.dim2.w,
                              ),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              // 1Logout & clear data
                              await FirebaseAuth.instance.signOut();
                              await UserManager().clear();

                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();

                              if (!context.mounted) return;

                              // Close the bottom sheet (optional but nice)
                              Navigator.of(context, rootNavigator: true).pop();

                              context.read<BottomNavCubit>().resetToHome();

                              //  Navigate to LocalAuthScreen as new root
                              Navigator.of(context, rootNavigator: true)
                                  .pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LocalAuthScreen(),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error logging out: ${e.toString()}'),
                                ),
                              );
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: AppColors.bluegray,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radius_46.r),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: AppDimensions.dim14.h),
                              child: Text(
                                AppStrings.yesLogout,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: AppFontStyles.fontSize_16.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation
                                  ],
                                ),
                              ),
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
