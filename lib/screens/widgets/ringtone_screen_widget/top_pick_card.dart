import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';

class TopPickCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String duration;
  final String iconPath;
  final bool isSelected;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onFavoriteTap;

  const TopPickCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.duration,
    required this.iconPath,
    this.isSelected = false,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onPlayTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: isSelected
              ? Border.all(color: AppColors.blueWaterIntake, width: 2.w)
              : Border.all(color: Colors.transparent, width: 2.w),
          boxShadow: AppStyle.boxShadowVariation2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              child: Image.asset(
                iconPath,
                width: 40.w,
                height: 40.w,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: 16.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "$subTitle • $duration",
              style: TextStyle(
                color: AppColors.bluegray.withOpacity(0.5),
                fontSize: 12.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (onPlayTap != null) onPlayTap!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: AppColors.blueWaterIntake,
                    size: 28.w,
                  ),
                ),
                SizedBox(width: 8.w),
                // Animated waveform
                _AnimatedVisualizer(isPlaying: isPlaying),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    if (onFavoriteTap != null) onFavoriteTap!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? Colors.red
                        : AppColors.bluegray.withOpacity(0.4),
                    size: 20.w,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedVisualizer extends StatefulWidget {
  final bool isPlaying;

  const _AnimatedVisualizer({required this.isPlaying});

  @override
  State<_AnimatedVisualizer> createState() => _AnimatedVisualizerState();
}

class _AnimatedVisualizerState extends State<_AnimatedVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    final durations = [400, 300, 500, 350, 450];
    _controllers = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[index]),
      ),
    );

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void didUpdateWidget(_AnimatedVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 32.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            5,
            (index) => AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                final baseHeight = (10 + (index % 3) * 5).h;
                final currentHeight =
                    baseHeight + (_controllers[index].value * 15).h;

                return Container(
                  width: 3.w,
                  height: currentHeight,
                  decoration: BoxDecoration(
                    color: widget.isPlaying
                        ? AppColors.blueWaterIntake
                        : AppColors.blueWaterIntake.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
