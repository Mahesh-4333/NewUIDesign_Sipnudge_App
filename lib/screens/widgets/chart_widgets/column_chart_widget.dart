import 'package:hydrify/helpers/logger.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';

class FlColumnChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
  // NOTE: this is now HydrationDaySummary
  final List<HydrationDaySummary> bottleData;

  const FlColumnChartWidget({
    super.key,
    required this.interval,
    required this.currentDate,
    required this.bottleData,
  });

  @override
  State<FlColumnChartWidget> createState() => _FlColumnChartWidgetState();
}

class _FlColumnChartWidgetState extends State<FlColumnChartWidget> {
  List<ChartData> chartData = [];
  double maxY = 100;
  double? currentUserGoal;
  final ScrollController _scrollController = ScrollController();

  double barWidth = AppDimensions.dim35.w; // default bar width
  double barSpacing = 16.w; // spacing between bars

  Offset? tappedIndexOffset;
  ChartData? tooltipData;
  int? tappedIndex;

  final List<String> weekLabels = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  final List<String> monthLabels = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _updateChartData(); // Initialize sync first
    _loadUserGoal().then((_) {
      _updateChartData();
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadUserGoal() async {
    final goal = await SharedPrefsHelper.getUserGoal();
    if (goal != null) {
      currentUserGoal = goal.toDouble();
    }
  }

  void _updateChartData() {
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isMonthly = widget.interval == FilterInterval.monthly;
    final isYearly = widget.interval == FilterInterval.yearly;

    final sorted = [...widget.bottleData]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (isWeekly) {
      // --- WEEKLY: 7 days Mon–Sun ---
      DateTime weekStart = widget.currentDate
          .subtract(Duration(days: widget.currentDate.weekday - 1));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

      chartData = List.generate(7, (i) {
        final dayDate = weekStart.add(Duration(days: i));

        final matches = sorted
            .where(
              (x) =>
                  x.date.year == dayDate.year &&
                  x.date.month == dayDate.month &&
                  x.date.day == dayDate.day,
            )
            .toList();

        double totalTarget = 0;
        double totalConsumed = 0;

        if (matches.isNotEmpty) {
          for (var m in matches) {
            totalTarget += m.target;
            totalConsumed += m.consumed;
          }
        }

        final double target;
        final now = DateTime.now();
        final isToday = dayDate.year == now.year &&
            dayDate.month == now.month &&
            dayDate.day == now.day;

        if (isToday && currentUserGoal != null) {
          target = currentUserGoal!;
        } else {
          target = totalTarget;
        }

        final double consumed = totalConsumed;
        double percent = target > 0 ? (consumed / target) * 100 : 0;

        return ChartData(weekLabels[i], percent, consumed, dayDate);
      });
    } else if (isMonthly) {
      // --- MONTHLY: 1..lastDayOfMonth ---
      final year = widget.currentDate.year;
      final month = widget.currentDate.month;

      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);
      final days = lastDay.day;

      chartData = List.generate(days, (i) {
        final dayDate = firstDay.add(Duration(days: i));

        final matches = sorted
            .where(
              (x) =>
                  x.date.year == dayDate.year &&
                  x.date.month == dayDate.month &&
                  x.date.day == dayDate.day,
            )
            .toList();

        double totalTarget = 0;
        double totalConsumed = 0;

        if (matches.isNotEmpty) {
          for (var m in matches) {
            totalTarget += m.target;
            totalConsumed += m.consumed;
          }
        }

        final double target;
        final now = DateTime.now();
        final isToday = dayDate.year == now.year &&
            dayDate.month == now.month &&
            dayDate.day == now.day;

        if (isToday && currentUserGoal != null) {
          target = currentUserGoal!;
        } else {
          target = totalTarget;
        }

        final double consumed = totalConsumed;
        double percent = target > 0 ? (consumed / target) * 100 : 0;

        return ChartData(
            (i + 1).toString(), // 1,2,3,...
            percent,
            consumed,
            dayDate);
      });
    } else if (isYearly) {
      // --- YEARLY: 12 months Jan..Dec ---
      final year = widget.currentDate.year;
      final inYear = sorted.where((x) => x.date.year == year).toList();

      chartData = List.generate(12, (i) {
        final monthIndex = i + 1;
        final list = inYear.where((x) => x.date.month == monthIndex).toList();

        double target = 0;
        double consumed = 0;
        final now = DateTime.now();

        for (var e in list) {
          if (e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day) {
            target += currentUserGoal ?? e.target;
          } else {
            target += e.target;
          }
          consumed += e.consumed;
        }

        double percent = target > 0 ? (consumed / target) * 100 : 0;
        final dateForPoint =
            list.isNotEmpty ? list.first.date : DateTime(year, monthIndex, 1);
        return ChartData(monthLabels[i], percent, consumed, dateForPoint);
      });
    } else {
      chartData = [];
    }

    double maxP = 0;
    if (chartData.isNotEmpty) {
      maxP = chartData
          .map((e) => e.completionPercent)
          .reduce((a, b) => a > b ? a : b);
    }
    maxY = maxP > 100 ? (maxP / 20).ceil() * 20.0 : 100.0;

    // ignore: avoid_print
    print(
        "DEBUG [Column]: Interval=${widget.interval}, ChartData length=${chartData.length}");
  }

  @override
  void didUpdateWidget(covariant FlColumnChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval ||
        oldWidget.currentDate != widget.currentDate ||
        oldWidget.bottleData != widget.bottleData) {
      _updateChartData(); // Update sync first
      _loadUserGoal().then((_) {
        _updateChartData();
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = widget.interval == FilterInterval.weekly;

    // Calculate chart width
    final rawChartWidth = (barWidth + barSpacing) * chartData.length;
    final chartWidth = isWeekly
        ? AppDimensions.dim365.w
        : (rawChartWidth < AppDimensions.dim365.w
            ? AppDimensions.dim365.w
            : rawChartWidth);

    // Adjust bar width for weekly to fit 7 bars
    if (isWeekly) {
      final availableWidth = AppDimensions.dim365.w;
      barWidth = (availableWidth - (6 * 10.w)) / 7; // 7 bars + 6 spaces
      barSpacing = 10.w;
    }

    return Container(
      color: Colors.transparent,
      width: double.maxFinite,
      height: AppDimensions.dim320.h,
      child: SizedBox(
        width: double.maxFinite,
        height: 324.h,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: AppDimensions.dim365.w,
                height: AppDimensions.dim262.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppDimensions.dim40.w,
                      height: AppDimensions.dim265.h,
                      child: CustomYAxis(maxY: maxY, divisions: 5),
                    ),
                    Expanded(
                      child: isWeekly
                          ? SizedBox(
                              width: chartWidth,
                              height: AppDimensions.dim272.h,
                              child: _buildBarChart(),
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              child: SizedBox(
                                width: chartWidth,
                                height: AppDimensions.dim272.h,
                                child: _buildBarChart(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (tappedIndexOffset != null && tooltipData != null)
              Positioned(
                left: (tappedIndexOffset?.dx ?? 0) -
                    (_scrollController.hasClients
                        ? _scrollController.offset
                        : 0) +
                    15,
                top: (tappedIndexOffset?.dy ?? 0),
                child: CustomChartToolTip(
                  percent: int.parse(
                      tooltipData!.completionPercent.toStringAsFixed(0)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        groupsSpace: barSpacing,
        maxY: maxY,
        barTouchData: _buildBarTouchData(),
        titlesData: _buildTitles(),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(chartData.length, (index) {
          final isSelected = tappedIndex == index;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: chartData[index].completionPercent,
                color: isSelected
                    ? const Color(0XFF369FFF)
                    : const Color(0XFF369FFF).withOpacity(0.48),
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radius_100),
                  topRight: Radius.circular(AppDimensions.radius_100),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.red,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 0,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem('', const TextStyle(color: Colors.transparent));
        },
      ),
      touchCallback: (event, response) {
        if (event.isInterestedForInteractions &&
            response != null &&
            response.spot != null) {
          setState(() {
            tooltipData = chartData[response.spot?.touchedBarGroupIndex ?? 0];
            tappedIndex = response.spot!.touchedBarGroupIndex;
            tappedIndexOffset = response.spot!.offset;

            Console.log(tag: "APP", value: "X - ${tappedIndexOffset?.dx}");
            Console.log(tag: "APP", value: "Y - ${tappedIndexOffset?.dy}");
          });
        } else {
          setState(() {
            tappedIndex = null;
            tappedIndexOffset = null;
          });
        }
      },
    );
  }

  FlTitlesData _buildTitles() {
    final isWeekly = widget.interval == FilterInterval.weekly;

    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, _) {
            int index = value.toInt();
            if (index < 0 || index >= chartData.length) {
              return const SizedBox();
            }

            final label = isWeekly ? weekLabels[index] : chartData[index].x;

            return Padding(
              padding: EdgeInsets.only(top: AppDimensions.dim5.h),
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.black,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_14,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
          reservedSize: AppDimensions.dim40.w,
          getTitlesWidget: (value, _) => Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Text(
              "${value.toInt()}%",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: AppColors.white,
                fontSize: AppFontStyles.fontSize_14,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ),
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

class CustomYAxis extends StatelessWidget {
  final double maxY;
  final int divisions;

  const CustomYAxis({
    super.key,
    this.maxY = 100,
    this.divisions = 5,
  });

  @override
  Widget build(BuildContext context) {
    final step = maxY ~/ divisions;

    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.dim20.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(divisions + 1, (i) {
          final value = maxY - (i * step);
          return Text(
            "${value.toInt()}%",
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: AppColors.black,
              fontSize: AppFontStyles.fontSize_14,
              fontVariations: [AppFontStyles.semiBoldFontVariation],
            ),
          );
        }),
      ),
    );
  }
}
