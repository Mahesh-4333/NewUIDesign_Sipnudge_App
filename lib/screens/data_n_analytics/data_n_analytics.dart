import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/screens/widgets/chart_widgets/custom_stacked_bar_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum MonthGoalCompletionStatus { Completed, Partial, NotFinished }

class DataNAnalyticsScreen extends StatefulWidget {
  const DataNAnalyticsScreen({super.key});

  @override
  State<DataNAnalyticsScreen> createState() => _DataNAnalyticsScreenState();
}

class _DataNAnalyticsScreenState extends State<DataNAnalyticsScreen> {
  bool isMonthlyAnalyticsSelected = false;
  bool isMonthGridExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _getAppBarWidget(),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: AppDimensions.dim100.h,
          ),
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
                buildMonthlyIntakeCard(.2),
                SizedBox(
                  height: 16.h,
                ),
                buildDistributionCard(),
                SizedBox(
                  height: 16.h,
                ),
                buildHabitConsistencyCard()
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _getAppBarWidget() {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      forceMaterialTransparency: true,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
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
            onPressed: () {},
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
                setState(() {
                  isMonthlyAnalyticsSelected = true;
                });
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
                setState(() {
                  isMonthlyAnalyticsSelected = false;
                });
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
  }

  Widget buildMonthGrid() {
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.all(0),
                  icon: Icon(Icons.chevron_left,
                      size: 28, color: AppColors.steelblue),
                ),
                Text(
                  "2025",
                  style: TextStyle(
                      color: AppColors.steelblue,
                      fontSize: AppFontStyles.fontSize_16,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [
                        AppFontStyles.boldFontVariation,
                      ]),
                ),
                SizedBox(width: AppDimensions.dim48.w),
              ],
            ),
            SizedBox(
              height: 12.h,
            ),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: months.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: 3.2,
              ),
              itemBuilder: (context, index) {
                MonthGoalCompletionStatus status =
                    MonthGoalCompletionStatus.Completed;

                return buildMonth(index, status, months[index]);
              },
            ),
            Divider(color: AppColors.color_136DEC0D),
            SizedBox(
              height: 16.h,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppDimensions.dim16.w,
              children: [
                buildLegendItem(AppColors.lightBlue400, "Goal Met"),
                buildLegendItem(AppColors.color_136DEC0D, "Partial")
              ],
            )
          ],
        ));
  }

  Widget buildMonthlyIntakeCard(double percentCompletion) {
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
          Container(
            alignment: Alignment.topLeft,
            child: Text(
              "${isMonthlyAnalyticsSelected ? "Monthly Intake" : "Quaterly Intake"}: Feb, 2026",
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
                  isMonthlyAnalyticsSelected
                      ? "MONTHLY GOAL"
                      : "ANNUAL PERFORMANCE",
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
  }

  Widget buildDistributionCard() {
    final List<ChartData> myData = [
      ChartData(backgroundValue: 100, foregroundValue: 50, label: "W - 1"),
      ChartData(backgroundValue: 95, foregroundValue: 30, label: "W - 2"),
      ChartData(backgroundValue: 80, foregroundValue: 60, label: "W - 3"),
      ChartData(backgroundValue: 85, foregroundValue: 40, label: "W - 4"),
    ];
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                      isMonthlyAnalyticsSelected
                          ? "Weekly Distribution"
                          : "Quarterly Distribution",
                      style: TextStyle(
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_18,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
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
                        fontVariations: [AppFontStyles.regularFontVariation],
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                        color: AppColors.color_F0FDF4,
                        borderRadius: BorderRadius.circular(360)),
                    child: Text(
                      "+12% vs last month",
                      style: TextStyle(
                        color: AppColors.color_16A34A,
                        fontSize: AppFontStyles.fontSize_10,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
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
}
