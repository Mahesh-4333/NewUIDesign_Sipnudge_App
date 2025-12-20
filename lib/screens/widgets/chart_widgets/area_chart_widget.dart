import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart'; // CustomYAxis
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart'; // CustomChartToolTip
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionAreaChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
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
  Offset? _touchPosition;
  // Inside _SyncfusionAreaChartWidgetState
  ChartSeriesController? _seriesController;

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

    final sorted = [...widget.bottleData]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (isWeekly) {
      DateTime weekStart = widget.currentDate
          .subtract(Duration(days: widget.currentDate.weekday - 1));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

      chartData = List.generate(7, (i) {
        final dayDate = weekStart.add(Duration(days: i));
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
          weekLabels[i],
          100,
          consumed,
          s.date,
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

        return ChartData((i + 1).toString(), 100, consumed, s.date);
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

        final dateForPoint =
            list.isNotEmpty ? list.first.date : DateTime(year, monthIndex, 1);

        return ChartData(monthLabels[i], percent, consumed, dateForPoint);
      });
    } else {
      chartData = [];
    }

    // Reset selection when data changes
    _selectedPointIndex = null;

    print(
        "DEBUG [SyncfusionArea]: Interval=${widget.interval}, points=${chartData.length}");
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
                              child:
                                  _buildSyncfusionChart(chartWidth, isWeekly),
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
            if (_touchPosition != null && _selectedPointIndex != null)
              Positioned(
                left: (_touchPosition?.dx ?? 0) -
                    (_scrollController.hasClients
                        ? _scrollController.offset
                        : 0) +
                    15,
                top: 5.h,
                child: _buildManualTooltip(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTooltip() {
    log("=-=-=-= building manual tool tip =-=-=-=-=-=- ");
    final data = chartData[_selectedPointIndex!];
    final liters = (data.completionVolume ?? 0) / 1000;

    return CustomChartToolTip(
      isPercent: false,
      percent: num.parse(liters.toStringAsFixed(2)),
    );
  }

  Widget _buildSyncfusionChart(double chartWidth, bool isWeekly) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      selectionGesture: ActivationMode.singleTap,
      selectionType: SelectionType.point,
      enableMultiSelection: false,
      tooltipBehavior: _tooltipBehavior,
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
        ),
      ),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      onChartTouchInteractionUp: (tapArgs) {
        setState(() {
          _selectedPointIndex = null;
          _touchPosition = null;
        });
      },
      onChartTouchInteractionDown: (tapArgs) {
        if (_seriesController != null) {
          final CartesianChartPoint<dynamic> chartPoint =
              _seriesController!.pixelToPoint(tapArgs.position);

          setState(() {
            _touchPosition = tapArgs.position;

            final dynamic xValue = chartPoint.x;

            if (xValue is String) {
              _selectedPointIndex =
                  chartData.indexWhere((data) => data.x == xValue);
            } else if (xValue is num) {
              int idx = xValue.round();
              if (idx >= 0 && idx < chartData.length) {
                _selectedPointIndex = idx;
              }
            }

            if (_selectedPointIndex == -1) {
              _selectedPointIndex = null;
            }
          });
        }
      },
      series: <CartesianSeries<ChartData, String>>[
        AreaSeries<ChartData, String>(
          dataSource: chartData,
          onRendererCreated: (ChartSeriesController controller) {
            _seriesController = controller;
          },
          xValueMapper: (ChartData d, _) => d.x,
          yValueMapper: (ChartData d, _) => d.completionPercent,
          onPointTap: (ChartPointDetails details) {
            setState(() {
              _selectedPointIndex = details.pointIndex;
            });
          },
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

          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.blueGradient.withOpacity(0.6),
              AppColors.blueGradient.withOpacity(0.1),
            ],
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
