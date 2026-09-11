import 'package:flutter/material.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/onboarding/choose_finish_screen.dart';
import 'package:hydrify/screens/onboarding/enable_bluetooth_screen.dart';
import 'package:hydrify/screens/onboarding/bottle_activation_screen.dart';
import 'package:hydrify/screens/onboarding/fresh_start_calibration_screen.dart';
import 'package:hydrify/screens/onboarding/onboarding_walkthrough_screen.dart';
import 'package:hydrify/screens/onboarding/intake_timeline_intro_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onFlowCompleted;
  final VoidCallback? onFlowSkipped;
  final int initialPage;
  final int initialBottleIndex;

  const OnboardingFlowScreen({
    super.key,
    this.onFlowCompleted,
    this.onFlowSkipped,
    this.initialPage = 0,
    this.initialBottleIndex = 1,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final PageController _pageController;
  late int _selectedBottleIndex;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _selectedBottleIndex = widget.initialBottleIndex;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (_currentPage == widget.initialPage) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      physics: const NeverScrollableScrollPhysics(), // Controlled via buttons
      children: [
        // Page 1: Choose Your Finish
        ChooseFinishScreen(
          onConfirm: (index) {
            setState(() {
              _selectedBottleIndex = index;
            });
            _nextPage();
          },
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),

        // Page 2: Enable Bluetooth
        EnableBluetoothScreen(
          selectedBottleIndex: _selectedBottleIndex,
          onEnableBluetooth: () {
            _nextPage();
          },
          onSkip: () {
            SharedPrefsHelper.setHasSkippedBluetooth(true);
            if (widget.initialPage > 0) {
              if (widget.onFlowSkipped != null) {
                widget.onFlowSkipped!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } else {
              _pageController.animateToPage(
                4,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            }
          },
          onBack: _previousPage,
        ),

        // Page 3: Bottle Activation
        BottleActivationScreen(
          selectedBottleIndex: _selectedBottleIndex,
          onDeviceSelected: _nextPage,
          onBack: _previousPage,
          isActive: _currentPage == 2,
        ),

        // Page 4: Fresh Start Calibration
        FreshStartCalibrationScreen(
          selectedBottleIndex: _selectedBottleIndex,
          onBack: _previousPage,
          onFinalize: () {
            if (widget.initialPage > 0) {
              if (widget.onFlowCompleted != null) {
                widget.onFlowCompleted!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } else {
              _nextPage();
            }
          },
        ),

        // Page 5: Introduction Walkthrough Slides
        OnboardingWalkthroughScreen(
          onFinish: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => IntakeTimelineIntroScreen(
                  onDone: () {
                    if (widget.onFlowCompleted != null) {
                      widget.onFlowCompleted!();
                    } else {
                      // Pop IntakeTimelineIntroScreen
                      Navigator.of(context).pop();
                      // Pop OnboardingFlowScreen
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
