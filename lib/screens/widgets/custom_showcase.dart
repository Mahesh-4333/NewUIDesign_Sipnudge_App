import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CustomShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final String buttonText;
  final ShapeBorder? targetShapeBorder;
  final BorderRadius? targetBorderRadius;
  final EdgeInsets? targetPadding;
  final double? overlayScale;
  final Color? overlayColor;
  final double? overlayOpacity;
  final double? blurValue;
  final double? overlayFadeWidth;

  const CustomShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.buttonText = 'Next',
    this.targetShapeBorder,
    this.targetBorderRadius,
    this.targetPadding,
    this.overlayScale = 0.4,
    this.overlayColor = AppColors.black40,
    this.overlayOpacity = 0.2,
    this.blurValue = 0.0,
    this.overlayFadeWidth = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      showArrow: true,
      overlayScale: overlayScale,
      overlayFadeWidth: overlayFadeWidth,
      overlayColor: overlayColor ?? Colors.black,
      overlayOpacity: overlayOpacity ?? 0.25,
      blurValue: blurValue ?? 5.0,
      tooltipBorder: Border.all(
        color: AppColors.bluegray.withOpacity(0.12),
        width: 1.5,
      ),
      tooltipBackgroundImage: const DecorationImage(
        image: AssetImage('assets/images/app_background.png'),
        fit: BoxFit.cover,
      ),
      targetShapeBorder: targetShapeBorder ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
      targetBorderRadius: targetShapeBorder != null
          ? null
          : (targetBorderRadius ?? BorderRadius.circular(8.r)),
      targetPadding: targetPadding ?? EdgeInsets.all(12.r),
      tooltipBackgroundColor: Colors.white,
      tooltipBorderRadius: BorderRadius.circular(16.r),
      tooltipPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      titleTextStyle: TextStyle(
        fontFamily: AppFontStyles.urbanistFontFamily,
        color: AppColors.bluegray,
        fontSize: AppFontStyles.fontSize_12 * 1.05,
        fontVariations: [
          AppFontStyles.extraBoldFontVariation,
        ],
      ),
      descTextStyle: TextStyle(
        fontFamily: AppFontStyles.urbanistFontFamily,
        color: AppColors.bluegray.withOpacity(0.8),
        fontSize: AppFontStyles.fontSize_14,
        fontVariations: [
          AppFontStyles.boldFontVariation,
        ],
      ),
      tooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: buttonText,
          backgroundColor: AppColors.bluegray.withOpacity(0.1),
          textStyle: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_12 * 1.05,
            fontVariations: [
              AppFontStyles.extraBoldFontVariation,
            ],
          ),
          onTap: () {
            if (context.mounted) {
              ShowCaseWidget.of(context).next();
            }
          },
        ),
      ],
      tooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        position: TooltipActionPosition.inside,
        gapBetweenContentAndAction: 10,
      ),
      child: child,
    );
  }
}
