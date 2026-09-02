import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/widgets/custom_anim_toggle.dart';

class SegmentedChoiceTile extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selectedOption;
  final Color activeColor;
  final void Function(String) onSelected;
  final bool hasSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  const SegmentedChoiceTile({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.activeColor,
    required this.onSelected,
    this.hasSwitch = false,
    this.switchValue = true,
    this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: AppColors.bluegray,
                  ),
                ),
              ),
              if (hasSwitch)
                AnimatedToggle(
                  value: switchValue,
                  onChanged: (val) {
                    onSwitchChanged?.call(val);
                  },
                ),
            ],
          ),
          SizedBox(height: 12.h),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasSwitch && !switchValue ? 0.35 : 1.0,
            child: IgnorePointer(
              ignoring: hasSwitch && !switchValue,
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Row(
                  children: options.map((option) {
                    final isSelected =
                        option == selectedOption && (!hasSwitch || switchValue);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onSelected(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(50.r),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: activeColor.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

