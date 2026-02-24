import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart'; // CustomYAxis
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart'; // CustomChartToolTip

class FlAreaChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
  final List<HydrationDaySummary> bottleData;

  const FlAreaChartWidget({
    super.key,
    required this.interval,
    required this.currentDate,
    required this.bottleData,
  });

  @override
  State<FlAreaChartWidget> createState() => _FlAreaChartWidgetState();
}

class _FlAreaChartWidgetState extends State<FlAreaChartWidget> {
  late List<ChartData> chartData;
  final ScrollController _scrollController = ScrollController();
  
  int? _touchedIndex;

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
    _updateChartData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_touchedIndex != null) {
      setState(() {});
    }
  }

  void _updateChartData() {
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isMonthly = widget.interval == FilterInterval.monthly;
    final isYearly = widget.interval == FilterInterval.yearly;

    final sorted = [...widget.bottleData]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (isWeekly) {
      DateTime weekStart = widget.currentDate
          .subtract(Duration(days: widget.currentDate.weekday - 1));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

      chartData = List.generate(7, (i) {
        final dayDate = weekStart.add(Duration(days: i));
        final matches = sorted.where(
          (x) =>
              x.date.year == dayDate.year &&
              x.date.month == dayDate.month &&
              x.date.day == dayDate.day,
        ).toList();

        double totalTarget = 0;
        double totalConsumed = 0;

        if (matches.isNotEmpty) {
          for (var m in matches) {
            totalTarget += m.target;
            totalConsumed += m.consumed;
          }
        }

        // If no matches, use default values
        final double target = totalTarget;
        final double consumed = totalConsumed;
        double percent = target > 0 ? (consumed / target) * 100 : 0;
        percent = percent.clamp(0, 100);

        //Console.log(tag: "IsWeeklyAreaChart", value: "$target $consumed $percent");
        return ChartData(
          weekLabels[i],
          percent,
          consumed,
          dayDate,
        );
      });
    } else if (isMonthly) {
      final year = widget.currentDate.year;
      final month = widget.currentDate.month;
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);
      final days = lastDay.day;

      chartData = List.generate(days, (i) {
        final dayDate = firstDay.add(Duration(days: i));
        final matches = sorted.where(
          (x) =>
              x.date.year == dayDate.year &&
              x.date.month == dayDate.month &&
              x.date.day == dayDate.day,
        ).toList();

        double totalTarget = 0;
        double totalConsumed = 0;

        if (matches.isNotEmpty) {
          for (var m in matches) {
            totalTarget += m.target;
            totalConsumed += m.consumed;
          }
        }

        final double target = totalTarget;
        final double consumed = totalConsumed;
        double percent = target > 0 ? (consumed / target) * 100 : 0;
        percent = percent.clamp(0, 100);

        return ChartData((i + 1).toString(), percent, consumed, dayDate);
      });
    } else if (isYearly) {
      final year = widget.currentDate.year;
      final inYear = sorted.where((x) => x.date.year == year).toList();

      chartData = List.generate(12, (i) {
        final monthIndex = i + 1;
        final list = inYear.where((x) => x.date.month == monthIndex).toList();
        double target = 0;
        double consumed = 0;
        for (var e in list) {
          target += e.target;
          consumed += e.consumed;
        }

        double percent = target > 0 ? (consumed / target) * 100 : 0;
        percent = percent.clamp(0, 100);

        Console.log(tag: "IsYearlyAreaChart", value: "$target $consumed $percent");

        final dateForPoint =
            list.isNotEmpty ? list.first.date : DateTime(year, monthIndex, 1);

        return ChartData(monthLabels[i], percent, consumed, dateForPoint);
      });
    } else {
      chartData = [];
    }

    _touchedIndex = null;
  }

  @override
  void didUpdateWidget(covariant FlAreaChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval ||
        oldWidget.currentDate != widget.currentDate ||
        oldWidget.bottleData != widget.bottleData) {
      _updateChartData();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = widget.interval == FilterInterval.weekly;
    double pointWidth = 50.w;
    final chartWidth = isWeekly
        ? AppDimensions.dim365.w
        : pointWidth * (chartData.isEmpty ? 1 : chartData.length);
    final expandedWidth = AppDimensions.dim365.w - AppDimensions.dim40.w;
    final drawingWidth = isWeekly ? expandedWidth - AppDimensions.dim9.w : chartWidth - AppDimensions.dim9.w - (pointWidth / 2);
    final drawingHeight = AppDimensions.dim262.h - AppDimensions.dim9.h - 32.h;

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
                  children: [
                    SizedBox(
                      width: AppDimensions.dim40.w,
                      height: AppDimensions.dim265.h,
                      child: const CustomYAxis(maxY: 100, divisions: 5),
                    ),
                    Expanded(
                      child: isWeekly
                          ? Container(
                              width: chartWidth,
                              padding: EdgeInsets.only(
                                left: AppDimensions.dim9.w,
                                top: AppDimensions.dim9.h,
                              ),
                              child: _buildAreaChart(chartWidth, isWeekly),
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              child: Container(
                                width: chartWidth,
                                padding: EdgeInsets.only(
                                  left: AppDimensions.dim9.w,
                                  right: pointWidth / 2,
                                  top: AppDimensions.dim9.h,
                                ),
                                child: _buildAreaChart(chartWidth, isWeekly),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (_touchedIndex != null)
              Positioned(
                left: () {
                  double localX;
                  if (chartData.length > 1) {
                    localX = (_touchedIndex! / (chartData.length - 1)) * drawingWidth;
                  } else {
                    localX = 0;
                  }
                  
                  double left = AppDimensions.dim40.w +
                      AppDimensions.dim14.w +
                      localX;
                  
                  if (!isWeekly && _scrollController.hasClients) {
                    left -= _scrollController.offset;
                  }
                  // Center the tooltip (width is 55.w)
                  return left - (AppDimensions.dim55.w / 2);
                }(),
                top: () {
                  final data = chartData[_touchedIndex!];
                  double percent = data.completionPercent;
                  // Map percent 0-100 to 0-drawingHeight (top to bottom)
                  double localY = (1 - (percent / 100)) * drawingHeight;
                  
                  // The chart container is at the bottom of the 324.h stack with height 262.h
                  // So the chart content starts at 324.h - 262.h = 62.h
                  // Plus the internal padding top of 9.h
                  double chartTopOffset = 62.h + AppDimensions.dim9.h;
                  // Put the tooltip above the point (tooltip height is 55.h)
                  // Added extra 5.h gap (approx 10% of tooltip height)
                  return chartTopOffset + localY - AppDimensions.dim55.h - 15.h;
                }(),
                child: _buildTooltip(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    final data = chartData[_touchedIndex!];
    final liters = (data.completionVolume ?? 0) / 1000;

    return CustomChartToolTip(
      isPercent: false,
      percent: num.parse(liters.toStringAsFixed(2)),
    );
  }

  Widget _buildAreaChart(double chartWidth, bool isWeekly) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= chartData.length) return const SizedBox();
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    chartData[index].x,
                    style: TextStyle(
                      color: AppColors.black,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_14,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                );
              },
              reservedSize: 32.h,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchSpotThreshold: 5,
          touchCallback: (event, response) {
            if (response != null &&
                response.lineBarSpots != null &&
                response.lineBarSpots!.isNotEmpty) {
              final spot = response.lineBarSpots!.first;
              if (spot.y != 0) {
                setState(() {
                  _touchedIndex = spot.spotIndex;
                });
              }
            } else {
              setState(() {
                _touchedIndex = null;
              });
            }
          },
          handleBuiltInTouches: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.transparent,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(chartData.length, (i) {
              return FlSpot(i.toDouble(), chartData[i].completionPercent);
            }),
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: const Color(0xFF42A5FF),
            barWidth: 3.w,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = _touchedIndex == index;
                return FlDotCirclePainter(
                  radius: isSelected ? 6.w : 4.w,
                  color: Colors.white,
                  strokeWidth: isSelected ? 4.w : 3.w,
                  strokeColor: const Color(0xFF42A5FF),
                );
              },
              checkToShowDot: (spot, barData) {
                // Show dot only if y != 0
                return spot.y != 0;
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF42A5FF).withValues(alpha: 0.4),
                  const Color(0xFF42A5FF).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}