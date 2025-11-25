import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

import 'package:flutter/services.dart';

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
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    // _value = widget.tickValues.contains(widget.initialValue)
    //     ? widget.initialValue
    //     : widget.tickValues.first;
  }

  void _snapToClosest(double val) {
    final closest = widget.tickValues.reduce(
      (a, b) => (val - a).abs() < (val - b).abs() ? a : b,
    );
    setState(() => _value = closest);
    widget.onChanged?.call(closest);
    HapticFeedback.mediumImpact(); // vibrate on snap
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.tickValues.first;
    final max = widget.tickValues.last;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            tickMarkShape: CustomTickMarkShape(),
            showValueIndicator: ShowValueIndicator.onlyForContinuous,
            trackHeight: AppDimensions.dim8.h,
            thumbShape: CustomThumbShape(),
            trackShape: GradientTrackShape(),
            overlayColor: Colors.transparent,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
          ),
          child: Slider(
            value: _value,
            label: "",
            min: min,
            max: max,
            divisions: widget.tickValues.length - 1,
            onChanged: (newValue) {
              setState(() => _value = newValue);
            },
            onChangeEnd: _snapToClosest,
          ),
        ),
        SizedBox(height: AppDimensions.dim12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.tickValues.map((val) {
            return Text(
              '${val.toStringAsFixed(1)}L',
              style: TextStyle(
                color: AppColors.black40,
                fontSize: AppFontStyles.fontSize_14,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
                // shadows: [
                //   Shadow(
                //     blurRadius: AppDimensions.dim5,
                //     color: AppColors.black.withOpacity(.25),
                //     offset: Offset(0, AppDimensions.dim4),
                //   )
                // ],
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}

class CustomThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0XFF9AE9FF), Color(0XFF005D84)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: 12,
        ),
      );

    final Paint borderPaint = Paint()
      ..color = AppColors.greywith80
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    context.canvas.drawCircle(
        center.translate(0, 1.5), 14, Paint()..color = Colors.black26);
    context.canvas.drawCircle(center, 12, paint);
    context.canvas.drawCircle(center, 12, borderPaint);
  }
}

class GradientTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? AppDimensions.dim8.h;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;

    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

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
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0XFF9AE9FF),
          Color(0XFF005D84),
        ],
      ).createShader(
        Rect.fromLTWH(
          trackRect.left,
          trackRect.top,
          thumbCenter.dx - trackRect.left,
          trackRect.height,
        ),
      );

    final Paint inactivePaint = Paint()..color = Color(0XFFFFFFFF);

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    final Path trackPath = Path()
      ..addRRect(RRect.fromRectAndRadius(trackRect, trackRadius));

    context.canvas.drawShadow(trackPath, Colors.black, 4, true);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
            trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom),
        trackRadius,
      ),
      activePaint,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
            thumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom),
        trackRadius,
      ),
      inactivePaint,
    );
    // ⬅️ ADD BORDER AROUND WHOLE TRACK
    final Paint borderPaint = Paint()
      ..color = AppColors.greywith80
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      borderPaint,
    );
  }
}

class CustomTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({
    required bool isEnabled,
    required SliderThemeData sliderTheme,
  }) {
    return const Size(2, 8);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required bool isEnabled,
    required TextDirection textDirection,
  }) {
    final paint = Paint()
      ..color = sliderTheme.activeTickMarkColor ?? Colors.white
      ..strokeWidth = 2;

    context.canvas.drawLine(
      Offset(center.dx, center.dy - 4),
      Offset(center.dx, center.dy + 4),
      paint,
    );
  }
}
