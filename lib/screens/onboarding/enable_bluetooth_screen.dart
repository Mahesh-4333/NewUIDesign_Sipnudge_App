import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/l10n/app_localizations.dart';

class EnableBluetoothScreen extends StatelessWidget {
  final int selectedBottleIndex;
  final VoidCallback onEnableBluetooth;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  const EnableBluetoothScreen({
    super.key,
    required this.selectedBottleIndex,
    required this.onEnableBluetooth,
    required this.onSkip,
    this.onBack,
  });

  String _getBottleAsset() {
    switch (selectedBottleIndex) {
      case 0:
        return AssetsPath.onboardingHalfBottleRed;
      case 1:
        return AssetsPath.onboardingHalfBottleBlack;
      case 2:
      default:
        return AssetsPath.onboardingHalfBottlePurple;
    }
  }

  void _showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A2FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              "Open Settings",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEnableBluetooth(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        final connectStatus = statuses[Permission.bluetoothConnect];
        final scanStatus = statuses[Permission.bluetoothScan];

        final isGranted = connectStatus?.isGranted == true ||
            scanStatus?.isGranted == true ||
            (connectStatus == null && scanStatus == null);

        if (!context.mounted) return;

        if (isGranted) {
          context.read<BleCubit>().start();
          onEnableBluetooth();
        } else if (connectStatus?.isPermanentlyDenied == true ||
            scanStatus?.isPermanentlyDenied == true ||
            connectStatus?.isDenied == true ||
            scanStatus?.isDenied == true) {
          _showPermissionDialog(
            context: context,
            title: "Bluetooth Permission Required",
            message:
                "Please enable Bluetooth permissions in Settings to connect to your Sipnudge bottle.",
          );
        }
      } else if (Platform.isIOS) {
        // Check current adapter state first (e.g. when returning from Settings)
        BluetoothAdapterState adapterState;
        try {
          adapterState = await FlutterBluePlus.adapterState.first.timeout(
            const Duration(milliseconds: 600),
            onTimeout: () => BluetoothAdapterState.unknown,
          );
        } catch (_) {
          adapterState = BluetoothAdapterState.unknown;
        }

        if (adapterState == BluetoothAdapterState.on ||
            adapterState == BluetoothAdapterState.off) {
          if (!context.mounted) return;
          context.read<BleCubit>().start();
          onEnableBluetooth();
          return;
        }

        if (adapterState == BluetoothAdapterState.unauthorized) {
          if (!context.mounted) return;
          _showPermissionDialog(
            context: context,
            title: "Bluetooth Permission Required",
            message:
                "Please enable Bluetooth in Settings to connect to your Sipnudge bottle.",
          );
          return;
        }

        // If unknown (first time launch), start BleCubit to trigger iOS native Bluetooth authorization prompt
        if (!context.mounted) return;
        context.read<BleCubit>().start();

        final updatedState = await FlutterBluePlus.adapterState
            .firstWhere((state) => state != BluetoothAdapterState.unknown)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => BluetoothAdapterState.unknown,
            );

        if (!context.mounted) return;

