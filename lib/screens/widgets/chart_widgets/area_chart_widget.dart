import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/hydration_summary.dart';
<<<<<<< HEAD
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';
=======
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart'; // CustomYAxis
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart'; // CustomChartToolTip
import 'package:syncfusion_flutter_charts/charts.dart';
>>>>>>> origin/develop

class SyncfusionAreaChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
<<<<<<< HEAD
  // NOTE: This is now HydrationDaySummary, name kept as bottleData so your caller doesn't break
=======
>>>>>>> origin/develop
  final List<HydrationDaySummary> bottleData;

  const SyncfusionAreaChartWidget({
    super.key,
    required this.interval,
    required this.currentDate,
    required this.bottleData,
  });

  @override
  State<SyncfusionAreaChartWidget> createState() =>
      _SyncfusionAreaChartWidgetState();
}

class _SyncfusionAreaChartWidgetState extends State<SyncfusionAreaChartWidget> {
  late List<ChartData> chartData;
  final ScrollController _scrollController = ScrollController();
  late SelectionBehavior _selectionBehavior;
  late TooltipBehavior _tooltipBehavior;
  int? _selectedPointIndex;

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
    _initializeSelectionBehavior();
    _initializeTooltipBehavior();
  }

  void _initializeSelectionBehavior() {
    _selectionBehavior = SelectionBehavior(
      enable: true,
      toggleSelection: true,
      selectedColor: const Color(0xFFA22EFF),
      unselectedColor: const Color(0xFF42A5FF),
      selectedBorderColor: Colors.white,
      selectedBorderWidth: 2,
      unselectedBorderColor: const Color(0xFF42A5FF),
      unselectedBorderWidth: AppDimensions.dim3.w,
    );
  }

  void _initializeTooltipBehavior() {
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipPosition: TooltipPosition.pointer,
      duration: 1000,
      color: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      canShowMarker: true,
      shouldAlwaysShow: false,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
          int seriesIndex) {
        if (data == null || data is! ChartData) {
          return const SizedBox.shrink();
        }

        final ChartData chartDataPoint = data;
        final liters = (chartDataPoint.completionVolume ?? 0) / 1000;

        return CustomChartToolTip(
          isPercent: false,
          percent: num.parse(liters.toStringAsFixed(2)),
        );
      },
    );
  }

  void _updateChartData() {
    final isWeekly = widget.interval == FilterInterval.weekly;
    final isMonthly = widget.interval == FilterInterval.monthly;
    final isYearly = widget.interval == FilterInterval.yearly;

<<<<<<< HEAD
    // Sort summaries by date once
=======
>>>>>>> origin/develop
    final sorted = [...widget.bottleData]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (isWeekly) {
<<<<<<< HEAD
      // --- WEEKLY: always 7 days Mon–Sun ---
=======
>>>>>>> origin/develop
      DateTime weekStart = widget.currentDate
          .subtract(Duration(days: widget.currentDate.weekday - 1));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

      chartData = List.generate(7, (i) {
        final dayDate = weekStart.add(Duration(days: i));
<<<<<<< HEAD

=======
>>>>>>> origin/develop
        final s = sorted.firstWhere(
          (x) =>
              x.date.year == dayDate.year &&
              x.date.month == dayDate.month &&
              x.date.day == dayDate.day,
          orElse: () => HydrationDaySummary(
            date: dayDate,
            dayIndex: i,
            target: 0,
            consumed: 0,
          ),
        );

        final double target = s.target;
        final double consumed = s.consumed;
        double percent = target > 0 ? (consumed / target) * 100 : 0;
        percent = percent.clamp(0, 100);

        return ChartData(
<<<<<<< HEAD
            weekLabels[i], // Mon..Sun
            percent, // 0–100
            consumed, // ml
            s.date);
      });
    } else if (isMonthly) {
      // --- MONTHLY: full calendar month 1..lastDay ---
=======
          weekLabels[i],
          percent,
          consumed,
          s.date,
        );
      });
    } else if (isMonthly) {
>>>>>>> origin/develop
      final year = widget.currentDate.year;
      final month = widget.currentDate.month;
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);
      final days = lastDay.day;

      chartData = List.generate(days, (i) {
        final dayDate = firstDay.add(Duration(days: i));
<<<<<<< HEAD

=======
>>>>>>> origin/develop
        final s = sorted.firstWhere(
          (x) =>
              x.date.year == dayDate.year &&
              x.date.month == dayDate.month &&
              x.date.day == dayDate.day,
          orElse: () => HydrationDaySummary(
            date: dayDate,
            dayIndex: i,
            target: 0,
            consumed: 0,
          ),
        );

        final double target = s.target;
        final double consumed = s.consumed;
        double percent = target > 0 ? (consumed / target) * 100 : 0;
        percent = percent.clamp(0, 100);

<<<<<<< HEAD
        return ChartData(
            (i + 1).toString(), // 1,2,3,...
            percent, // 0–100
            consumed, // ml
            s.date);
      });
    } else if (isYearly) {
      // --- YEARLY: always 12 months ---
=======
        return ChartData((i + 1).toString(), percent, consumed, s.date);
      });
    } else if (isYearly) {
>>>>>>> origin/develop
      final year = widget.currentDate.year;
      final inYear = sorted.where((x) => x.date.year == year).toList();

      chartData = List.generate(12, (i) {
        final monthIndex = i + 1;
<<<<<<< HEAD

        final list = inYear.where((x) => x.date.month == monthIndex).toList();

=======
        final list = inYear.where((x) => x.date.month == monthIndex).toList();
>>>>>>> origin/develop
        double target = 0;
        double consumed = 0;
        for (var e in list) {
          target += e.target;
          consumed += e.consumed;
        }

        double percent = target > 0 ? (consumed / target) * 100 : 0;
        percent = percent.clamp(0, 100);

<<<<<<< HEAD
        // Use first day of the month if there is no data for that month
        final dateForPoint =
            list.isNotEmpty ? list.first.date : DateTime(year, monthIndex, 1);

        return ChartData(
          monthLabels[i], // Jan, Feb, ...
          percent,
          consumed,
          dateForPoint,
        );
=======
        final dateForPoint =
            list.isNotEmpty ? list.first.date : DateTime(year, monthIndex, 1);

        return ChartData(monthLabels[i], percent, consumed, dateForPoint);
>>>>>>> origin/develop
      });
    } else {
      chartData = [];
    }

