import 'package:flutter/material.dart';
import 'package:hydrify/screens/onboarding/choose_finish_screen.dart';
import 'package:hydrify/screens/onboarding/enable_bluetooth_screen.dart';
import 'package:hydrify/screens/onboarding/bottle_activation_screen.dart';
import 'package:hydrify/screens/onboarding/fresh_start_calibration_screen.dart';

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

  void _nextPage() {
    _pageController.nextPage(
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
      physics: const NeverScrollableScrollPhysics(), // Controlled via buttons
      children: [
        // Page 1: Choose Your Finish
        ChooseFinishScreen(
          onConfirm: _nextPage,
        ),

        // Page 2: Enable Bluetooth
        EnableBluetoothScreen(
          onEnableBluetooth: _nextPage,
          onSkip: widget.onFlowSkipped ?? _nextPage,
        ),

        // Page 3: Bottle Activation
        BottleActivationScreen(
          onDeviceSelected: _nextPage,
        ),

        // Page 4: Fresh Start Calibration
        FreshStartCalibrationScreen(
          onFinalize: () {
            if (widget.onFlowCompleted != null) {
              widget.onFlowCompleted!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
