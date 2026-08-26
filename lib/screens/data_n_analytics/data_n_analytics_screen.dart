import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/data_analytics/data_analytics_cubit.dart';
import 'package:hydrify/helpers/common.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/analytics_pdf_service.dart';
import 'package:hydrify/screens/calendar/calendar_screen.dart';
import 'package:hydrify/screens/widgets/chart_widgets/custom_stacked_bar_chart.dart';
import 'package:hydrify/screens/widgets/data_analytics/animated_month_item.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum MonthGoalCompletionStatus { Completed, Partial, NotFinished }

class DataNAnalyticsScreen extends StatefulWidget {
  const DataNAnalyticsScreen({super.key});

  @override
  State<DataNAnalyticsScreen> createState() => _DataNAnalyticsScreenState();
}

class _DataNAnalyticsScreenState extends State<DataNAnalyticsScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isCapturing = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SizedBox(
        height: 0,
        width: 0,
      ),
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _titleWidget(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Screenshot(
                    controller: screenshotController,
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
                            horizontal: AppDimensions.dim24.w,
                            vertical: AppDimensions.dim12.h),
                        child: Column(
                          children: [
                            SizedBox(
                              height: AppDimensions.dim17.h,
                            ),
                            if (!_isCapturing) ...[
                              buildMonthyNYearlyToggle(),
                              SizedBox(
                                height: AppDimensions.dim24.h,
                              ),
                            ],
                            buildMonthGrid(),
                            SizedBox(
                              height: 16.h,
                            ),
                            BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
                              builder: (context, state) {
                                if (state.isLoading) {
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 32.h),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.color_0083FF,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                if (state.error != null &&
                                    state.analyticsData == null) {
                                  final l10n = AppLocalizations.of(context);
                                  return Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 32.h),
                                    child: Center(
                                      child: Text(
                                        l10n?.couldNotLoadAnalytics ??
                                            "Could not load analytics.\nCheck your connection.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.color_4D758B,
                                          fontFamily:
                                              AppFontStyles.urbanistFontFamily,
                                          fontSize: AppFontStyles.fontSize_14,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
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
                            //buildEliteSmartInsights(),
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
                            if (!_isCapturing)
                              Container(
                                width: 209.89,
                                height: 49,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(100), // cleaner
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
                                  onPressed: () async {
                                    context.read<BottomNavCubit>().hideBar();
                                    await showExportBottomSheet(context);
                                    context.read<BottomNavCubit>().showBar();
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
                                    AppLocalizations.of(context)?.exportData ??
                                        "Export Data",
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      fontSize: AppFontStyles.fontSize_16,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 150.h,
                            )
                          ],
                        ),
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
                AppLocalizations.of(context)?.dataAnalytics ??
                    'Data & Analytics',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ],
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CalendarScreen()));
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
        final l10n = AppLocalizations.of(context);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      child: Text(
                        l10n?.monthly ?? "Monthly",
                        style: TextStyle(
                          color: isMonthlyAnalyticsSelected
                              ? AppColors.white
                              : AppColors.steelblue,
                          fontSize: AppFontStyles.fontSize_16,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
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
                      child: Text(
                        l10n?.yearly ?? "Yearly",
                        style: TextStyle(
                          color: !isMonthlyAnalyticsSelected
                              ? AppColors.white
                              : AppColors.steelblue,
                          fontSize: AppFontStyles.fontSize_16,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildMonthGrid() {
    final currentYear = DateTime.now().year;

    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final locale = Localizations.localeOf(context).toString();
        final months = List.generate(12, (index) {
          final date = DateTime(2024, index + 1, 1);
          return DateFormat('MMMM', locale).format(date);
        });
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
                                  MonthGoalCompletionStatus.NotFinished;

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
                          // Row(
                          //   mainAxisSize: MainAxisSize.min,
                          //   spacing: AppDimensions.dim16.w,
                          //   children: [
                          //     buildLegendItem(
                          //         AppColors.lightBlue400, "Goal Met"),
                          //     buildLegendItem(
                          //         AppColors.color_136DEC0D, "Partial")
                          //   ],
                          // )
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
        final data = state.analyticsData?['monthlyIntake'];
        final double percentCompletion =
            data != null ? (data['percentage'] / 100.0) : 0.0;
        final totalIntake = data != null ? "${data['totalIntake']}L" : "0.0L";
        final target = data != null ? "${data['target']}L" : "0.0L";
        final offSlot = data != null ? "${data['offSlot']}L" : "0.0L";
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
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  final prefix = isMonthlyIntake
                      ? (l10n?.monthlyIntake ?? "Monthly Intake")
                      : (l10n?.quarterlyIntake ?? "Quarterly Intake");
                  final suffix = isMonthlyIntake
                      ? "$selectedMonthName, $selectedYear"
                      : "$selectedYear";

                  return Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "$prefix: $suffix",
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_18,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 29.h,
              ),
              CircularPercentIndicator(
                radius: 96.w,
                percent: percentCompletion.clamp(0.0, 1.0),
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
                      "${(percentCompletion * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_30,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    Text(
                      isMonthlyIntake
                          ? (AppLocalizations.of(context)?.monthlyGoal ??
                              "MONTHLY GOAL")
                          : (AppLocalizations.of(context)?.annualPerformance ??
                              "ANNUAL PERFORMANCE"),
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
                        AppLocalizations.of(context)?.totalIntake ??
                            "Total Intake",
                        style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            letterSpacing: .6),
                      ),
                      Text(
                        totalIntake,
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
                        AppLocalizations.of(context)?.target ?? "Target",
                        style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            letterSpacing: .6),
                      ),
                      Text(
                        target,
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
                        AppLocalizations.of(context)?.offSlot ?? "Off Slot",
                        style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            letterSpacing: .6),
                      ),
                      Text(
                        offSlot,
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
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final List<ChartData> myData = [];
        double maxWeeklyValue = 100.0; // Default or calculate from data

        if (state.analyticsData?['weeklyDistribution'] != null) {
          final List distribution = state.analyticsData!['weeklyDistribution'];
          double maxVal = 0.0;
          for (var w in distribution) {
            double scheduled =
                double.tryParse(w['scheduled'].toString()) ?? 0.0;
            double offSlot = double.tryParse(w['offSlot'].toString()) ?? 0.0;
            double total = scheduled + offSlot;
            if (total > maxVal) maxVal = total;

            myData.add(ChartData(
                backgroundValue: total,
                foregroundValue: scheduled,
                label: w['label']?.toString() ?? ""));
          }
          if (maxVal > 0) {
            maxWeeklyValue = maxVal * 1.2; // Add some headroom
          }
        }

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
                                  ? (AppLocalizations.of(context)
                                          ?.weeklyDistribution ??
                                      "Weekly Distribution")
                                  : (AppLocalizations.of(context)
                                          ?.quarterlyDistribution ??
                                      "Quarterly Distribution"),
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
                              AppLocalizations.of(context)
                                      ?.scheduledVsOffSlot ??
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
                              state.analyticsData?['monthlyIntake']
                                          ?['totalIntake'] !=
                                      null
                                  ? "${state.analyticsData!['monthlyIntake']['totalIntake']}L"
                                  : "0.0L",
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
                          Builder(builder: (context) {
                            final vsLastMonth =
                                state.analyticsData?['vsLastMonth'] ?? 0;
                            final isPositive = vsLastMonth >= 0;
                            final color = isPositive
                                ? AppColors.color_16A34A
                                : AppColors.redAccent;
                            final bgColor = isPositive
                                ? AppColors.color_F0FDF4
                                : AppColors.redAccent.withOpacity(0.1);
                            final sign = isPositive ? "+" : "";
                            final l10n = AppLocalizations.of(context);
                            final comparisonText = state.isMonthlySelected
                                ? (l10n?.vsLastMonth ?? "vs last month")
                                : (l10n?.vsLastYear ?? "vs last year");

                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(360)),
                              child: Text(
                                "$sign$vsLastMonth% $comparisonText",
                                style: TextStyle(
                                  color: color,
                                  fontSize: AppFontStyles.fontSize_10,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation
                                  ],
                                ),
                              ),
                            );
                          }),
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
                    maxValue: maxWeeklyValue,
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppDimensions.dim16.w,
                    children: [
                      buildLegendItem(AppColors.lightBlue400,
                          AppLocalizations.of(context)?.scheduledUpper ?? "SCHEDULED"),
                      buildLegendItem(AppColors.color_136DEC0D,
                          AppLocalizations.of(context)?.offSlotUpper ?? "OFF-SLOT")
                    ],
                  )
                ]));
      },
    );
  }

  Widget buildHabitConsistencyCard() {
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final habit = state.analyticsData?['habitConsistency'];
        final efficiency = habit?['efficiency']?.toString() ?? '0';
        final streak = habit?['streak']?.toString() ?? '0';
        final insight = habit?['insight'] as String? ??
            (l10n?.keepUpHydrationHabits ?? 'Keep up your hydration habits!');
        final percentage =
            state.analyticsData?['monthlyIntake']?['percentage'] ?? 0;
        final tierLabel = percentage >= 80
            ? (l10n?.eliteTier ?? 'Elite Tier')
            : percentage >= 60
                ? (l10n?.good ?? 'Good')
                : (l10n?.improving ?? 'Improving');

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
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      l10n?.habitConsistency ?? "Habit Consistency",
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_18,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                        color: AppColors.color_136DEC.withOpacity(.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      tierLabel,
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
                    child: buildConsistencyWidget(
                        isStreak: false, value: efficiency),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child:
                        buildConsistencyWidget(isStreak: true, value: streak),
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
                      insight,
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
      },
    );
  }

  Widget buildConsistencyWidget({
    required String value,
    required bool isStreak,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStreak
              ? (l10n?.streak ?? "Streak")
              : (l10n?.consistency ?? "Consistency"),
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
                    l10n?.days ?? "days",
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
              ? (l10n?.consecutiveDaysGoal ??
                  "Consecutive days reaching daily goal")
              : (l10n?.followingScheduleVsOffSlot ??
                  "Following schedule vs off-slot drinking"),
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

  Future<void> showExportBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
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
                      AppLocalizations.of(context)?.exportOptions ??
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
                      AppLocalizations.of(context)
                              ?.downloadHydrationHistorySubtitle ??
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
                      onTap: () async {
                        try {
                          final RenderBox? box =
                              context.findRenderObject() as RenderBox?;
                          final Rect? shareRect = box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null;

                          // 1. Hide buttons for screenshot
                          setState(() => _isCapturing = true);

                          // 2. Short delay to ensure UI rebuilds
                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          final Uint8List? imageBytes =
                              await screenshotController.capture(
                            pixelRatio: 2.0,
                          );

                          // 3. Show buttons back
                          setState(() => _isCapturing = false);

                          if (imageBytes != null) {
                            final directory =
                                await getApplicationDocumentsDirectory();
                            final imagePath =
                                await File('${directory.path}/analytics.jpg')
                                    .create();
                            await imagePath.writeAsBytes(imageBytes);

                            if (context.mounted) {
                              final shareText = AppLocalizations.of(context)
                                      ?.shareHydrationAnalyticsText ??
                                  'Check out my hydration analytics!';
                              await Share.shareXFiles(
                                [XFile(imagePath.path)],
                                text: shareText,
                                sharePositionOrigin: shareRect,
                              );
                            }
                          }
                        } catch (e) {
                          setState(() => _isCapturing = false);
                          debugPrint("Error capturing screenshot: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      AppLocalizations.of(context)
                                              ?.failedToExportJpg ??
                                          "Failed to export JPG")),
                            );
                          }
                        }
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
                                  AppLocalizations.of(context)?.downloadAsJpg ??
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
                                  AppLocalizations.of(context)
                                          ?.downloadAsJpgDescription ??
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
                      onTap: () async {
                        final cubitState =
                            context.read<DataAnalyticsCubit>().state;
                        final data = cubitState.analyticsData;
                        if (data == null) return;
                        Navigator.of(context).pop();
                        final userEmail =
                            await SharedPrefsHelper.getUserEmail() ?? 'User';
                        await AnalyticsPdfService.generateAndShare(
                          analyticsData: data,
                          year: cubitState.selectedYear,
                          month: cubitState.isMonthlySelected
                              ? cubitState.selectedMonth
                              : null,
                          userEmail: userEmail,
                        );
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
                                  AppLocalizations.of(context)?.downloadAsPdf ??
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
                                  AppLocalizations.of(context)
                                          ?.downloadAsPdfDescription ??
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
                          AppLocalizations.of(context)?.cancel ?? "Cancel",
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
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final insights = state.analyticsData?['eliteSmartInsights'];
        final title = insights?['title'] as String? ?? 'Keep Going!';
        final description = insights?['description'] as String? ??
            'Stay consistent with your hydration habits.';
        final optimalWindow = insights?['optimalWindow'] as String? ?? '--:--';

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
                    AppLocalizations.of(context)?.eliteSmartInsights ??
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
                      text: title,
                      style: TextStyle(
                          color: AppColors.white,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: AppFontStyles.fontSize_14,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white),
                    ),
                    TextSpan(text: '.\n$description'),
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
                      "${AppLocalizations.of(context)?.optimalWindow ?? 'Optimal Window'}: $optimalWindow",
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
      },
    );
  }

  Widget buildHistoricalTrends() {
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final trends = state.analyticsData?['historicalTrends'];
        final avgDaily = trends != null ? "${trends['averageDaily']}L" : "0.0L";
        final peakStreak = trends != null
            ? "${trends['peakStreak']} ${l10n?.days ?? 'Days'}"
            : "0 ${l10n?.days ?? 'Days'}";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.historicalTrends ?? "Historical Trends",
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
                        l10n?.averageDaily ?? "Average Daily",
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
                        l10n?.basedOnLast30Days ?? "Based on last 30 days",
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
                    avgDaily,
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
                      Icons.bolt_rounded,
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
                        l10n?.peakStreak ?? "Peak Streak",
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
                        l10n?.goalMetConsecutiveDays ??
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
                    peakStreak,
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
      },
    );
  }

  Widget buildQuarterlyBreakDown() {
    return BlocBuilder<DataAnalyticsCubit, DataAnalyticsState>(
      builder: (context, state) {
        final distribution =
            state.analyticsData?['weeklyDistribution'] as List?;
        if (distribution == null || distribution.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.quarterlyBreakdown ??
                  "Quarterly Breakdown",
              style: TextStyle(
                color: AppColors.color_4D758B,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_18,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
            SizedBox(height: 8.h),
            ...List.generate(distribution.length, (index) {
              final qData = distribution[index];
              final double target =
                  double.tryParse(qData['target'].toString()) ?? 0.0;
              final double scheduled =
                  double.tryParse(qData['scheduled'].toString()) ?? 0.0;
              final double offSlot =
                  double.tryParse(qData['offSlot'].toString()) ?? 0.0;
              final double consumed = scheduled + offSlot;
              final double percent =
                  target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

              return Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.dim12.h),
                child: buildQuarterlyItems(
                  quarterNumber: index,
                  consumed: consumed,
                  percent: percent,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget buildQuarterlyItems(
      {required int quarterNumber,
      required double consumed,
      required double percent}) {
    final l10n = AppLocalizations.of(context);
    String quarterTitle;
    String monthRange;

    switch (quarterNumber) {
      case 0:
        quarterTitle = l10n?.firstQuarter ?? "First Quarter";
        monthRange = l10n?.januaryToMarch ?? "January to March";
        break;
      case 1:
        quarterTitle = l10n?.secondQuarter ?? "Second Quarter";
        monthRange = l10n?.aprilToJune ?? "April to June";
        break;
      case 2:
        quarterTitle = l10n?.thirdQuarter ?? "Third Quarter";
        monthRange = l10n?.julyToSeptember ?? "July to September";
        break;
      case 3:
        quarterTitle = l10n?.fourthQuarter ?? "Fourth Quarter";
        monthRange = l10n?.octoberToDecember ?? "October to December";
        break;
      default:
        quarterTitle =
            "${l10n?.quarter ?? 'Quarter'} ${quarterNumber + 1}";
        monthRange = "";
    }

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
              percent: percent,
              linearGradient: const LinearGradient(
                colors: [
                  Color(0xFF0058BC),
                  Color(0xFF008284),
                ],
              ),
              backgroundColor: AppColors.white,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 3.w,
              animation: true,
              center: Text(
                "${(percent * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: AppColors.color_4D758B,
                  fontSize: AppFontStyles.fontSize_13,
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
                "${consumed.toStringAsFixed(1)}L",
                style: TextStyle(
                  color: AppColors.color_4D758B,
                  fontSize: AppFontStyles.fontSize_16,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
              ),
              Text(
                l10n?.goalReached ?? "Goal Reached",
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_12,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
