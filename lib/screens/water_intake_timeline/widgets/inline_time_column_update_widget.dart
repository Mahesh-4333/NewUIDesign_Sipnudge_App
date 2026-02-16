import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/widgets/custom_wheel_inline_time_widget.dart';

class InlineTimeColumnUpdateWidget extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool isEndTime;
  final Function onTimeChanged;
  const InlineTimeColumnUpdateWidget({super.key, required this.label, required this.onTimeChanged, required this.time, this.isEndTime = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.greyColorText1,
                fontSize: AppFontStyles.fontSize_12,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation]),),
        // Simplified time display as in screenshot
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.9,
              child: SizedBox(
                child: InlineTimePicker(onChanged: (newTime) {
                  onTimeChanged(DateTime(
                    0,
                    0,
                    0,
                    newTime.hour,
                    newTime.minute,
                  ));
                }, timeOfDay: time,),
              ),
            )
          ],
        ),
      ],
    );
  }
}
