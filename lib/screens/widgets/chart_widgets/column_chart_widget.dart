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
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';
import 'package:hydrify/services/sync_bus.dart';

class FlColumnChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
  // NOTE: this is now HydrationDaySummary
  final List<HydrationDaySummary> bottleData;
  final List<Map<String, dynamic>>? manualLogs;

  const FlColumnChartWidget({
    super.key,
    required this.interval,
    required this.currentDate,
    required this.bottleData,
    this.manualLogs,
  });

  @override
  State<FlColumnChartWidget> createState() => _FlColumnChartWidgetState();
}

class _FlColumnChartWidgetState extends State<FlColumnChartWidget> {
  List<ChartData> chartData = [];
  double maxY = 100;
  double? currentUserGoal;
  List<Map<String, dynamic>> _allLogs = [];
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
    SyncBus.instance.addListener(_onSyncComplete);
    _initLogsAndGoal().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
    });
  }

  Future<void> _initLogsAndGoal() async {
    final goal = await SharedPrefsHelper.getUserGoal();
    if (goal != null) {
      currentUserGoal = goal.toDouble();
    }
    if (widget.manualLogs != null && widget.manualLogs!.isNotEmpty) {
      _allLogs = widget.manualLogs!;
    } else {
      // Fast local SQLite query
      try {
        final dbHelper = DatabaseHelper();
        _allLogs = await dbHelper.getHydrationLogs();
      } catch (e) {
        Console.log(
            tag: "ColumnChart", value: "Failed to fetch local hydration logs: $e");
      }
    }
    _updateChartData();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SyncBus.instance.removeListener(_onSyncComplete);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSyncComplete() {
    if (!mounted) return;
    _initLogsAndGoal();
  }

  void _scrollToToday() {
    if (!mounted) return;
    final today = DateTime.now();
    int? targetIndex;

    if (widget.interval == FilterInterval.monthly) {
      if (widget.currentDate.year == today.year &&
          widget.currentDate.month == today.month) {
        targetIndex = today.day - 1; // 0-based index for today
      }
    } else if (widget.interval == FilterInterval.yearly) {
      if (widget.currentDate.year == today.year) {
        targetIndex = today.month - 1; // 0-based index for current month
      }
    }

    if (targetIndex == null) return;

    final double barTotalWidth = barWidth + barSpacing;
    final double positionOfBarEnd =
        (targetIndex + 1) * barTotalWidth - barSpacing;
    final viewportWidth = AppDimensions.dim365.w - AppDimensions.dim40.w;

    double targetOffset = positionOfBarEnd - viewportWidth + 30.w;
    if (targetOffset < 0) targetOffset = 0;

    final double maxScroll = (chartData.length * barTotalWidth) - viewportWidth;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  double _getLoggedAmount(List<Map<String, dynamic>> logs, DateTime date,
      List<String> types, FilterInterval interval) {
    double total = 0.0;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    for (var log in logs) {
      try {
        final String? localDate = log['localDate'] as String?;
        final String? rawTs = log['timestamp'] as String?;

        bool isMatch = false;

        if (localDate != null && localDate.length >= 10) {
          final cleanLocalDate = localDate.substring(0, 10);
          if (interval == FilterInterval.yearly) {
            final parts = cleanLocalDate.split('-');
            if (parts.length >= 2) {
              isMatch = int.parse(parts[0]) == date.year &&
                  int.parse(parts[1]) == date.month;
            }
          } else {
            isMatch = cleanLocalDate == dateStr;
          }
        } else if (rawTs != null &&
            !rawTs.endsWith('Z') &&
            rawTs.length >= 10) {
          // SQLite local time string (e.g. "2026-08-11T08:57:00.000000")
          final cleanLocalDate = rawTs.substring(0, 10);
          if (interval == FilterInterval.yearly) {
            final parts = cleanLocalDate.split('-');
            if (parts.length >= 2) {
              isMatch = int.parse(parts[0]) == date.year &&
                  int.parse(parts[1]) == date.month;
            }
          } else {
            isMatch = cleanLocalDate == dateStr;
          }
        } else if (rawTs != null) {
          // Fallback for old logs with UTC/Z timestamps and no localDate
          final logTime = DateTime.parse(rawTs).toLocal();
          if (interval == FilterInterval.yearly) {
            isMatch = logTime.year == date.year && logTime.month == date.month;
          } else {
            isMatch = logTime.year == date.year &&
                logTime.month == date.month &&
                logTime.day == date.day;
          }
        }

        if (isMatch) {
          final type = log['type'] as String;
          if (types.contains(type)) {
            total += (log['consumed'] as num).toDouble();
          }
        }
      } catch (_) {}
    }
    return total;
  }

  void _updateChartData() {
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isMonthly = widget.interval == FilterInterval.monthly;
    final isYearly = widget.interval == FilterInterval.yearly;

    final sorted = [...widget.bottleData]
      ..sort((a, b) => a.date.compareTo(b.date));

    ChartData buildChartDataForDate(String xLabel, DateTime dayDate,
        double totalTarget, double totalConsumed) {
      final double target;
      final now = DateTime.now();
      final isToday = dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;

      if (totalTarget > 0) {
        target = totalTarget;
      } else if (isToday && currentUserGoal != null) {
        target = currentUserGoal!;
      } else {
        target = 2500;
      }

      final double consumed = totalConsumed;
      double percent = target > 0 ? (consumed / target) * 100 : 0;

      // Logged breakdown:
      double loggedWater =
          _getLoggedAmount(_allLogs, dayDate, ['Water'], widget.interval);
      double loggedMilk =
          _getLoggedAmount(_allLogs, dayDate, ['Milk'], widget.interval);
      double loggedCoffee =
          _getLoggedAmount(_allLogs, dayDate, ['Coffee'], widget.interval);
      double loggedTea =
          _getLoggedAmount(_allLogs, dayDate, ['Tea'], widget.interval);
      double loggedJuice =
          _getLoggedAmount(_allLogs, dayDate, ['Juice'], widget.interval);

      double loggedWaterAmt = loggedWater * 1.0;
      double loggedMilkAmt = loggedMilk * 1.5;
      double loggedCoffeeAmt =
          loggedCoffee * 0.8 + loggedTea * 0.85 + loggedJuice * 0.9;

      double totalLoggedAmt = loggedWaterAmt + loggedMilkAmt + loggedCoffeeAmt;
      double bottleAmt = consumed - totalLoggedAmt;
      if (bottleAmt < 0) bottleAmt = 0.0;

      double loggedPercent = target > 0 ? (loggedWaterAmt / target) * 100 : 0;
      double milkPercent = target > 0 ? (loggedMilkAmt / target) * 100 : 0;
      double coffeePercent = target > 0 ? (loggedCoffeeAmt / target) * 100 : 0;
      double bottlePercent = target > 0 ? (bottleAmt / target) * 100 : 0;

      double totalPercent =
          loggedPercent + milkPercent + coffeePercent + bottlePercent;
      if (percent > 0 && totalPercent > 0) {
        double scale = percent / totalPercent;
        loggedPercent *= scale;
        milkPercent *= scale;
        coffeePercent *= scale;
        bottlePercent *= scale;
      }

      return ChartData(
        xLabel,
        percent,
        consumed,
        dayDate,
        loggedPercent: loggedPercent,
        milkPercent: milkPercent,
        coffeePercent: coffeePercent,
        bottlePercent: bottlePercent,
      );
    }

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

        return buildChartDataForDate(
            weekLabels[i], dayDate, totalTarget, totalConsumed);
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

        return buildChartDataForDate(
            (i + 1).toString(), dayDate, totalTarget, totalConsumed);
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
            target += e.target > 0 ? e.target : (currentUserGoal ?? 2500);
          } else {
            target += e.target > 0 ? e.target : 2500;
          }
          consumed += e.consumed;
        }

        final dateForPoint =
            list.isNotEmpty ? list.first.date : DateTime(year, monthIndex, 1);

        return buildChartDataForDate(
            monthLabels[i], dateForPoint, target, consumed);
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
        oldWidget.bottleData != widget.bottleData ||
        oldWidget.manualLogs != widget.manualLogs) {
      if (widget.manualLogs != null && widget.manualLogs!.isNotEmpty) {
        _allLogs = widget.manualLogs!;
      }
      _updateChartData();
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
      }
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.transparent,
          width: double.maxFinite,
          height: 300.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: AppDimensions.dim272.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: AppDimensions.dim40.w,
                      height: AppDimensions.dim272.h,
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
              if (tappedIndexOffset != null && tooltipData != null)
                Positioned(
                  left: AppDimensions.dim40.w +
                      (tappedIndexOffset?.dx ?? 0) -
                      (_scrollController.hasClients
                          ? _scrollController.offset
                          : 0) -
                      (AppDimensions.dim48.w / 2),
                  top: (() {
                    const double topOffset = 58.0;
                    final double drawableHeight = AppDimensions.dim272.h - 40.h;
                    final double barTopY = (topOffset * 0.4.h) +
                        drawableHeight -
                        ((tooltipData!.completionPercent / maxY) *
                            drawableHeight);
                    return barTopY - AppDimensions.dim55.h + 4.h;
                  })(),
                  child: CustomChartToolTip(
                    percent: int.parse(
                        tooltipData!.completionPercent.toStringAsFixed(0)),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(const Color(0xFF3B82F6), "BOTTLE"),
            SizedBox(width: 16.w),
            _buildLegendItem(const Color(0xFF93C5FD), "LOGGED"),
            SizedBox(width: 16.w),
            _buildLegendItem(const Color(0xFFB45309), "COFFEE"),
            SizedBox(width: 16.w),
            _buildLegendItem(const Color(0xFFE2E8F0), "MILK"),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: 11.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.semiBoldFontVariation],
          ),
        ),
      ],
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
          final item = chartData[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.completionPercent,
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radius_100),
                  topRight: Radius.circular(AppDimensions.radius_100),
                ),
                rodStackItems: _buildStackItems(item),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<BarChartRodStackItem> _buildStackItems(ChartData item) {
    final double segment1 = item.loggedPercent;
    final double segment2 = item.milkPercent;
    final double segment3 = item.coffeePercent;
    final double segment4 = item.bottlePercent;

    final List<BarChartRodStackItem> stackItems = [];
    double currentY = 0.0;

    if (segment1 > 0) {
      stackItems.add(BarChartRodStackItem(
          currentY,
          (currentY + segment1).clamp(0.0, maxY),
          const Color(0xFF93C5FD))); // LOGGED (light blue)
      currentY += segment1;
    }
    if (segment2 > 0) {
      stackItems.add(BarChartRodStackItem(
          currentY,
          (currentY + segment2).clamp(0.0, maxY),
          const Color(0xFFE2E8F0))); // MILK (grey)
      currentY += segment2;
    }
    if (segment3 > 0) {
      stackItems.add(BarChartRodStackItem(
          currentY,
          (currentY + segment3).clamp(0.0, maxY),
          const Color(0xFFB45309))); // COFFEE (brown)
      currentY += segment3;
    }
    if (segment4 > 0) {
      stackItems.add(BarChartRodStackItem(
          currentY,
          (currentY + segment4).clamp(0.0, maxY),
          const Color(0xFF3B82F6))); // BOTTLE (dark blue)
      currentY += segment4;
    }

    // Fallback if there is total percentage but stack is empty (e.g. legacy data without beverage breakups)
    if (stackItems.isEmpty && item.completionPercent > 0) {
      stackItems.add(BarChartRodStackItem(0.0,
          item.completionPercent.clamp(0.0, maxY), const Color(0xFF3B82F6)));
    }

    return stackItems;
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

  bool _isToday(int index) {
    if (index < 0 || index >= chartData.length) return false;
    final itemDate = chartData[index].date;
    final now = DateTime.now();

    if (widget.interval == FilterInterval.yearly) {
      return itemDate.year == now.year && itemDate.month == now.month;
    } else {
      return itemDate.year == now.year &&
          itemDate.month == now.month &&
          itemDate.day == now.day;
    }
  }

  FlTitlesData _buildTitles() {
    final isWeekly = widget.interval == FilterInterval.weekly;

    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36.h,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index < 0 || index >= chartData.length) {
              return const SizedBox();
            }

            final label = isWeekly ? weekLabels[index] : chartData[index].x;
            final isToday = _isToday(index);

            return SideTitleWidget(
              meta: meta,
              space: 4.h,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(
                      color: isToday
                          ? AppColors.blueWaterIntake
                          : Colors.transparent,
                      width: 1.2.w,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.black,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_14,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      height: 1.0,
                    ),
                  ),
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
      padding: EdgeInsets.only(bottom: 30.h),
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
