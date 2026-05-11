import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CapsuleBarPainter extends CustomPainter {
  final double fgValue;
  final double bgValue;
  final double maxValue;
  final Color foregroundColor;
  final Color backgroundColor;

  CapsuleBarPainter({
    required this.fgValue,
    required this.bgValue,
    required this.maxValue,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(size.width / 2);

    // Calculate heights relative to maxValue
    double bgHeight = (bgValue / maxValue) * size.height;
    double fgHeight = (fgValue / maxValue) * size.height;

    // 1. Draw Background Bar (Dark Blue)
    paint.color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, size.height - bgHeight, size.width, bgHeight),
        topLeft: radius,
        topRight: radius,
      ),
      paint,
    );

    // 2. Draw Foreground Bar (Light Blue)
    paint.color = foregroundColor;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, size.height - fgHeight, size.width, fgHeight),
        topLeft: radius,
        topRight: radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CapsuleBarPainter oldDelegate) => true;
}

class CustomStackedBarChart extends StatefulWidget {
  final List<ChartData> data;
  final double chartHeight;
  final double barWidth;
  final double maxValue;

  const CustomStackedBarChart({
    super.key,
    required this.data,
    this.chartHeight = 200,
    this.barWidth = 50,
    this.maxValue = 100, // Assuming your data is 0-100
  });

  @override
  State<CustomStackedBarChart> createState() => _CustomStackedBarChartState();
}

class _CustomStackedBarChartState extends State<CustomStackedBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.data.length, (index) {
        final item = widget.data[index];
        final isSelected = _selectedIndex == index;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedIndex == index) {
                        _selectedIndex = null;
                      } else {
                        _selectedIndex = index;
                      }
                    });
                  },
                  child: CustomPaint(
                    size: Size(widget.barWidth, widget.chartHeight),
                    painter: CapsuleBarPainter(
                      fgValue: item.foregroundValue,
                      bgValue: item.backgroundValue,
                      maxValue: widget.maxValue,
                      backgroundColor: const Color(0xFF4A90F5),
                      foregroundColor: const Color(0xFFA6CCF8),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -15.h,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.bluegray,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "${item.backgroundValue}L",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              style: TextStyle(
                color: AppColors.color_4C6C9A,
                fontSize: AppFontStyles.fontSize_10,
                fontFamily: AppFontStyles.lexendFontFamily,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class ChartData {
  final double foregroundValue; // The "inner" bar value
  final double backgroundValue; // The "outer" bar value
  final String label;

  ChartData({
    required this.foregroundValue,
    required this.backgroundValue,
    required this.label,
  });
}
