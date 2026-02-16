import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/widgets/chart_widgets/area_chart_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart';

class CustomChartDataWidget extends StatefulWidget {
  const CustomChartDataWidget({super.key});

  @override
  State<CustomChartDataWidget> createState() => _CustomChartDataWidgetState();
}

class _CustomChartDataWidgetState extends State<CustomChartDataWidget> {
  bool _isColumnChartSelected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.only(
          top: AppDimensions.defaultPadding.w,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
          bottom: AppDimensions.dim30.h),
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_4,
              color: AppColors.black.withOpacity(.25),
              offset: Offset(
                AppDimensions.dim2,
                AppDimensions.dim2,
              ),
            )
          ],
          // gradient: LinearGradient(
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //     colors: [
          //       Color(0XFF9F7DA5),
          //       Color.fromARGB(255, 121, 101, 123),
          //     ]),
          // borderRadius: BorderRadius.circular(
          //   AppDimensions.radius_10,
          // ),
          borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
          border: Border.all(color: AppColors.greywith80, width: 1.w),
          //color: Colors.transparent,
          color: AppColors.white),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _isColumnChartSelected
                    ? AppStrings.drinkCompletion
                    : "${AppStrings.drinkCompletion} (L)",
                style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation]),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radius_5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: AppDimensions.radius_5,
                      color: Colors.black.withOpacity(.4),
                      offset: Offset(
                        AppDimensions.dim2,
                        AppDimensions.dim2,
                      ),
                    )
                  ],
                  color: AppColors.white,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _isColumnChartSelected = true;
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.dim18.w,
                            vertical: AppDimensions.dim8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radius_5,
                          ),
                          color: _isColumnChartSelected
                              ? Color(0XFF369FFF)
                              : AppColors.white,
                        ),
                        child: SvgPicture.asset(
                          "assets/images/bar_chart_ic.svg",
                          color: _isColumnChartSelected
                              ? null
                              : AppColors.disabledGreyColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _isColumnChartSelected = false;
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.dim18.w,
                            vertical: AppDimensions.dim8.h),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radius_5,
                            ),
                            color: _isColumnChartSelected
                                ? AppColors.white
                                : Color(0XFF369FFF)),
                        child: SvgPicture.asset(
                          "assets/images/spline_chart_ic.svg",
                          color: _isColumnChartSelected
                              ? AppColors.disabledGreyColor
                              : AppColors.white,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: AppDimensions.dim10.h,
          ),
          BlocBuilder<BleCubit, BleState>(
            builder: (context, state) {
              return BlocBuilder<FilterCubit, FilterState>(
                builder: (context, filterState) {
                  final filterCubit = context.read<FilterCubit>();
                  DateTime startDate;
                  DateTime endDate;

                  final current = filterState.currentDate;

                  if (filterState.currentInterval == FilterInterval.weekly) {
                    // Align with your chart: week starts on Monday
                    DateTime weekStart = current
                        .subtract(Duration(days: current.weekday - 1)); // Mon
                    weekStart = DateTime(
                        weekStart.year, weekStart.month, weekStart.day);

                    startDate = weekStart;

                    final weekEnd =
                        weekStart.add(const Duration(days: 6)); // Sun
                    endDate = DateTime(
                      weekEnd.year,
                      weekEnd.month,
                      weekEnd.day,
                      23,
                      59,
                      59,
                      999999, // 23:59:59.999999
                    );
                  } else if (filterState.currentInterval ==
                      FilterInterval.monthly) {
                    // Full month
                    startDate = DateTime(current.year, current.month, 1);
                    endDate = DateTime(current.year, current.month + 1, 1)
                        .subtract(const Duration(microseconds: 1));
                  } else if (filterState.currentInterval ==
                      FilterInterval.yearly) {
                    // ✨ Full year
                    startDate = DateTime(current.year, 1, 1);
                    endDate = DateTime(current.year + 1, 1, 1)
                        .subtract(const Duration(microseconds: 1));
                  } else {
                    // fallback (optional)
                    startDate =
                        DateTime(current.year, current.month, current.day);
                    endDate = DateTime(current.year, current.month, current.day,
                        23, 59, 59, 999999);
                  }

                  log("Start date is $startDate , end date is $endDate");

                  return FutureBuilder<List<HydrationDaySummary>>(
                    future: context
                        .read<BottleDataCubit>()
                        .getHydrationSummariesForRange(startDate, endDate),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            AppStrings.errorLoadingData,
                            style: TextStyle(
                              color: AppColors.redColor,
                              fontSize: AppFontStyles.fontSize_18.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            AppStrings.noDataAvailable,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: AppFontStyles.fontSize_18.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      return Visibility(
                        visible: _isColumnChartSelected,
                        replacement: SyncfusionAreaChartWidget(
                          interval: filterState.currentInterval,
                          currentDate: filterState.currentDate,
                          bottleData: snapshot.data ?? [],
                        ),
                        child: FlColumnChartWidget(
                          interval: filterState.currentInterval,
                          currentDate: filterState.currentDate,
                          bottleData: snapshot.data ?? [],
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  List<HydrationDaySummary> generateMockWeeklyData(DateTime currentDate) {
    final weekStart =
    currentDate.subtract(Duration(days: currentDate.weekday - 1));

    return List.generate(7, (i) {
      final date = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day - i,
      );

      return HydrationDaySummary(
        date: date,
        dayIndex: i,
        target: 3000, // 3L target
        consumed: 1000 + (i * 250), // increasing mock intake
      );
    });
  }

  List<HydrationDaySummary> generateMockMonthlyData(DateTime currentDate) {
    final year = currentDate.year;
    final month = currentDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    return List.generate(lastDay, (i) {
      final date = DateTime(year, month, i + 1);

      return HydrationDaySummary(
        date: date,
        dayIndex: i,
        target: 3000,
        consumed: (1500 + (i * 100)) % 3000, // varied mock pattern
      );
    });
  }

  List<HydrationDaySummary> generateMockYearlyData(int year) {
    List<HydrationDaySummary> data = [];

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        data.add(
          HydrationDaySummary(
            date: DateTime(year, month, day),
            dayIndex: day,
            target: 3000,
            consumed: 1000 + (month * 100), // month-based variation
          ),
        );
      }
    }

    return data;
  }
}
