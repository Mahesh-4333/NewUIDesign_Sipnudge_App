// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/cubit/filter/filter_cubit.dart';
// import 'package:hydrify/models/chart_data.dart';
// import 'package:hydrify/models/hydration_summary.dart';
// import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart';
// import 'package:hydrify/screens/widgets/chart_widgets/tool_tip_widget.dart';

// class FlAreaChartWidget extends StatefulWidget {
//   final FilterInterval interval;
//   final DateTime currentDate;
//   final List<HydrationDaySummary> hydrationSummaries;

//   const FlAreaChartWidget({
//     super.key,
//     required this.interval,
//     required this.currentDate,
//     required this.hydrationSummaries,
//   });

//   @override
//   State<FlAreaChartWidget> createState() => _FlAreaChartWidgetState();
// }

// class _FlAreaChartWidgetState extends State<FlAreaChartWidget> {
//   late List<ChartData> chartData;
//   final ScrollController _scrollController = ScrollController();
//   Offset? _tooltipPos; // tooltip position in chart coordinates
//   TouchLineBarSpot? _touchedSpot;
//   ChartData? tooltipData;

//   final List<String> weekLabels = [
//     'Mon',
//     'Tue',
//     'Wed',
//     'Thu',
//     'Fri',
//     'Sat',
//     'Sun'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _updateChartData();
//   }

//   void _updateChartData() {
//     final isWeekly = widget.interval == FilterInterval.weekly;

//     // Sort summaries by date just to be safe
//     final sorted = [...widget.hydrationSummaries]
//       ..sort((a, b) => a.date.compareTo(b.date));

//     if (isWeekly) {
//       // Ensure exactly 7 days (Mon → Sun) based on currentDate
//       DateTime weekStart = widget.currentDate
//           .subtract(Duration(days: widget.currentDate.weekday - 1));
//       weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

//       chartData = List.generate(7, (i) {
//         final dayDate = weekStart.add(Duration(days: i));

//         // find matching summary for this date
//         final HydrationDaySummary summary = sorted.firstWhere(
//           (s) =>
//               s.date.year == dayDate.year &&
//               s.date.month == dayDate.month &&
//               s.date.day == dayDate.day,
//           orElse: () => HydrationDaySummary(
//             date: dayDate,
//             dayIndex: i,
//             target: 0,
//             consumed: 0,
//           ),
//         );

//         final label = weekLabels[i];
//         final target = summary.target;
//         final consumed = summary.consumed;

//         double percent = 0;
//         if (target > 0) {
//           percent = (consumed / target) * 100;
//         }
//         if (percent < 0) percent = 0;
//         if (percent > 100) percent = 100;

//         return ChartData(
//             label,
//             percent,
//             consumed, // ml (tooltip converts to L)
//             summary.date);
//       });
//     } else {
//       // Monthly / Yearly – just map summaries in order
//       chartData = sorted.map((summary) {
//         String label;
//         if (widget.interval == FilterInterval.monthly) {
//           // show day of month
//           label = summary.date.day.toString();
//         } else {
//           // yearly – you can customize this (e.g., month name)
//           label = "${summary.date.month}/${summary.date.year % 100}";
//         }

//         final target = summary.target;
//         final consumed = summary.consumed;

//         double percent = 0;
//         if (target > 0) {
//           percent = (consumed / target) * 100;
//         }
//         if (percent < 0) percent = 0;
//         if (percent > 100) percent = 100;
//         print(label);
//         print(percent);
//         print(consumed);

//         return ChartData(
//             label,
//             percent,
//             consumed, // ml
//             summary.date);
//       }).toList();
//     }

//     // debug
//     // ignore: avoid_print
//     print(
//         "DEBUG: Interval=${widget.interval}, ChartData length=${chartData.length}");
//   }

