import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/l10n/app_localizations.dart';

class BottleActivationScreen extends StatefulWidget {
  final int selectedBottleIndex;
  final VoidCallback onDeviceSelected;
  final VoidCallback? onBack;
  final bool isActive;

  const BottleActivationScreen({
    super.key,
    required this.selectedBottleIndex,
    required this.onDeviceSelected,
    this.onBack,
    this.isActive = false,
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

  String _getBottleTouchAsset() {
    switch (widget.selectedBottleIndex) {
      case 0:
        return AssetsPath.onboardingRedTouch;
      case 1:
        return AssetsPath.onboardingBlackTouch;
      case 2:
      default:
        return AssetsPath.onboardingPurpleTouch;
    }
  }

  String _getBottleAvatarAsset() {
    switch (widget.selectedBottleIndex) {
      case 0:
        return AssetsPath.onboardingRed;
      case 1:
        return AssetsPath.onboardingBlack;
      case 2:
      default:
        return AssetsPath.onboardingPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BleCubit, BleState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == BleStatus.connected) {
          widget.onDeviceSelected();
        }
      },
      child: Scaffold(
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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                    AppLocalizations.of(context)?.bottleActivation ??
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
                    AppLocalizations.of(context)
                            ?.wakeUpSmartBottleDescription ??
                        "Let's wake up your smart bottle and get it\nconnected to your wellness profile.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF7A8E9E),
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Illustration Box
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulseValue = CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      ).value;

                      return Container(
                        width: 300.w,
                        height: 250.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            // BoxShadow(
                            //   color: const Color(0xFF00A2FF).withValues(
                            //     alpha: 0.06 + (pulseValue * 0.14),
                            //   ),
                            //   blurRadius: 2 + (pulseValue * 12),
                            //   spreadRadius: 0,
                            //   offset: const Offset(0, 6),
                            // ),
                            // BoxShadow(
                            //   color: Colors.black.withValues(
                            //     alpha: 0.04,
                            //   ),
                            //   blurRadius: 51,
                            //   offset: const Offset(0, 4),
                            // ),
                          ],
                        ),
                        child: Image.asset(
                          _getBottleTouchAsset(),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 20.h),

                  // Wake Your Bottle
                  Text(
                    AppLocalizations.of(context)?.wakeYourBottle ??
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
                    AppLocalizations.of(context)?.touchCapDescription ??
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
                            color:
                                const Color(0xFF00A3FF).withValues(alpha: 0.2),
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
                    AppLocalizations.of(context)?.scanning ?? "SCANNING...",
                    style: TextStyle(
                      color: const Color(0xFF00A3FF),
                      fontSize: 12.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      letterSpacing: 1.2,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Discovered Devices List
                  BlocBuilder<BleCubit, BleState>(
                    builder: (context, state) {
                      final filtered = state.scannedDevices;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppLocalizations.of(context)?.discoveredDevices ??
                                  "DISCOVERED DEVICES",
                              style: TextStyle(
                                color: const Color(0xFF7A8E9E),
                                fontSize: 12.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 1.h,
                            color: const Color(0xFFE2E8F0),
                          ),
                          SizedBox(height: 16.h),
                          if (filtered.isNotEmpty)
                            ...filtered.map((r) {
                              final device = r.device;
                              final rssi = r.rssi;
                              String signalLabel =
                                  AppLocalizations.of(context)?.excellent ??
                                      "Excellent";
                              if (rssi < -80) {
                                signalLabel =
                                    AppLocalizations.of(context)?.weak ??
                                        "Weak";
                              } else if (rssi < -60) {
                                signalLabel =
                                    AppLocalizations.of(context)?.good ??
                                        "Good";
                              }

                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: GestureDetector(
                                  onTap: () {
                                    context
                                        .read<BleCubit>()
                                        .connectToSelectedDevice(device);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30.r),
                                      border: Border.all(
                                        color: const Color(0xFF00A3FF)
                                            .withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
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
                                              _getBottleAvatarAsset(),
                                              height: 32.h,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 14.w),

                                        // Device Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                device.platformName.isNotEmpty
                                                    ? device.platformName
                                                    : "Sipnudge Pro",
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF2C434C),
                                                  fontSize: 16.sp,
                                                  fontFamily: AppFontStyles
                                                      .urbanistFontFamily,
                                                  fontVariations: [
                                                    AppFontStyles
                                                        .boldFontVariation
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 6.w,
                                                    height: 6.w,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xFF00C853),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Text(
                                                    state.status ==
                                                                BleStatus
                                                                    .connecting &&
                                                            state.message
                                                                .contains(device
                                                                    .platformName)
                                                        ? (AppLocalizations.of(
                                                                    context)
                                                                ?.connecting ??
                                                            "Connecting...")
                                                        : (AppLocalizations.of(
                                                                    context)
                                                                ?.readyToPair ??
                                                            "Ready to pair"),
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFF7A8E9E),
                                                      fontSize: 13.sp,
                                                      fontFamily: AppFontStyles
                                                          .urbanistFontFamily,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Signal Strength
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "$rssi dBm",
                                              style: TextStyle(
                                                color: const Color(0xFF2C434C),
                                                fontSize: 13.sp,
                                                fontFamily: AppFontStyles
                                                    .urbanistFontFamily,
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              signalLabel,
                                              style: TextStyle(
                                                color: const Color(0xFF7A8E9E),
                                                fontSize: 11.sp,
                                                fontFamily: AppFontStyles
                                                    .urbanistFontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                          else ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth_disabled_rounded,
                                    color: const Color(0xFF7A8E9E),
                                    size: 32.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    AppLocalizations.of(context)
                                            ?.noDeviceFound ??
                                        "No device found",
                                    style: TextStyle(
                                      color: const Color(0xFF7A8E9E),
                                      fontSize: 14.sp,
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
                          SizedBox(height: 20.h),
                          // Bottom Info Box
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FB)
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: const Color(0xFF00A3FF)
                                    .withValues(alpha: 0.15),
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
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: const Color(0xFF3B5B66),
                                        fontSize: 13.sp,
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        height: 1.3,
                                      ),
                                      children: [
                                        TextSpan(
                                            text: AppLocalizations.of(context)
                                                    ?.tapOn ??
                                                "Tap on "),
                                        TextSpan(
                                          text: filtered.isNotEmpty &&
                                                  filtered.first.device
                                                      .platformName.isNotEmpty
                                              ? filtered
                                                  .first.device.platformName
                                              : "Sipnudge Pro",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                            text: AppLocalizations.of(context)
                                                    ?.toEstablishSecureConnection ??
                                                " to establish a secure connection and verify sensor calibration."),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
