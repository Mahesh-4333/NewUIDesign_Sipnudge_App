import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';

class FreshStartCalibrationScreen extends StatefulWidget {
  final int selectedBottleIndex;
  final VoidCallback onFinalize;
  final VoidCallback? onBack;

  const FreshStartCalibrationScreen({
    super.key,
    required this.selectedBottleIndex,
    required this.onFinalize,
    this.onBack,
  });

  @override
  State<FreshStartCalibrationScreen> createState() =>
      _FreshStartCalibrationScreenState();
}

class _FreshStartCalibrationScreenState
    extends State<FreshStartCalibrationScreen> {
  bool _isCalibrating = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottleDataCubit, BottleDataState>(
      buildWhen: (previous, current) =>
          previous.volumePercent != current.volumePercent,
      builder: (context, state) {
        final volumePercent = state.volumePercent;
        final currentVolume =
            ((volumePercent / 100) * 600).round().clamp(0, 600);
        final isCalibrated = currentVolume >= 500 && currentVolume <= 600;

        final String emptyBottleCutAsset;
        switch (widget.selectedBottleIndex) {
          case 0:
            emptyBottleCutAsset = AssetsPath.onboardingEmptyBottleCuttRed;
            break;
          case 1:
            emptyBottleCutAsset = AssetsPath.onboardingEmptyBottleCuttBlack;
            break;
          case 2:
            emptyBottleCutAsset = AssetsPath.onboardingEmptyBottleCuttPurple;
            break;
          default:
            emptyBottleCutAsset = AssetsPath.onboardingEmptyBottleCuttRed;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Bar with Back Arrow
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: InkWell(
                        onTap: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Title Header
                  Text(
                    AppLocalizations.of(context)?.freshStart ?? "Fresh Start",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.bluegray,
                      fontSize: 32.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppLocalizations.of(context)?.freshStartDescription ??
                        "Fill bottle until the float disc aligns with the maximum\nlevel marker. Do not exceed capacity to maintain\nsensor accuracy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF7A8E9E),
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
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
                                  AppLocalizations.of(context)?.targetVolume ??
                                      "TARGET VOLUME",
                                  style: TextStyle(
                                    color: const Color(0xFF7A8E9E),
                                    fontSize: 12.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(
                                    begin: 0,
                                    end: currentVolume,
                                  ),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.fastEaseInToSlowEaseOut,
                                  builder: (context, value, child) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          "$value",
                                          style: TextStyle(
                                            color: const Color(0xFF1E293B),
                                            fontSize: 32.sp,
                                            fontFamily: AppFontStyles
                                                .urbanistFontFamily,
                                            fontVariations: [
                                              AppFontStyles.boldFontVariation
                                            ],
                                          ),
                                        ),
                                        Text(
                                          AppLocalizations.of(context)
                                                  ?.maxVolumeFormat(
                                                      "500~600") ??
                                              "/500~600 ml",
                                          style: TextStyle(
                                            color: const Color(0xFF1E293B),
                                            fontSize: 20.sp,
                                            fontFamily: AppFontStyles
                                                .urbanistFontFamily,
                                            fontVariations: [
                                              AppFontStyles.boldFontVariation
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Calibration Pill Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
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
                                    decoration: BoxDecoration(
                                      color: isCalibrated
                                          ? const Color(0xFF78E000)
                                          : AppColors.bluegray,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    isCalibrated
                                        ? (AppLocalizations.of(context)
                                                ?.calibrated ??
                                            "Calibrated")
                                        : (AppLocalizations.of(context)
                                                ?.calibration ??
                                            "Calibration"),
                                    style: TextStyle(
                                      color: const Color(0xFF00629D),
                                      fontSize: 13.sp,
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation
                                      ],
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
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Back layer: Steel Material Background
                              Image.asset(
                                AssetsPath.onboardingSteelMaterial,
                                fit: BoxFit.contain,
                              ),
                              // Middle layer: Water Wave Animation
                              Positioned(
                                bottom: 10.h,
                                width: 37.w,
                                height: 130.h,
                                child: Opacity(
                                  opacity: 0.6,
                                  child: WaterWaveWidget(
                                    fillPercent: currentVolume / 600,
                                    speed: const Duration(seconds: 3),
                                    amplitude: 4,
                                    waveCount: 3,
                                    borderRadius: BorderRadius.zero,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ),
                              // Front layer: Empty Bottle Cut-out Overlay
                              Image.asset(
                                emptyBottleCutAsset,
                                fit: BoxFit.contain,
                              ),

                              // MAX Dashed Line & Label
                              Positioned(
                                top: 65.h,
                                left: 10.w,
                                right: 10.w,
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)?.max ??
                                          "MAX",
                                      style: TextStyle(
                                        color: const Color(0xFFD32F2F),
                                        fontSize: 11.sp,
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontVariations: [
                                          AppFontStyles.boldFontVariation
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final boxWidth = constraints.maxWidth;
                                          const dashWidth = 4.0;
                                          const dashSpace = 3.0;
                                          final dashCount = (boxWidth /
                                                  (dashWidth + dashSpace))
                                              .floor();
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children:
                                                List.generate(dashCount, (_) {
                                              return SizedBox(
                                                width: dashWidth,
                                                height: 1.5,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFD32F2F),
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                            AppLocalizations.of(context)?.overfillingWarning ??
                                "Overfilling may cause cap displacement \nand interfere with hydration tracking \nsensors.",
                            style: TextStyle(
                              color: const Color(0xFF3B5B66),
                              fontSize: 15.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [
                                AppFontStyles.semiBoldFontVariation
                              ],
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Container(
                            padding: EdgeInsets.all(0.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF4FF),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -45.h,
                                  right: -45.w,
                                  child: Container(
                                    width: 110.w,
                                    height: 110.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2EBFF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 14.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        color: const Color(0xFF00629D),
                                        size: 22.sp,
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        AppLocalizations.of(context)
                                                ?.precision ??
                                            "Precision",
                                        style: TextStyle(
                                          color: const Color(0xFF0A192F),
                                          fontSize: 16.sp,
                                          fontFamily:
                                              AppFontStyles.urbanistFontFamily,
                                          fontVariations: [
                                            AppFontStyles.boldFontVariation
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        AppLocalizations.of(context)
                                                ?.precisionDescription ??
                                            "Ensures accurate \nhydration \ntracking.",
                                        style: TextStyle(
                                          color: const Color(0xFF4A5568),
                                          fontSize: 12.sp,
                                          fontFamily:
                                              AppFontStyles.urbanistFontFamily,
                                          height: 1.3,
                                          fontVariations: [
                                            AppFontStyles.boldFontVariation
                                          ],
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

                      SizedBox(width: 12.w),

                      // Seal Card
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Container(
                            padding: EdgeInsets.all(0.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF4FF),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -45.h,
                                  right: -45.w,
                                  child: Container(
                                    width: 110.w,
                                    height: 110.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2EBFF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 14.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        color: const Color(0xFF00629D),
                                        size: 22.sp,
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        AppLocalizations.of(context)?.seal ??
                                            "Seal",
                                        style: TextStyle(
                                          color: const Color(0xFF0A192F),
                                          fontSize: 16.sp,
                                          fontFamily:
                                              AppFontStyles.urbanistFontFamily,
                                          fontVariations: [
                                            AppFontStyles.boldFontVariation
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        AppLocalizations.of(context)
                                                ?.sealDescription ??
                                            "Prevents leaks \nand pressure \nbuild-up.",
                                        style: TextStyle(
                                          color: const Color(0xFF4A5568),
                                          fontSize: 12.sp,
                                          fontFamily:
                                              AppFontStyles.urbanistFontFamily,
                                          height: 1.3,
                                          fontVariations: [
                                            AppFontStyles.boldFontVariation
                                          ],
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
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Finalize Calibration Button
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: (isCalibrated && !_isCalibrating)
                          ? () async {
                              setState(() {
                                _isCalibrating = true;
                              });
                              // Simulate a 1.5 second calibration process
                              await Future.delayed(
                                  const Duration(milliseconds: 1500));
                              if (mounted) {
                                widget.onFinalize();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF00A3FF).withValues(alpha: 0.6),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.r),
                        ),
                      ),
                      child: _isCalibrating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  AppLocalizations.of(context)?.calibrating ??
                                      "Caliberating..",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isCalibrated
                                      ? (AppLocalizations.of(context)
                                              ?.finalizeCalibration ??
                                          "Finalize Calibration")
                                      : (AppLocalizations.of(context)
                                              ?.calibrating ??
                                          "Calibrating..."),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.boldFontVariation
                                    ],
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
                                    isCalibrated
                                        ? Icons.check_rounded
                                        : Icons.play_arrow_rounded,
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
      },
    );
  }
}
