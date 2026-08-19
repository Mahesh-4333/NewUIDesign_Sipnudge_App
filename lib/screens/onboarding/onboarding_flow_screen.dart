import 'package:flutter/material.dart';
import 'package:hydrify/screens/onboarding/choose_finish_screen.dart';
import 'package:hydrify/screens/onboarding/enable_bluetooth_screen.dart';
import 'package:hydrify/screens/onboarding/bottle_activation_screen.dart';
import 'package:hydrify/screens/onboarding/fresh_start_calibration_screen.dart';
import 'package:hydrify/screens/onboarding/onboarding_walkthrough_screen.dart';
import 'package:hydrify/screens/onboarding/intake_timeline_intro_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onFlowCompleted;
  final VoidCallback? onFlowSkipped;

  const OnboardingFlowScreen({
    super.key,
    this.onFlowCompleted,
    this.onFlowSkipped,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _selectedBottleIndex = 1; // Default Candy Red
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
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
            _pageController.animateToPage(
              4,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
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
          onFinalize: _nextPage,
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
