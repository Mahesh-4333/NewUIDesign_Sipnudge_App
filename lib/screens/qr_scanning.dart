import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/auth_options_screen.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/home_screen.dart';
import 'package:hydrify/screens/personalinfo.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/services/qr_generator.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner>
    with SingleTickerProviderStateMixin {
  String? _errorText;
  bool _isProcessing = false;

  /// Scanner related
  late MobileScannerController _controller;
  bool _cameraReady = true;

  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  // Tap recognizers for footer links
  final TapGestureRecognizer _privacyTap = TapGestureRecognizer();
  final TapGestureRecognizer _termsTap = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();

    // Initialize scanner controller with explicit settings
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Normalized animation from 0.0 to 1.0
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    // Initialize tap handlers
    _privacyTap.onTap = () => _onFooterLinkTap(LinkType.privacy);
    _termsTap.onTap = () => _onFooterLinkTap(LinkType.terms);
  }

  @override
  void dispose() {
    _controller.dispose();
    _lineController.dispose();
    // dispose recognizers
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  static const List<String> _validColors = [
    'black',
    'green',
    'purple',
    'gray',
    'red',
  ];

  Future<void> _handleQR(String value) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      final decoded = jsonDecode(value);

      if (decoded is! Map<String, dynamic>) {
        throw Exception("Not object");
      }

      if (!decoded.containsKey('color')) {
        throw Exception("Missing color");
      }

      final String qrColor = decoded['color'].toString().trim().toLowerCase();

      const validColors = [
        'purple',
        'black',
        'gray',
        'green',
        'red',
      ];

      if (!validColors.contains(qrColor)) {
        throw Exception("Unsupported color");
      }

      await SharedPrefsHelper.setBottleColor(qrColor);

      if (!mounted) return;

      // await Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => const BottomNavScreenNew(),
      //   ),
      // );
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthOptionsScreen(),
        ),
      );
    } catch (e) {
      debugPrint("QR ERROR: $e");

      setState(() {
        _errorText = "Invalid QR Code";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// 🔹 FIRST EXPANDED — HEADER (LOGO + TEXT)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/app_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: AppDimensions.dim50.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/sipnudge1.png",
                        width: AppDimensions.dim229.w,
                        height: AppDimensions.dim51.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: AppDimensions.dim20.h),
                      Text(
                        "Scan QR",
                        // style: TextStyle(
                        //   color: Color(0xFF4D758B), // Simple color for testing
                        //   fontSize: 20.sp,
                        //   fontWeight: FontWeight.w700,
                        // ),
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_20.sp,
                          fontFamily: AppFontStyles.museoModernoFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: AppDimensions.dim8.h),
                      Text(
                        "Point your Camera at the QR Code",
                        textAlign: TextAlign.center,
                        // style: TextStyle(
                        //   color: Color(0xFF4D758B), // Simple color for testing
                        //   fontSize: 16.sp,
                        //   fontWeight: FontWeight.w400,
                        // ),
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_16.sp,
                          fontFamily: AppFontStyles.museoModernoFontFamily,
                          fontVariations: [AppFontStyles.regularFontVariation],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 🔹 SECOND EXPANDED — SCANNER
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/app_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _buildScanner(),
            ),
          ),

          /// 🔹 THIRD EXPANDED — BUTTON AREA
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/app_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 140.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_errorText != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              _errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppColors.greywith80),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: Text(
                                "or",
                                // style: TextStyle(
                                //   color: Color(
                                //     0xFF616161,
                                //   ), // Simple color for testing
                                //   fontSize: 16.sp,
                                //   fontWeight: FontWeight.w500,
                                // ),
                                style: TextStyle(
                                  color: Color(0xFF616161),
                                  fontSize: AppFontStyles.fontSize_18.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.semiBoldFontVariation,
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.greywith80),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 58.h,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF9FFFFA),
                                  Color(0xFFD1FFC4),
                                ],
                              ),
                              border: Border.all(color: AppColors.bluegray),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: AuthButton(
                              text: "Continue as Guest",
                              gradient: AppColors.guestButtonColor,
                              textColor: AppColors.buttonTextPurpleColor,
                              areTwoItems: false,
                              borderColor: AppColors.bluegray,
                              onTap: () {
                                SharedPrefsHelper.setUserEmail("guest_user");

                                UiUtilsService.showToast(
                                  context: context,
                                  text: "Continuing as Guest",
                                );

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserInfoInputScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 🔹 FOOTER TEXT
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 25.h),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/app_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      fontSize: AppFontStyles.fontSize_13,
                      color: Colors.black,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily),
                  children: [
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: AppFontStyles.fontSize_13,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _onFooterLinkTap(LinkType.privacy);
                        },
                    ),
                    TextSpan(
                      text: '     .     ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: AppFontStyles.fontSize_13,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _onFooterLinkTap(LinkType.terms);
                        },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanRect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: constraints.maxWidth * 0.85,
          height: constraints.maxHeight * 0.7,
        );

        return Stack(
          children: [
            // Camera Feed - Full area without scanWindow restriction
            Positioned.fromRect(
              rect: scanRect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_isProcessing) return;

                    final List<Barcode> barcodes = capture.barcodes;

                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code != null && code.isNotEmpty) {
                        debugPrint('Barcode detected: $code');
                        _handleQR(code);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),

            // Animated Scanning Line
            Positioned.fromRect(
              rect: scanRect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: AnimatedBuilder(
                  animation: _lineAnimation,
                  builder: (_, __) {
                    return Stack(
                      children: [
                        Positioned(
                          top: scanRect.height * _lineAnimation.value - 1.5,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.amber.withOpacity(0.8),
                                  Colors.amber,
                                  Colors.amber.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Overlay with corner decorations
            Positioned.fill(
              child: CustomPaint(painter: _ScannerOverlayPainter(scanRect)),
            ),
          ],
        );
      },
    );
  }

  void _onFooterLinkTap(LinkType type) async {
    final uri = Uri.parse(type == LinkType.privacy
        ? "https://sipnudge.com/policies/privacy-policy"
        : "https://sipnudge.com/policies/terms-of-service");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open the webpage")),
      );
    }
  }
}

