import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';

class GoalTextWidget extends StatefulWidget {
  final double todayConsumptionPercentage;

  const GoalTextWidget({super.key, required this.todayConsumptionPercentage});

  @override
  _GoalTextWidgetState createState() => _GoalTextWidgetState();
}

class _GoalTextWidgetState extends State<GoalTextWidget> {
  bool _showAlternate = false;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Toggle text every second
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _showAlternate = !_showAlternate;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.dim350.w,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          _showAlternate
              ? AppStrings.touchTheCapToSyncNow
              : AppStrings.getGoalString(widget.todayConsumptionPercentage),
          key: ValueKey<bool>(_showAlternate),
          style: TextStyle(
            fontSize: AppFontStyles.fontSize_16,
            color: AppColors.white,
            height: AppFontStyles.getLineHeight(AppFontStyles.fontSize_16, 120),
            fontVariations: [
              AppFontStyles.semiBoldFontVariation,
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
