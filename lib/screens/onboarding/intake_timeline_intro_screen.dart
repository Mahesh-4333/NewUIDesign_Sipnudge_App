import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/home_screen.dart';

class IntakeTimelineIntroScreen extends StatefulWidget {
  final VoidCallback? onDone;

  const IntakeTimelineIntroScreen({super.key, this.onDone});

  @override
  State<IntakeTimelineIntroScreen> createState() =>
      _IntakeTimelineIntroScreenState();
}

class _IntakeTimelineIntroScreenState extends State<IntakeTimelineIntroScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/onboarding/intake_tutorial.mp4',
      );
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0);
      _videoController.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
        _fadeController.forward();
      }
    }
  }

  void _goToHome() {
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BottomNavScreenNew()),
        (route) => false,
      );
    }
  }

  void _goToSchedule() {
    // Signal HomeScreen to auto-trigger the bell drag animation
    HomeScreen.autoTriggerTimelineDrag = true;

    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BottomNavScreenNew()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
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
          child: Column(
            children: [
              // ── Top blue header ─────────────────────────────────────────
              // _buildHeader(),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 28.h),

                      // Title
                      Text(
                        "Let's Schedule\nyour timeline",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26.sp,
                          color: AppColors.bluegray,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          height: 1.25,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Subtitle
                      Text(
                        "Set your schedule to complete the 7 micro goals.\nSipnudge will keep you on track with reminders\nand smart snoozes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.bluegray.withValues(alpha: 0.7),
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.semiBoldFontVariation],
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // ── Video / Placeholder box ──────────────────────
                      _buildVideoBox(),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),

              // ── Bottom buttons ───────────────────────────────────────────
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 20.h,
        bottom: 28.h,
        left: 24.w,
        right: 24.w,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5BC8F5),
            Color(0xFF2196F3),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Text(
        "Water Intake Timeline",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24.sp,
          color: Colors.white,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontVariations: [AppFontStyles.boldFontVariation],
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildVideoBox() {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.bluegray,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: _buildVideoContent(),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasVideoError) {
      // Fallback placeholder when video is missing / error
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 56.sp,
              color: const Color(0xFF00A2FF).withValues(alpha: 0.4),
            ),
            SizedBox(height: 12.h),
            Text(
              "Demo video",
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF94A3B8),
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
              ),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00A2FF),
          strokeWidth: 2,
        ),
      );
    }

    // Initialized — show video fitted inside the box
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController.value.size.width,
              height: _videoController.value.size.height,
              child: VideoPlayer(_videoController),
            ),
          ),
          // Subtle mute icon at bottom-right
          Positioned(
            bottom: 10.h,
            right: 10.w,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_off_rounded,
                size: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
      child: Row(
        children: [
          // Skip button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _goToHome,
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Skip",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: const Color(0xFF475569),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Schedule now button
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: _goToSchedule,
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A2FF), Color(0xFF2563EB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A2FF).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Schedule now",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
