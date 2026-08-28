import 'dart:math' as math;
import 'package:hydrify/helpers/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/models/food_scan_data.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:intl/intl.dart';

class FlColumnChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
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
  List<Map<String, dynamic>> _foodScans = [];
  final ScrollController _scrollController = ScrollController();

  String? _selectedCategory; // null = all visible, or 'BOTTLE', 'COFFEE', etc.

  int _carouselIndex = 1; // Default to JUICE
  static const int _kCarouselLoop = 1000;
  late final PageController _legendPageController;

  final List<Map<String, dynamic>> _carouselCategories = [
    {
      'label': 'TEA',
      'icon': AssetsPath.logHydrationTea,
    },
    {
      'label': 'JUICE',
      'icon': AssetsPath.logHydrationJuice,
    },
    {
      'label': 'MILK',
      'icon': AssetsPath.logHydrationMilk,
    },
    {
      'label': 'COFFEE',
      'icon': AssetsPath.logHydrationCoffee,
    },
    {
      'label': 'MEAL',
      'icon': AssetsPath.logHydrationMeal,
    },
    {
      'label': 'BOTTLE',
      'icon': AssetsPath.logHydrationBottle,
    },
    {
      'label': 'LOGGED',
      'icon': AssetsPath.logHydrationLogged,
    },
  ];

  double barWidth = AppDimensions.dim35.w;
  double barSpacing = 16.w;

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
    _legendPageController = PageController(
      initialPage:
          (_kCarouselLoop * _carouselCategories.length) + _carouselIndex,
      viewportFraction: 0.333,
    );
    _selectedCategory = _carouselCategories[_carouselIndex]['label'];
    SyncBus.instance.addListener(_onSyncComplete);
    _updateChartData();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToToday(animated: false));
    _initLogsAndGoal().then((_) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToToday(animated: true));
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
      try {
        final dbHelper = DatabaseHelper();
        _allLogs = await dbHelper.getHydrationLogs();
      } catch (e) {
        Console.log(
            tag: "ColumnChart",
            value: "Failed to fetch local hydration logs: $e");
      }
    }
    try {
      final dbHelper = DatabaseHelper();
      _foodScans = await dbHelper.getAllFoodScans();
    } catch (e) {
      Console.log(tag: "ColumnChart", value: "Failed to fetch food scans: $e");
    }
    _updateChartData();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _legendPageController.dispose();
    SyncBus.instance.removeListener(_onSyncComplete);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSyncComplete() {
    if (!mounted) return;
    _initLogsAndGoal();
  }

  double _getItemColumnWidth() {
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isMonthly = widget.interval == FilterInterval.monthly;
    if (isWeekly) return barWidth + 8.w;
    if (isMonthly) return barWidth + 8.w;
    return barWidth + 10.w;
  }

  void _scrollToToday({bool animated = true}) {
    if (!mounted) return;
    final today = DateTime.now();
    int? targetIndex;

    if (widget.interval == FilterInterval.monthly) {
      if (widget.currentDate.year == today.year &&
          widget.currentDate.month == today.month) {
        targetIndex = today.day - 1;
      }
    } else if (widget.interval == FilterInterval.yearly) {
      if (widget.currentDate.year == today.year) {
        targetIndex = today.month - 1;
      }
    }

    if (targetIndex == null) return;

    final double itemColumnWidth = _getItemColumnWidth();
    final double itemTotalWidth = itemColumnWidth + barSpacing;

    final double targetCenter =
        6.w + (targetIndex * itemTotalWidth) + (itemColumnWidth / 2);
    final double viewportWidth = AppDimensions.dim365.w - AppDimensions.dim40.w;

    double targetOffset = targetCenter - (viewportWidth / 2);
    if (targetOffset < 0) targetOffset = 0;

    final double maxScroll =
        (chartData.length * itemTotalWidth) - viewportWidth;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    }
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

  double _getLoggedAmount(List<Map<String, dynamic>> logs, DateTime date,
      List<String> types, FilterInterval interval) {
    double total = 0.0;
    final dateStr =
        '${date.year.toString().padLeft(4, "0")}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';

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

  double _getFoodScanAmount(List<Map<String, dynamic>> scans, DateTime date,
      List<String> types, FilterInterval interval) {
    double total = 0.0;
    final dateStr =
        '${date.year.toString().padLeft(4, "0")}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
    final lowerTypes = types.map((t) => t.toLowerCase()).toList();
    final bool isMealType = lowerTypes.contains('meal');

    for (var scan in scans) {
      try {
        final scanData = FoodScanData.fromMap(scan);
        final rawKey = (scanData.foodKey ?? 'Meal').trim().toLowerCase();

        bool keyMatches = false;
        if (isMealType) {
          keyMatches = rawKey == 'meal';
        } else {
          keyMatches = lowerTypes.contains(rawKey);
        }

        if (!keyMatches) continue;

        final String? rawTs =
            (scan['created_at'] ?? scan['timestamp']) as String?;
        if (rawTs == null) continue;

        bool isMatch = false;
        if (rawTs.length >= 10) {
          final cleanDate = rawTs.substring(0, 10);
          if (interval == FilterInterval.yearly) {
            final parts = cleanDate.split('-');
            if (parts.length >= 2) {
              isMatch = int.parse(parts[0]) == date.year &&
                  int.parse(parts[1]) == date.month;
            }
          } else {
            isMatch = cleanDate == dateStr;
          }
        }

        if (isMatch) {
          final waterMl =
              (scan['water_content_ml'] ?? scan['waterContentMl'] ?? 0) as num;
          total += waterMl.toDouble();
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

      double loggedWater = _getLoggedAmount(
              _allLogs, dayDate, ['Water'], widget.interval) +
          _getFoodScanAmount(_foodScans, dayDate, ['Water'], widget.interval);
      double loggedMilk = _getLoggedAmount(
              _allLogs, dayDate, ['Milk'], widget.interval) +
          _getFoodScanAmount(_foodScans, dayDate, ['Milk'], widget.interval);
      double loggedCoffee = _getLoggedAmount(
              _allLogs, dayDate, ['Coffee'], widget.interval) +
          _getFoodScanAmount(_foodScans, dayDate, ['Coffee'], widget.interval);
      double loggedTea =
          _getLoggedAmount(_allLogs, dayDate, ['Tea'], widget.interval) +
              _getFoodScanAmount(_foodScans, dayDate, ['Tea'], widget.interval);
      double loggedJuice = _getLoggedAmount(
              _allLogs, dayDate, ['Juice'], widget.interval) +
          _getFoodScanAmount(_foodScans, dayDate, ['Juice'], widget.interval);
      double loggedMeal =
          _getFoodScanAmount(_foodScans, dayDate, ['Meal'], widget.interval);

      double loggedWaterAmt = loggedWater * 1.0;
      double loggedMilkAmt = loggedMilk * 1.5;
      double loggedCoffeeAmt = loggedCoffee * 0.8;
      double loggedTeaAmt = loggedTea * 0.85;
      double loggedJuiceAmt = loggedJuice * 0.9;
      double loggedMealAmt = loggedMeal * 1.0;

      double totalLoggedAmt = loggedWaterAmt +
          loggedMilkAmt +
          loggedCoffeeAmt +
          loggedTeaAmt +
          loggedJuiceAmt +
          loggedMealAmt;

      double manualDrinksAmt = loggedWaterAmt +
          loggedMilkAmt +
          loggedCoffeeAmt +
          loggedTeaAmt +
          loggedJuiceAmt;

      double bottleAmt = totalConsumed - manualDrinksAmt;
      if (bottleAmt < 0) bottleAmt = 0.0;

      double consumed = bottleAmt + totalLoggedAmt;
      if (consumed < totalConsumed) consumed = totalConsumed;

      double percent = target > 0 ? (consumed / target) * 100 : 0;
      double loggedPercent = target > 0 ? (loggedWaterAmt / target) * 100 : 0;
      double milkPercent = target > 0 ? (loggedMilkAmt / target) * 100 : 0;
      double coffeePercent = target > 0 ? (loggedCoffeeAmt / target) * 100 : 0;
      double teaPercent = target > 0 ? (loggedTeaAmt / target) * 100 : 0;
      double juicePercent = target > 0 ? (loggedJuiceAmt / target) * 100 : 0;
      double mealPercent = target > 0 ? (loggedMealAmt / target) * 100 : 0;
      double bottlePercent = target > 0 ? (bottleAmt / target) * 100 : 0;

      double totalPercent = loggedPercent +
          milkPercent +
          coffeePercent +
          teaPercent +
          juicePercent +
          mealPercent +
          bottlePercent;
      if (percent > 0 && totalPercent > 0) {
        double scale = percent / totalPercent;
        loggedPercent *= scale;
        milkPercent *= scale;
        coffeePercent *= scale;
        teaPercent *= scale;
        juicePercent *= scale;
        mealPercent *= scale;
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
        teaPercent: teaPercent,
        juicePercent: juicePercent,
        mealPercent: mealPercent,
        bottlePercent: bottlePercent,
      );
    }

    if (isWeekly) {
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
      final year = widget.currentDate.year;

      chartData = List.generate(12, (i) {
        final month = i + 1;
        final matches = sorted
            .where((x) => x.date.year == year && x.date.month == month)
            .toList();

        double totalTarget = 0;
        double totalConsumed = 0;

        if (matches.isNotEmpty) {
          for (var m in matches) {
            totalTarget += m.target;
            totalConsumed += m.consumed;
          }
        }

        final dateForPoint = DateTime(year, month, 1);
        return buildChartDataForDate(
            monthLabels[i], dateForPoint, totalTarget, totalConsumed);
      });
    } else {
      chartData = [];
    }

    maxY = 100.0;
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
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToToday(animated: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isMonthly = widget.interval == FilterInterval.monthly;

    if (isWeekly) {
      final availableWidth = AppDimensions.dim365.w;
      barWidth = (availableWidth - (6 * 10.w)) / 7;
      barSpacing = 10.w;
    } else if (isMonthly) {
      barWidth = AppDimensions.dim35.w;
      barSpacing = 16.w;
    } else {
      barWidth = 24.w;
      barSpacing = 16.w;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.transparent,
          width: double.maxFinite,
          height: 330.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: AppDimensions.dim40.w,
                height: 280.h,
                child: CustomYAxis(maxY: maxY, divisions: 5),
              ),
              Expanded(
                child: isWeekly
                    ? SizedBox(
                        height: 330.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(chartData.length, (index) {
                            return Expanded(
                              child: Center(
                                child: _buildSingleBarColumn(index),
                              ),
                            );
                          }),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.hardEdge,
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: SizedBox(
                          height: 330.h,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(chartData.length, (index) {
                              final isLast = index == chartData.length - 1;
                              return Container(
                                margin: EdgeInsets.only(
                                    right: isLast ? 0 : barSpacing),
                                child: _buildSingleBarColumn(index),
                              );
                            }),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        _buildHorizontalIconsLegend(),
      ],
    );
  }

  Widget _buildSingleBarColumn(int index) {
    final item = chartData[index];
    final isToday = _isToday(index);
    final int displayPercent =
        int.parse(item.completionPercent.toStringAsFixed(0));
    final bool isSelectedBar = (tappedIndex == index) ||
        (tappedIndex == null && isToday && displayPercent > 0);
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isYearly = widget.interval == FilterInterval.yearly;

    final String label;
    final locale = Localizations.localeOf(context).toString();
    if (isWeekly) {
      label = DateFormat('E', locale).format(item.date);
    } else if (isYearly) {
      label = DateFormat('MMM', locale).format(item.date);
    } else {
      label = (index + 1).toString();
    }

    final double usableHeight = 220.h;
    final double barHeight = ((item.completionPercent / maxY) * usableHeight)
        .clamp(0.0, usableHeight);

    return GestureDetector(
      onTap: () {
        if (displayPercent <= 0) return;
        VibrationHelper.lightTap();
        setState(() {
          if (tappedIndex == index) {
            tappedIndex = null;
            tooltipData = null;
          } else {
            tappedIndex = index;
            tooltipData = item;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _getItemColumnWidth(),
        height: 280.h,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Stacked Bar Area
                barHeight <= 0
                    ? const SizedBox.shrink()
                    : _buildStackedBarSegments(
                        item, isToday, isSelectedBar, barHeight, usableHeight),
                // 2. Bottom Label Area
                SizedBox(
                  height: 36.h,
                  child: Center(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100.r),
                        border: Border.all(
                          color: isToday
                              ? AppColors.blueWaterIntake
                              : Colors.transparent,
                          width: 1.2.w,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
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
                  ),
                ),
              ],
            ),
            // Tooltip positioned above the bar
            if (tappedIndex == index && displayPercent > 0)
              Positioned(
                bottom: barHeight + 36.h + 2.h,
                child: CustomChartToolTip(
                  percent: displayPercent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedBarSegments(ChartData item, bool isTodayBar,
      bool isSelectedBar, double totalBarHeight, double usableHeight) {
    // List of active segments in order from bottom to top:
    final List<_BarSegmentData> segments = [];

    if (item.loggedPercent > 0) {
      segments.add(_BarSegmentData(
        category: 'LOGGED',
        percent: item.loggedPercent,
        color: const Color(0xFF96CAFF),
      ));
    }
    if (item.milkPercent > 0) {
      segments.add(_BarSegmentData(
        category: 'MILK',
        percent: item.milkPercent,
        color: const Color(0xFFD6E2EC),
      ));
    }
    if (item.teaPercent > 0) {
      segments.add(_BarSegmentData(
        category: 'TEA',
        percent: item.teaPercent,
        color: const Color(0xFFE07A4F),
      ));
    }
    if (item.coffeePercent > 0) {
      segments.add(_BarSegmentData(
        category: 'COFFEE',
        percent: item.coffeePercent,
        color: const Color(0xFF755850),
      ));
    }
    if (item.mealPercent > 0) {
      segments.add(_BarSegmentData(
        category: 'MEAL',
        percent: item.mealPercent,
        color: const Color(0xFFFFB800),
      ));
    }
    if (item.juicePercent > 0) {
      segments.add(_BarSegmentData(
        category: 'JUICE',
        percent: item.juicePercent,
        color: const Color(0xFF60D394),
      ));
    }
    if (item.bottlePercent > 0) {
      segments.add(_BarSegmentData(
        category: 'BOTTLE',
        percent: item.bottlePercent,
        color: const Color(0xFF2596FF),
      ));
    }

    if (segments.isEmpty && item.completionPercent > 0) {
      segments.add(_BarSegmentData(
        category: 'BOTTLE',
        percent: item.completionPercent,
        color: const Color(0xFF96CAFF),
      ));
    }

    final bool isTargetBar = isTodayBar || isSelectedBar;

    // Calculate segment heights and find elevated segment if any
    final List<double> segHeights = [];
    int elevatedIndex = -1;
    double elevatedBottomOffset = 0.0;
    double currentBottom = 0.0;

    final double effectiveTotalPercent = math.max(item.completionPercent, maxY);

    for (int i = 0; i < segments.length; i++) {
      final double h =
          ((segments[i].percent / effectiveTotalPercent) * usableHeight)
              .clamp(0.0, totalBarHeight);
      segHeights.add(h);

      if (isTargetBar &&
          _selectedCategory != null &&
          _selectedCategory == segments[i].category &&
          elevatedIndex == -1) {
        elevatedIndex = i;
        elevatedBottomOffset = currentBottom;
      }
      currentBottom += h;
    }

    return SizedBox(
      width: _getItemColumnWidth(),
      height: totalBarHeight,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Base Stacked Bar with Original Perfect Rounded Dome Top
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radius_100),
              ),
              child: SizedBox(
                width: barWidth,
                height: totalBarHeight,
                child: Column(
                  verticalDirection:
                      VerticalDirection.up, // Stack bottom to top!
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(segments.length, (i) {
                    return Container(
                      width: barWidth,
                      height: segHeights[i],
                      color: segments[i].color,
                    );
                  }),
                ),
              ),
            ),

            // 2. Elevated Ribbon Segment Overlay (Extending wider with drop shadow)
            if (elevatedIndex != -1)
              Positioned(
                bottom: elevatedBottomOffset,
                child: Container(
                  width: barWidth + 8.w,
                  height: segHeights[elevatedIndex],
                  decoration: BoxDecoration(
                    color: segments[elevatedIndex].color,
                    borderRadius: elevatedIndex == segments.length - 1
                        ? BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radius_100),
                          )
                        : (elevatedIndex == 0
                            ? BorderRadius.vertical(
                                top: Radius.circular(6.r),
                              )
                            : BorderRadius.circular(6.r)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: segments[elevatedIndex]
                            .color
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scrollLegendPrevious() {
    VibrationHelper.lightTap();
    if (_legendPageController.hasClients) {
      final double currentPage = _legendPageController.page ??
          _legendPageController.initialPage.toDouble();
      final int targetPage = (currentPage - 1).round();
      _legendPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollLegendNext() {
    VibrationHelper.lightTap();
    if (_legendPageController.hasClients) {
      final double currentPage = _legendPageController.page ??
          _legendPageController.initialPage.toDouble();
      final int targetPage = (currentPage + 1).round();
      _legendPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onLegendItemTap(int index) {
    VibrationHelper.lightTap();
    final int currentCenter =
        _legendPageController.hasClients && _legendPageController.page != null
            ? _legendPageController.page!.round()
            : (_kCarouselLoop * _carouselCategories.length) + _carouselIndex;

    if (index == currentCenter) {
      final int actualIndex = index % _carouselCategories.length;
      final String label = _carouselCategories[actualIndex]['label'] as String;
      setState(() {
        if (_selectedCategory == label) {
          _selectedCategory = null;
        } else {
          _selectedCategory = label;
        }
      });
    } else {
      if (_legendPageController.hasClients) {
        _legendPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  Widget _buildHorizontalIconsLegend() {
    return Container(
      margin: EdgeInsets.only(top: 10.h, bottom: 6.h, left: 24.w, right: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Chevron Arrow
          GestureDetector(
            onTap: _scrollLegendPrevious,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: const Color(0xFF80BFFF),
              ),
            ),
          ),

          // Gaussian Animated Carousel View
          Expanded(
            child: SizedBox(
              height: 60.h,
              child: AnimatedBuilder(
                animation: _legendPageController,
                builder: (context, _) {
                  final double page = _legendPageController.hasClients &&
                          _legendPageController.position.haveDimensions
                      ? (_legendPageController.page ??
                          _legendPageController.initialPage.toDouble())
                      : _legendPageController.initialPage.toDouble();

                  return PageView.builder(
                    controller: _legendPageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (pageIndex) {
                      final newIndex = pageIndex % _carouselCategories.length;
                      setState(() {
                        _carouselIndex = newIndex;
                        _selectedCategory =
                            _carouselCategories[newIndex]['label'];
                      });
                    },
                    itemBuilder: (context, index) {
                      final int actualIndex =
                          index % _carouselCategories.length;
                      final double diff = index - page;
                      final double absDiff = diff.abs();

                      // Gaussian bell curve decay factor
                      final double gaussian =
                          math.exp(-1.8 * diff * diff).clamp(0.0, 1.0);

                      final double scale = 0.72 + (0.28 * gaussian);
                      final double opacity =
                          (0.25 + (0.75 * gaussian)).clamp(0.0, 1.0);
                      final bool isSelected = _selectedCategory ==
                          _carouselCategories[actualIndex]['label'];

                      return Center(
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: _buildCarouselItem(
                              actualIndex,
                              isCenter: absDiff < 0.45,
                              isSelected: isSelected,
                              gaussianFactor: gaussian,
                              onTap: () => _onLegendItemTap(index),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Right Chevron Arrow
          GestureDetector(
            onTap: _scrollLegendNext,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: const Color(0xFF80BFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLocalizedLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key.toUpperCase()) {
      case 'TEA':
        return l10n?.tea ?? 'TEA';
      case 'JUICE':
        return l10n?.juice ?? 'JUICE';
      case 'MILK':
        return l10n?.milk ?? 'MILK';
      case 'COFFEE':
        return l10n?.coffee ?? 'COFFEE';
      case 'MEAL':
        return l10n?.meal ?? 'MEAL';
      case 'BOTTLE':
        return l10n?.bottle ?? 'BOTTLE';
      case 'LOGGED':
        return l10n?.logged ?? 'LOGGED';
      default:
        return key;
    }
  }

  Widget _buildCarouselItem(
    int index, {
    required bool isCenter,
    required bool isSelected,
    required double gaussianFactor,
    VoidCallback? onTap,
  }) {
    final cat = _carouselCategories[index];
    final String rawLabel = cat['label'] as String;
    final String label = _getCategoryLocalizedLabel(context, rawLabel);
    final String iconPath = cat['icon'] as String;

    const Color inactiveText = Color(0xFFCBD5E1);
    final Color textColor = Color.lerp(
      inactiveText,
      const Color(0xFF1E293B),
      gaussianFactor,
    )!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38.w,
            height: 38.w,
            child: Center(
              child: Image.asset(
                iconPath,
                width: 38.w,
                height: 38.w,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.local_drink_rounded,
                    size: 20.sp,
                    color: isCenter ? const Color(0xFF48CF7E) : inactiveText,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontWeight: isCenter ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarSegmentData {
  final String category;
  final double percent;
  final Color color;

  const _BarSegmentData({
    required this.category,
    required this.percent,
    required this.color,
  });
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
      padding: EdgeInsets.only(top: 18.h, bottom: 36.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(divisions + 1, (i) {
          final value = maxY - (i * step);
          final String label =
              (i == 0 && value >= 100) ? "100%+" : "${value.toInt()}%";
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: AppColors.black,
                fontSize: AppFontStyles.fontSize_14,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
              ),
            ),
          );
        }),
      ),
    );
  }
}
