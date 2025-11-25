import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:intl/intl.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CurrentSlotStatsWidget extends StatelessWidget {
  final String slotName;
  final VoidCallback? onTap;

  const CurrentSlotStatsWidget({
    super.key,
    required this.slotName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottleDataCubit, BottleDataState>(
      buildWhen: (previous, current) =>
          previous.volumePercent != current.volumePercent,
      builder: (context, state) {
        return FutureBuilder(
          future: () {
            DateTime now = DateTime.now();
            DateTime startDate = DateTime(now.year, now.month, now.day);
            DateTime endDate = startDate
                .add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1));

            return context
                .read<BottleDataCubit>()
                .getHistoryForDateRange(startDate, endDate);
          }(),
          builder: (context, snapshot) {
            double waterVolumeConsumed = 0;
            double completionPercent = 0;

            if (snapshot.hasData || snapshot.data?.isNotEmpty == true) {
              waterVolumeConsumed =
                  WaterConsumptionCalculator.calculateDailyConsumption(
                      snapshot.data!);

              completionPercent =
                  WaterConsumptionCalculator.calculateCompletionPercentage(
                      waterVolumeConsumed);
            }

            return _buildStatsCard(
              todayConsumption: waterVolumeConsumed,
              todayConsumptionPercentage: completionPercent,
              formattedTime: DateFormat.jm().format(DateTime.now()),
              slotName: slotName,
              onTap: onTap,
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCard({
    required double todayConsumption,
    required double todayConsumptionPercentage,
    required String formattedTime,
    required String slotName,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppDimensions.dim70.h,
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
        decoration: BoxDecoration(
          color: AppColors.goalCompletionStatsPurple,
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.dim4.r,
              spreadRadius: 0,
              color: Colors.black.withOpacity(.25),
              offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
            )
          ],
          border: GradientBoxBorder(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0XFF3F3F3F),
              ],
            ),
            width: AppDimensions.dim1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.dim90.r),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim16.w,
          vertical: AppDimensions.dim13.h,
        ),
        child: Row(
          children: [
            /// Water drop icon
            SizedBox(
              width: AppDimensions.dim28.w,
              height: AppDimensions.dim28.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 1.3.w),
                      child: Transform.translate(
                        offset: Offset(0, AppDimensions.dim3.h),
                        child: Opacity(
                          opacity: 0.3,
                          child: SvgPicture.asset(
                            'assets/images/waterdrop_ic.svg',
                            color: Colors.black,
                            width: AppDimensions.dim28.w,
                            height: AppDimensions.dim28.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/waterdrop_ic.svg',
                    fit: BoxFit.contain,
                    width: AppDimensions.dim28.w,
                    height: AppDimensions.dim28.h,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.dim14.w),

            /// Water + Consumption
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Water",
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: AppColors.white,
                    fontSize: AppFontStyles.fontSize_12,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  ),
                ),
                TweenAnimationBuilder<int>(
                  tween: IntTween(
                    begin: 0,
                    end: todayConsumption.toInt(),
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  builder: (context, value, child) {
                    String displayValue;
                    if (value < 1000) {
                      displayValue = "$value ml";
                    } else {
                      displayValue = "${(value / 1000).toStringAsFixed(1)} L";
                    }
                    return Text(
                      displayValue,
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_16,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(width: AppDimensions.dim30.w),

            /// Slot name chip
            Container(
              width: AppDimensions.dim118.w,
              height: AppDimensions.dim26.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.goalCompletionStatesMealPurple,
                border: Border.all(
                  color: AppColors.white,
                  width: AppDimensions.dim1,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: AppDimensions.dim3.r,
                    spreadRadius: 0,
                    color: Colors.black.withOpacity(.38),
                    offset: Offset(0, 0),
                  )
                ],
                borderRadius: BorderRadius.circular(
                  AppDimensions.radius_40,
                ),
              ),
              child: Text(
                slotName,
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.white,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_14,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
            SizedBox(width: AppDimensions.dim40.w),

            /// Completed % section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Completed",
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: AppColors.white,
                    fontSize: AppFontStyles.fontSize_12,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  ),
                ),
                TweenAnimationBuilder<int>(
                  tween: IntTween(
                    begin: 0,
                    end: todayConsumptionPercentage.toInt(),
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  builder: (context, value, child) {
                    return Text(
                      "$value%",
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_16,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