<<<<<<< HEAD
    // ignore: avoid_print
    print(
        "DEBUG [Area]: Interval=${widget.interval}, ChartData length=${chartData.length}");
=======
    // Reset selection when data changes
    _selectedPointIndex = null;

    print(
        "DEBUG [SyncfusionArea]: Interval=${widget.interval}, points=${chartData.length}");
>>>>>>> origin/develop
  }

  @override
  void didUpdateWidget(covariant SyncfusionAreaChartWidget oldWidget) {
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
                    // Sticky Y axis (fixed)
                    SizedBox(
                      width: AppDimensions.dim40.w,
                      height: AppDimensions.dim265.h,
                      child: const CustomYAxis(maxY: 100, divisions: 5),
                    ),

                    // Chart area (scrollable horizontally for monthly/yearly)
                    Expanded(
                      child: isWeekly
                          ? Container(
                              width: chartWidth,
                              padding: EdgeInsets.only(
                                left: AppDimensions.dim9.w,
                                top: AppDimensions.dim9.h,
                              ),
<<<<<<< HEAD
                              child: _buildLineChart(chartWidth, isWeekly),
=======
                              child:
                                  _buildSyncfusionChart(chartWidth, isWeekly),
>>>>>>> origin/develop
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
                                child:
                                    _buildSyncfusionChart(chartWidth, isWeekly),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
<<<<<<< HEAD
            if (_tooltipPos != null)
              Positioned(
                left: (_tooltipPos!.dx) -
                    (_scrollController.hasClients
                        ? _scrollController.offset
                        : 0) +
                    46.w,
                top: _tooltipPos!.dy,
                child: FractionalTranslation(
                  translation: const Offset(-1.2, 0.0),
                  child: CustomChartToolTip(
                    isPercent: false,
                    // ml → L
                    percent: num.parse(
                      ((tooltipData?.completionVolume ?? 0) / 1000)
                          .toStringAsFixed(2),
                    ),
                  ),
                ),
              ),
=======
>>>>>>> origin/develop
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildLineChart(double chartWidth, bool isWeekly) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 25,
              showTitles: true,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox();
                }
                final label = isWeekly ? weekLabels[index] : chartData[index].x;
                return Padding(
                  padding: EdgeInsets.only(top: AppDimensions.dim8.h),
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
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              chartData.length,
              (i) => FlSpot(
                i.toDouble(),
                chartData[i].completionPercent,
              ),
            ),
            isCurved: false,
            color: const Color(0xFF42A5FF),
            barWidth: AppDimensions.dim3.w,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.blueGradient.withOpacity(.6),
                  AppColors.blueGradient.withOpacity(.1),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: AppDimensions.dim4.h,
                color: AppColors.white,
                strokeWidth: AppDimensions.dim4.h,
                strokeColor: const Color(0xFF42A5FF),
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItems: (_) => [],
          ),
          touchCallback: (event, response) {
            if (event.isInterestedForInteractions &&
                response != null &&
                (response.lineBarSpots?.isNotEmpty ?? false)) {
              final s = response.lineBarSpots!.first;
              setState(() {
                _touchedSpot = s;
                tooltipData = chartData[s.x.toInt()];
                _tooltipPos = _spotToPixel(
                  s,
                  chartWidth: chartWidth,
                  chartHeight: AppDimensions.dim262.h,
                  minX: 0,
                  maxX: (chartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  leftReserved: 0,
                  rightReserved: 0,
                  topReserved: 0,
                  bottomReserved: 30,
                );
              });
            } else {
              setState(() {
                _touchedSpot = null;
                _tooltipPos = null;
                tooltipData = null;
              });
            }
          },
=======
  Widget _buildSyncfusionChart(double chartWidth, bool isWeekly) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,

      // Enable selection gesture
      selectionGesture: ActivationMode.singleTap,
      selectionType: SelectionType.point,
      enableMultiSelection: false,

      // Tooltip behavior
      tooltipBehavior: _tooltipBehavior,

      // Selection callback
      onSelectionChanged: (SelectionArgs args) {
        if (args.selectedColor != null) {
          setState(() {
            _selectedPointIndex = args.pointIndex;
          });
          print("Point selected: ${args.pointIndex}");
        } else {
          setState(() {
            _selectedPointIndex = null;
          });
          print("Selection cleared");
        }
      },

      // Also handle point tap for direct interaction

      // Hide Syncfusion's Y axis
      primaryYAxis: NumericAxis(
        isVisible: false,
        minimum: 0,
        maximum: 100,
        interval: 20,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),

      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelPlacement: LabelPlacement.onTicks,
        labelStyle: TextStyle(
          color: AppColors.black,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontSize: AppFontStyles.fontSize_14,
>>>>>>> origin/develop
        ),
      ),

      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,

      series: <CartesianSeries<ChartData, String>>[
        AreaSeries<ChartData, String>(
          dataSource: chartData,
          xValueMapper: (ChartData d, _) => d.x,
          yValueMapper: (ChartData d, _) => d.completionPercent,

          // Border styling
          borderColor: const Color(0xFF42A5FF),
          borderWidth: AppDimensions.dim3.w,

          // Marker settings for better touch
          markerSettings: MarkerSettings(
            isVisible: true,
            height: AppDimensions.dim10.h,
            width: AppDimensions.dim10.h,
            borderWidth: AppDimensions.dim4.w,
            borderColor: const Color(0xFF42A5FF),
            color: AppColors.white,
            shape: DataMarkerType.circle,
          ),

          // Selection behavior
          selectionBehavior: _selectionBehavior,

          // Trackball (alternative to selection)
          enableTooltip: true,

          // Gradient
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.blueGradient.withOpacity(0.6),
              AppColors.blueGradient.withOpacity(0.1),
            ],
          ),

          // Data label for selected point
          dataLabelSettings: DataLabelSettings(
            isVisible: false, // Set to true if you want labels on all points
            builder: (dynamic data, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              // Show custom tooltip only for selected point
              if (_selectedPointIndex == pointIndex) {
                final ChartData chartDataPoint = data as ChartData;
                final liters = (chartDataPoint.completionVolume ?? 0) / 1000;
                return CustomChartToolTip(
                  isPercent: false,
                  percent: num.parse(liters.toStringAsFixed(2)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
