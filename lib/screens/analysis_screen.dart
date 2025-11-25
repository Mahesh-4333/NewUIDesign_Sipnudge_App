import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/screens/widgets/chart_widgets/custom_chart_data_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/drink_types_widget.dart';
import 'package:hydrify/screens/widgets/date_filter_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image:
              AssetImage("assets/images/app_background.png"), // your image path
          fit: BoxFit.cover,
        ),
        // gradient: LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [
        //     AppColors.gradientStart,
        //     AppColors.gradientEnd,
        //   ],
        // ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: AppDimensions.defaultPadding.w,
            bottom: AppDimensions.dim20.w,
          ),
          child: ListView(
            children: [
              DateFilterWidget(),
              SizedBox(
                height: AppDimensions.dim25.h,
              ),
              CustomChartDataWidget(),
              SizedBox(
                height: AppDimensions.dim25.h,
              ),
              DrinkTypesWidget(),
            ],
          ),
        ),
      ),
    ));
  }
}