        if (updatedState == BluetoothAdapterState.on ||
            updatedState == BluetoothAdapterState.off) {
          onEnableBluetooth();
        } else if (updatedState == BluetoothAdapterState.unauthorized) {
          _showPermissionDialog(
            context: context,
            title: "Bluetooth Permission Required",
            message:
                "Please enable Bluetooth in Settings to connect to your Sipnudge bottle.",
          );
        }
      }
    } catch (e) {
      debugPrint("Error enabling Bluetooth: $e");
    }
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
          child: Column(
            children: [
              // Top Bar with Back Arrow
              Padding(
                padding: EdgeInsets.only(left: 16.w, top: 4.h, bottom: 0.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      if (onBack != null) {
                        onBack!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        onSkip();
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

              // Headline & Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)?.connect ?? 'Connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF35586B),
                        fontSize: 26.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF00629D),
                          Color(0xFF4DA6CD),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        AppLocalizations.of(context)?.yourSipnudgeBottle ?? 'Your Sipnudge Bottle',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppLocalizations.of(context)?.bluetoothRequiredDescription ?? 'Bluetooth is required to sync your\nhydration data from your smart bottle\nto the app in real-time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 13.sp,
                        height: 1.35,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              // Center Bottle & Overlapping Glass Card Area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    height: 800.h,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Prominent, Large Bottle Graphic
                        Positioned(
                          top: 0,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Shadow Silhouette Layer
                              Transform.translate(
                                offset: Offset(0, 10.h),
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 25,
                                    sigmaY: 25,
                                    tileMode: TileMode.decal,
                                  ),
                                  child: Image.asset(
                                    _getBottleAsset(),
                                    width: 320.w,
                                    height: 530.h,
                                    fit: BoxFit.fitWidth,
                                    alignment: Alignment.topCenter,
                                    color: Colors.black.withValues(alpha: 0.22),
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              // Actual Bottle Image Layer
                              Image.asset(
                                _getBottleAsset(),
                                width: 300.w,
                                height: 530.h,
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.topCenter,
                              ),
                            ],
                          ),
                        ),

                        // Translucent / Glassmorphic Card
                        Positioned(
                          bottom: 260.h,
                          left: 42.w,
                          right: 42.w,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 20.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(39, 206, 236, 255),
                                      const Color.fromARGB(13, 168, 220, 252),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                        128, 229, 229, 229),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFeatureRow(
                                      icon: AssetsPath
                                          .onboardingHalfRealTimeTracking,
                                      title: AppLocalizations.of(context)?.realTimeTracking ?? 'Real-time tracking',
                                      subtitle: AppLocalizations.of(context)?.instantLiquidLevelUpdates ?? 'Instant liquid level updates.',
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      height: 1.0,
                                      color: const Color.fromARGB(
                                          80, 229, 229, 229),
                                    ),
                                    SizedBox(height: 10.h),
                                    _buildFeatureRow(
                                      icon: AssetsPath.onboardingSmartNudge,
                                      title: AppLocalizations.of(context)?.smartNudges ?? 'Smart nudges',
                                      subtitle: AppLocalizations.of(context)?.personalizedHabitBuilding ?? 'Personalized habit building.',
                                    ),
                                    SizedBox(height: 10.h),
                                    Container(
                                      height: 1.0,
                                      color: const Color.fromARGB(
                                          80, 229, 229, 229),
                                    ),
                                    SizedBox(height: 18.h),
                                    _buildFeatureRow(
                                      icon:
                                          AssetsPath.onboardingAccurateHistory,
                                      title: AppLocalizations.of(context)?.accurateHistory ?? 'Accurate history',
                                      subtitle: AppLocalizations.of(context)?.detailedConsumptionLogs ?? 'Detailed consumption logs.',
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
              ),

              // Bottom Action Buttons
              Padding(
                padding: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  bottom: 10.h,
                  top: 8.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Enable Bluetooth Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: () => _handleEnableBluetooth(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A2FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
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
                              AppLocalizations.of(context)?.enableBluetooth ?? 'Enable Bluetooth',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation,
                                ],
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
                        AppLocalizations.of(context)?.skipNoBottle ?? "Skip: I don't have a bottle",
                        style: TextStyle(
                          color: const Color(0xFF1E293B),
                          fontSize: 14.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          decoration: TextDecoration.underline,
                          fontVariations: [
                            AppFontStyles.boldFontVariation,
                          ],
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
    );
  }

  Widget _buildFeatureRow({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: const BoxDecoration(
            color: Color(0xFFE2F3FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              icon,
              color: const Color(0xFF00A2FF),
              width: 24.w,
              height: 24.w,
            ),
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
                  color: Color(0xffE5EEFF),
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14.5.sp,
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
