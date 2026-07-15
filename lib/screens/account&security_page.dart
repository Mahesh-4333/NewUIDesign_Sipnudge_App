import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/account&security/account&security_cubit.dart';
import 'package:hydrify/cubit/account&security/account&security_state.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/local_auth_screen.dart';
import 'package:hydrify/screens/widgets/account&security_widgets/toggle_state_widget.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountAndSecurityPage extends StatelessWidget {
  const AccountAndSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppStrings.accountandsecurity,
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_AppBar,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              AppFontStyles.boldFontVariation,
            ],
          ),
        ),
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            "assets/images/back_ic.svg",
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 32.h,
                    horizontal: 24.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xCCC6C6C6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12.r,
                        spreadRadius: 2.r,
                        offset: Offset(0, 4.r),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72.r,
                        height: 72.r,
                        decoration: BoxDecoration(
                          color: AppColors.errorRedColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.errorRedColor,
                          size: 38.r,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        AppStrings.deleteaccount,
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: 22.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.accountremove,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.darkgray,
                          fontSize: 15.sp,
                          height: 1.5,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showDeleteConfirmation(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRedColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: Text(
                            AppStrings.deleteaccount,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation bottom sheet before permanently deleting the account.
  void _showDeleteConfirmation(BuildContext context) async {
    context.read<BottomNavCubit>().hideBar();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteAccountSheet(parentContext: context),
    );
    context.read<BottomNavCubit>().showBar();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Account Confirmation Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  final BuildContext parentContext;
  const _DeleteAccountSheet({required this.parentContext});

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  bool _isDeleting = false;

  Future<void> _performDelete() async {
    setState(() => _isDeleting = true);

    try {
      final userId = await SharedPrefsHelper.getUserId();
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (userId == null) {
        _showError('Could not find your account. Please try again.');
        return;
      }

      // 1. Call backend to permanently delete all data
      final apiService = ApiService();
      final success = await apiService.deleteAccount(
        userId,
        firebaseUid: firebaseUser?.uid,
      );

      if (!success) {
        _showError('Failed to delete account. Please try again.');
        return;
      }

      // 2. Sign out Firebase Auth (backend already deleted the Auth user)
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      // 3. Clear local data
      await UserManager().clear();
      await DatabaseHelper().clearAllDatabaseData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Console.log(tag: 'DELETE_ACCOUNT', value: 'Account permanently deleted.');

      if (!mounted) return;

      // 4. Close bottom sheet and navigate to login
      Navigator.of(context).pop();

      widget.parentContext.read<BottomNavCubit>().resetToHome();

      Navigator.of(widget.parentContext, rootNavigator: true)
          .pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LocalAuthScreen()),
        (route) => false,
      );
    } catch (e) {
      Console.log(tag: 'DELETE_ACCOUNT', value: 'Error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: Colors.black.withOpacity(0)),
        ),

        // Sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: 20.h,
              left: 28.w,
              right: 28.w,
              bottom: 36.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 20.h),

                // Icon
                Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_forever_rounded,
                      color: Colors.red.shade600, size: 32.r),
                ),
                SizedBox(height: 16.h),

                Text(
                  'Delete Account?',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                  ),
                ),
                SizedBox(height: 10.h),

                Text(
                  'This action is permanent and cannot be undone.\n'
                  'All your hydration data, history, and settings will be permanently deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    height: 1.5,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                  ),
                ),
                SizedBox(height: 28.h),

                // Buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isDeleting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40.r),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black87,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Delete
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _performDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40.r),
                          ),
                        ),
                        child: _isDeleting
                            ? SizedBox(
                                height: 20.r,
                                width: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Yes, Delete',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontWeight: FontWeight.bold,
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
