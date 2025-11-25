import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim20.w, vertical: AppDimensions.dim8.h),
      margin: EdgeInsets.only(bottom: AppDimensions.dim10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radius_40.r),

        // 🔵 Selected border
        border: Border.all(
          color: AppColors.greywith80,
          width: 1.w,
        ),

        // ☁ Soft shadow like mockup
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.25),
            blurRadius: 4.r,
            offset: Offset(2.r, 2.r),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_20.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.fontWeightVariation600],
            ),
          ),
          SwitchTheme(
            data: SwitchThemeData(
              thumbColor: WidgetStateProperty.all(AppColors.white),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.lightBlue400;
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
      ),
    );
  }
}

//========================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_font_styles.dart';

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
//             color: AppColors.white,
//             fontSize: AppFontStyles.fontSize_18.sp,
//             fontFamily: AppFontStyles.urbanistFontFamily,
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: Colors.white,
//           activeTrackColor: AppColors.purpleHeart,
//           inactiveThumbColor: AppColors.whitewithopacity90,
//           inactiveTrackColor: Colors.transparent,
//         ),
//       ],
//     );
//   }
// }

//========================================================================
