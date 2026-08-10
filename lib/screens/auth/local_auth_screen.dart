import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/providers/authentication_provider.dart';
import 'package:hydrify/screens/auth/auth_options_screen.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/onboarding/environmental_harmony_location_screen.dart';
import 'package:provider/provider.dart';

class LocalAuthScreen extends StatefulWidget {
  const LocalAuthScreen({super.key});

  @override
  State<LocalAuthScreen> createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing glow: 0.0 → 1.0 → 0.0, repeat forever
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _handleStartupAuth();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleStartupAuth() async {
    if (!mounted) return;

    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    final canCheck = await authProvider.canCheckBiometrics();
    if (canCheck) {
      await authProvider.authenticateWithBiometrics();
    }

    if (!mounted) return;

    final loggedInUserEmail = await SharedPrefsHelper.getUserEmail() ?? "";
    final hasUserFilledInPersonalInfo =
        await SharedPrefsHelper.isPersonalInfoSubmitted();
    final hasUserSelectedPersonalGoal = await SharedPrefsHelper.getUserGoal();
    final isOnboardingCompleted =
        await SharedPrefsHelper.isOnboardingFlowCompleted();

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              if (loggedInUserEmail.isNotEmpty) {
                if (hasUserFilledInPersonalInfo == true &&
                    hasUserSelectedPersonalGoal != null) {
                  if (isOnboardingCompleted) {
                    return const BottomNavScreenNew();
                  } else {
                    return const EnvironmentalHarmonyLocationScreen();
                  }
                } else {
                  return const UserInfoInputScreen();
                }
              } else {
                // If logged out, send to Auth Options
                return const AuthOptionsScreen();
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
            // Bottle image with pulsing radial glow behind it
            Transform.translate(
              offset: Offset(0.w, 0),
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Pulsing glow layer ──
                      Container(
                        width: AppDimensions.dim300.w * 1.1,
                        height: AppDimensions.dim300.h * 1.1,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF64B5F6).withOpacity(
                                0.15 + (_glowAnimation.value * 0.55),
                              ),
                              blurRadius: 20 + (_glowAnimation.value * 30),
                              spreadRadius: 3 + (_glowAnimation.value * 10),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFFFFF).withOpacity(
                                0.05 + (_glowAnimation.value * 0.2),
                              ),
                              blurRadius: 10 + (_glowAnimation.value * 20),
                              spreadRadius: 1 + (_glowAnimation.value * 5),
                            ),
                          ],
                        ),
                      ),
                      // ── Bottle image ──
                      child!,
                    ],
                  );
                },
                child: Transform.rotate(
                  angle: -0.01745, // –1° left (π/180 radians)
                  child: Image.asset(
                    AssetsPath.bottleRingCap,
                    width: AppDimensions.dim300.w,
                    height: AppDimensions.dim300.h,
                    fit: BoxFit.cover,
                  ),
                ),
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
