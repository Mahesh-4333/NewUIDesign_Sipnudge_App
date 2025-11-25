import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/reminder%20time&mode/reminder_time_interval_cubit.dart';
import 'package:hydrify/cubit/reminder%20time&mode/reminder_time_interval_state.dart';

class IntervalBottomSheet extends StatelessWidget {
  const IntervalBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimeIntervalCubit(),
      child: GestureDetector(
        onTap: () {
          // Prevent closing on tapping anywhere inside the sheet
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            color: Colors.black.withOpacity(0.5), // Background overlay
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  bottom: 30.h,
                  top: 10.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB586BE), Color(0xFF131313)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context), // Pass context here
                    _buildContent(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      //padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.only(
        left: AppDimensions.dim20.w,
        top: AppDimensions.dim20.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.reminderTime,
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                FontVariation(
                  'wght',
                  AppFontStyles.fontWeightVariation600.value,
                ),
              ],
              color: AppColors.white,
              fontSize: AppFontStyles.fontSize_24.sp,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context); // Now context is available here
            },
            icon: Icon(
              Icons.close,
              color: AppColors.white,
              size: AppFontStyles.fontSize_22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      //padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.only(
        left: AppDimensions.dim20.w,
        top: AppDimensions.dim20.h,
        bottom: AppDimensions.dim5.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left side: label
          Text(
            'Select Sip Interval',
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                FontVariation(
                  'wght',
                  AppFontStyles.fontWeightVariation600.value,
                ),
              ],

              color: AppColors.white,
              fontSize: AppFontStyles.fontSize_20.sp, // responsive font size
            ),
          ),

          /// Right side: button + icon
          BlocBuilder<TimeIntervalCubit, TimeIntervalState>(
            builder: (context, state) {
              String interval = '';
              if (state is TimeIntervalUpdated) {
                interval = state.interval;
              } else if (state is TimeIntervalInitial) {
                interval = state.interval;
              }

              return Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<TimeIntervalCubit>().updateInterval();
                    },
                    child: Container(
                      width: AppDimensions
                          .dim100.w, // fixed width, adjust as needed
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.dim6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenwhite20.withOpacity(.22),
                        border: Border.all(
                          color: AppColors.white,
                          width: AppDimensions.dim1.w,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radius_100.r,
                        ),
                      ),
                      alignment: Alignment.center, // center the text
                      child: Text(
                        interval,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            FontVariation(
                              'wght',
                              AppFontStyles.fontWeightVariation600.value,
                            ),
                          ],
                          color: AppColors.white,
                          fontSize: AppFontStyles.fontSize_16.sp,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: AppDimensions.dim10.w), // responsive gap
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.arrow_forward_ios,
                  //     color: AppColors.white,
                  //     size:
                  //         AppFontStyles.fontSize_18.sp, // responsive icon size
                  //   ),
                  //   onPressed: () {
                  //     showModalBottomSheet(
                  //       context: context,
                  //       isScrollControlled: true,
                  //       backgroundColor: Colors.transparent,
                  //       builder: (_) => BlocProvider.value(
                  //         value: context.read<
                  //             ReminderIntervalCubit>(), // reuse existing cubit
                  //         child: ReminderBottomSheet(
                  //           aiReminder:
                  //               true, // pass true/false depending on your logic
                  //           onSave: (selectedTimes) {
                  //             // Handle the selected reminder times here
                  //             debugPrint("Selected times: $selectedTimes");
                  //           },
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
