import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CustomNextButton extends StatelessWidget {
  const CustomNextButton(
      {super.key, required this.onNextPressed, required this.text});

  final String text;
  final Function onNextPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onNextPressed(),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          AppColors.lightBlue400,
        ),
        fixedSize: WidgetStatePropertyAll(
          Size(
            AppDimensions.dim400.w,
            AppDimensions.dim56.h,
          ),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.white,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.fontSize_16,
            fontVariations: [
              AppFontStyles.fontWeightVariation600,
            ],
          ),
        ),
      ),
    );
  }
}
