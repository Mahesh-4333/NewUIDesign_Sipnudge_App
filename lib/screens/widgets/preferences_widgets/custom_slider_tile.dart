import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CustomSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final String suffix;
  final bool hideRightText;
  final EdgeInsets? sliderPadding;
  final List<Color>? gradientColors;
  final Color? thumbColor;

  const CustomSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.suffix = "%",
    this.sliderPadding,
    this.hideRightText = false,
    this.gradientColors,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: 17.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!hideRightText)
                Padding(
                  padding: EdgeInsets.only(right: 25.w),
                  child: Text(
                    "${(value * 100).toInt()}$suffix",
                    style: TextStyle(
                      color: const Color(
                          0xFF00B0FF), // Bright blue from screenshot
                      fontSize: 15.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: sliderPadding ?? EdgeInsets.zero,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 11.h,
                padding: EdgeInsets.zero,
                activeTrackColor: gradientColors != null
                    ? Colors.transparent
                    : const Color(0xFF00B0FF),
                inactiveTrackColor: AppColors.gray400,
                thumbColor: thumbColor ?? AppColors.white,
                overlayColor:
                    (thumbColor ?? const Color(0xFF00B0FF)).withOpacity(0.2),
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 10.r,
                  elevation: 4,
                  pressedElevation: 6,
                ),
                trackShape: gradientColors != null
                    ? GradientSliderTrackShape(
                        gradient: LinearGradient(colors: gradientColors!))
                    : const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientSliderTrackShape extends RoundedRectSliderTrackShape {
  final LinearGradient gradient;

  const GradientSliderTrackShape({required this.gradient});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 0,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final activeGradientRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    // Paint for inactive track
    final Paint inactivePaint = Paint()
      ..color = isEnabled
          ? (sliderTheme.inactiveTrackColor ?? Colors.grey)
          : (sliderTheme.disabledInactiveTrackColor ??
              Colors.grey.withOpacity(0.5));

    // Paint for active track (Gradient)
    // We use the full trackRect for the shader to keep the gradient "fixed"
    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect);

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    // Draw inactive track
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      inactivePaint,
    );

    // Draw active track
    if (thumbCenter.dx > trackRect.left) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(activeGradientRect, trackRadius),
        activePaint,
      );
    }
  }
}
