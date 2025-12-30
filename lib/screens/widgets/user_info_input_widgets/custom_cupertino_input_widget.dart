// file: custom_cupertino_input_widget.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/cupertino_bottom_sheet.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_toggle_button_widget.dart';

class CustomCupertinoInputWidget extends StatefulWidget {
  final String title;
  final String placeholderText;
  final String leftToggleLabel;
  final String rightToggleLabel;
  final String defaultToggleValue;

  // cm primary values
  final int primaryInitialValue;
  final int primaryMinValue;
  final int primaryMaxValue;

  // optional ft primary values (when toggle = ft)
  final int? primaryInitialFt;
  final int? primaryMinFt;
  final int? primaryMaxFt;

  // secondary picker (inches)
  final int? secondaryInitialValue;
  final int? secondaryMinValue;
  final int? secondaryMaxValue;

  final String? suffix;
  final String? secondarySuffix;
  final bool hasSecondaryValue; // legacy/default
  final bool unitSelectionRequired;
  final String? selectedValue;
  final Function(Map<String, dynamic>) onValueSelected;
  final Function(String) onUnitChanged;

  const CustomCupertinoInputWidget({
    super.key,
    required this.title,
    required this.placeholderText,
    required this.leftToggleLabel,
    required this.rightToggleLabel,
    required this.defaultToggleValue,
    required this.primaryInitialValue,
    required this.primaryMinValue,
    required this.primaryMaxValue,
    this.primaryInitialFt,
    this.primaryMinFt,
    this.primaryMaxFt,
    this.secondaryInitialValue,
    this.secondaryMinValue,
    this.secondaryMaxValue,
    this.suffix,
    this.selectedValue,
    this.secondarySuffix,
    this.hasSecondaryValue = false,
    required this.onValueSelected,
    required this.onUnitChanged,
    this.unitSelectionRequired = true,
  });

  @override
  State<CustomCupertinoInputWidget> createState() =>
      _CustomCupertinoInputWidgetState();
}

class _CustomCupertinoInputWidgetState
    extends State<CustomCupertinoInputWidget> {
  late String selectedUnit;
  String? selectedValueText;

  @override
  void initState() {
    super.initState();
    selectedUnit = widget.defaultToggleValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final bool isFt = selectedUnit == "ft";
              final int initialValueToUse = isFt
                  ? (widget.primaryInitialFt ?? widget.primaryInitialValue)
                  : widget.primaryInitialValue;
              final int minValueToUse = isFt
                  ? (widget.primaryMinFt ?? widget.primaryMinValue)
                  : widget.primaryMinValue;
              final int maxValueToUse = isFt
                  ? (widget.primaryMaxFt ?? widget.primaryMaxValue)
                  : widget.primaryMaxValue;

              final bool hasSecondaryToUse = isFt;
              final int secondaryInitial = widget.secondaryInitialValue ?? 0;
              final int secondaryMin = widget.secondaryMinValue ?? 0;
              final int secondaryMax = widget.secondaryMaxValue ?? 11;
              final String? suffixToUse =
                  (!isFt && widget.unitSelectionRequired)
                      ? (widget.suffix ??
                          (selectedUnit.isNotEmpty ? selectedUnit : null))
                      : null;
              final String? secondarySuffixToUse = isFt
                  ? (widget.secondarySuffix ?? 'in')
                  : widget.secondarySuffix;

              final result = await showCupertinoPickerBottomSheet(
                context: context,
                title: widget.title,
                hasSecondaryValue: hasSecondaryToUse,
                secondaryInitialValue: secondaryInitial,
                secondaryMaxValue: secondaryMax,
                secondaryMinValue: secondaryMin,
                initialValue: initialValueToUse,
                minValue: minValueToUse,
                maxValue: maxValueToUse,
                suffix: suffixToUse,
                secondarySuffix: secondarySuffixToUse,
              );

              if (result != null) {
                // Normalize result so onValueSelected gets an explicit suffix
                final normalized = Map<String, dynamic>.from(result);
                normalized['suffix'] =
                    isFt ? 'ft' : (normalized['suffix'] ?? 'cm');

                // Update local display string immediately (but widget.selectedValue from Bloc is authoritative)
                setState(() {
                  if (isFt) {
                    final int feet =
                        normalized['primaryValue'] ?? initialValueToUse;
                    final int inches = normalized['secondaryValue'] ?? 0;
                    selectedValueText = "$feet' $inches\"";
                  } else {
                    final int cm =
                        normalized['primaryValue'] ?? initialValueToUse;
                    final String s = normalized['suffix'] ?? 'cm';
                    selectedValueText = "$cm $s".trim();
                  }
                });

                widget.onValueSelected(normalized);
              }
            },
            child: Container(
              padding: EdgeInsets.all(
                AppDimensions.dim12.w,
              ),
              decoration: BoxDecoration(
                color: Color(0xffffffff),
                //color: AppColors.customRadioUnselectedFillColor,
                border: Border.all(
                  color: AppColors.lightgray,
                  width: AppDimensions.dim1,
                ),
                borderRadius: BorderRadius.circular(
                  AppDimensions.radius_25,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: AppDimensions.dim4,
                    color: Colors.black.withOpacity(.4),
                    offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
                  )
                ],
              ),
              child: Text(
                (widget.selectedValue != null &&
                        widget.selectedValue!.isNotEmpty)
                    ? widget.selectedValue!
                    : widget.placeholderText,
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_16,
                  fontVariations: [AppFontStyles.regularFontVariation],
                  color: (widget.selectedValue != null &&
                          widget.selectedValue!.isNotEmpty)
                      ? AppColors.black
                      : Color(0xCCCFCFCF),
                ),
              ),
            ),
          ),
        ),
        widget.unitSelectionRequired
            ? SizedBox(
                width: AppDimensions.dim16.w,
              )
            : SizedBox.shrink(),
        widget.unitSelectionRequired
            ? CustomToggleButtonWidget(
                toggleType: 2,
                leftLabel: widget.leftToggleLabel,
                rightLabel: widget.rightToggleLabel,
                initialValue: widget.defaultToggleValue,
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value;

                    selectedValueText = null;
                  });
                  widget.onUnitChanged(value);
                },
              )
            : SizedBox.shrink(),
      ],
    );
  }
}

String getSuffixForUnit(String unit) {
  switch (unit) {
    case "in":
    case "cm":
      return unit;
    case "kg":
      return "kg";
    case "lbs":
      return "lbs";
    default:
      return "";
  }
}
