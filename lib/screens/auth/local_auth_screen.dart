import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/providers/authentication_provider.dart';
import 'package:hydrify/screens/auth/auth_options_screen.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:provider/provider.dart';

class LocalAuthScreen extends StatefulWidget {
  const LocalAuthScreen({super.key});

  @override
  State<LocalAuthScreen> createState() =>
      _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(
        Duration(
          milliseconds: 500,
        ), () {
      _handleStartupAuth();
    });
  }

  Future<void> _handleStartupAuth() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false);

    bool success = false;

    // Keep showing popup until user authenticates
    while (mounted && !success) {
      success = await authProvider.authenticateWithBiometrics();

      if (!success) {
        // Small delay to avoid spam feeling
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    if (!mounted) return;

    final loggedInUserEmail =
        await SharedPrefsHelper.getUserEmail() ?? "";
    final hasUserFilledInPersonalInfo =
        await SharedPrefsHelper.isPersonalInfoSubmitted();
    final hasUserSelectedPersonalGoal =
        await SharedPrefsHelper.getUserGoal();

    Future.delayed(
      const Duration(milliseconds: 800),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) {
              if (loggedInUserEmail.isNotEmpty) {
                if (hasUserFilledInPersonalInfo == true &&
                    hasUserSelectedPersonalGoal != null) {
                  return BottomNavScreenNew();
                } else {
                  return UserInfoInputScreen();
                }
              } else {
                return AuthOptionsScreen();
              }
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/app_background.png"), // your image path
            fit: BoxFit.cover,
          ),
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [
          //     AppColors.gradientStart,
          //     AppColors.gradientEnd,
          //   ],
          // ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: AppDimensions.dim285.h,
            ),
            Transform.translate(
              offset: Offset(
                  10.w, 0), // move left by 20 logical pixels
              child: Image.asset(
                "assets/images/bottle_top_image1.png",
                width: AppDimensions.dim346.w,
                height: AppDimensions.dim346.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(
              height: AppDimensions.dim174.h,
            ),
            // SvgPicture.asset(
            //   "assets/images/ai_meet_hyd1.svg",
            // ),
            Image.asset(
              "assets/images/ai.png",
              width: AppDimensions.dim500.w,
              height: AppDimensions.dim85.h,
            ),
          ],
        ),
      ),
    );
  }
}