//   @override
//   void didUpdateWidget(covariant FlAreaChartWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.interval != widget.interval ||
//         oldWidget.currentDate != widget.currentDate ||
//         oldWidget.hydrationSummaries != widget.hydrationSummaries) {
//       _updateChartData();
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isWeekly = widget.interval == FilterInterval.weekly;
//     double pointWidth = 50.w;
//     final chartWidth =
//         isWeekly ? AppDimensions.dim365.w : pointWidth * chartData.length;

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
//                       child: isWeekly
//                           ? Container(
//                               width: chartWidth,
//                               padding: EdgeInsets.only(
//                                 left: AppDimensions.dim9.w,
//                                 top: AppDimensions.dim9.h,
//                               ),
//                               child: _buildLineChart(chartWidth, isWeekly),
//                             )
//                           : SingleChildScrollView(
//                               controller: _scrollController,
//                               scrollDirection: Axis.horizontal,
//                               padding: EdgeInsets.zero,
//                               child: Container(
//                                 width: chartWidth,
//                                 padding: EdgeInsets.only(
//                                   left: AppDimensions.dim9.w,
//                                   right: pointWidth /
//                                       2, // Add right padding to show last point fully
//                                   top: AppDimensions.dim9.h,
//                                 ),
//                                 child: _buildLineChart(chartWidth, isWeekly),
//                               ),
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_tooltipPos != null)
//               Positioned(
//                 left: (_tooltipPos!.dx) -
//                     (_scrollController.hasClients
//                         ? _scrollController.offset
//                         : 0) +
//                     46.w,
//                 top: _tooltipPos!.dy,
//                 child: FractionalTranslation(
//                   translation: const Offset(-1.2, 0.0),
//                   child: CustomChartToolTip(
//                     isPercent: false,
//                     // completionVolume is in ml -> show liters with 2 decimals
//                     percent: num.parse(
//                       ((tooltipData?.completionVolume ?? 0) / 1000)
//                           .toStringAsFixed(2),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLineChart(double chartWidth, bool isWeekly) {
//     return LineChart(
//       LineChartData(
//         minY: 0,
//         maxY: 100,
//         gridData: FlGridData(show: false),
//         borderData: FlBorderData(show: false),
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               reservedSize: 25,
//               showTitles: true,
//               getTitlesWidget: (value, _) {
//                 int index = value.toInt();
//                 if (index < 0 || index >= chartData.length) {
//                   return const SizedBox();
//                 }
//                 final label = isWeekly ? weekLabels[index] : chartData[index].x;
//                 return Padding(
//                   padding: EdgeInsets.only(top: AppDimensions.dim8.h),
//                   child: Text(
//                     label,
//                     style: TextStyle(
//                       color: AppColors.black,
//                       fontFamily: AppFontStyles.urbanistFontFamily,
//                       fontSize: AppFontStyles.fontSize_14,
//                       fontVariations: [AppFontStyles.boldFontVariation],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         lineBarsData: [
//           LineChartBarData(
//             spots: List.generate(
//               chartData.length,
//               (i) => FlSpot(
//                 i.toDouble(),
//                 chartData[i].completionPercent,
//               ),
//             ),
//             isCurved: true,
//             color: const Color(0xFF42A5FF),
//             barWidth: AppDimensions.dim3.w,
//             belowBarData: BarAreaData(
//               show: true,
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   AppColors.blueGradient.withOpacity(.6),
//                   AppColors.blueGradient.withOpacity(.1),
//                 ],
//               ),
//             ),
//             dotData: FlDotData(
//               show: true,
//               getDotPainter: (spot, percent, barData, index) =>
//                   FlDotCirclePainter(
//                 radius: AppDimensions.dim4.h,
//                 color: AppColors.white,
//                 strokeWidth: AppDimensions.dim4.h,
//                 strokeColor: const Color(0xFF42A5FF),
//               ),
//             ),
//           ),
//         ],
//         lineTouchData: LineTouchData(
//           enabled: true,
//           touchTooltipData: LineTouchTooltipData(
//             getTooltipColor: (_) => Colors.transparent,
//             getTooltipItems: (_) => [],
//           ),
//           touchCallback: (event, response) {
//             if (event.isInterestedForInteractions &&
//                 response != null &&
//                 (response.lineBarSpots?.isNotEmpty ?? false)) {
//               final s = response.lineBarSpots!.first;
//               setState(() {
//                 _touchedSpot = s;
//                 tooltipData = chartData[s.x.toInt()];
//                 _tooltipPos = _spotToPixel(
//                   s,
//                   chartWidth: chartWidth,
//                   chartHeight: AppDimensions.dim262.h,
//                   minX: 0,
//                   maxX: (chartData.length - 1).toDouble(),
//                   minY: 0,
//                   maxY: 100,
//                   leftReserved: 0,
//                   rightReserved: 0,
//                   topReserved: 0,
//                   bottomReserved: 30,
//                 );
//               });
//             } else {
//               setState(() {
//                 _touchedSpot = null;
//                 _tooltipPos = null;
//                 tooltipData = null;
//               });
//             }
//           },
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
