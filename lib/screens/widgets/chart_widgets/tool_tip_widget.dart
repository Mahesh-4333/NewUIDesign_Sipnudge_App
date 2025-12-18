import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CustomChartToolTip extends StatelessWidget {
  const CustomChartToolTip(
      {super.key, required this.percent, this.isPercent = true});

  final num percent;
  final bool isPercent;
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            child: SvgPicture.asset(
              "assets/images/tooltip.svg",
              width: AppDimensions.dim55.w,
              height: AppDimensions.dim55.h,
            ),
          ),
          Positioned(
            bottom: 24.h,
            child: Text(
              "$percent${isPercent ? "%" : "L"}",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: AppFontStyles.fontSize_10,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