/// 🔹 SCANNER OVERLAY PAINTER
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;

  _ScannerOverlayPainter(this.scanRect);

  @override
  void paint(Canvas canvas, Size size) {
    /// CORNER PAINT
    final cornerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 50.0;
    const cornerRadius = 20.0;

    /// ───────── TOP LEFT ─────────
    final topLeftPath = Path()
      ..moveTo(scanRect.left, scanRect.top + cornerLength)
      ..lineTo(scanRect.left, scanRect.top + cornerRadius)
      ..quadraticBezierTo(
        scanRect.left,
        scanRect.top,
        scanRect.left + cornerRadius,
        scanRect.top,
      )
      ..lineTo(scanRect.left + cornerLength, scanRect.top);
    canvas.drawPath(topLeftPath, cornerPaint);

    /// ───────── TOP CENTER ─────────
    canvas.drawLine(
      Offset(scanRect.center.dx - cornerLength / 1.5, scanRect.top),
      Offset(scanRect.center.dx + cornerLength / 1.5, scanRect.top),
      cornerPaint,
    );

    /// ───────── TOP RIGHT ─────────
    final topRightPath = Path()
      ..moveTo(scanRect.right - cornerLength, scanRect.top)
      ..lineTo(scanRect.right - cornerRadius, scanRect.top)
      ..quadraticBezierTo(
        scanRect.right,
        scanRect.top,
        scanRect.right,
        scanRect.top + cornerRadius,
      )
      ..lineTo(scanRect.right, scanRect.top + cornerLength);
    canvas.drawPath(topRightPath, cornerPaint);

    /// ───────── BOTTOM LEFT ─────────
    final bottomLeftPath = Path()
      ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
      ..lineTo(scanRect.left, scanRect.bottom - cornerRadius)
      ..quadraticBezierTo(
        scanRect.left,
        scanRect.bottom,
        scanRect.left + cornerRadius,
        scanRect.bottom,
      )
      ..lineTo(scanRect.left + cornerLength, scanRect.bottom);
    canvas.drawPath(bottomLeftPath, cornerPaint);

    /// ───────── BOTTOM CENTER ─────────
    canvas.drawLine(
      Offset(scanRect.center.dx - cornerLength / 1.5, scanRect.bottom),
      Offset(scanRect.center.dx + cornerLength / 1.5, scanRect.bottom),
      cornerPaint,
    );

    /// ───────── BOTTOM RIGHT ─────────
    final bottomRightPath = Path()
      ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
      ..lineTo(scanRect.right - cornerRadius, scanRect.bottom)
      ..quadraticBezierTo(
        scanRect.right,
        scanRect.bottom,
        scanRect.right,
        scanRect.bottom - cornerRadius,
      )
      ..lineTo(scanRect.right, scanRect.bottom - cornerLength);
    canvas.drawPath(bottomRightPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum LinkType { privacy, terms }
