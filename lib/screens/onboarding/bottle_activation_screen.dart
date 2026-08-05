import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class BottleActivationScreen extends StatefulWidget {
  final VoidCallback onDeviceSelected;

  const BottleActivationScreen({
    super.key,
    required this.onDeviceSelected,
  });

  @override
  State<BottleActivationScreen> createState() => _BottleActivationScreenState();
}

class _BottleActivationScreenState extends State<BottleActivationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              // Title Header
              Text(
                "Bottle Activation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3B5B66),
                  fontSize: 26.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Let's wake up your smart bottle and get it\nconnected to your wellness profile.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7A8E9E),
                  fontSize: 14.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  height: 1.3,
                ),
              ),

              SizedBox(height: 20.h),

              // Illustration Box
              Container(
                width: 220.w,
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.asset(
                    AssetsPath.onboardingBottleTouch,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Wake Your Bottle
              Text(
                "Wake Your Bottle",
                style: TextStyle(
                  color: const Color(0xFF2C434C),
                  fontSize: 20.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "Gently touch the cap to activate the\nsensor and start advertising.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7A8E9E),
                  fontSize: 14.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  height: 1.3,
                ),
              ),

              SizedBox(height: 20.h),

              // Scanning Animation Icon
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A3FF).withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_rounded,
                    color: const Color(0xFF00A3FF),
                    size: 24.sp,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "SCANNING...",
                style: TextStyle(
                  color: const Color(0xFF00A3FF),
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 1.2,
                ),
              ),

              SizedBox(height: 20.h),

              // Discovered Devices Section Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "DISCOVERED DEVICES",
                  style: TextStyle(
                    color: const Color(0xFF7A8E9E),
                    fontSize: 12.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Discovered Device Card
              GestureDetector(
                onTap: widget.onDeviceSelected,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: const Color(0xFF00A3FF).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Bottle Avatar Container
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F4F8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            AssetsPath.onboardingBlack,
                            height: 32.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // Device Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sipnudge Pro",
                              style: TextStyle(
                                color: const Color(0xFF2C434C),
                                fontSize: 16.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [AppFontStyles.boldFontVariation],
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00C853),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Ready to pair",
                                  style: TextStyle(
                                    color: const Color(0xFF7A8E9E),
                                    fontSize: 13.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Signal Strength
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "-42 dBm",
                            style: TextStyle(
                              color: const Color(0xFF2C434C),
                              fontSize: 13.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "Excellent",
                            style: TextStyle(
                              color: const Color(0xFF7A8E9E),
                              fontSize: 11.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Bottom Info Box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FB).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF00A3FF).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFF00A3FF),
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Tap on Sipnudge Pro to establish a secure connection and verify sensor calibration.",
                        style: TextStyle(
                          color: const Color(0xFF3B5B66),
                          fontSize: 13.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
