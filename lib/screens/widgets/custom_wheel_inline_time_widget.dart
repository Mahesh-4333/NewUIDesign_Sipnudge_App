import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class InlineTimePicker extends StatefulWidget {
  final ValueChanged<TimeOfDay> onChanged;
  final TimeOfDay? timeOfDay;

  const InlineTimePicker({super.key, required this.onChanged, this.timeOfDay});

  @override
  State<InlineTimePicker> createState() => _InlineTimePickerState();
}

class _InlineTimePickerState extends State<InlineTimePicker> {
  final hourCtrl = FixedExtentScrollController(initialItem: 6);
  final minuteCtrl = FixedExtentScrollController(initialItem: 30);
  final amPmCtrl = FixedExtentScrollController(initialItem: 0);

  int hourIndex = 6;
  int minuteIndex = 30;
  int amPmIndex = 0;

  int hour = 7;
  int minute = 30;
  bool isAm = true;

  @override
  void initState() {
    super.initState();

    if (widget.timeOfDay != null) {
      final t = widget.timeOfDay!;

      // Convert to 12-hour format
      isAm = t.hour < 12;

      hour = t.hour % 12;
      if (hour == 0) hour = 12;

      minute = t.minute;

      // Calculate wheel indexes
      hourIndex = hour - 1;
      minuteIndex = minute;
      amPmIndex = isAm ? 0 : 1;

      // IMPORTANT: jump wheels after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        hourCtrl.jumpToItem(hourIndex);
        minuteCtrl.jumpToItem(minuteIndex);
        amPmCtrl.jumpToItem(amPmIndex);
      });
    }
  }

  void _emit() {
    final h = isAm
        ? (hour == 12 ? 0 : hour)
        : (hour == 12 ? 12 : hour + 12);

    widget.onChanged(TimeOfDay(hour: h, minute: minute));
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selectedIndex,
    required String Function(int) label,
    required void Function(int) onSelected,
    double width = 40,
    bool isAmPm = false
  }) {
    return SizedBox(
      width: width,
      height: 120,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 36,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (_, index) {
            final isSelected = index == selectedIndex;

            return Center(
              child: Text(
                label(index),
                style: TextStyle(
                  fontSize: isAmPm ? AppFontStyles.fontSize_18 :  AppFontStyles.fontSize_28,
                  fontVariations: [isSelected ? AppFontStyles.boldFontVariation : AppFontStyles.boldFontVariation],
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: isSelected
                      ? const Color(0xFF3FB7FF)
                      : AppColors.greyColorText1,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Selection indicator
        Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _wheel(
              controller: hourCtrl,
              count: 12,
              selectedIndex: hourIndex,
              label: (i) => (i + 1).toString().padLeft(2, '0'),
              onSelected: (i) {
                setState(() {
                  hourIndex = i;
                  hour = i + 1;
                });
                _emit();
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            _wheel(
              controller: minuteCtrl,
              count: 60,
              selectedIndex: minuteIndex,
              label: (i) => i.toString().padLeft(2, '0'),
              onSelected: (i) {
                setState(() {
                  minuteIndex = i;
                  minute = i;
                });
                _emit();
              },
            ),

            _wheel(
              controller: amPmCtrl,
              count: 2,
              width: 50,
              selectedIndex: amPmIndex,
              label: (i) => i == 0 ? 'AM' : 'PM',
              onSelected: (i) {
                setState(() {
                  amPmIndex = i;
                  isAm = i == 0;
                });
                _emit();
              },
              isAmPm: true
            ),
          ],

        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Column(
              children: [
                // 🔝 Top Shadow
                Container(
                  height: AppDimensions.dim50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // 🔻 Bottom Shadow
                Container(
                  height: AppDimensions.dim50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
