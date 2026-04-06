import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DataAndAnalyticsPage extends StatefulWidget {
  const DataAndAnalyticsPage({super.key});

  @override
  State<DataAndAnalyticsPage> createState() => _DataAndAnalyticsPageState();
}

class _DataAndAnalyticsPageState extends State<DataAndAnalyticsPage> {
  bool isYearly = true;
  int selectedYear = 2026;
  String selectedMonth = "Jan";

  final List<int> years = [
    2019,
    2020,
    2021,
    2022,
    2023,
    2024,
    2025,
    2026,
    2027,
    2028,
    2029,
    2030
  ];
  final List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Column(
                    children: [
                      _buildToggle(),
                      SizedBox(height: 20.h),
                      _buildSelectionGrid(),
                      SizedBox(height: 20.h),
                      _buildIntakeCard(),
                      SizedBox(height: 20.h),
                      _buildDistributionCard(),
                      SizedBox(height: 20.h),
                      _buildHabitConsistencyCard(),
                      SizedBox(height: 20.h),
                      _buildSmartInsightsCard(),
                      SizedBox(height: 20.h),
                      _buildBreakdownSection(),
                      SizedBox(
                          height:
                              100.h), // Space for bottom nav or just padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.raisinblack),
          ),
          Text(
            'Data & Analytics',
            style: TextStyle(
              color: AppColors.raisinblack,
              fontSize: 22.sp,
              fontFamily: AppFontStyles.lexendFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.calendar_month,
                  color: AppColors.lightSkyBlue, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 45.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isYearly = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      !isYearly ? AppColors.lightSkyBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Text(
                  'Monthly',
                  style: TextStyle(
                    color: !isYearly ? Colors.white : AppColors.greyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isYearly = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isYearly ? AppColors.lightSkyBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Text(
                  'Yearly',
                  style: TextStyle(
                    color: isYearly ? Colors.white : AppColors.greyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionGrid() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.chevron_left, color: AppColors.greyColor, size: 20.sp),
              Text(
                isYearly ? selectedYear.toString() : selectedMonth,
                style: TextStyle(
                  color: AppColors.raisinblack,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.greyColor, size: 20.sp),
            ],
          ),
          SizedBox(height: 15.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: (isYearly ? years : months).map((item) {
              bool isSelected =
                  isYearly ? (item == selectedYear) : (item == selectedMonth);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isYearly) {
                      selectedYear = item as int;
                    } else {
                      selectedMonth = item as String;
                    }
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 100.w) / 4,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.lightSkyBlue.withOpacity(0.1)
                        : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(10.r),
                    border: isSelected
                        ? Border.all(color: AppColors.lightSkyBlue, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.lightSkyBlue
                            : AppColors.greyColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.lightSkyBlue, "Goal Met"),
              SizedBox(width: 20.w),
              _buildLegendItem(
                  AppColors.lightSkyBlue.withOpacity(0.3), "Partial"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(label,
            style: TextStyle(color: AppColors.greyColor, fontSize: 10.sp)),
      ],
    );
  }

  Widget _buildIntakeCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isYearly ? 'Yearly Intake: 2025' : 'Monthly Intake: $selectedMonth',
            style: TextStyle(
              color: AppColors.raisinblack,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: SizedBox(
              height: 180.h,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    showLabels: false,
                    showTicks: false,
                    startAngle: 270,
                    endAngle: 270,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.15,
                      color: AppColors.lightSkyBlue.withOpacity(0.1),
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: 82,
                        width: 0.15,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: AppColors.lightSkyBlue,
                        cornerStyle: CornerStyle.bothCurve,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        positionFactor: 0.1,
                        angle: 90,
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '82%',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.raisinblack,
                              ),
                            ),
                            Text(
                              isYearly
                                  ? 'ANNUAL\nPERFORMANCE'
                                  : 'MONTHLY\nPERFORMANCE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.greyColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("TOTAL INTAKE", "842.4L"),
              _buildStatItem("TARGET", "830L"),
              _buildStatItem("OFF SLOT", "12.4L"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.greyColor,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 4.h),
        Text(value,
            style: TextStyle(
                color: AppColors.raisinblack,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDistributionCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYearly ? 'Quarterly Distribution' : 'Weekly Distribution',
                    style: TextStyle(
                      color: AppColors.raisinblack,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Scheduled vs Off-slot',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '6.2L',
                    style: TextStyle(
                      color: AppColors.lightSkyBlue,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '+12% vs last month',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 150.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'Jan-Mar',
                          'Apr-Jun',
                          'Jul-Sep',
                          'Oct-Dec'
                        ];
                        const monthTitles = ['W1', 'W2', 'W3', 'W4'];
                        final labels = isYearly ? titles : monthTitles;
                        if (value.toInt() < labels.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(labels[value.toInt()],
                                style: TextStyle(
                                    color: AppColors.greyColor,
                                    fontSize: 10.sp)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(0, 8, 4),
                  _buildBarGroup(1, 7, 5),
                  _buildBarGroup(2, 8.5, 3.5),
                  _buildBarGroup(3, 9, 3),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.lightSkyBlue, "Scheduled"),
              SizedBox(width: 20.w),
              _buildLegendItem(
                  AppColors.lightSkyBlue.withOpacity(0.4), "Off-slot"),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.lightSkyBlue,
          width: 35.w,
          borderRadius: BorderRadius.circular(8.r),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: AppColors.lightSkyBlue.withOpacity(0.1),
          ),
          rodStackItems: [
            BarChartRodStackItem(
                0, y2, AppColors.lightSkyBlue.withOpacity(0.4)),
            BarChartRodStackItem(y2, y1, AppColors.lightSkyBlue),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitConsistencyCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Habit Consistency',
                style: TextStyle(
                  color: AppColors.raisinblack,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.lightSkyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Text(
                  'ELITE TIER',
                  style: TextStyle(
                      color: AppColors.lightSkyBlue,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Consistency",
                        style: TextStyle(
                            color: AppColors.greyColor, fontSize: 12.sp)),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Text("92%",
                            style: TextStyle(
                                color: AppColors.raisinblack,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 5.w),
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 18.sp),
                      ],
                    ),
                    Text("Following schedule on-slot drinking",
                        style: TextStyle(
                            color: AppColors.greyColor, fontSize: 10.sp)),
                  ],
                ),
              ),
              Container(
                  width: 1, height: 60.h, color: Colors.grey.withOpacity(0.1)),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Streak",
                        style: TextStyle(
                            color: AppColors.greyColor, fontSize: 12.sp)),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Text("352",
                            style: TextStyle(
                                color: AppColors.raisinblack,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 5.w),
                        Text("days",
                            style: TextStyle(
                                color: AppColors.greyColor, fontSize: 14.sp)),
                        SizedBox(width: 5.w),
                        Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 18.sp),
                      ],
                    ),
                    Text("Consecutive days reaching daily goal",
                        style: TextStyle(
                            color: AppColors.greyColor, fontSize: 10.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.lightSkyBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: AppColors.lightSkyBlue, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "\"Most off-slot drinking happens at 11 PM. Try hydrating more during the day.\"",
                    style: TextStyle(
                        color: AppColors.raisinblack,
                        fontSize: 11.sp,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsightsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF369FFF), Color(0xFF6FB9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightSkyBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 22.sp),
              SizedBox(width: 10.w),
              Text(
                'Elite Smart Insights',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(
            'Your hydration consistency is Peak Performing. Morning intake is up by 14%, significantly reducing mid-day fatigue markers.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12.sp,
                height: 1.5),
          ),
          SizedBox(height: 15.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Optimal Window: 08:00 - 11:30',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold),
                ),
                Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isYearly ? 'Quarterly Breakdown' : 'Monthly Breakdown',
          style: TextStyle(
              color: AppColors.raisinblack,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 15.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final titles = [
              'First Quarter',
              'Second Quarter',
              'Third Quarter',
              'Fourth Quarter'
            ];
            final subTitles = [
              'January to March',
              'April to June',
              'July to September',
              'October to December'
            ];
            final values = ['248.5', '267.1', '255.3', '265.3'];

            return Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 45.w,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightSkyBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.lightSkyBlue.withOpacity(0.2),
                          width: 1),
                    ),
                    child: Center(
                      child: Text(
                        "${(index + 1) * 25}%",
                        style: TextStyle(
                            color: AppColors.lightSkyBlue,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titles[index],
                            style: TextStyle(
                                color: AppColors.raisinblack,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold)),
                        Text(subTitles[index],
                            style: TextStyle(
                                color: AppColors.greyColor, fontSize: 11.sp)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(values[index],
                          style: TextStyle(
                              color: AppColors.raisinblack,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold)),
                      Text("Goal Met",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
