import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/cupertino_bottom_sheet.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_toggle_button_widget.dart';

class CustomTimeInputWidget extends StatefulWidget {
  const CustomTimeInputWidget({
    super.key,
    required this.isBedtime,
    this.selectedHours,
    this.selectedMins,
  });

  final bool isBedtime;
  final int? selectedMins;
  final int? selectedHours;

  @override
  State<CustomTimeInputWidget> createState() => _CustomTimeInputWidgetState();
}

class _CustomTimeInputWidgetState extends State<CustomTimeInputWidget> {
  int selectedHour = 1;
  int selectedMinute = 0;

  Future<void> _pickTime() async {
    // Call the sheet once and request both pickers together
    final result = await showCupertinoPickerBottomSheet(
      context: context,
      title: 'Select Time',
      initialValue: selectedHour,
      minValue: 1,
      maxValue: 12,
      suffix: 'hrs',

      // enable the secondary (minutes) picker
      hasSecondaryValue: true,
      secondaryInitialValue: selectedMinute,
      secondaryMinValue: 0,
      secondaryMaxValue: 59,
      secondarySuffix: 'min',
    );

    // If user pressed Done and returned a map, update hour+minute together
    if (result != null && result.isNotEmpty) {
      // The sheet returns keys 'primaryValue' and 'secondaryValue'
      final returnedHour = result['primaryValue'] as int?;
      final returnedMinute = result['secondaryValue'] as int?;

      if (returnedHour != null) selectedHour = returnedHour;
      if (returnedMinute != null) selectedMinute = returnedMinute;

      if (widget.isBedtime == false) {
        context
            .read<UserInfoCubit>()
            .updateWakeupTime(hour: selectedHour, minute: selectedMinute);
      } else {
        context
            .read<UserInfoCubit>()
            .updateBedTime(hour: selectedHour, minute: selectedMinute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hourText = widget.selectedHours != null
        ? widget.selectedHours!.toString().padLeft(2, '0')
        : "--";
    final minText = widget.selectedMins != null
        ? widget.selectedMins!.toString().padLeft(2, '0')
        : "--";

    return Row(
      children: [
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            width: (AppDimensions.dim133.w * 2) +
                AppDimensions.dim12.w, // combine both widths + spacing
            height: AppDimensions.dim48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radius_15),
              border: Border.all(
                color: AppColors.greywith80,
                width: AppDimensions.dim1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              "$hourText : $minText",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_20,
                fontVariations: [AppFontStyles.fontWeightVariation600],
                color: const Color(0xFF5B6E7E),
              ),
            ),
          ),
        ),
        Spacer(),
        CustomToggleButtonWidget(
          leftLabel: "AM",
          rightLabel: "PM",
          toggleType: 2,
          initialValue: widget.isBedtime ? "PM" : "AM",
          onChanged: (value) {
            if (widget.isBedtime) {
              context.read<UserInfoCubit>().updateBedTime(period: value);
            } else {
              context.read<UserInfoCubit>().updateWakeupTime(period: value);
            }
          },
        ),
      ],
    );
  }
}

//=== IGNORE BELOW THIS LINE ===

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'dart:async';

// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/cubit/user_info/user_info_cubit.dart';

// import 'package:hydrify/helpers/cupertino_bottom_sheet.dart';
// import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_toggle_button_widget.dart';

// class CustomTimeInputWidget extends StatefulWidget {
//   const CustomTimeInputWidget(
//       {super.key,
//       required this.isBedtime,
//       this.selectedHours,
//       this.selectedMins});

//   final bool isBedtime;
//   final int? selectedMins;
//   final int? selectedHours;
//   @override
//   State<CustomTimeInputWidget> createState() => _CustomTimeInputWidgetState();
// }

// class _CustomTimeInputWidgetState extends State<CustomTimeInputWidget> {
//   int selectedHour = 1;
//   int selectedMinute = 0;

//   Future<void> _pickHour() async {
//     final result = await showCupertinoPickerBottomSheet(
//       context: context,
//       title: 'Select Hour',
//       initialValue: selectedHour,
//       minValue: 1,
//       maxValue: 12,
//       suffix: 'hrs',
//     );

