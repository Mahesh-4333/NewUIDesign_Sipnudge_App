import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/models/drink_type_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DrinkTypeChartWidget extends StatelessWidget {
  final double waterPercentage;
  final double foodPercentage;
  final double remainingPercentage;
  final double waterConsumed;
  final double totalPercentage;

  const DrinkTypeChartWidget({
    super.key,
    required this.waterPercentage,
    required this.foodPercentage,
    required this.remainingPercentage,
    required this.waterConsumed,
    required this.totalPercentage,
  });

  List<DrinkTypeData> _prepareChartData() {
    List<DrinkTypeData> chartData = [
      DrinkTypeData(
        category: 'Water',
        percentage: waterPercentage,
        color: Color(0XFF369FFF),
      ),
      DrinkTypeData(
        category: 'Food',
        percentage: foodPercentage,
        color: Color(0Xff0E8B0A),
      ),
    ];
    if (remainingPercentage > 0) {
      chartData.add(
        DrinkTypeData(
          category: 'Remaining',
          percentage: remainingPercentage,
          color: AppColors.redColor.withOpacity(.2),
        ),
      );
    }

    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.dim200.h,
      height: AppDimensions.dim200.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SfCircularChart(
            margin: EdgeInsets.all(0),
            series: <CircularSeries>[
              DoughnutSeries<DrinkTypeData, String>(
                dataSource: _prepareChartData(),
                xValueMapper: (DrinkTypeData data, _) => data.category,
                yValueMapper: (DrinkTypeData data, _) => data.percentage,
                pointColorMapper: (DrinkTypeData data, _) => data.color,
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${totalPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_24.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Text(
              //   '${waterConsumed.toStringAsFixed(0)} ml',
              //   style: TextStyle(
              //     fontSize: AppFontStyles.fontSize_16.sp,
              //     fontFamily: AppFontStyles.urbanistFontFamily,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
