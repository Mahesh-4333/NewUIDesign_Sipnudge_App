import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/data_analytics/data_analytics_cubit.dart';
import 'package:hydrify/helpers/common.dart';
import 'package:hydrify/screens/calendar/calendar_screen.dart';
import 'package:hydrify/screens/widgets/chart_widgets/custom_stacked_bar_chart.dart';
import 'package:hydrify/screens/widgets/data_analytics/animated_month_item.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum MonthGoalCompletionStatus { Completed, Partial, NotFinished }

class DataNAnalyticsScreen extends StatefulWidget {
  const DataNAnalyticsScreen({super.key});

  @override
  State<DataNAnalyticsScreen> createState() => _DataNAnalyticsScreenState();
}

class _DataNAnalyticsScreenState extends State<DataNAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SizedBox(height: 0, width: 0,),
      // appBar: _getAppBarWidget(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_background.png'),
            // Assuming a background texture exists or using a subtle gradient
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),),
        child: SafeArea(
          child: Column(
            children: [
              _titleWidget(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Container(
                    width: double.infinity,
                    // padding: EdgeInsets.only(
                    //   top: AppDimensions.dim100.h,
                    // ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/app_background.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.dim40.w,
                          vertical: AppDimensions.dim12.h),
                      child: Column(
                        children: [
                          SizedBox(
                            height: AppDimensions.dim17.h,
                          ),
                          buildMonthyNYearlyToggle(),
                          SizedBox(
                            height: AppDimensions.dim24.h,
                          ),
                          buildMonthGrid(),
                          SizedBox(
                            height: 16.h,
                          ),
                          buildIntakeCard(),
                          SizedBox(
                            height: 16.h,
                          ),
                          buildDistributionCard(),
                          SizedBox(
                            height: 16.h,
                          ),
                          buildHabitConsistencyCard(),
                          SizedBox(
                            height: 16.h,
                          ),
                          buildEliteSmartInsights(),
                          SizedBox(
                            height: 16.h,
                          ),
                          BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
                            builder: (context, state) {
                              return Visibility(
                                visible: state.isMonthlySelected,
                                replacement: buildQuarterlyBreakDown(),
                                child: buildHistoricalTrends(),
                              );
                            },
                          ),
                          SizedBox(
                            height: 20.h,
                          ),
                          Container(
                            width: 209.89,
                            height: 49,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100), // cleaner
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.color_1E69B3,
                                  AppColors.color_3B82F6,
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.color_3B82F6_30,
                                  offset: Offset(0, 9.76),
                                  blurRadius: 12.2,
                                ),
                                BoxShadow(
                                  color: AppColors.color_3B82F6_30,
                                  offset: Offset(0, -3),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                showExportBottomSheet(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 39.03,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: Text(
                                "Export Data",
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontSize: AppFontStyles.fontSize_16,
                                  fontVariations: [AppFontStyles.boldFontVariation],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 150.h,)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding _titleWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Color(0xFF475569)),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Data & Analytics',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontVariations: [AppFontStyles.boldFontVariation,],
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: Color(0xFF5D7B91),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: 48.w), // To balance the back button
          IconButton(
              onPressed: () {
                context.read<DataAnalyticsCubit>().toggleCalendar();
                Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarScreen()));
              },
              icon: Icon(Icons.calendar_month_outlined,
                  color: AppColors.lightBlue400)),

        ],
      ),
    );
  }

  PreferredSizeWidget _getAppBarWidget() {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      forceMaterialTransparency: true,
      // surfaceTintColor: Colors.transparent,
      // backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: SvgPicture.asset(
          "assets/images/back_ic.svg",
          color: AppColors.bluegray,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
            onPressed: () {
              context.read<DataAnalyticsCubit>().toggleCalendar();
            },
            icon: Icon(Icons.calendar_month_outlined,
                color: AppColors.lightBlue400))
      ],
      title: Text(
        AppStrings.dataAnalytics,
        style: TextStyle(
          color: AppColors.bluegray,
          fontSize: AppFontStyles.fontSize_AppBar,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontVariations: [AppFontStyles.boldFontVariation],
        ),
      ),
    );
  }

  Widget buildMonthyNYearlyToggle() {
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final bool isMonthlyAnalyticsSelected = state.isMonthlySelected;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          width: AppDimensions.dim360.w,
          height: AppDimensions.dim42.h,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<DataAnalyticsCubit>()
                        .toggleAnalyticsMode(isMonthly: true);
                  },
                  child: Container(
                    width: AppDimensions.dim179.w,
                    height: AppDimensions.dim42.h,
                    decoration: BoxDecoration(
                      color: isMonthlyAnalyticsSelected
                          ? AppColors.color_0083FF
                          : AppColors.white,
                      border: BoxBorder.all(
                          width: AppDimensions.dim2.w,
                          color: isMonthlyAnalyticsSelected
                              ? AppColors.color_9CCEFD
                              : AppColors.white),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Center(
                      child: Text("Monthly",
                          style: TextStyle(
                            color: isMonthlyAnalyticsSelected
                                ? AppColors.white
                                : AppColors.steelblue,
                            fontSize: AppFontStyles.fontSize_16,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          )),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<DataAnalyticsCubit>()
                        .toggleAnalyticsMode(isMonthly: false);
                  },
                  child: Container(
                    width: AppDimensions.dim179.w,
                    height: AppDimensions.dim42.h,
                    decoration: BoxDecoration(
                      color: !isMonthlyAnalyticsSelected
                          ? AppColors.color_0083FF
                          : AppColors.white,
                      border: BoxBorder.all(
                          color: !isMonthlyAnalyticsSelected
                              ? AppColors.color_9CCEFD
                              : AppColors.white),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Center(
                      child: Text("Yearly",
                          style: TextStyle(
                            color: !isMonthlyAnalyticsSelected
                                ? AppColors.white
                                : AppColors.steelblue,
                            fontSize: AppFontStyles.fontSize_16,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          )),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildMonthGrid() {
    final currentYear = DateTime.now().year;

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.dim12.r),
            border: Border.all(color: AppColors.color_136DEC0D),
            boxShadow: [
              BoxShadow(
                color: AppColors.black40,
                offset: const Offset(0, 1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            vertical: AppDimensions.dim16.h,
            horizontal: AppDimensions.dim24.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      context.read<DataAnalyticsCubit>().changeYear(-1);
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chevron_left,
                        size: 28, color: AppColors.steelblue),
                  ),
                  Text(
                    "${state.selectedYear}",
                    style: TextStyle(
                      color: AppColors.steelblue,
                      fontSize: AppFontStyles.fontSize_16,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [
                        AppFontStyles.boldFontVariation,
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: state.selectedYear < currentYear ? 1.0 : 0.0,
                    child: IconButton(
                      onPressed: state.selectedYear < currentYear
                          ? () =>
                              context.read<DataAnalyticsCubit>().changeYear(1)
                          : null,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.chevron_right,
                          size: 28, color: AppColors.steelblue),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: state.isCalendarExpanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 12.h),
                          GridView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: months.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 10.h,
                              crossAxisSpacing: 10.w,
                              childAspectRatio: 3.2,
                            ),
                            itemBuilder: (context, index) {
                              MonthGoalCompletionStatus status =
                                  MonthGoalCompletionStatus.Completed;

                              bool isSelected =
                                  state.selectedMonth == (index + 1);

                              return AnimatedMonthItem(
                                index: index,
                                status: status,
                                monthName: months[index],
                                isSelected: isSelected,
                                onTap: () {
                                  context
                                      .read<DataAnalyticsCubit>()
                                      .selectMonth(index);

                                  // context
                                  //     .read<DataAnalyticsCubit>()
                                  //     .toggleCalendar();
                                },
                              );
                            },
                          ),
                          Divider(color: AppColors.color_136DEC0D),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: AppDimensions.dim16.w,
                            children: [
                              buildLegendItem(
                                  AppColors.lightBlue400, "Goal Met"),
                              buildLegendItem(
                                  AppColors.color_136DEC0D, "Partial")
                            ],
                          )
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildIntakeCard() {
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final bool isMonthlyIntake = state.isMonthlySelected;
        final double percentCompletion = .5;

        final selectedMonthName =
            CommonHelper.getMonthNameFromZeroIndex(state.selectedMonth ?? 0);
        final selectedYear = state.selectedYear;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.dim12.r),
            border: Border.all(color: AppColors.color_136DEC0D),
            boxShadow: [
              BoxShadow(
                color: AppColors.black40,
                offset: const Offset(0, 1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
              vertical: AppDimensions.dim16.h,
              horizontal: AppDimensions.dim24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "${isMonthlyIntake ? "Monthly Intake: " : "Quaterly Intake: "}${isMonthlyIntake ? selectedMonthName : ""}${isMonthlyIntake ? ", $selectedYear" : "$selectedYear"}",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_18,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
              SizedBox(
                height: 29.h,
              ),
              CircularPercentIndicator(
                radius: 96.w,
                percent: percentCompletion,
                progressColor: AppColors.color_0083FF,
                backgroundColor: AppColors.color_F1F5F9,
                circularStrokeCap: CircularStrokeCap.round,
                lineWidth: 12.w,
                animation: true,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${(percentCompletion * 100).toStringAsPrecision(2)}%",
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_30,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    Text(
                      isMonthlyIntake ? "MONTHLY GOAL" : "ANNUAL PERFORMANCE",
                      style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_12,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.semiBoldFontVariation],
                          letterSpacing: 1),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Total Intake",
                        style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            letterSpacing: .6),
                      ),
                      Text(
                        "25.5L",
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_20,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      )
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Target",
                        style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            letterSpacing: .6),
                      ),
                      Text(
                        "25.5L",
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_20,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      )
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Off Slot",
                        style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            letterSpacing: .6),
                      ),
                      Text(
                        "2.1L",
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_20,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildDistributionCard() {
    final List<ChartData> myData = [
      ChartData(backgroundValue: 100, foregroundValue: 50, label: "W - 1"),
      ChartData(backgroundValue: 95, foregroundValue: 30, label: "W - 2"),
      ChartData(backgroundValue: 80, foregroundValue: 60, label: "W - 3"),
      ChartData(backgroundValue: 85, foregroundValue: 40, label: "W - 4"),
    ];
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.dim12.r),
              border: Border.all(color: AppColors.color_136DEC0D),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black40,
                  offset: const Offset(0, 1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
                vertical: AppDimensions.dim16.h,
                horizontal: AppDimensions.dim24.w),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              state.isMonthlySelected
                                  ? "Weekly Distribution"
                                  : "Quarterly Distribution",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_18,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Scheduled vs. Off-slot",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_14,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.regularFontVariation
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "6.2L",
                              style: TextStyle(
                                color: AppColors.color_136DEC,
                                fontSize: AppFontStyles.fontSize_24,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.lightFontWeightVariation
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                                color: AppColors.color_F0FDF4,
                                borderRadius: BorderRadius.circular(360)),
                            child: Text(
                              "+12% vs last month",
                              style: TextStyle(
                                color: AppColors.color_16A34A,
                                fontSize: AppFontStyles.fontSize_10,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 29.h,
                  ),
                  CustomStackedBarChart(
                    data: myData,
                    chartHeight: 192.h,
                    barWidth: 60.w,
                    maxValue: 100,
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppDimensions.dim16.w,
                    children: [
                      buildLegendItem(AppColors.lightBlue400, "SCHEDULED"),
                      buildLegendItem(AppColors.color_136DEC0D, "OFF-SLOT")
                    ],
                  )
                ]));
      },
    );
  }

  Widget buildHabitConsistencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.dim12.r),
        border: Border.all(color: AppColors.color_136DEC0D),
        boxShadow: [
          BoxShadow(
            color: AppColors.black40,
            offset: const Offset(0, 1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
          vertical: AppDimensions.dim16.h, horizontal: AppDimensions.dim24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Habit Consistency",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_18,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: AppColors.color_136DEC.withOpacity(.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                  "Elite Tier",
                  style: TextStyle(
                    color: AppColors.color_136DEC,
                    fontSize: AppFontStyles.fontSize_10,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 16.h,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildConsistencyWidget(isStreak: false, value: "92"),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: buildConsistencyWidget(isStreak: true, value: "18"),
              ),
            ],
          ),
          SizedBox(
            height: 8.h,
          ),
          Divider(
            color: AppColors.color_F8FAFC,
          ),
          SizedBox(
            height: 8.h,
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.color_EFF6FF),
                width: 32.w,
                height: 32.h,
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.color_136DEC,
                  size: 18,
                ),
              ),
              SizedBox(
                width: 12.w,
              ),
              Expanded(
                child: Text(
                  "Most off-slot drinking happens at 11PM. Try hydrating more during dinner.",
                  style: TextStyle(
                    color: AppColors.color_4D758B,
                    fontSize: AppFontStyles.fontSize_12,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget buildConsistencyWidget({
    required String value,
    required bool isStreak,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStreak ? "Streak" : "Consistency",
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontSize: AppFontStyles.fontSize_14,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.regularFontVariation],
          ),
        ),
        SizedBox(
          height: 4.h,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "$value${isStreak ? "" : "%"}",
              style: TextStyle(
                color: AppColors.color_0F172A,
                fontSize: AppFontStyles.fontSize_24,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
              ),
            ),
            SizedBox(
              width: 8.h,
            ),
            Visibility(
              visible: isStreak,
              replacement: Icon(
                Icons.verified_outlined,
                size: 20.w,
                color: AppColors.color_22C55E,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "days",
                    style: TextStyle(
                      color: AppColors.color_64748B,
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  SizedBox(
                    width: 8.h,
                  ),
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 24.w,
                    color: AppColors.color_F97316,
                  )
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 4.h,
        ),
        Text(
          isStreak
              ? "Consecutive days reaching daily goal"
              : "Following schedule vs off-slot drinking",
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontSize: AppFontStyles.fontSize_10,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.semiBoldFontVariation],
          ),
        ),
      ],
    );
  }

  Widget buildLegendItem(Color color, String text) {
    return SizedBox(
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(
            width: 6.w,
          ),
          Text(
            text,
            style: TextStyle(
              color: AppColors.color_64748B,
              fontSize: AppFontStyles.fontSize_12,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          )
        ],
      ),
    );
  }

  Widget buildMonth(
      int index, MonthGoalCompletionStatus status, String monthName) {
    return Container(
      width: AppDimensions.dim70.w,
      height: AppDimensions.dim25.h,
      padding: EdgeInsets.all(
        status == MonthGoalCompletionStatus.Partial ? 1 : .5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.dim15.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.color_E7E7E7,
            AppColors.color_00050C.withOpacity(.9)
          ],
        ),
        boxShadow: status == MonthGoalCompletionStatus.Partial
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.dim15.r),
          color: status == MonthGoalCompletionStatus.Completed
              ? AppColors.color_136DEC
              : status == MonthGoalCompletionStatus.Partial
                  ? AppColors.color_D0E2FB
                  : AppColors.white,
        ),
        alignment: Alignment.center,
        child: Text(
          monthName,
          style: TextStyle(
            color: status != MonthGoalCompletionStatus.Completed
                ? AppColors.steelblue
                : AppColors.white,
            fontSize: AppFontStyles.fontSize_10,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
      ),
    );
  }

  void showExportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // IMPORTANT
      barrierColor: Colors.black.withOpacity(0.5), // #00000080
      builder: (context) {
        return Stack(
          children: [
            // 🔹 Blur Background
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 8, // adjust for intensity
                sigmaY: 8,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),

            // 🔹 Bottom Sheet Content
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.dim48.w,
                    vertical: AppDimensions.dim15.h),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: AppDimensions.dim48.w,
                      height: AppDimensions.dim5.h,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.color_CBD5E1,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      "Export Options",
                      style: TextStyle(
                        color: AppColors.black,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: AppFontStyles.fontSize_20,
                        fontVariations: [
                          AppFontStyles.boldFontVariation,
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Download your hydration history for your records",
                      style: TextStyle(
                        color: AppColors.color_414755,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: AppFontStyles.fontSize_14,
                        fontVariations: [
                          AppFontStyles.lightFontWeightVariation,
                        ],
                      ),
                    ),
                    SizedBox(height: 17.h),
                    GestureDetector(
                      onTap: () {
                        ////TODO : Save the current screenshot as JPG
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              offset: Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: AppDimensions.dim52.h,
                              width: AppDimensions.dim52.h,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.color_EBF2FE),
                              child: Icon(
                                Icons.photo_library_outlined,
                                size: 25.w,
                                color: AppColors.color_3B82F6,
                              ),
                            ),
                            SizedBox(
                              width: 25.w,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Download as JPG",
                                  style: TextStyle(
                                    color: AppColors.color_414141,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontSize: AppFontStyles.fontSize_18,
                                    fontVariations: [
                                      AppFontStyles.semiBoldFontVariation,
                                    ],
                                  ),
                                ),
                                Text(
                                  "High-resolution visual summary for social sharing.",
                                  style: TextStyle(
                                    color: AppColors.color_464545,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontSize: AppFontStyles.fontSize_10,
                                    fontVariations: [
                                      AppFontStyles.lightFontWeightVariation,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Icon(
                              Icons.keyboard_arrow_right,
                              size: AppDimensions.dim32.w,
                              color: AppColors.color_4F4F4F,
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 17.h),
                    GestureDetector(
                      onTap: () {
                        ////TODO : Download and save current screenshot as PDF
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              offset: Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: AppDimensions.dim52.h,
                              width: AppDimensions.dim52.h,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.color_EBF2FE),
                              padding: EdgeInsets.all(13.5.h),
                              child: SvgPicture.asset(
                                "assets/images/export_as_pdf_icon.svg",
                                height: 12.h,
                                width: 12.h,
                                fit: BoxFit.fitWidth,
                                color: AppColors.color_3B82F6,
                              ),
                            ),
                            SizedBox(
                              width: 25.w,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Download as PDF",
                                  style: TextStyle(
                                    color: AppColors.color_414141,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontSize: AppFontStyles.fontSize_18,
                                    fontVariations: [
                                      AppFontStyles.semiBoldFontVariation,
                                    ],
                                  ),
                                ),
                                Text(
                                  "Detailed document of daily statistics and trends.",
                                  style: TextStyle(
                                    color: AppColors.color_464545,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontSize: AppFontStyles.fontSize_10,
                                    fontVariations: [
                                      AppFontStyles.lightFontWeightVariation,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Icon(
                              Icons.keyboard_arrow_right,
                              size: AppDimensions.dim32.w,
                              color: AppColors.color_4F4F4F,
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: AppDimensions.dim52.h,
                    ),
                    Container(
                      width: AppDimensions.dim350.w,
                      height: AppDimensions.dim49.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100), // cleaner
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.color_1E69B3,
                            AppColors.color_3B82F6,
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 39.03,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: AppColors.white,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontSize: AppFontStyles.fontSize_16,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildEliteSmartInsights() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.dim20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.dim15.w),
        color: AppColors.color_369FFF,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: AppDimensions.dim32.h,
                width: AppDimensions.dim32.h,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(.1)),
                child: Icon(
                  Icons.lightbulb_rounded,
                  size: 20.w,
                  color: AppColors.white,
                ),
              ),
              SizedBox(
                width: AppDimensions.dim12.w,
              ),
              Text(
                "Elite Smart Insights",
                style: TextStyle(
                  color: AppColors.white,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_16,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              )
            ],
          ),
          SizedBox(
            height: AppDimensions.dim11.h,
          ),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppColors.white,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_14,
                fontVariations: [AppFontStyles.regularFontVariation],
                height: 1.625,
              ),
              children: [
                TextSpan(text: 'Your hydration consistency is '),
                TextSpan(
                  text: 'Peak Performing',
                  style: TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_14,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.white),
                ),
                const TextSpan(
                  text:
                      '.\nMorning intake is up by 14%, significantly reducing mid-day fatigue markers.',
                ),
              ],
            ),
          ),
          SizedBox(
            height: AppDimensions.dim11.h,
          ),
          Container(
            padding: EdgeInsets.all(AppDimensions.dim12.w),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(.1),
              borderRadius: BorderRadius.circular(
                AppDimensions.dim8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Optimal Window: 08:00 - 11:30",
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_12,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                Icon(
                  Icons.trending_up,
                  size: AppDimensions.dim15.w,
                  color: AppColors.white,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildHistoricalTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Historical Trends",
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.fontSize_18,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
        SizedBox(
          height: 8.h,
        ),
        Container(
          padding: EdgeInsets.all(AppDimensions.dim16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.dim15.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40000000),
                offset: const Offset(0, 2),
                blurRadius: 10.0,
                spreadRadius: 0.0,
              ),
            ],
            border: Border.all(
              color: AppColors.color_F1F5F9,
              width: AppDimensions.dim1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: AppDimensions.dim40.h,
                width: AppDimensions.dim40.h,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.color_F8FAFC),
                child: Icon(
                  Icons.water_drop_outlined,
                  size: 20.w,
                  color: AppColors.color_136DEC,
                ),
              ),
              SizedBox(
                width: AppDimensions.dim16.w,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Average Daily",
                    style: TextStyle(
                      color: AppColors.color_4D758B,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_18,
                      fontVariations: [
                        AppFontStyles.boldFontVariation,
                      ],
                    ),
                  ),
                  Text(
                    "Based on last 30 days",
                    style: TextStyle(
                      color: AppColors.color_4D758B,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_12,
                      fontVariations: [
                        AppFontStyles.regularFontVariation,
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                "2.1L",
                style: TextStyle(
                  color: AppColors.color_4D758B,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_18,
                  fontVariations: [
                    AppFontStyles.fontWeightVariation600,
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 8.h,
        ),
        Container(
          padding: EdgeInsets.all(AppDimensions.dim16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.dim15.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40000000),
                offset: const Offset(0, 2),
                blurRadius: 10.0,
                spreadRadius: 0.0,
              ),
            ],
            border: Border.all(
              color: AppColors.color_F1F5F9,
              width: AppDimensions.dim1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: AppDimensions.dim40.h,
                width: AppDimensions.dim40.h,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.color_F8FAFC),
                child: Icon(
                  Icons.water_drop_outlined,
                  size: 20.w,
                  color: AppColors.color_136DEC,
                ),
              ),
              SizedBox(
                width: AppDimensions.dim16.w,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Peak Streak",
                    style: TextStyle(
                      color: AppColors.color_4D758B,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_18,
                      fontVariations: [
                        AppFontStyles.boldFontVariation,
                      ],
                    ),
                  ),
                  Text(
                    "Goal met consecutive days",
                    style: TextStyle(
                      color: AppColors.color_4D758B,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_12,
                      fontVariations: [
                        AppFontStyles.regularFontVariation,
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                "18 Days",
                style: TextStyle(
                  color: AppColors.color_4D758B,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_18,
                  fontVariations: [
                    AppFontStyles.fontWeightVariation600,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildQuarterlyBreakDown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quarterly Breakdown",
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.fontSize_18,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
        SizedBox(
          height: 8.h,
        ),
        ...List.generate(
            4,
            (index) => Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.dim12.h),
                  child: buildQuarterlyItems(
                      quarterNumber: index, goal: 237.8, percent: .22),
                )),
      ],
    );
  }

  Widget buildQuarterlyItems(
      {required int quarterNumber,
      required double goal,
      required double percent}) {
    String quarterTitle;
    String monthRange;

    switch (quarterNumber) {
      case 0:
        quarterTitle = "First Quarter";
        monthRange = "January to March";
        break;
      case 1:
        quarterTitle = "Second Quarter";
        monthRange = "April to June";
        break;
      case 2:
        quarterTitle = "Third Quarter";
        monthRange = "July to September";
        break;
      case 3:
        quarterTitle = "Fourth Quarter";
        monthRange = "October to December";
        break;
      default:
        quarterTitle = "Quarter ${quarterNumber + 1}";
        monthRange = "";
    }

    int goalCompletionStatus = 0;

    return Container(
      padding: EdgeInsets.all(AppDimensions.dim13.w),
      margin: EdgeInsets.only(
          bottom: AppDimensions.dim12.h), // Added margin for spacing
      height: AppDimensions.dim82.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.dim15.w),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 2),
            blurRadius: 10.0,
            spreadRadius: 0.0,
          ),
        ],
        border: Border.all(
          color: AppColors.color_F1F5F9,
          width: AppDimensions.dim1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppColors.color_EFF6FF,
              shape: BoxShape.circle,
            ),
            child: CircularPercentIndicator(
              radius: 23.w,
              percent: .5,
              progressColor: AppColors.color_0083FF,
              backgroundColor: AppColors.white,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 3.w,
              animation: true,
              center: Text(
                "${(percent * 100).toStringAsPrecision(2)}%",
                style: TextStyle(
                  color: AppColors.color_4D758B,
                  fontSize: AppFontStyles.fontSize_8,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
          ),
          SizedBox(width: AppDimensions.dim16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quarterTitle,
                  style: TextStyle(
                    color: AppColors.color_4D758B,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_14,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                Text(
                  monthRange,
                  style: TextStyle(
                    color: AppColors.color_4D758B,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_12,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                goal.toString(),
                style: TextStyle(
                  color: AppColors.color_4D758B,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_16,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
              ),
              Text(
                goalCompletionStatus == 1
                    ? "Goal reached"
                    : goalCompletionStatus == 0
                        ? "Goal Incomplete"
                        : "Goal Exceeded",
                style: TextStyle(
                  color: AppColors.color_006768,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_10,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
