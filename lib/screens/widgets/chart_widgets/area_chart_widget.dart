import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/water_consumption_data.dart';
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';

class SyncfusionAreaChartWidget extends StatefulWidget {
  final FilterInterval interval;
  final DateTime currentDate;
  final List<BottleData> bottleData;

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
    List<WaterConsumptionData> consumptionData;

    if (widget.interval == FilterInterval.weekly) {
      // Monday of the week
      DateTime weekStart = widget.currentDate
          .subtract(Duration(days: widget.currentDate.weekday - 1));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

      chartData = List.generate(7, (i) {
        final dayDate = weekStart.add(Duration(days: i));
        final found = rawWeeklyData.firstWhere(
            (e) =>
                e.date.year == dayDate.year &&
                e.date.month == dayDate.month &&
                e.date.day == dayDate.day,
            orElse: () =>
                WaterConsumptionData(date: dayDate, consumedVolume: 0));
        return found;
      });
    } else if (widget.interval == FilterInterval.monthly) {
      consumptionData = WaterConsumptionCalculator.getMonthlyData(
        widget.bottleData,
        widget.currentDate,
      );
    } else {
      consumptionData = WaterConsumptionCalculator.getYearlyData(
        widget.bottleData,
        widget.currentDate,
      );
    }

    chartData = WaterConsumptionCalculator.formatChartData(
      consumptionData,
      widget.interval,
    );

    print(
        "DEBUG: Interval=${widget.interval}, ChartData length=${chartData.length}");
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
                                  top: AppDimensions.dim9.h),
                              child: _buildLineChart(chartWidth, isWeekly),
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
                    percent: num.parse(
                      ((tooltipData?.completionVolume ?? 0) / 1000)
                          .toStringAsFixed(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                if (index < 0 || index >= chartData.length)
                  return const SizedBox();
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
              (i) => FlSpot(i.toDouble(), chartData[i].completionPercent),
            ),
            isCurved: true,
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
        ),
      ),
    );
  }

  Offset _spotToPixel(
    TouchLineBarSpot s, {
    required double chartWidth,
    required double chartHeight,
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    required double leftReserved,
    required double rightReserved,
    required double topReserved,
    required double bottomReserved,
  }) {
    final innerW = chartWidth - leftReserved - rightReserved;
    final innerH = chartHeight - topReserved - bottomReserved;

    final dx = leftReserved + ((s.x - minX) / (maxX - minX)) * innerW;
    final dy = topReserved + (1 - (s.y - minY) / (maxY - minY)) * innerH;

    return Offset(dx, dy);
  }
}

//=========================================================================

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/cubit/filter/filter_cubit.dart';
// import 'package:hydrify/helpers/water_consumption_data_helper.dart';
// import 'package:hydrify/models/bottle_data.dart';
// import 'package:hydrify/models/chart_data.dart';
// import 'package:hydrify/models/water_consumption_data.dart';
// import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart';
// import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';

// class FlAreaChartWidget extends StatefulWidget {
//   final FilterInterval interval;
//   final DateTime currentDate;
//   final List<BottleData> bottleData;

//   const FlAreaChartWidget({
//     super.key,
//     required this.interval,
//     required this.currentDate,
//     required this.bottleData,
//   });

//   @override
//   State<FlAreaChartWidget> createState() => _FlAreaChartWidgetState();
// }

// class _FlAreaChartWidgetState extends State<FlAreaChartWidget> {
//   late List<ChartData> chartData;
//   Offset? tappedIndexOffset;
//   ChartData? tooltipData;
//   int? tappedIndex;
//   TouchLineBarSpot? _touchedSpot;
//   Offset? _tooltipPos; // in chart-content coordinates
//   final ScrollController _scrollController = ScrollController();
//   @override
//   void initState() {
//     super.initState();
//     _updateChartData();
//   }

//   void _updateChartData() {
//     List<WaterConsumptionData> consumptionData;
//     if (widget.interval == FilterInterval.weekly) {
//       DateTime weekStart = widget.currentDate.subtract(
//         Duration(days: widget.currentDate.weekday % 7),
//       );
//       weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

//       consumptionData = WaterConsumptionCalculator.getWeeklyData(
//         widget.bottleData,
//         weekStart,
//       );
//     } else if (widget.interval == FilterInterval.monthly) {
//       consumptionData = WaterConsumptionCalculator.getMonthlyData(
//         widget.bottleData,
//         widget.currentDate,
//       );
//     } else {
//       consumptionData = WaterConsumptionCalculator.getYearlyData(
//         widget.bottleData,
//         widget.currentDate,
//       );
//     }

//     chartData = WaterConsumptionCalculator.formatChartData(
//       consumptionData,
//       widget.interval,
//     );

//     print(
//         "DEBUG: Interval=${widget.interval}, ChartData length=${chartData.length}");
//   }

//   @override
//   void didUpdateWidget(covariant FlAreaChartWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.interval != widget.interval ||
//         oldWidget.currentDate != widget.currentDate ||
//         oldWidget.bottleData != widget.bottleData) {
//       _updateChartData();
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     double pointWidth = 50.w;
//     final chartWidth = pointWidth * chartData.length;

