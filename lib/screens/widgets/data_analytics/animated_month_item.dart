import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/data_n_analytics/data_n_analytics_screen.dart';

class AnimatedMonthItem extends StatefulWidget {
  final int index;
  final MonthGoalCompletionStatus status;
  final String monthName;
  final bool
      isSelected; // Helpful if you want to highlight the selected month later
  final VoidCallback onTap;

  const AnimatedMonthItem({
    super.key,
    required this.index,
    required this.status,
    required this.monthName,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<AnimatedMonthItem> createState() => _AnimatedMonthItemState();
}

class _AnimatedMonthItemState extends State<AnimatedMonthItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onTap(); // Trigger the actual selection logic
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: AppDimensions.dim70.w,
              height: AppDimensions.dim25.h,
              padding: EdgeInsets.all(
                widget.status == MonthGoalCompletionStatus.Partial ? 1 : .5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.dim15.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.color_E7E7E7,
                    AppColors.color_00050C.withOpacity(.9)
                  ],
                ),
                boxShadow: widget.status == MonthGoalCompletionStatus.Partial
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.dim15.r),
                  color: widget.status == MonthGoalCompletionStatus.Completed
                      ? AppColors.color_136DEC
                      // You can add a check here for widget.isSelected if you want a different color when active
                      : widget.status == MonthGoalCompletionStatus.Partial
                          ? AppColors.color_D0E2FB
                          : AppColors.white,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.monthName,
                  style: TextStyle(
                    color: widget.status != MonthGoalCompletionStatus.Completed
                        ? AppColors.steelblue
                        : AppColors.white,
                    fontSize: AppFontStyles.fontSize_10,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
