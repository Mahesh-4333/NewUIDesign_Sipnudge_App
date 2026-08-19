import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/screens/onboarding/onboarding_flow_screen.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';
import 'package:hydrify/screens/onboarding/hydration_ring_onboarding_screen.dart';
import 'package:hydrify/screens/widgets/custom_anim_toggle.dart';

class HomeScreenWidgetInstructionsScreen extends StatefulWidget {
  final bool isFromOnboarding;

  const HomeScreenWidgetInstructionsScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  State<HomeScreenWidgetInstructionsScreen> createState() =>
      _HomeScreenWidgetInstructionsScreenState();
}

class _HomeScreenWidgetInstructionsScreenState
    extends State<HomeScreenWidgetInstructionsScreen>
    with WidgetsBindingObserver {
  bool _smartRemindersEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final smartReminders = await SharedPrefsHelper.isSmartRemindersEnabled();
    final hasNotificationPermission = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        _smartRemindersEnabled = smartReminders && hasNotificationPermission;
        _isLoading = false;
      });
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

  Future<void> _toggleSmartReminders(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() {
          _smartRemindersEnabled = true;
        });
        await SharedPrefsHelper.setSmartRemindersEnabled(true);
      } else {
        setState(() {
          _smartRemindersEnabled = false;
        });
        await SharedPrefsHelper.setSmartRemindersEnabled(false);
        if (mounted) {
          _showPermissionDialog(
            context: context,
            title: "Notification Permission Required",
            message:
                "Please enable notification permission in Settings to receive smart hydration reminders.",
          );
        }
      }
    } else {
      setState(() {
        _smartRemindersEnabled = false;
      });
      await SharedPrefsHelper.setSmartRemindersEnabled(false);
    }
  }

  void _onBackPressed() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (widget.isFromOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HydrationRingOnboardingScreen(isFromOnboarding: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/app_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header Back Button
                Padding(
                  padding: EdgeInsets.only(
                      left: 24.w, right: 24.w, top: 12.h, bottom: 4.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _onBackPressed,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.bluegray,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 8.h),
                        // Title
                        Text(
                          loc?.stayConnectedAndOnTrack ??
                              "Stay Connected\n& On Track",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: 26.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Subtitle
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            loc?.understandingHydrationRingSubtitle ??
                                "Understanding your hydration ring helps you crush your goals.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.bluegray,
                              fontSize: 14.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                              height: 1.4,
                            ),
                          ),
                        ),

                        // Card 1: Widget Mockup
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Image.asset(
                            "assets/onboarding/widget_redesign.png",
                            width: 350.w,
                          ),
                        ),

                        // Instruction Steps Header
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            loc?.addTheWidgetToHomeScreenInstruction ??
                                "Add the widget to your Home Screen and\nsee your goal and progress at a glance",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.bluegray,
                              fontSize: 15.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),

                        // Instruction Steps
                        _buildInstructionStep(
                          number: "1",
                          text: loc?.touchAndHoldHomeScreen ??
                              "Touch and hold your Home Screen",
                        ),
                        SizedBox(height: 14.h),
                        _buildInstructionStep(
                          number: "2",
                          text: loc?.tapEditThenAddWidget ??
                              "Tap Edit, then Add Widget",
                        ),
                        SizedBox(height: 14.h),
                        _buildInstructionStep(
                          number: "3",
                          text: loc?.chooseMyWaterAndTapAddWidget ??
                              "Choose My Water and tap Add Widget",
                        ),
                        SizedBox(height: 40.h),

                        // Card 2: Smart Reminders Settings
                        if (!_isLoading) _buildSmartSettingsCard(),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                // Bottom Continue Button
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        // Block navigation if smart reminders are not enabled
                        if (!_smartRemindersEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enable Smart Reminders to continue.',
                                style: TextStyle(
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontSize: 14.sp,
                                ),
                              ),
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 12.h),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        if (widget.isFromOnboarding) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OnboardingFlowScreen(
                                onFlowCompleted: () async {
                                  await SharedPrefsHelper
                                      .setOnboardingFlowCompleted(true);
                                  FirebaseMessagingService().init();
                                  if (!context.mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BottomNavScreenNew(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                onFlowSkipped: () async {
                                  await SharedPrefsHelper
                                      .setOnboardingFlowCompleted(true);
                                  FirebaseMessagingService().init();
                                  if (!context.mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BottomNavScreenNew(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _smartRemindersEnabled
                            ? const Color(0xFF00A2FF)
                            : const Color(0xFFCBD5E1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: Text(
                        loc?.continueBtn ?? "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
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
    );
  }

  Widget _buildWidgetMockup() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Ring gauge Column
          Expanded(
            flex: 11,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96.w,
                  height: 96.w,
                  child: CustomPaint(
                    painter: _WidgetProgressRingPainter(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "50%",
                            style: TextStyle(
                              fontSize: 22.sp,
                              color: const Color(0xFF0F172A),
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "+ 200 ml",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFFD48256),
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: "1,360",
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      TextSpan(
                        text: " / 2,000 ml",
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.w),

          // Right Info Column
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Battery Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Stylized horizontal battery icon
                    Row(
                      children: [
                        Container(
                          width: 14.w,
                          height: 7.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF22C55E), width: 1.2),
                            borderRadius: BorderRadius.circular(1.5.r),
                          ),
                          padding: const EdgeInsets.all(0.8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.72,
                              child: Container(color: const Color(0xFF22C55E)),
                            ),
                          ),
                        ),
                        Container(
                          width: 1.w,
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(0.5.r),
                              bottomRight: Radius.circular(0.5.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "BATTERY",
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: const Color(0xFF64748B),
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "72%",
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: const Color(0xFF64748B),
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Thin Battery bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    minHeight: 2.5.h,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                  ),
                ),
                SizedBox(height: 10.h),

                // Status Message
                Text(
                  "You’re on track",
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF0F172A),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: 10.h),

                // Next Sip Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 14.sp,
                        color: const Color(0xFF00A2FF),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Next sip",
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF94A3B8),
                            fontFamily: AppFontStyles.urbanistFontFamily,
                          ),
                        ),
                        Text(
                          "4:00 PM",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF0F172A),
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Pills Row
                Row(
                  children: [
                    // Coffee Pill
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF6EE),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: const Color(0xFFF3E5D8), width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Coffee",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF8B5A2B),
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5A2B),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 4.w,
                                height: 4.w,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // Water Pill
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7FF),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: const Color(0xFFD0E2FB), width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Water",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF0083FF),
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0083FF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 10.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Padding(
      padding: EdgeInsets.only(left: 14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              color: Color(0xFF00A2FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: 14.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSettingsCard() {
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Image.asset(
                "assets/onboarding/bell_reminder.png",
                width: 18.w,
                height: 18.w,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.smartReminders ?? "Smart Reminders",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: const Color(0xFF0F172A),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  loc?.smartRemindersDescription ??
                      "Receive timely nudges based on your activity and environment.",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AnimatedToggle(
            value: _smartRemindersEnabled,
            onChanged: _toggleSmartReminders,
          ),
        ],
      ),
    );
  }
}

class _WidgetProgressRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;

    // Track paint matching exact top-opening arc
    final paintTrack = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.w;

    final paintBlue = Paint()
      ..color = const Color(0xFF00A2FF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9.w;

    final paintYellow = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9.w;

    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -1.2;
    const totalSweep = 5.5;

    // 1. Base track
    canvas.drawArc(rect, startAngle, totalSweep, false, paintTrack);

    // 2. Blue progress (50%)
    double blueSweep = totalSweep * 0.5;
    canvas.drawArc(rect, startAngle, blueSweep, false, paintBlue);

    // 3. Yellow arc segment (following blue arc)
    double yellowStart = startAngle + blueSweep;
    double yellowSweep = 0.55;
    canvas.drawArc(rect, yellowStart, yellowSweep, false, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
