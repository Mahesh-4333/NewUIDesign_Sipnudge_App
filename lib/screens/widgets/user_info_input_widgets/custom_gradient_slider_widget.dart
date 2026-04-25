import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/vibration_helper.dart';

class CustomGradientSlider extends StatefulWidget {
  final List<double> tickValues;
  final double initialValue;
  final ValueChanged<double>? onChanged;

  const CustomGradientSlider({
    super.key,
    required this.tickValues,
    required this.initialValue,
    this.onChanged,
  });

  @override
  State<CustomGradientSlider> createState() => _CustomGradientSliderState();
}

class _CustomGradientSliderState extends State<CustomGradientSlider> {
  late PageController _pageController;
  late int _currentIndex;
  final double _viewportFraction = 0.35; // Adjust to control spacing

  @override
  void initState() {
    super.initState();
    _currentIndex = _findClosestIndex(widget.initialValue);
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant CustomGradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.tickValues != widget.tickValues) {
      final newIndex = _findClosestIndex(widget.initialValue);
      if (newIndex != _currentIndex) {
        _currentIndex = newIndex;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _findClosestIndex(double value) {
    final ticks = widget.tickValues;
    int bestIndex = 0;
    double bestDiff = (ticks[0] - value).abs();

    for (int i = 1; i < ticks.length; i++) {
      final diff = (ticks[i] - value).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    final value = widget.tickValues[index];
    VibrationHelper.vibrate(duration: 15, amplitude: 100);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 90.h,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 1. The Track (Moving Gradient Fill)
              // This stays vertically centered relative to the thumb
              Positioned(
                top: 8.h, // Align with thumb center
                child: IgnorePointer(
                  child: _buildTrackBackground(),
                ),
              ),

              // 2. The Interactive Carousel (Labels and Ticks)
              // We make this tall enough to contain the labels below the track
              PageView.builder(
                controller: _pageController,
                itemCount: widget.tickValues.length,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final value = widget.tickValues[index];
                  return _buildTickItem(index, value);
                },
              ),

              // 3. The Fixed Thumb (Centered on top of track)
              Positioned(
                top: 0,
                child: IgnorePointer(
                  child: _buildFixedThumb(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackBackground() {
    final double trackHeight = 10.h;
    final double radius = trackHeight / 2;

    return Container(
      width: 1.sw -
          AppDimensions.defaultPadding.w * 4, // Consistent with screen padding
      height: trackHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.greywith80, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double progress = 0.0;
            if (_pageController.hasClients &&
                _pageController.position.haveDimensions) {
              progress = (_pageController.page ?? _currentIndex.toDouble()) /
                  (widget.tickValues.length - 1);
            } else {
              progress = _currentIndex / (widget.tickValues.length - 1);
            }

            return Row(
              children: [
                Expanded(
                  flex: (progress * 1000).toInt().clamp(1, 1000),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0XFF9AE9FF), Color(0XFF005D84)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - progress) * 1000).toInt().clamp(1, 1000),
                  child: Container(color: Colors.white),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTickItem(int index, double value) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double valueInPage = 0.0;
        if (_pageController.hasClients &&
            _pageController.position.haveDimensions) {
          valueInPage = _pageController.page! - index;
        } else {
          valueInPage = (_currentIndex - index).toDouble();
        }

        double opacity = (1 - (valueInPage.abs() * 0.7)).clamp(0.0, 1.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Spacer for Track/Thumb area
            SizedBox(height: 35.h),
            // Ticks (Optional, helps visual continuity)
            Container(
              width: 1.w,
              height: 5.h,
              color: AppColors.bluegray.withOpacity(0.9),
            ),
            SizedBox(height: 10.h),
            Opacity(
              opacity: opacity,
              child: Text(
                "${value.toStringAsFixed(1)}L",
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFixedThumb() {
    return Container(
      width: 26.w,
      height: 26.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0XFF9AE9FF), Color(0XFF005D84)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        // border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
