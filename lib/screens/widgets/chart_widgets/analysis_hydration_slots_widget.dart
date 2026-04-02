import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/models/hydration_entry.dart';

class AnalysisHydrationSlotsWidget extends StatefulWidget {
  const AnalysisHydrationSlotsWidget({super.key});

  @override
  State<AnalysisHydrationSlotsWidget> createState() => _AnalysisHydrationSlotsWidgetState();
}

class _AnalysisHydrationSlotsWidgetState extends State<AnalysisHydrationSlotsWidget> {
  int _activeTabIndex = 0; // 0: Scheduled, 1: All, 2: Off-Slot

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationState>(
      builder: (context, state) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
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
            border: Border.all(color: AppColors.bluegray.withOpacity(0.1), width: 1.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabBar(),
              SizedBox(height: AppDimensions.dim25.h),
              
              // Mockup Area Chart Placeholder
              // Text based on the screenshot that shows an area graph
              _buildChartPlaceholder(),
              
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
                    colors: [AppColors.white, AppColors.white, AppColors.bottomnavbar],
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

  Widget _buildChartPlaceholder() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: SizedBox(
        height: 180.h,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(8, (i) => Text(
                "${1000 - i*100}",
                style: TextStyle(color: Colors.grey, fontSize: 10.sp),
              )),
            ),
            Container( // Placeholder for spline charts as shown in the screenshot
               decoration: BoxDecoration(
                 color: Color(0xFFE2EFFD).withOpacity(0.4),
                 borderRadius: BorderRadius.circular(10.r),
               ),
               alignment: Alignment.center,
               child: Text(
                 "[ Area Spline Chart Segment Here ]", 
                 style: TextStyle(color: AppColors.bluegray.withOpacity(0.6), fontSize: 13.sp),
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(HydrationState state) {
    List<HydrationEntry> scheduledEntries = state.entries; // For actual logic
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
             _buildSlotItemIndicator("Wakeup Time", "7:10 am", "550/500 ml", true)
          else 
            ...scheduledEntries.map((e) => _buildSlotItemIndicator(
               e.slot.label, 
               e.formattedRange, 
               "${e.waterDrank.toInt()}/${e.amount.toInt()} ml", 
               e.waterDrank >= e.amount
             )).toList(),

          SizedBox(height: AppDimensions.dim25.h),
          
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
          _buildSlotItemIndicator("Early Morning Boost", "6:45 . Outside regular slot", "100 ml", true),
          _buildSlotItemIndicator("Post breakfast Time", "10:12 . Manual Log", "250 ml", true),
        ],
      ),
    );
  }

  Widget _buildSlotItemIndicator(String title, String subtitle, String amountText, bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.dim12.h),
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim16.w, vertical: AppDimensions.dim16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radius_30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.bluegray.withOpacity(0.1), width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.dim10.w),
            decoration: BoxDecoration(
              color: Color(0xFFE2EFFD).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, color: Color(0xFF6AA7FB), size: 18.w),
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
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF10B981), width: 1.5.w),
            ),
            child: Icon(Icons.check, color: Color(0xFF10B981), size: 14.w),
          ),
        ],
      ),
    );
  }
}
