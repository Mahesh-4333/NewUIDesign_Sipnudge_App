import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/screens/onboarding/home_screen_widget_instructions_screen.dart';
import 'package:hydrify/screens/onboarding/environmental_harmony_location_screen.dart';

class TimelineSlot {
  final String label;
  final String pendingIcon;
  final String ongoingIcon;
  final String completedIcon;

  const TimelineSlot({
    required this.label,
    required this.pendingIcon,
    required this.ongoingIcon,
    required this.completedIcon,
  });

  String getLocalizedLabel(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return label;
    switch (label) {
      case 'Wakeup':
        return loc.wakeupLabel;
      case 'Breakfast':
        return loc.breakfastLabel;
      case 'Mid-Morning':
        return loc.midMorningLabel;
      case 'Lunch':
        return loc.lunchLabel;
      case 'Mid-Afternoon':
        return loc.midAfternoonLabel;
      case 'Evening':
        return loc.eveningLabel;
      case 'Dinner':
        return loc.dinnerLabel;
      default:
        return label;
    }
  }
}

class HydrationRingOnboardingScreen extends StatefulWidget {
  final bool isFromOnboarding;

  const HydrationRingOnboardingScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  State<HydrationRingOnboardingScreen> createState() =>
      _HydrationRingOnboardingScreenState();
}

