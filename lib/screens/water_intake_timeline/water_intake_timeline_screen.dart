import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/screens/water_intake_timeline/widgets/inline_time_column_update_widget.dart';
import 'package:hydrify/screens/widgets/custom_wheel_inline_time_widget.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:intl/intl.dart';

class WaterIntakeTimelineScreen extends StatefulWidget {
  const WaterIntakeTimelineScreen({super.key});

  @override
  State<WaterIntakeTimelineScreen> createState() => _WaterIntakeTimelineState();
}

class _WaterIntakeTimelineState extends State<WaterIntakeTimelineScreen> {
  String title = "Home";
  bool isSelected = false;
  int _activeTabIndex = 0; // 0: Completed, 1: Pending, 2: Schedule
  int? _expandedIndex;

  TimeOfDay? tempStartTime;
  TimeOfDay? tempEndTime;

  double waterGoal = 0;
  
  @override
  void initState() {
    super.initState();
    context.read<BottomNavCubit>().hideBar();
    final hydrationCubit = context.read<HydrationCubit>();
    final bottleCubit = context.read<BottleDataCubit>();
    final bleCubit = context.read<BleCubit>();
    bleCubit.checkAndResetForNewDay(hydrationCubit
        .generateDefaultHydrationSlots(hydrationCubit.state.goal.toDouble()));
    //hydrationCubit.subscribeToBleUpdates(bleCubit);

    hydrationCubit.loadSlotsFromDb();

    bottleCubit.stream.listen((_) {
      //hydrationCubit.updateSlotCompletionStatus();
    });

    getWaterGoal();
  }

