import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';

import 'package:hydrify/cubit/ble/ble_cubit.dart';

class CustomBeatingBleStatusIndicator extends StatefulWidget {
  const CustomBeatingBleStatusIndicator({super.key});

  @override
  State<CustomBeatingBleStatusIndicator> createState() =>
      _CustomBeatingBleStatusIndicatorState();
}

class _CustomBeatingBleStatusIndicatorState
    extends State<CustomBeatingBleStatusIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _spreadAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _blurAnimation = Tween<double>(begin: 1, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _spreadAnimation = Tween<double>(begin: 1, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && !_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleCubit, BleState>(
      builder: (context, state) {
        final bool isConnected =
            (state.status == BleStatus.connected) &&
            (state.isServiceDiscoveryDone == true);

        final bool isTransitional = state.status == BleStatus.connecting ||
            state.status == BleStatus.scanning ||
            state.status == BleStatus.initializing ||
            (state.status == BleStatus.connected &&
                state.isServiceDiscoveryDone != true);

        final Color connectionColor = isConnected
            ? AppColors.batteryIndicator
            : (isTransitional ? const Color(0xFFFFA500) : AppColors.redColor);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: AppDimensions.dim10.w,
              height: AppDimensions.dim10.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0XFF9677E9),
                boxShadow: [
                  BoxShadow(
                    blurRadius: _blurAnimation.value,
                    spreadRadius: _spreadAnimation.value,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
              child: Container(
                width: AppDimensions.dim8.w,
                height: AppDimensions.dim8.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connectionColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