//     if (result?.isNotEmpty == true) {
//       selectedHour = result?['primaryValue'];
//       if (widget.isBedtime == false) {
//         context.read<UserInfoCubit>().updateWakeupTime(
//               hour: selectedHour,
//             );
//       } else {
//         context.read<UserInfoCubit>().updateBedTime(
//               hour: selectedHour,
//             );
//       }
//     }
//   }

//   Future<void> _pickMinute() async {
//     final result = await showCupertinoPickerBottomSheet(
//       context: context,
//       title: 'Select Minutes',
//       initialValue: selectedMinute,
//       minValue: 0,
//       maxValue: 59,
//       suffix: 'min',
//     );

//     if (result?.isNotEmpty == true) {
//       selectedMinute = result?['primaryValue'];
//       if (widget.isBedtime == false) {
//         context.read<UserInfoCubit>().updateWakeupTime(
//               minute: selectedMinute,
//             );
//       } else {
//         context.read<UserInfoCubit>().updateBedTime(
//               minute: selectedMinute,
//             );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         GestureDetector(
//           onTap: _pickHour,
//           child: Container(
//             width: AppDimensions.dim133.w,
//             height: AppDimensions.dim48.h,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: AppColors.customRadioUnselectedFillColor,
//               border: Border.all(
//                 color: AppColors.unSelectedPurpleToggle,
//                 width: AppDimensions.dim1,
//               ),
//               borderRadius: BorderRadius.circular(
//                 AppDimensions.radius_15,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   blurRadius: AppDimensions.dim4,
//                   color: Colors.black.withOpacity(.4),
//                   offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
//                 )
//               ],
//             ),
//             child: Text(
//               widget.selectedHours == null
//                   ? "Hrs"
//                   : widget.selectedHours.toString(),
//               style: TextStyle(
//                 fontFamily: AppFontStyles.urbanistFontFamily,
//                 fontSize: AppFontStyles.fontSize_16,
//                 fontVariations: [AppFontStyles.regularFontVariation],
//                 color: widget.selectedHours != null
//                     ? AppColors.white
//                     : Colors.white.withOpacity(.5),
//               ),
//             ),
//           ),
//         ),
//         SizedBox(
//           width: AppDimensions.dim12.w,
//         ),
//         Text(
//           ":",
//           style: TextStyle(
//             fontSize: AppFontStyles.fontSize_24,
//             fontVariations: [AppFontStyles.fontWeightVariation600],
//             color: Colors.white.withOpacity(.5),
//           ),
//         ),
//         SizedBox(
//           width: AppDimensions.dim12.w,
//         ),
//         GestureDetector(
//           onTap: _pickMinute,
//           child: Container(
//             width: AppDimensions.dim133.w,
//             height: AppDimensions.dim48.h,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: AppColors.customRadioUnselectedFillColor,
//               border: Border.all(
//                 color: AppColors.unSelectedPurpleToggle,
//                 width: AppDimensions.dim1,
//               ),
//               borderRadius: BorderRadius.circular(
//                 AppDimensions.radius_15,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   blurRadius: AppDimensions.dim4,
//                   color: Colors.black.withOpacity(.4),
//                   offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
//                 )
//               ],
//             ),
//             child: Text(
//               widget.selectedMins == null
//                   ? "Mins"
//                   : widget.selectedMins.toString(),
//               style: TextStyle(
//                 fontFamily: AppFontStyles.urbanistFontFamily,
//                 fontSize: AppFontStyles.fontSize_16,
//                 fontVariations: [AppFontStyles.regularFontVariation],
//                 color: widget.selectedHours != null
//                     ? AppColors.white
//                     : Colors.white.withOpacity(.5),
//               ),
//             ),
//           ),
//         ),
//         Spacer(),
//         CustomToggleButtonWidget(
//           leftLabel: "AM",
//           rightLabel: "PM",
//           toggleType: 2,
//           initialValue: widget.isBedtime ? "PM" : "AM",
//           // ? context.read<UserInfoCubit>().state.bedtimePeriod ?? "PM"
//           // : context.read<UserInfoCubit>().state.wakeupPeriod ?? "PM",
//           onChanged: (value) {
//             if (widget.isBedtime) {
//               context.read<UserInfoCubit>().updateBedTime(period: value);
//             } else {
//               context.read<UserInfoCubit>().updateWakeupTime(period: value);
//             }
//           },
//         )
//       ],
//     );
//   }
// }