  Future<void> getWaterGoal() async {
    waterGoal = (await SharedPrefsHelper.getUserGoal() ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (result, result1) {
        // Handle back navigation if needed
        context.read<BottomNavCubit>().showBar(); // Refresh data on return
      },
      child: BlocConsumer<HydrationCubit, HydrationState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            UiUtilsService.showToast(
                context: context, text: state.errorMessage!);
          }
        },
        builder: (context, state) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: _getAppBarWidget(),
            body: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: AppDimensions.dim100.h,
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/app_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  _getDateWidget(),
                  SizedBox(height: 10.h),
                  _getProgressWidget(state),
                  SizedBox(height: AppDimensions.dim30),
                  _getTabBarWidget(),
                  SizedBox(height: AppDimensions.dim25),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _getTabContent(state),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _getAppBarWidget() {
    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: SvgPicture.asset(
          "assets/images/back_ic.svg",
          color: AppColors.bluegray,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        AppStrings.waterintaketimeline,
        style: TextStyle(
          color: AppColors.bluegray,
          fontSize: AppFontStyles.fontSize_AppBar,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontVariations: [AppFontStyles.boldFontVariation],
        ),
      ),
    );
  }

  Widget _getDateWidget() {
    final now = DateTime.now();
    final formattedDate = DateFormat("EEEE, d MMM yyyy").format(now);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20, vertical: AppDimensions.dim10),
      padding: EdgeInsets.symmetric(vertical: AppDimensions.dim10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.bluegray.withValues(alpha: 0.1)),
      ),
      alignment: Alignment.center,
      child: Text(
        formattedDate,
        style: TextStyle(
          color: AppColors.steelblue, // Use steelblue constant
          fontSize: 20.sp,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontVariations: [AppFontStyles.boldFontVariation],
        ),
      ),
    );
  }

  Widget _getProgressWidget(HydrationState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Row(
        children: [
          SizedBox(
            height: 100.w,
            width: 100.w,
            child: ProgressCircle(
              gradientColors: const [
                Colors.white,
                Color(0xFF9FDCFF),
                Color(0xFF3FBAFF)
              ],
              backgroundColor: AppColors.gray400,
              elevation: 0,
              shadowOffset: Offset(0, 0),
              strokeWidth: 10.w,
              labelStyle: TextStyle(
                fontSize: 16.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: AppColors.bluegray,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
              subLabelStyle: TextStyle(
                fontSize: 10.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: Color(0xFF00A5FF),
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ),
          SizedBox(width: 30.w),
          Expanded(
            child: FutureBuilder(
              future: (){
                DateTime now = DateTime.now();
                DateTime startDate = DateTime(now.year, now.month, now.day);
                DateTime endDate = startDate
                    .add(const Duration(days: 1))
                    .subtract(const Duration(milliseconds: 1));

                return context
                    .read<BottleDataCubit>()
                    .getHistoryForDateRange(startDate, endDate);
              }(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                double waterVolumeConsumed = 0;
                double completionPercent = 0;

                if (snapshot.hasData || snapshot.data?.isNotEmpty == true) {
                  waterVolumeConsumed =
                      WaterConsumptionCalculator.calculateDailyConsumption(
                          snapshot.data!);

                  completionPercent =
                      WaterConsumptionCalculator.calculateCompletionPercentage(
                          waterVolumeConsumed, waterGoal);
                }

                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${completionPercent.toStringAsFixed(0)} %",
                            style: TextStyle(
                              color: Color(0xFF3FB7FF),
                              fontSize: 22.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          TextSpan(
                            text: " of Daily Target",
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 14.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Connect your Bottle to sync data",
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTabBarWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 55.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
          // Inner shadow simulation
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem("Completed", 0),
          _buildTabItem("Pending", 1),
          _buildTabItem("Schedule", 2),
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
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: AppDimensions.dim8),
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
                      ]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 7,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Color(0xff4D758B)),
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.darkgray,
              fontSize: 14.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getTabContent(HydrationState state) {
    if (_activeTabIndex == 2) {
      return _buildIntakeWindowsView(state);
    } else {
      // return _buildActivityTimelineView(state);
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: AppDimensions.dim600,),
          // Blur overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16), // match your card radius
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),

          // Center Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Coming Soon",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActivityTimelineView(HydrationState state) {
    final entries = _activeTabIndex == 0
        ? state.entries.where((e) => e.waterDrank >= e.amount).toList()
        : state.entries.where((e) => e.waterDrank < e.amount).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.bluegray.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ACTIVITY TIMELINE",
                  style: TextStyle(
                    color: AppColors.mediumgray,
                    fontSize: AppFontStyles.fontSize_14,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "${state.entries.where((e) => e.waterDrank < e.amount).length}/${state.entries.length} SLOTS REMAINING",
                  style: TextStyle(
                    color: Color(0xFF3FB7FF),
                    fontSize: 12.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.bluegray.withOpacity(0.1)),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      _activeTabIndex == 0
                          ? "No completed slots yet"
                          : "All slots completed!",
                      style: TextStyle(
                        color: AppColors.greyColor,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: 20.h, bottom: 20.h),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineItem(
                          entries[index], index == entries.length - 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(HydrationEntry entry, bool isLast) {
    bool isCompleted = entry.waterDrank >= entry.amount;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: Column(
              children: [
                _getSlotIcon(entry.slot.label, isCompleted),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: AppColors.bluegray.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 15.w),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 20.w, bottom: 25.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.slot.label,
                    style: TextStyle(
                      color: AppColors.bluegray,
                      fontSize: AppFontStyles.fontSize_19,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  Text(
                    entry.formattedRange,
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Intake details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${entry.waterDrank.toInt()}ml",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_16,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            TextSpan(
                              text: " / ${entry.amount.toInt()}ml",
                              style: TextStyle(
                                color: Color(0xFF3FB7FF),
                                fontSize: AppFontStyles.fontSize_12,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.semiBoldFontVariation
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: isCompleted
                                  ? "Target Met"
                                  : "${(entry.amount - entry.waterDrank).toInt()} ml",
                              style: TextStyle(
                                color: isCompleted
                                    ? Color(0xFF3FB7FF)
                                    : Color(0xFF3FB7FF),
                                fontSize: AppFontStyles.fontSize_12,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            TextSpan(
                              text: " remaining",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_12,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 6.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.bluegray.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor:
                            (entry.waterDrank / entry.amount).clamp(0.001, 1.0),
                        child: Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Color(0xFF3FB7FF),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSlotIcon(String label, bool isCompleted) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: AppColors.lightBlue400,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15.r),
            border:
                Border.all(color: Color(0xFF3FB7FF).withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(12.w),
          child: Image.asset(
            _getSlotIconPath(label),
            color: isCompleted ? Colors.white : Color(0xFF3FB7FF),
          ),
        ),
        if (isCompleted)
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child:
                Icon(Icons.check_circle, color: Color(0xFF3FB7FF), size: 16.sp),
          ),
      ],
    );
  }

  Widget _buildIntakeWindowsView(HydrationState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.bluegray.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xffF7FAFF),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r),),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child:  Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "INTAKE WINDOWS",
                    style: TextStyle(
                      color: AppColors.greyColorText1,
                      fontSize: AppFontStyles.fontSize_14,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Logic to add slots
                    },
                    child: Text(
                      "Add Slots",
                      style: TextStyle(
                        color: AppColors.blueWaterIntake,
                        fontSize: AppFontStyles.fontSize_14,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.bluegray.withValues(alpha: 0.1)),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                  vertical: 10.h, horizontal: AppDimensions.dim10),
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                bool isExpanded = _expandedIndex == index;

                return Column(
                  children: [
                    ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      leading: Container(
                        width: 45.w,
                        height: 45.w,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppColors.blueWaterIntake
                              : Color(0xFFEFF9FF),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(10.w),
                        child: Image.asset(
                          _getSlotIconPath(entry.slot.label),
                          color: isExpanded ? Colors.white : Color(0xFF3FB7FF),
                        ),
                      ),
                      title: Text(
                        entry.slot.label,
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: AppFontStyles.fontSize_19,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      subtitle: Text(
                        entry.formattedRange,
                        style: TextStyle(
                          color: AppColors.greyColorText1,
                          fontSize: 12.sp,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isExpanded)
                            IconButton(
                              icon: Image.asset(
                                AssetsPath.updateSlot,
                                width: 30.w,
                              ),
                              onPressed: () {
                                setState(() {
                                  _expandedIndex = isExpanded ? null : index;
                                });

                                tempStartTime = null;
                                tempEndTime = null;
                              },
                            ),
                          if (isExpanded)
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    _expandedIndex = isExpanded ? null : index;
                                  });
                                },
                                icon: CircleAvatar(
                                  backgroundColor: AppColors.lightBlue400,
                                  child: Icon(
                                    Icons.keyboard_arrow_up,
                                    color: AppColors.white,
                                    size: AppDimensions.dim30,
                                  ),
                                )),
                        ],
                      ),
                    ),
                    if (isExpanded) _buildInlineTimePicker(entry),
                  ],
                );
              },
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 3,
                indent: AppDimensions.dim20,
                endIndent: AppDimensions.dim20,
                color: AppColors.bluegray.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTimePicker(HydrationEntry entry) {
    return Container(
      margin: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        bottom: 20.h,
      ),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: Offset(0, 0)),
        ],
        border: Border.all(color: AppColors.bluegray.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InlineTimeColumnUpdateWidget(
                  label: "FROM",
                  time: entry.startTime,
                  onTimeChanged: (newTime) {
                    setState(() {
                      tempStartTime = TimeOfDay.fromDateTime(newTime);
                    });
                  }),
              InlineTimeColumnUpdateWidget(
                  label: "TO",
                  time: entry.endTime,
                  onTimeChanged: (newTime) {
                    setState(() {
                      tempEndTime = TimeOfDay.fromDateTime(newTime);
                    });
                  }),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _expandedIndex = null),
                child: Text("CANCEL",
                    style: TextStyle(
                        color: AppColors.greyColor,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation])),
              ),
              SizedBox(width: 20.w),
              MaterialButton(
                onPressed: () {
                  // Actually logic to update would go here
                  context.read<HydrationCubit>().updateTimeSlot(
                        slot: entry.slot,
                        newStart: tempStartTime!,
                        newEnd: tempEndTime!,
                      );

                  setState(() => _expandedIndex = null);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.dim4,
                      horizontal: AppDimensions.dim20),
                  decoration: BoxDecoration(
                    color: AppColors.blueWaterIntake,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.r),
                      bottomLeft: Radius.circular(15.r),
                      bottomRight: Radius.circular(15.r),
                      topRight: Radius.circular(15.r),
                    ),
                  ),
                  child: Text("UPDATE",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation])),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.transparent, // In screenshot it looks like plain text
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF3FB7FF),
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getSlotIconPath(String label) {
    if (label.contains("Wakeup Time")) {
      return AssetsPath.wakeUp;
    } else if (label.contains("Breakfast Time")) {
      return AssetsPath.breakfast;
    } else if (label.contains("Lunch Time")) {
      return AssetsPath.lunch;
    } else if (label.contains("After Dinner")) {
      return AssetsPath.dinner;
    } else if (label.contains("Mid-Afternoon")) {
      return AssetsPath.midAfternoon;
    } else if (label.contains("Evening")) {
      return AssetsPath.evening;
    } else {
      return AssetsPath.midMorning;
    }
  }
}