class _HydrationRingOnboardingScreenState
    extends State<HydrationRingOnboardingScreen> {
  int _currentStep = 0;
  bool _isCompleted = false;
  Timer? _timer;
  final ScrollController _timelineScrollController = ScrollController();

  // Single continuous list of intake timeline slots
  static const List<TimelineSlot> _slots = [
    TimelineSlot(
      label: 'Wakeup',
      pendingIcon: AssetsPath.wakeUpPending,
      ongoingIcon: AssetsPath.wakeUpOngoing,
      completedIcon: AssetsPath.wakeUpCompleted,
    ),
    TimelineSlot(
      label: 'Breakfast',
      pendingIcon: AssetsPath.breakfastPending,
      ongoingIcon: AssetsPath.breakfastOngoing,
      completedIcon: AssetsPath.breakfastCompleted,
    ),
    TimelineSlot(
      label: 'Mid-Morning',
      pendingIcon: AssetsPath.midMorningPending,
      ongoingIcon: AssetsPath.midMorningOngoing,
      completedIcon: AssetsPath.midMorningCompleted,
    ),
    TimelineSlot(
      label: 'Lunch',
      pendingIcon: AssetsPath.lunchPending,
      ongoingIcon: AssetsPath.lunchOngoing,
      completedIcon: AssetsPath.lunchCompleted,
    ),
    TimelineSlot(
      label: 'Mid-Afternoon',
      pendingIcon: AssetsPath.midAfternoonPending,
      ongoingIcon: AssetsPath.midAfternoonOngoing,
      completedIcon: AssetsPath.midAfternoonCompleted,
    ),
    TimelineSlot(
      label: 'Evening',
      pendingIcon: AssetsPath.eveningPending,
      ongoingIcon: AssetsPath.eveningOngoing,
      completedIcon: AssetsPath.eveningCompleted,
    ),
    TimelineSlot(
      label: 'Dinner',
      pendingIcon: AssetsPath.dinnerPending,
      ongoingIcon: AssetsPath.dinnerOngoing,
      completedIcon: AssetsPath.dinnerCompleted,
    ),
  ];

  // Sequential 1-by-1 slot progression:
  final List<Map<String, dynamic>> _stepData = [
    // Step 0: Initial Start (0 ml)
    {
      'percent': 0,
      'addMl': '+ 200 ml',
      'currentMl': '0 / 2,000 ml',
      'statusTitle': "Let’s hit today’s goal",
      'currentGoal': '7:00 AM - 8:00 AM',
      'nextGoal': '8:15 AM - 8:30 AM',
      'bottomTitle': 'See Your Day at a Glance',
      'bottomSubtitle':
          'Your ring shows how close you are to your daily hydration goal.',
      'isProGoal': false,
      'activeSlotIndex': 0,
      'slotStates': [0, 0, 0, 0, 0, 0, 0],
      'showYellowArc': false,
    },
    // Step 1: Wakeup Micro-goal (0 ml)
    {
      'percent': 0,
      'addMl': '+ 200 ml',
      'currentMl': '0 / 2,000 ml',
      'statusTitle': 'Keep Sipping',
      'currentGoal': '7:00 AM - 8:00 AM',
      'nextGoal': '8:15 AM - 8:30 AM',
      'bottomTitle': 'Stay on Your Next Goal',
      'bottomSubtitle':
          'Your yellow ring highlights the micro-goal to focus on right now.',
      'isProGoal': false,
      'activeSlotIndex': 0,
      'slotStates': [1, 0, 0, 0, 0, 0, 0],
      'showYellowArc': true,
    },
    // Step 2: Wakeup Completed, Breakfast Active (300 ml)
    {
      'percent': 15,
      'addMl': '+ 300 ml',
      'currentMl': '300 / 2,000 ml',
      'statusTitle': 'Keep Sipping',
      'currentGoal': '8:30 AM - 9:00 AM',
      'nextGoal': '10:30 AM - 11:00 AM',
      'bottomTitle': 'Watch Your Progress Build',
      'bottomSubtitle':
          'Every sip adds to your blue ring and moves you closer to your goal.',
      'isProGoal': false,
      'activeSlotIndex': 1,
      'slotStates': [2, 1, 0, 0, 0, 0, 0],
      'showYellowArc': true,
    },
    // Step 3: Breakfast Completed, Mid-Morning Active (600 ml)
    {
      'percent': 30,
      'addMl': '+ 300 ml',
      'currentMl': '600 / 2,000 ml',
      'statusTitle': 'Keep Sipping',
      'currentGoal': '10:30 AM - 11:00 AM',
      'nextGoal': '1:00 PM - 2:00 PM',
      'bottomTitle': 'Watch Your Progress Build',
      'bottomSubtitle':
          'Every sip adds to your blue ring and moves you closer to your goal.',
      'isProGoal': false,
      'activeSlotIndex': 2,
      'slotStates': [2, 2, 1, 0, 0, 0, 0],
      'showYellowArc': true,
    },
    // Step 4: Mid-Morning Completed, Lunch Active (900 ml)
    {
      'percent': 45,
      'addMl': '+ 300 ml',
      'currentMl': '900 / 2,000 ml',
      'statusTitle': 'You’re on track',
      'statusTitleColor': const Color(0xFFFFB300),
      'currentGoal': '1:00 PM - 2:00 PM',
      'nextGoal': '4:00 PM - 4:30 PM',
      'bottomTitle': 'Watch Your Progress Build',
      'bottomSubtitle':
          'Every sip adds to your blue ring and moves you closer to your goal.',
      'isProGoal': false,
      'activeSlotIndex': 3,
      'slotStates': [2, 2, 2, 1, 0, 0, 0],
      'showYellowArc': false,
    },
    // Step 5: Lunch Completed, Mid-Afternoon Active (1,200 ml)
    {
      'percent': 60,
      'addMl': '+ 400 ml',
      'currentMl': '1,200 / 2,000 ml',
      'statusTitle': 'Keep Sipping',
      'currentGoal': '4:00 PM - 4:30 PM',
      'nextGoal': '6:30 PM - 7:00 PM',
      'bottomTitle': 'Watch Your Progress Build',
      'bottomSubtitle':
          'Every sip adds to your blue ring and moves you closer to your goal.',
      'isProGoal': false,
      'activeSlotIndex': 4,
      'slotStates': [2, 2, 2, 2, 1, 0, 0],
      'showYellowArc': true,
    },
    // Step 6: Mid-Afternoon Completed, Evening Active (1,600 ml)
    {
      'percent': 80,
      'addMl': '+ 340 ml',
      'currentMl': '1,600 / 2,000 ml',
      'statusTitle': 'Keep Sipping',
      'currentGoal': '6:30 PM - 7:00 PM',
      'nextGoal': '8:30 PM - 9:30 PM',
      'bottomTitle': 'Watch Your Progress Build',
      'bottomSubtitle':
          'Every sip adds to your blue ring and moves you closer to your goal.',
      'isProGoal': false,
      'activeSlotIndex': 5,
      'slotStates': [2, 2, 2, 2, 2, 1, 0],
      'showYellowArc': true,
    },
    // Step 7: Evening Completed, Dinner Active -> Goal Reached! (2,000 ml)
    {
      'percent': 100,
      'addMl': '+ 250 ml',
      'currentMl': '2,000 / 2,000 ml',
      'statusTitle': 'You’re on track',
      'currentGoal': '8:30 PM - 9:30 PM',
      'nextGoal': '-',
      'bottomTitle': 'Sip Smart, Stay Sharp',
      'bottomSubtitle':
          'Keep the yellow segment as small as possible or gone entirely to stay ahead of schedule.',
      'isProGoal': true,
      'activeSlotIndex': 6,
      'slotStates': [2, 2, 2, 2, 2, 2, 2],
      'showYellowArc': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        if (_currentStep < _stepData.length - 1) {
          setState(() {
            _currentStep++;
            if (_currentStep == _stepData.length - 1) {
              _isCompleted = true;
              _timer?.cancel();
            }
          });
          _scrollToActiveSlot();
        } else {
          _timer?.cancel();
        }
      }
    });
  }

  void _scrollToActiveSlot() {
    if (!_timelineScrollController.hasClients) return;

    final activeSlotIndex = _stepData[_currentStep]['activeSlotIndex'] as int;
    final itemWidth = 60.w;
    final itemMargin = 12.w;
    final totalItemWidth = itemWidth + itemMargin;

    final targetOffset = (activeSlotIndex * totalItemWidth);

    _timelineScrollController.animateTo(
      targetOffset.clamp(
          0.0, _timelineScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (widget.isFromOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EnvironmentalHarmonyLocationScreen(),
        ),
      );
    }
  }

  void _onNextPressed() {
    if (!_isCompleted) return;

    if (widget.isFromOnboarding) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HomeScreenWidgetInstructionsScreen(isFromOnboarding: true),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  String _getLocalizedStatusTitle(String defaultTitle) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return defaultTitle;
    if (defaultTitle == "Let’s hit today’s goal") return loc.letsHitTodaysGoal;
    if (defaultTitle == "Keep Sipping") return loc.keepSippingText;
    if (defaultTitle == "You’re on track") return loc.youreOnTrack;
    return defaultTitle;
  }

  String _getLocalizedBottomTitle(String defaultTitle) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return defaultTitle;
    if (defaultTitle == "See Your Day at a Glance") return loc.seeYourDayAtAGlance;
    if (defaultTitle == "Stay on Your Next Goal") return loc.stayOnYourNextGoal;
    if (defaultTitle == "Watch Your Progress Build") return loc.watchYourProgressBuild;
    if (defaultTitle == "Sip Smart, Stay Sharp") return loc.sipSmartStaySharp;
    return defaultTitle;
  }

  String _getLocalizedBottomSubtitle(String defaultSubtitle) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return defaultSubtitle;
    if (defaultSubtitle ==
        "Your ring shows how close you are to your daily hydration goal.") {
      return loc.ringShowsDailyHydrationGoal;
    }
    if (defaultSubtitle ==
        "Your yellow ring highlights the micro-goal to focus on right now.") {
      return loc.yellowRingHighlightsMicroGoal;
    }
    if (defaultSubtitle ==
        "Every sip adds to your blue ring and moves you closer to your goal.") {
      return loc.everySipAddsToBlueRing;
    }
    if (defaultSubtitle ==
        "Keep the yellow segment as small as possible or gone entirely to stay ahead of schedule.") {
      return loc.keepYellowSegmentSmall;
    }
    return defaultSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final data = _stepData[_currentStep];
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
              image: AssetImage('assets/images/app_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Back Button
                Padding(
                  padding: EdgeInsets.only(
                      left: 24.w, right: 24.w, top: 12.h, bottom: 4.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _onBackPressed,
                      borderRadius: BorderRadius.circular(20.r),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.bluegray,
                        size: 24,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 8.h),
                      // Header Title
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
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
                      ),
                      SizedBox(height: 8.h),
                      // Header Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 36.w),
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
                      SizedBox(height: 20.h),

                      // Main Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: _buildHydrationRingCard(data),
                      ),

                      SizedBox(height: 12.h),

                      // Middle Down Arrow Icon
                      _buildDownArrow(),

                      SizedBox(height: 8.h),

                      // Single Horizontal Timeline Row (Moves left 1-by-1 step under the down arrow)
                      _buildTimelineRow(data),

                      SizedBox(height: 35.h),

                      // Bottom Explanation Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: _buildBottomExplanation(data),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button (Activates when 2,000 ml progress completes)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _isCompleted ? _onNextPressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted
                          ? const Color(0xFF00A2FF)
                          : const Color(0xFF94A3B8).withValues(alpha: 0.4),
                      disabledBackgroundColor:
                          const Color(0xFF94A3B8).withValues(alpha: 0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      loc?.continueBtn ?? "Continue",
                      style: TextStyle(
                        color: _isCompleted
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
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

  String _formatMl(int ml) {
    if (ml >= 1000) {
      final thousands = ml ~/ 1000;
      final remainder = ml % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return '$ml';
  }

  Widget _buildHydrationRingCard(Map<String, dynamic> data) {
    final targetPercent = (data['percent'] as num).toDouble();
    final showYellowArc = data['showYellowArc'] as bool;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: (showYellowArc ? 1.0 : 0.0)),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (context, yellowOpacity, _) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetPercent),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            builder: (context, animatedPercent, _) {
              final animatedMl = (animatedPercent / 100.0 * 2000).round();

              return Column(
                children: [
                  // Circular Progress Ring Gauge
                  SizedBox(
                    width: 130.w,
                    height: 130.w,
                    child: CustomPaint(
                      painter: _OnboardingRingPainter(
                        percent: animatedPercent,
                        yellowOpacity: yellowOpacity,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${animatedPercent.round()}%",
                              style: TextStyle(
                                fontSize: 24.sp,
                                color: const Color(0xFF0F172A),
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            _AnimatedAddMlText(
                              text: data['addMl'] as String,
                              stepKey: _currentStep,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // ML progress text
                  _buildMlProgressText(animatedMl),
                  SizedBox(height: 10.h),

                  // Status title
                  Text(
                    _getLocalizedStatusTitle(data['statusTitle'] as String),
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: (data['statusTitleColor'] as Color?) ??
                          (data['statusTitle'] == "You’re on track"
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF0F172A)),
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Goals Info Box (Current Goal & Next Goal)
                  Row(
                    children: [
                      Expanded(
                        child: _buildGoalTimeItem(
                          label: AppLocalizations.of(context)
                                  ?.currentGoalLabel ??
                              "Current Goal",
                          time: data['currentGoal'],
                        ),
                      ),
                      Container(
                        width: 1.w,
                        height: 28.h,
                        color: const Color(0xFFCBD5E1),
                      ),
                      Expanded(
                        child: _buildGoalTimeItem(
                          label:
                              AppLocalizations.of(context)?.nextGoalLabel ??
                                  "Next Goal",
                          time: data['nextGoal'],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMlProgressText(int currentMl, {int targetMl = 2000}) {
    final current = _formatMl(currentMl);
    final target = _formatMl(targetMl);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15.sp,
          fontFamily: AppFontStyles.urbanistFontFamily,
        ),
        children: [
          TextSpan(
            text: current,
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          TextSpan(
            text: " / $target ml",
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTimeItem({required String label, required String time}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.access_time_rounded,
            size: 17.sp,
            color: const Color(0xFF00A2FF),
          ),
        ),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.greyColor,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF0F172A),
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownArrow() {
    return CustomPaint(
      size: const Size(16, 10),
      painter: _TriangleArrowPainter(),
    );
  }

  Widget _buildTimelineRow(Map<String, dynamic> data) {
    final activeSlotIndex = data['activeSlotIndex'] as int;
    final slotStates = data['slotStates'] as List<int>;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 60.w;
    final sidePadding = (screenWidth / 2) - (itemWidth / 2);

    return SizedBox(
      height: 72.h,
      child: SingleChildScrollView(
        controller: _timelineScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: Row(
          children: List.generate(_slots.length, (index) {
            final slot = _slots[index];
            final state = (index < slotStates.length) ? slotStates[index] : 0;
            final isHighlighted = (index == activeSlotIndex);

            String iconPath;
            if (state == 2) {
              iconPath = slot.completedIcon;
            } else if (state == 1) {
              iconPath = slot.ongoingIcon;
            } else {
              iconPath = slot.pendingIcon;
            }

            return GestureDetector(
              onTap: () {
                int stepToJump = index + 1;
                if (stepToJump >= _stepData.length) {
                  stepToJump = _stepData.length - 1;
                }
                setState(() {
                  _currentStep = stepToJump;
                  if (_currentStep == _stepData.length - 1) {
                    _isCompleted = true;
                  }
                });
                _scrollToActiveSlot();
              },
              child: Container(
                width: itemWidth,
                margin: EdgeInsets.only(right: 12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44.w,
                      height: 44.w,
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      slot.getLocalizedLabel(context),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isHighlighted
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: isHighlighted
                            ? [AppFontStyles.boldFontVariation]
                            : [],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomExplanation(Map<String, dynamic> data) {
    final loc = AppLocalizations.of(context);

    if (data['isProGoal'] == true) {
      return Column(
        children: [
          Text(
            _getLocalizedBottomTitle(data['bottomTitle'] as String),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22.sp,
              color: AppColors.bluegray,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 16.sp,
                      color: const Color(0xFF0284C7),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      loc?.theProGoal ?? "THE PRO GOAL",
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.bluegray,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  _getLocalizedBottomSubtitle(data['bottomSubtitle'] as String),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.greyColor,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(_currentStep),
        children: [
          Text(
            _getLocalizedBottomTitle(data['bottomTitle'] as String),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22.sp,
              color: AppColors.bluegray,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              _getLocalizedBottomSubtitle(data['bottomSubtitle'] as String),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.bluegray,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingRingPainter extends CustomPainter {
  final double percent;
  final double yellowOpacity;

  _OnboardingRingPainter({
    required this.percent,
    required this.yellowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Track paint
    final paintTrack = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.w;

    // Blue progress paint
    final paintBlue = Paint()
      ..color = const Color(0xFF00A2FF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.w;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Top-opening arc math
    const startAngle = -1.2;
    const totalSweep = 5.5;

    // 1. Draw base light grey track
    canvas.drawArc(rect, startAngle, totalSweep, false, paintTrack);

    // 2. Calculate blue progress
    double blueFraction = (percent / 100.0).clamp(0.0, 1.0);
    double blueSweep = totalSweep * blueFraction;

    // 3. Draw yellow arc BEFORE blue so blue paints on top,
    //    hiding the yellow rounded cap that would overlap into the blue zone.
    if (yellowOpacity > 0.01) {
      final paintYellow = Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: yellowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10.w;

      double yellowStart = startAngle + blueSweep;
      double yellowSweep = 0.55; // ~32 degrees highlight segment

      if (yellowStart + yellowSweep > startAngle + totalSweep) {
        yellowSweep = (startAngle + totalSweep) - yellowStart;
      }

      if (yellowSweep > 0) {
        canvas.drawArc(rect, yellowStart, yellowSweep, false, paintYellow);
      }
    }

    // 4. Draw blue progress arc on top (covers yellow's left rounded cap)
    if (blueSweep > 0) {
      canvas.drawArc(rect, startAngle, blueSweep, false, paintBlue);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingRingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.yellowOpacity != yellowOpacity;
  }
}

class _AnimatedAddMlText extends StatefulWidget {
  final String text;
  final int stepKey;

  const _AnimatedAddMlText({
    required this.text,
    required this.stepKey,
  });

  @override
  State<_AnimatedAddMlText> createState() => _AnimatedAddMlTextState();
}

class _AnimatedAddMlTextState extends State<_AnimatedAddMlText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedAddMlText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepKey != widget.stepKey || oldWidget.text != widget.text) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFFD48256),
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
