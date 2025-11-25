// import 'package:flutter/material.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// //import 'package:flutter_screenutil/flutter_screenutil.dart';

// class ToggleTile extends StatelessWidget {
//   final String title;
//   final bool value;
//   final Function(bool) onChanged;

//   const ToggleTile({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             //color: const Color(0xFFFFFFFF),
//             color: AppColors.white,
//             fontSize: AppFontStyles.fontSize_18,
//             fontFamily: AppFontStyles.urbanistFontFamily,
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: AppColors.white,
//           activeTrackColor: AppColors.gradientStart,
//           inactiveThumbColor: AppColors.white,
//           inactiveTrackColor: AppColors.whitewithopacity90,
//           materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         ),
//       ],
//     );
//   }
// }

//========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
//import 'package:flutter_screenutil/flutter_screenutil.dart';

class ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const ToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            //color: const Color(0xFFFFFFFF),
            color: AppColors.white,
            fontSize: AppFontStyles.fontSize_20.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              FontVariation('wght', AppFontStyles.fontWeightVariation600.value),
            ],
          ),
        ),
        SwitchTheme(
          data: SwitchThemeData(
            thumbColor: WidgetStateProperty.all(AppColors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.violetBlue;
              }
              return AppColors.tuna;
            }),
            trackOutlineColor: WidgetStateProperty.all(
              Colors.white,
            ), // 👈 White border
            trackOutlineWidth: WidgetStateProperty.all(
              1.5,
            ), // 👈 Border thickness
            splashRadius: 0,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}
