import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiProvisioningScreen extends StatefulWidget {
  const WifiProvisioningScreen({super.key});

  @override
  State<WifiProvisioningScreen> createState() => _WifiProvisioningScreenState();
}

class _WifiProvisioningScreenState extends State<WifiProvisioningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  final _userIdController = TextEditingController();

  int _selectedPriority = 1; // 1 = Primary, 2 = Secondary, 3 = Tertiary
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _countdown = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<BottomNavCubit>().hideBar();
    _loadUserId();
    _loadCredentialsForPriority(_selectedPriority);
  }

  Future<void> _loadCredentialsForPriority(int priority) async {
    final ssid = await SharedPrefsHelper.getWifiSsidForPriority(priority);
    final password =
        await SharedPrefsHelper.getWifiPasswordForPriority(priority);
    Console.log(
        tag: "WIFI_PROV",
        value:
            "Loaded for priority $priority: SSID='$ssid', Password='${password != null ? '***' : 'null'}'");
    if (mounted) {
      setState(() {
        _ssidController.text = ssid ?? "";
        _passController.text = password ?? "";
      });
    }
  }

  Future<void> _autofillWifiSSID() async {
    // 1. Request location permission since it's required for getWifiName()
    final status = await Permission.locationWhenInUse.request();
    debugPrint(
        "=======> Wi-Fi Provisioning location permission status: $status");

    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFFE8ECEF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: const Text(
              "Location Permission Required",
              style: TextStyle(
                  color: Color(0xFF004976), fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Accessing the Wi-Fi network name (SSID) requires location permission. "
              "Please enable Location Access in your system settings to use this feature.",
              style: TextStyle(color: AppColors.darkgray),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel",
                    style: TextStyle(color: Color(0xFF5D7B91))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004976),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text("Open Settings",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!status.isGranted && !status.isLimited && !status.isRestricted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Location permission is required to retrieve Wi-Fi SSID.")),
        );
      }
      return;
    }

    try {
      final info = NetworkInfo();
      String? wifiName = await info.getWifiName();
      debugPrint("=======> Wi-Fi Name retrieved: $wifiName");
      if (wifiName != null &&
          wifiName.isNotEmpty &&
          wifiName != "<unknown ssid>") {
        // Strip quotes if present (iOS wraps SSID in double quotes)
        if (wifiName.startsWith('"') &&
            wifiName.endsWith('"') &&
            wifiName.length > 1) {
          wifiName = wifiName.substring(1, wifiName.length - 1);
        }
        if (mounted) {
          setState(() {
            _ssidController.text = wifiName!;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Autofilled SSID: $wifiName")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Could not retrieve Wi-Fi name. Please ensure you are connected to Wi-Fi and Precise Location is enabled.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching Wi-Fi name: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    _userIdController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final uid = await SharedPrefsHelper.getUserId();
    if (uid != null && mounted) {
      setState(() {
        _userIdController.text = uid;
      });
    }
  }

  void _startCountdown() {
    setState(() {
      _isLoading = true;
      _countdown = 20;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _provisionWifi() async {
    if (!_formKey.currentState!.validate()) return;

    // Save credentials locally first so they are never lost
    await SharedPrefsHelper.setWifiCredentialsForPriority(
      _selectedPriority,
      _ssidController.text.trim(),
      _passController.text,
    );

    final bleCubit = context.read<BleCubit>();
    final bool isConnected = bleCubit.state.status == BleStatus.connected;

    if (isConnected) {
      _startCountdown();
    }

    try {
      final response = await bleCubit.provisionWifi(
        priority: _selectedPriority,
        ssid: _ssidController.text.trim(),
        pass: _passController.text,
        userId: _userIdController.text.trim(),
      );

      if (isConnected) {
        _stopCountdown();
      }

      if (response.result == 'saved_pending') {
        _showResultDialog(
          title: "Saved Offline",
          message:
              "Wi-Fi credentials saved to pending queue!\n\nThey will be sent to the SipNudge bottle automatically the next time it connects.",
          isSuccess: true,
        );
      } else if (response.result == 'ok') {
        // Shift priority selector to the next tab (Primary -> Secondary -> Tertiary)
        final nextPriority =
            _selectedPriority == 1 ? 2 : (_selectedPriority == 2 ? 3 : 3);
        setState(() {
          _selectedPriority = nextPriority;
        });
        await _loadCredentialsForPriority(nextPriority);

        _showResultDialog(
          title: "Provisioned Successfully",
          message:
              "Wi-Fi credentials saved and connection test succeeded!\n\nPriority: ${response.priority}\nIP Address: ${response.ip}",
          isSuccess: true,
        );
      } else if (response.result == 'fail') {
        String recMessage = "An unknown error occurred during testing.";
        if (response.reason == 'ap_not_found') {
          recMessage =
              "Access point not found.\nVerify the SSID and remain within range.";
        } else if (response.reason == 'auth_failed') {
          recMessage =
              "Authentication failed.\nIncorrect password or weak signal strength.";
        } else if (response.reason == 'timeout') {
          recMessage =
              "Connection test timed out.\nVerify the SSID/password and check if the bottle is in Wi-Fi range.";
        }

        _showResultDialog(
          title: "Connection Failed",
          message:
              "Wi-Fi credentials saved, but the connection test failed.\n\nReason: $recMessage",
          isSuccess: false,
        );
      } else if (response.result == 'saved') {
        _showResultDialog(
          title: "Settings Stored",
          message: "User ID has been successfully stored to the bottle.",
          isSuccess: true,
        );
      } else {
        _showResultDialog(
          title: "Error",
          message:
              "Invalid request or error received from bottle.\nReason: ${response.reason}",
          isSuccess: false,
        );
      }
    } catch (e) {
      if (isConnected) {
        _stopCountdown();
      }
      _showResultDialog(
        title: "System Error",
        message: "Failed to communicate with the bottle:\n$e",
        isSuccess: false,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: const Color(0xFFE8ECEF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF75555),
                  size: 72.sp,
                ),
                SizedBox(height: 20.h),
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF004976),
                    fontSize: 20.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.darkgray,
                    fontSize: 14.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (isSuccess && title == "Provisioned Successfully") {
                        Navigator.pop(context); // Go back to bottle spec screen
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004976),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      elevation: 0,
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<BottomNavCubit>().showBar();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image and subtle gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/app_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusCard(),
                            SizedBox(height: 20.h),
                            _buildProvisioningForm(),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BottomNavCubit>().showBar();
            },
            icon: const Icon(Icons.arrow_back, color: Color(0xFF475569)),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Wi-Fi Provisioning',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF5D7B91),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return BlocBuilder<BleCubit, BleState>(
      builder: (context, bleState) {
        final isConnected = bleState.status == BleStatus.connected;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: AppStyle.boxShadowVariation2,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xff46E73D)
                      : AppColors.redColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? "Bottle Connected" : "Bottle Disconnected",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: const Color(0xFF004976),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isConnected
                          ? "Ready to provision network configuration."
                          : "Connect your bottle over BLE to send configurations.",
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.greyColorText1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProvisioningForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: AppStyle.boxShadowVariation2,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Wi-Fi Settings",
            style: TextStyle(
              fontSize: 14.sp,
              fontVariations: [AppFontStyles.boldFontVariation],
              color: const Color(0xFF5D7B91),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _ssidController,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "SSID / Network Name is required";
              }
              if (val.trim().length > 32) {
                return "SSID must be 32 characters or less";
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.wifi_lock, color: Color(0xFF94A3B8)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                tooltip: "Autofill Connected Wi-Fi SSID",
                onPressed: _isLoading ? null : _autofillWifiSSID,
              ),
              labelText: "SSID (Network Name)",
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              hintText: "e.g., Home Wi-Fi",
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
            ),
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: AppColors.raisinblack,
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _passController,
            obscureText: _obscurePassword,
            validator: (val) {
              if (val != null && val.length > 63) {
                return "Password must be 63 characters or less";
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              labelText: "Wi-Fi Password",
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              hintText: "Leave blank for open networks",
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
            ),
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: AppColors.raisinblack,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "Priority",
            style: TextStyle(
              fontSize: 12.sp,
              fontVariations: [AppFontStyles.boldFontVariation],
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          _buildPrioritySelector(),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _provisionWifi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
              ),
              child: Text(
                "Provision & Test Network",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  fontFamily: AppFontStyles.urbanistFontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          _buildPriorityTab(1, "Primary"),
          _buildPriorityTab(2, "Secondary"),
          _buildPriorityTab(3, "Tertiary"),
        ],
      ),
    );
  }

  Widget _buildPriorityTab(int priority, String label) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading
            ? null
            : () {
                setState(() {
                  _selectedPriority = priority;
                });
                _loadCredentialsForPriority(priority);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontVariations: [
                isSelected
                    ? AppFontStyles.boldFontVariation
                    : AppFontStyles.semiBoldFontVariation
              ],
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: AppStyle.boxShadowVariation2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: CircularProgressIndicator(
                        value: _countdown / 20.0,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6)),
                      ),
                    ),
                    Text(
                      "$_countdown",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: const Color(0xFF004976),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Text(
                  "Testing Wi-Fi Connection...",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF004976),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "The bottle is verifying your Wi-Fi details. This may take up to 20 seconds.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: AppColors.greyColorText1,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
