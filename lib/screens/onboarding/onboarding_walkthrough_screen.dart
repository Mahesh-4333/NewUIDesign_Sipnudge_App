import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/onboarding/intake_timeline_intro_screen.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';

class WalkthroughSlide {
  final String asset;
  final String title;
  final String subtitle;

  const WalkthroughSlide({
    required this.asset,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingWalkthroughScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const OnboardingWalkthroughScreen({
    super.key,
    this.onFinish,
  });

  @override
  State<OnboardingWalkthroughScreen> createState() =>
      _OnboardingWalkthroughScreenState();
}

class _OnboardingWalkthroughScreenState
    extends State<OnboardingWalkthroughScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 3;
  Timer? _autoScrollTimer;

  List<WalkthroughSlide> _getSlides(BuildContext context) {
    return [
      WalkthroughSlide(
        asset: AssetsPath.onboardingHydration,
        title: AppLocalizations.of(context)?.walkthroughTitle1 ??
            "Sipnudge - Your Ultimate\nHydration Co-pilot!",
        subtitle: AppLocalizations.of(context)?.walkthroughSubtitle1 ??
            "Stay healthy, & conquer your hydration goals!\nTrack your water intake, set reminders, and\nunlock achievements for a healthier you.",
      ),
      WalkthroughSlide(
        asset: AssetsPath.onboardingVisualizeProgress,
        title: AppLocalizations.of(context)?.walkthroughTitle2 ??
            "Track Your Hydration &\nVisualize Your Progress",
        subtitle: AppLocalizations.of(context)?.walkthroughSubtitle2 ??
            "Set reminders to stay consistent, review your\ndaily hydration history, and visualize your\nprogress over time.",
      ),
      WalkthroughSlide(
        asset: AssetsPath.onboardingGoalWithSipnudge,
        title: AppLocalizations.of(context)?.walkthroughTitle3 ??
            "Achieve Your Hydration\nGoals with Sipnudge Now",
        subtitle: AppLocalizations.of(context)?.walkthroughSubtitle3 ??
            "Level up your hydration game with Sipnudge\nachievements. Unlock premium features, and\nmake hydration a lifelong habit.",
      ),
      WalkthroughSlide(
        asset: AssetsPath.onboardingHydrationInMeal,
        title: AppLocalizations.of(context)?.walkthroughTitle4 ??
            "Uncover the Hidden\nHydration in Your Meals",
        subtitle: AppLocalizations.of(context)?.walkthroughSubtitle4 ??
            "Scan your food to instantly calculate its water\ncontent and auto-correct your daily drinking\ngoals for effortless, total hydration.",
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.73);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_currentIndex == 0) {
      setState(() {
        _secondsRemaining = 2;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_secondsRemaining > 1) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _secondsRemaining = 0;
          });
        }
      });
    } else {
      setState(() {
        _secondsRemaining = 0;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _startTimer();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!mounted) return;
    final slidesLength = _getSlides(context).length;
    if (_currentIndex < slidesLength - 1) {
      _autoScrollTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        _nextSlide(slidesLength);
      });
    }
  }

  void _nextSlide(int slidesLength) {
    if (_currentIndex < slidesLength - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() async {
    _timer?.cancel();
    await SharedPrefsHelper.setOnboardingFlowCompleted(true);
    FirebaseMessagingService().init();
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else if (mounted) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => const IntakeTimelineIntroScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);
    final isUnlocked = _secondsRemaining == 0;
    final isLastSlide = _currentIndex == slides.length - 1;
    final buttonText = isLastSlide
        ? (AppLocalizations.of(context)?.letsGetStarted ?? "Lets get started")
        : (AppLocalizations.of(context)?.next ?? "Next");

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),

            // Carousel PageView displaying center image with next/prev image peeking at edges
            Expanded(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: slides.length,
                    // physics: const NeverScrollableScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemBuilder: (context, index) {
                      double scale = 1.0;
                      double opacity = 1.0;

                      if (_pageController.position.haveDimensions) {
                        final page =
                            _pageController.page ?? _currentIndex.toDouble();
                        final diff = (page - index).abs();
                        scale = (1.0 - (diff * 0.12)).clamp(0.85, 1.0);
                        opacity = (1.0 - (diff * 0.25)).clamp(0.70, 1.0);
                      } else {
                        final diff = (_currentIndex - index).abs().toDouble();
                        scale = (1.0 - (diff * 0.12)).clamp(0.85, 1.0);
                        opacity = (1.0 - (diff * 0.25)).clamp(0.70, 1.0);
                      }

                      return Center(
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24.r),
                                child: Image.asset(
                                  slides[index].asset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 12.h),

            // Bottom Controls Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  // Page Indicator Dots / Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final isSelected = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        height: 7.h,
                        width: isSelected ? 28.w : 7.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF369FFF)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 18.h),

                  // Slide Title Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      slides[_currentIndex].title,
                      key: ValueKey<int>(_currentIndex),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: 26.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        height: 1.2,
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Slide Subtitle Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Padding(
                      key: ValueKey<int>(_currentIndex + 100),
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        slides[_currentIndex].subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: 15.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.semiBoldFontVariation],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 26.h),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: ElevatedButton(
                      onPressed: isUnlocked
                          ? () {
                              if (isLastSlide) {
                                _finishOnboarding();
                              } else {
                                _nextSlide(slides.length);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnlocked
                            ? const Color(0xFF369FFF)
                            : const Color(0xFFE2F2FE),
                        disabledBackgroundColor: const Color(0xFFE2F2FE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27.r),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.white
                                    : const Color(0xFF90CAFF),
                                fontSize: 16.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                          ),
                          if (!isUnlocked)
                            Positioned(
                              right: 6.w,
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF7FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF90CAFF),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "${_secondsRemaining}s",
                                    style: TextStyle(
                                      color: const Color(0xFF7CB8F7),
                                      fontSize: 13.sp,
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation
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

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
