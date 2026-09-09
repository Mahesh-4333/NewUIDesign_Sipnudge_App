import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/services/health_service.dart';

class AppleHealthOnboardingScreen extends StatefulWidget {
  const AppleHealthOnboardingScreen({super.key});

  @override
  State<AppleHealthOnboardingScreen> createState() =>
      _AppleHealthOnboardingScreenState();
}

class _AppleHealthOnboardingScreenState
    extends State<AppleHealthOnboardingScreen> {
  final PageController _pageController = PageController();

  bool _isAuthorizing = false;

  Future<void> _handleAllowHealthAccess() async {
    if (_isAuthorizing) return;

    setState(() {
      _isAuthorizing = true;
    });

    try {
      // 1. Mark permission as requested so it won't re-prompt in future screens
      await SharedPrefsHelper.setHasRequestedHealthPermission(true);

      // 2. Request native authorization from Apple Health / HealthKit
      await HealthService().requestAuthorization();
    } catch (e) {
      Console.log(
          tag: "AppleHealthOnboarding",
          value: "Error during Health authorization: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAuthorizing = false;
        });

        // 3. Move directly to User Information / Registration Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const UserInfoInputScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildStep1Intro(),
              _buildStep2Permissions(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 1: Apple Health Introduction Page
  // ==========================================
  Widget _buildStep1Intro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 18.h),

                  // Header Title
                  Text(
                    "Connect with Apple\nHealth",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: -0.3,
                      color: const Color(0xFF2C4F62),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Center Card: Apple Health App Icon with soft shadow
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 28,
                          offset: Offset(0, 10),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AssetsPath.appleHealthIcon,
                      width: 108.w,
                      height: 108.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // "Apple Health" Card Label
                  Text(
                    "Apple Health",
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C4F62),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // Description Paragraph
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Text(
                      "Sipnudge uses your Apple Health data (height, weight, and daily activity) to calculate an accurate, dynamically changing hydration goal tailored just for you.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: 17.sp,
                        height: 1.42,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        color: const Color(0xFF4A708B),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 4 Feature Icons Row (water, height, steps, weight)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeatureIcon(
                          imagePath: AssetsPath.appleHealthWater,
                          label: "water",
                        ),
                        _buildFeatureIcon(
                          imagePath: AssetsPath.appleHealthHeight,
                          label: "height",
                        ),
                        _buildFeatureIcon(
                          imagePath: AssetsPath.appleHealthSteps,
                          label: "steps",
                        ),
                        _buildFeatureIcon(
                          imagePath: AssetsPath.appleHealthWeight,
                          label: "weight",
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // "Lets start →" Action Button
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    child: InkWell(
                      onTap: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      },
                      borderRadius: BorderRadius.circular(30.r),
                      child: Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A2FF),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3300A2FF),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Lets start",
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontSize: 16.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcon({
    required String imagePath,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 28.w,
          height: 28.w,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A708B),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 2: Permissions Preview & Authorization
  // ==========================================
  Widget _buildStep2Permissions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 18.h),

                  // Header Title
                  Text(
                    "Connect with Apple\nHealth",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: -0.3,
                      color: const Color(0xFF2C4F62),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Center Dark Card: iOS Health Access Permission Image
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Image.asset(
                      AssetsPath.applePermission,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Description Paragraph
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    child: Text(
                      "Sync your steps for adaptive hydration goals and automatically record your water intake in Apple Health.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: 16.5.sp,
                        height: 1.42,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        color: const Color(0xFF4A708B),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // "Continue →" Action Button
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    child: InkWell(
                      onTap: _isAuthorizing ? null : _handleAllowHealthAccess,
                      borderRadius: BorderRadius.circular(30.r),
                      child: Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A2FF),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3300A2FF),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isAuthorizing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Continue",
                                      style: TextStyle(
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontSize: 16.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