//     return Container(
//       color: Colors.transparent,
//       width: double.maxFinite,
//       height: AppDimensions.dim320.h,
//       child: SizedBox(
//         width: double.maxFinite,
//         height: 324.h,
//         child: Stack(
//           children: [
//             Positioned(
//               bottom: 0,
//               child: SizedBox(
//                 width: AppDimensions.dim365.w,
//                 height: AppDimensions.dim262.h,
//                 child: Row(
//                   children: [
//                     SizedBox(
//                       width: AppDimensions.dim40.w,
//                       height: AppDimensions.dim265.h,
//                       child: CustomYAxis(maxY: 100, divisions: 5),
//                     ),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         controller: _scrollController,
//                         scrollDirection: Axis.horizontal,
//                         padding: EdgeInsets.zero,
//                         child: Container(
//                           width: chartWidth,
//                           padding: EdgeInsets.only(
//                               left: AppDimensions.dim9.w,
//                               top: AppDimensions.dim9.h),
//                           child: LineChart(
//                             LineChartData(
//                               minY: 0,
//                               maxY: 100,
//                               gridData: FlGridData(show: false),
//                               borderData: FlBorderData(show: false),
//                               titlesData: FlTitlesData(
//                                 bottomTitles: AxisTitles(
//                                   sideTitles: SideTitles(
//                                     reservedSize: 25,
//                                     showTitles: true,
//                                     getTitlesWidget: (value, _) {
//                                       int index = value.toInt();
//                                       if (index < 0 ||
//                                           index >= chartData.length) {
//                                         return const SizedBox();
//                                       }
//                                       return Padding(
//                                         padding: EdgeInsets.only(
//                                             top: AppDimensions.dim8.h),
//                                         child: Text(
//                                           chartData[index].x,
//                                           style: TextStyle(
//                                             color: AppColors.black,
//                                             fontFamily: AppFontStyles
//                                                 .urbanistFontFamily,
//                                             fontSize: AppFontStyles.fontSize_14,
//                                             fontVariations: [
//                                               AppFontStyles.boldFontVariation
//                                             ],
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 leftTitles: AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false),
//                                 ),
//                                 topTitles: AxisTitles(
//                                     sideTitles: SideTitles(showTitles: false)),
//                                 rightTitles: AxisTitles(
//                                     sideTitles: SideTitles(showTitles: false)),
//                               ),
//                               lineBarsData: [
//                                 LineChartBarData(
//                                   spots: List.generate(
//                                     chartData.length,
//                                     (i) => FlSpot(
//                                       i.toDouble(),
//                                       chartData[i].completionPercent,
//                                     ),
//                                   ),
//                                   isCurved: true,
//                                   color: Color(0xFF42A5FF),
//                                   barWidth: AppDimensions.dim3.w,
//                                   belowBarData: BarAreaData(
//                                     show: true,
//                                     gradient: LinearGradient(
//                                       begin: Alignment.topCenter,
//                                       end: Alignment.bottomCenter,
//                                       colors: [
//                                         AppColors.blueGradient.withOpacity(.6),
//                                         AppColors.blueGradient.withOpacity(.1),
//                                       ],
//                                     ),
//                                   ),
//                                   dotData: FlDotData(
//                                     show: true,
//                                     getDotPainter:
//                                         (spot, percent, barData, index) {
//                                       return FlDotCirclePainter(
//                                         radius: AppDimensions.dim4.h,
//                                         color: AppColors.white,
//                                         strokeWidth: AppDimensions.dim4.h,
//                                         strokeColor: Color(0xFF42A5FF),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               ],
//                               lineTouchData: LineTouchData(
//                                 enabled: true,
//                                 touchTooltipData: LineTouchTooltipData(
//                                   getTooltipColor: (_) => Colors.transparent,
//                                   getTooltipItems: (_) => [],
//                                 ),
//                                 touchCallback: (event, response) {
//                                   if (event.isInterestedForInteractions &&
//                                       response != null &&
//                                       (response.lineBarSpots?.isNotEmpty ??
//                                           false)) {
//                                     final s = response.lineBarSpots!.first;
//                                     setState(() {
//                                       _touchedSpot = s;
//                                       _tooltipPos = _spotToPixel(
//                                         s,
//                                         chartWidth: chartWidth,
//                                         chartHeight: AppDimensions.dim262.h,
//                                         minX: 0,
//                                         maxX: (chartData.length - 1).toDouble(),
//                                         minY: 0,
//                                         maxY: 100,
//                                         leftReserved:
//                                             0, // we disabled leftTitles
//                                         rightReserved: 0,
//                                         topReserved: 0,
//                                         bottomReserved: 30,
//                                       );
//                                     });
//                                   } else {
//                                     setState(() {
//                                       _touchedSpot = null;
//                                       _tooltipPos = null;
//                                     });
//                                   }
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_tooltipPos != null)
//               Positioned(
//                 left: _tooltipPos!.dx - _scrollController.offset + 46.w,
//                 top: _tooltipPos!.dy,
//                 child: FractionalTranslation(
//                   translation: const Offset(-0.5, 0.0),
//                   child: CustomChartToolTip(
//                     isPercent: false,
//                     percent: num.parse(
//                       ((tooltipData?.completionVolume ?? 0)).toStringAsFixed(1),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Offset _spotToPixel(
//     TouchLineBarSpot s, {
//     required double chartWidth,
//     required double chartHeight,
//     required double minX,
//     required double maxX,
//     required double minY,
//     required double maxY,
//     required double leftReserved,
//     required double rightReserved,
//     required double topReserved,
//     required double bottomReserved,
//   }) {
//     final innerW = chartWidth - leftReserved - rightReserved;
//     final innerH = chartHeight - topReserved - bottomReserved;

//     final dx = leftReserved + ((s.x - minX) / (maxX - minX)) * innerW;
//     final dy = topReserved + (1 - (s.y - minY) / (maxY - minY)) * innerH;

//     return Offset(dx, dy);
//   }
// }
