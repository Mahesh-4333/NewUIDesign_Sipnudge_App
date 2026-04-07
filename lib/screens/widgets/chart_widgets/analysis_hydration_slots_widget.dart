import 'dart:ui';
import 'dart:developer';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/models/hydration_entry.dart';

class AnalysisHydrationSlotsWidget extends StatefulWidget {
  const AnalysisHydrationSlotsWidget({super.key});

  @override
  State<AnalysisHydrationSlotsWidget> createState() =>
      _AnalysisHydrationSlotsWidgetState();
}

class _AnalysisHydrationSlotsWidgetState
    extends State<AnalysisHydrationSlotsWidget>
    with AutomaticKeepAliveClientMixin {
  int _activeTabIndex = 0; // 0: Scheduled, 1: All, 2: Off-Slot

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<HydrationCubit, HydrationState>(
      builder: (context, state) {
        log("[AnalysisWidget] Building AnalysisHydrationSlotsWidget with ${state.entries.length} entries",
            name: "UI_DEBUG");
        return Container(
          margin:
              EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
          padding: EdgeInsets.symmetric(vertical: AppDimensions.dim20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
                color: AppColors.bluegray.withOpacity(0.1), width: 1.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabBar(),
              SizedBox(height: 80.h),
              _buildChart(state),
              SizedBox(height: AppDimensions.dim30.h),
              _buildListContent(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      height: 55.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem("Scheduled", 0),
          _buildTabItem("All", 1),
          _buildTabItem("Off-Slot", 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.white,
                      AppColors.white,
                      AppColors.bottomnavbar
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 7,
                      offset: Offset(1, 2),
                    ),
                  ],
                  border: Border.all(color: Color(0xff4D758B)),
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xff2C4A5B),
              fontSize: 14.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(HydrationState state) {
    final entries = state.entries;
    final amountSpots = <FlSpot>[];
    final offslotSpots = <FlSpot>[];

    log("[AnalysisWidget] Building Chart with ${entries.length} entries",
        name: "UI_DEBUG");

    for (int i = 0; i < entries.length; i++) {
      log("[AnalysisWidget] Slot $i: waterDrank=${entries[i].waterDrank}, offslot=${entries[i].offslot}",
          name: "UI_DEBUG");
      amountSpots.add(FlSpot(i.toDouble(), entries[i].waterDrank));
      offslotSpots.add(FlSpot(i.toDouble(), entries[i].offslot));
    }

        double maxVal = 0;
        if (entries.isNotEmpty) {
          final maxAmount =
              entries.map((e) => e.waterDrank).reduce((a, b) => a > b ? a : b);
          final maxOffslot =
              entries.map((e) => e.offslot).reduce((a, b) => a > b ? a : b);

          if (_activeTabIndex == 0) {
            maxVal = maxAmount;
          } else if (_activeTabIndex == 2) {
            maxVal = maxOffslot;
          } else {
            maxVal = math.max(maxAmount, maxOffslot);
          }
        }

        // Calculate chartMaxY based on max value, rounding up to nearest 100
        double chartMaxY = ((maxVal / 100).ceil() * 100).toDouble();
        if (chartMaxY < 200) {
          chartMaxY = 200; // Lower minimum floor to be more responsive
        }
        chartMaxY += 100; // Add one extra interval for padding at the top

        double yInterval = (chartMaxY / 5).ceilToDouble();
        if (yInterval < 50) {
          yInterval = 50;
        }

        final Color topLineColor = const Color(0xFFA8D59D); // Light green
        final Color topDotColor = const Color(0xFF2C5E1A); // Dark green

        final Color bottomLineColor = const Color(0xFFEFA69D); // Light red
        final Color bottomDotColor = const Color(0xFFAC2618); // Dark red

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
          child: SizedBox(
            height: 250.h,
            child: Row(
              children: [
                // Fixed Y-Axis
                Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: SizedBox(
                    width: 35.w,
                    child: LineChart(
                      LineChartData(
                        minY: 0, // Starts at 0 now
                        maxY: chartMaxY,
                        clipData: const FlClipData.all(),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1.w,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [FlSpot(0, 0)],
                            color: Colors.transparent,
                          )
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35.w,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12.sp,
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Scrollable X-Axis Chart
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: math.max(
                        MediaQuery.of(context).size.width - 80.w,
                        entries.length * 60.w,
                      ),
                      margin: EdgeInsets.only(top: 0.h),
                      padding: EdgeInsets.only(right: 20.w, left: 10.w),
                      child: LineChart(
                        LineChartData(
                          minX: -0.2, // Add padding on the left
                          maxX: entries.isEmpty
                              ? 0.4
                              : (entries.length - 1).toDouble() +
                                  0.4, // Add padding on the right
                          minY: -4, // Starts at 0
                          maxY: chartMaxY,
                          clipData: const FlClipData.all(),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30.h,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  // Ensure we only render for exactly the integer indices of our entries
                                  if (value % 1 != 0 ||
                                      value < 0.0 ||
                                      value >= entries.length.toDouble()) {
                                    return const SizedBox.shrink();
                                  }
                                  int index = value.toInt();
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8.h),
                                    child: Text(
                                      "${entries[index].startTime.hour}:${entries[index].startTime.minute < 10 ? "0${entries[index].startTime.minute}" : entries[index].startTime.minute}",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12.sp,
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontVariations: [
                                          AppFontStyles.regularFontVariation
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipColor: (spot) =>
                                  Colors.black.withOpacity(0.8),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final isAmount = spot.barIndex == 0;
                                  final label =
                                      isAmount ? 'Amount' : 'Off-Slot';
                                  return LineTooltipItem(
                                    '$label\n${spot.y.toStringAsFixed(0)} ml',
                                    TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            if (_activeTabIndex == 0 || _activeTabIndex == 1)
                              LineChartBarData(
                                spots: amountSpots.isNotEmpty
                                    ? amountSpots
                                    : [const FlSpot(0, 0)],
                                isCurved: true,
                                curveSmoothness: 0.3, // Smoother curve
                                preventCurveOverShooting: true,
                                color: topLineColor,
                                barWidth: 3.w,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, barData) =>
                                      spot.y != 0,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 3.w,
                                      color: topDotColor,
                                      strokeWidth: 0,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      topLineColor.withOpacity(0.4),
                                      topLineColor.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            if (_activeTabIndex == 2 || _activeTabIndex == 1)
                              LineChartBarData(
                                spots: offslotSpots.isNotEmpty
                                    ? offslotSpots
                                    : [const FlSpot(0, 0)],
                                isCurved: true,
                                curveSmoothness: 0.3, // Smoother curve
                                preventCurveOverShooting: true,
                                color: bottomLineColor,
                                barWidth: 3.w,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, barData) =>
                                      spot.y != 0,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 3.w,
                                      color: bottomDotColor,
                                      strokeWidth: 0,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      bottomLineColor.withOpacity(0.4),
                                      bottomLineColor.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildListContent(HydrationState state) {
    List<HydrationEntry> scheduledEntries = state.entries;
    List<HydrationEntry> offslotEntries =
        state.entries.where((e) => e.offslot > 0).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeTabIndex == 0 || _activeTabIndex == 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Scheduled Records",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                Text(
                  "VIEW ALL",
                  style: TextStyle(
                    color: AppColors.bluegray.withOpacity(0.7),
                    fontSize: AppFontStyles.fontSize_12,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.dim16.h),
            if (scheduledEntries.isEmpty)
              _buildSlotItemIndicator("No Schedule Records",
                  "No Schedule consumption logged", "0 ml", false)
            else
              ...scheduledEntries
                  .where((e) => e.waterDrank.toInt() >= e.amount.toInt())
                  .map((e) => _buildSlotItemIndicator(
                      e.slot.label,
                      e.formattedRange,
                      "${e.waterDrank.toInt()}/${e.amount.toInt()} ml",
                      e.status == HydrationStatus.completed)),
            SizedBox(height: AppDimensions.dim25.h),
          ],
          if (_activeTabIndex == 2 || _activeTabIndex == 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Off-Slot",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                Text(
                  "VIEW ALL",
                  style: TextStyle(
                    color: AppColors.bluegray.withOpacity(0.7),
                    fontSize: AppFontStyles.fontSize_12,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.dim16.h),
            if (offslotEntries.isEmpty)
              _buildSlotItemIndicator("No Off-Slot Records",
                  "No off-slot consumption logged", "0 ml", false)
            else
              ...offslotEntries
                  .map((e) => _buildSlotItemIndicator(
                      e.slot.label,
                      "Off-slot consumption",
                      "${e.offslot.toInt()} ml",
                      e.offslot > 0))
                  .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotItemIndicator(
      String title, String subtitle, String amountText, bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.dim12.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
        border: Border.all(
            color: AppColors.greyColorText1.withValues(alpha: 0.3), width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.dim10.w),
            decoration: BoxDecoration(
              color: Color(0xFFE2EFFD).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              AssetsPath.timeAnaIcon,
              width: 40.w,
              height: 40.w,
            ),
          ),
          SizedBox(width: AppDimensions.dim16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_16,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "$subtitle   |   $amountText",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: AppFontStyles.fontSize_12,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.dim8.w),
          if (isCompleted)
            Padding(
              padding: EdgeInsets.only(right: 15.w),
              child: Image.asset(
                AssetsPath.doneAnaIcon,
                width: 25.w,
                height: 25.w,
              ),
            ),
        ],
      ),
    );
  }
}