class ProgressCircle extends StatelessWidget {
  final List<Color>? gradientColors;
  final Color? progressColor;
  final Color backgroundColor;
  final double elevation;
  final Offset shadowOffset;
  final double strokeWidth;
  final TextStyle labelStyle;
  final TextStyle subLabelStyle;

  const ProgressCircle({
    super.key,
    this.gradientColors,
    this.progressColor,
    this.backgroundColor = const Color(0x22AAAAAA),
    this.elevation = 8,
    this.shadowOffset = const Offset(4, 6),
    this.strokeWidth = 14,
    required this.labelStyle,
    required this.subLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottleDataCubit, BottleDataState>(
      buildWhen: (previous, current) =>
          previous.volumePercent != current.volumePercent,
      builder: (context, state) {
        return FutureBuilder<Map<String, Object?>>(
          future: () async {
            // 🔹 Fetch daily history data
            DateTime now = DateTime.now();
            DateTime startDate = DateTime(now.year, now.month, now.day);
            DateTime endDate = startDate
                .add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1));

            final history = await context
                .read<BottleDataCubit>()
                .getHistoryForDateRange(startDate, endDate);

            // 🔹 Fetch user goal (in mL) dynamically from SharedPreferences
            final userGoalMl = await SharedPrefsHelper.getUserGoal() ?? 2000;

            return {
              'history': history,
              'userGoalLiters': userGoalMl / 1000.0,
            };
          }(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final history =
                snapshot.data!['history'] as List<BottleData>? ?? [];
            final userGoalMl =
                (snapshot.data!['userGoalLiters'] as double? ?? 2.0) * 1000;

            double waterVolumeConsumed = 0; // drank in ml

            if (history.isNotEmpty) {
              waterVolumeConsumed =
                  WaterConsumptionCalculator.calculateDailyConsumption(history);
            }

            double percent = (waterVolumeConsumed / userGoalMl).clamp(0.0, 1.0);

            return SizedBox(
              child: CustomPaint(
                painter: GradientCirclePainter(
                  percent: percent,
                  gradientColors: gradientColors,
                  progressColor: progressColor,
                  backgroundColor: backgroundColor,
                  elevation: elevation,
                  shadowOffset: shadowOffset,
                  strokeWidth: strokeWidth,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${waterVolumeConsumed.toInt()}ml",
                        style: labelStyle,
                      ),
                      Text(
                        "/${userGoalMl.toInt()}ml",
                        style: subLabelStyle,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GradientCirclePainter extends CustomPainter {
  final double percent;
  final List<Color>? gradientColors;
  final Color? progressColor;
  final Color backgroundColor;
  final double elevation;
  final Offset shadowOffset;
  final double strokeWidth;

  GradientCirclePainter({
    required this.percent,
    required this.gradientColors,
    required this.progressColor,
    required this.backgroundColor,
    required this.elevation,
    required this.shadowOffset,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width / 2) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // --- Unified shadow for the whole ring ---
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, elevation);

    canvas.save();
    canvas.translate(shadowOffset.dx, shadowOffset.dy);
    canvas.drawCircle(center, radius, shadowPaint);
    canvas.restore();

    // Background (unfinished part)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    Paint progressPaint;
    if (gradientColors != null && gradientColors!.length > 1) {
      final colors = List<Color>.from(gradientColors!);
      colors.add(gradientColors!.first);

      final stops =
          List<double>.generate(colors.length, (i) => i / (colors.length - 1));

      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        transform: GradientRotation(-pi / 2),
        colors: colors,
        stops: stops,
        tileMode: TileMode.clamp,
      );

      progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
    } else {
      progressPaint = Paint()
        ..color = progressColor ?? Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
    }

    canvas.drawArc(rect, -pi / 2, 2 * pi * percent, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant GradientCirclePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.elevation != elevation ||
        oldDelegate.shadowOffset != shadowOffset ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
