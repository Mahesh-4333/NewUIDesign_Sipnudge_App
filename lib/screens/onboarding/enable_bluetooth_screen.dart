import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class EnableBluetoothScreen extends StatelessWidget {
  final VoidCallback onEnableBluetooth;
  final VoidCallback onSkip;

  const EnableBluetoothScreen({
    super.key,
    required this.onEnableBluetooth,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10.h),

            // Top Bottle Graphic
            SizedBox(
              height: 280.h,
              child: Center(
                child: Image.asset(
                  AssetsPath.onboardingScanningBottle,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Spacer(),

            // Glassmorphic Feature Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.water_drop_rounded,
                      title: "Real-time tracking",
                      subtitle: "Instant liquid level updates.",
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Divider(
                        color: const Color(0xFFE8EEF3),
                        height: 1.h,
                      ),
                    ),
                    _buildFeatureRow(
                      icon: Icons.psychology_alt_outlined,
                      title: "Smart nudges",
                      subtitle: "Personalized habit building.",
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Divider(
                        color: const Color(0xFFE8EEF3),
                        height: 1.h,
                      ),
                    ),
                    _buildFeatureRow(
                      icon: Icons.history_rounded,
                      title: "Accurate history",
                      subtitle: "Detailed consumption logs.",
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Bottom Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  // Enable Bluetooth Button
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: onEnableBluetooth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_rounded,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Enable Bluetooth",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // Skip Button
                  GestureDetector(
                    onTap: onSkip,
                    child: Text(
                      "Skip: I don't have a bottle",
                      style: TextStyle(
                        color: const Color(0xFF3B5B66),
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
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
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: const BoxDecoration(
            color: Color(0xFFEBF5FB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00A3FF),
            size: 20.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF2C434C),
                  fontSize: 16.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF7A8E9E),
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
