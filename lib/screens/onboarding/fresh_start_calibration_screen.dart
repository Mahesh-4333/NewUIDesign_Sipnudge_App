import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class FreshStartCalibrationScreen extends StatelessWidget {
  final VoidCallback onFinalize;

  const FreshStartCalibrationScreen({
    super.key,
    required this.onFinalize,
  });

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
                "Fresh Start",
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
                "Fill bottle until the float disc aligns with the maximum\nlevel marker. Do not exceed capacity to maintain\nsensor accuracy.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7A8E9E),
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  height: 1.35,
                ),
              ),

              SizedBox(height: 20.h),

              // Target Volume Container
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row: TARGET VOLUME + Calibration Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TARGET VOLUME",
                              style: TextStyle(
                                color: const Color(0xFF7A8E9E),
                                fontSize: 12.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [AppFontStyles.boldFontVariation],
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "0",
                                  style: TextStyle(
                                    color: const Color(0xFF1E293B),
                                    fontSize: 32.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontVariations: [AppFontStyles.boldFontVariation],
                                  ),
                                ),
                                Text(
                                  "/600 ml",
                                  style: TextStyle(
                                    color: const Color(0xFF1E293B),
                                    fontSize: 20.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontVariations: [AppFontStyles.boldFontVariation],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Calibration Pill Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FB),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A3FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "Calibration",
                                style: TextStyle(
                                  color: const Color(0xFF00A3FF),
                                  fontSize: 13.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Bottle Graphic with MAX Line
                    Container(
                      height: 200.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            AssetsPath.onboardingHalfBottle,
                            fit: BoxFit.contain,
                          ),

                          // MAX Dashed Line & Label
                          Positioned(
                            top: 85.h,
                            left: 10.w,
                            right: 10.w,
                            child: Row(
                              children: [
                                Text(
                                  "MAX",
                                  style: TextStyle(
                                    color: const Color(0xFFD32F2F),
                                    fontSize: 11.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontVariations: [AppFontStyles.boldFontVariation],
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final boxWidth = constraints.maxWidth;
                                      const dashWidth = 4.0;
                                      const dashSpace = 3.0;
                                      final dashCount =
                                          (boxWidth / (dashWidth + dashSpace)).floor();
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(dashCount, (_) {
                                          return SizedBox(
                                            width: dashWidth,
                                            height: 1.5,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD32F2F),
                                              ),
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Info Warning Box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FB).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFF3B5B66),
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Overfilling may cause cap displacement and interfere with hydration tracking sensors.",
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

              SizedBox(height: 16.h),

              // Two Feature Cards (Precision & Seal)
              Row(
                children: [
                  // Precision Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBF5FB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.speed_rounded,
                              color: const Color(0xFF00A3FF),
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "Precision",
                            style: TextStyle(
                              color: const Color(0xFF2C434C),
                              fontSize: 15.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Ensures accurate hydration tracking.",
                            style: TextStyle(
                              color: const Color(0xFF7A8E9E),
                              fontSize: 12.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Seal Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBF5FB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: const Color(0xFF00A3FF),
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "Seal",
                            style: TextStyle(
                              color: const Color(0xFF2C434C),
                              fontSize: 15.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Prevents leaks and pressure build-up.",
                            style: TextStyle(
                              color: const Color(0xFF7A8E9E),
                              fontSize: 12.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Finalize Calibration Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: onFinalize,
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
                      Text(
                        "Finalize Calibration",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.all(2.r),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: const Color(0xFF00A3FF),
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
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
