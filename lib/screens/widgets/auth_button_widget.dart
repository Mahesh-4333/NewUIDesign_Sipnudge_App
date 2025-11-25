import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class AuthButton extends StatelessWidget {
  final String? iconPath;
  final String text;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;
  final bool areTwoItems;

  const AuthButton(
      {super.key,
      this.iconPath,
      required this.text,
      required this.color,
      required this.onTap,
      this.textColor = AppColors.white,
      this.areTwoItems = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppDimensions.defaultPadding),
        width: AppDimensions.dim382.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radius_40),
          border: Border.all(
            color: AppColors.silvergray,
            width: AppDimensions.dim1,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_5,
              color: Colors.black.withOpacity(.25),
              offset: Offset(AppDimensions.dim2, AppDimensions.dim2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment:
              areTwoItems ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            if (iconPath != null) ...[
              SizedBox(
                width: AppDimensions.dim24.w,
                height: AppDimensions.dim24.h,
                child: SvgPicture.asset(
                  iconPath!,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: AppDimensions.dim78.w),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: iconPath != null ? Colors.black : textColor,
                fontSize: AppFontStyles.fontSize_16.sp,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
