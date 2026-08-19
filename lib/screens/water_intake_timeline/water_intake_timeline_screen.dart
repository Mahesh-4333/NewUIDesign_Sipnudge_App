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
import 'package:hydrify/constants/app_enums.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/water_intake_timeline/widgets/dialy_target_widget.dart';
import 'package:hydrify/screens/water_intake_timeline/widgets/inline_time_column_update_widget.dart';
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
  int _activeTabIndex = 2; // 0: Completed, 1: Pending, 2: Schedule
  int? _expandedIndex;
  TimeOfDay? tempStartTime;
  TimeOfDay? tempEndTime;
  double waterGoal = 0;
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final hydrationCubit = context.read<HydrationCubit>();
    hydrationCubit.loadSlotsFromDb();
    getWaterGoal();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemKeys.containsKey(index)) {
        final context = _itemKeys[index]!.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> getWaterGoal() async {
    waterGoal = (await SharedPrefsHelper.getUserGoal() ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HydrationCubit, HydrationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          UiUtilsService.showToast(context: context, text: state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
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
                SizedBox(height: 25.h),
                // _getDateWidget(),
                SizedBox(height: 10.h),
                _getProgressWidget(state),
                SizedBox(height: 20.h),
                _getTabBarWidget(),
                SizedBox(height: 20.h),
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
    );
  }

  PreferredSizeWidget _getAppBarWidget() {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      forceMaterialTransparency: true,
      surfaceTintColor: Colors.transparent,
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
      margin: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim20, vertical: AppDimensions.dim10),
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
                Color(0xFFFFFFFF),
                Color(0xFFA5DDFF),
                Color(0xFF3FBAFF)
              ],
              backgroundColor: AppColors.gray400,
              elevation: 0,
              shadowOffset: Offset(0, 0),
              strokeWidth: 11.w,
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
          Expanded(
            child: const DailyTargetWidget(),
          ),
        ],
      ),
    );
  }

  Widget _getTabBarWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 2.w),
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(AppLocalizations.of(context)?.completed ?? "Completed", 0),
          _buildTabItem(AppLocalizations.of(context)?.pending ?? "Pending", 1),
          _buildTabItem(AppLocalizations.of(context)?.schedule ?? "Schedule", 2),
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
                      ]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
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

  Widget _getTabContent(HydrationState state) {
    if (_activeTabIndex == 0) {
      return _buildActivityCompletedView(state);
      // return Padding(
      //   padding: EdgeInsets.only(bottom: 120.h),
      //   child: Stack(
      //     alignment: Alignment.center,
      //     children: [
      //       SizedBox(
      //         width: AppDimensions.dim600,
      //       ),
      //       // Blur overlay
      //       Positioned.fill(
      //         child: ClipRRect(
      //           borderRadius:
      //               BorderRadius.circular(16), // match your card radius
      //           child: BackdropFilter(
      //             filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      //             child: Container(
      //               color: Colors.black.withOpacity(0.2),
      //             ),
      //           ),
      //         ),
      //       ),
      //
      //       // Center Text
      //       Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //         decoration: BoxDecoration(
      //           color: Colors.black.withOpacity(0.7),
      //           borderRadius: BorderRadius.circular(20),
      //         ),
      //         child: const Text(
      //           "Coming Soon",
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // );
    } else if (_activeTabIndex == 1) {
      return _buildActivityPendingView(state);
      // return Padding(
      //   padding: EdgeInsets.only(bottom: 120.h),
      //   child: Stack(
      //     alignment: Alignment.center,
      //     children: [
      //       SizedBox(
      //         width: AppDimensions.dim600,
      //       ),
      //       // Blur overlay
      //       Positioned.fill(
      //         child: ClipRRect(
      //           borderRadius:
      //               BorderRadius.circular(16), // match your card radius
      //           child: BackdropFilter(
      //             filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      //             child: Container(
      //               color: Colors.black.withOpacity(0.2),
      //             ),
      //           ),
      //         ),
      //       ),
      //
      //       // Center Text
      //       Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //         decoration: BoxDecoration(
      //           color: Colors.black.withOpacity(0.7),
      //           borderRadius: BorderRadius.circular(20),
      //         ),
      //         child: const Text(
      //           "Coming Soon",
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // );
    } else {
      return _buildIntakeScheduleView(state);
    }
  }

  Widget _buildActivityCompletedView(HydrationState state) {
    final entries = state.entries
        .where((e) => e.status == HydrationStatus.completed)
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 110.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColorText1.withValues(alpha: 0.7),
            blurRadius: 2,
            offset: Offset(1, 2),
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
                  DateFormat("EEEE, d MMM yyyy").format(DateTime.now()),
                  style: TextStyle(
                    color: AppColors.mediumgray,
                    fontSize: AppFontStyles.fontSize_14,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)?.completedSlots ?? "Completed Slots",
                  style: TextStyle(
                    color: Color(0xFF3FB7FF),
                    fontSize: 14.sp,
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
                          ? (AppLocalizations.of(context)?.noCompletedSlotsYet ?? "No completed slots yet")
                          : (AppLocalizations.of(context)?.allSlotsCompleted ?? "All slots completed!"),
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

  Widget _buildActivityPendingView(HydrationState state) {
    final entries = state.entries
        .where((e) => e.status == HydrationStatus.pending)
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 110.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColorText1.withValues(alpha: 0.7),
            blurRadius: 2,
            offset: Offset(1, 2),
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
                  DateFormat("EEEE, d MMM yyyy").format(DateTime.now()),
                  style: TextStyle(
                    color: AppColors.mediumgray,
                    fontSize: AppFontStyles.fontSize_14,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)?.pendingSlots ?? "Pending Slots",
                  style: TextStyle(
                    color: Color(0xFF3FB7FF),
                    fontSize: 14.sp,
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
                          ? (AppLocalizations.of(context)?.noCompletedSlotsYet ?? "No completed slots yet")
                          : (AppLocalizations.of(context)?.allSlotsCompleted ?? "All slots completed!"),
                      style: TextStyle(
                        color: AppColors.greyColor,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: 20.h, bottom: 30.h),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildCompletedTimelineItem(
                          entries[index], index == entries.length - 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTimelineItem(HydrationEntry entry, bool isLast) {
    final status = _getSlotStatus(entry);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: Column(
              children: [
                _getCompletedSlotIcon(entry.slot.label, status),
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
                      height: 0.9,
                      color: AppColors.bluegray,
                      fontSize: AppFontStyles.fontSize_22,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  Text(
                    entry.formattedRange,
                    style: TextStyle(
                      color: AppColors.greyColorText1,
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
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
                              text: "${entry.waterDrank.toInt()}",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_24,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            TextSpan(
                              // text: " ${entry.amount.toInt()}ml",
                              text: "ml",
                              style: TextStyle(
                                color: AppColors.greyColorText1,
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
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: status == HydrationStatus.completed
                                  ? (AppLocalizations.of(context)?.targetMet ?? "Target Met")
                                  : "${(entry.amount - entry.waterDrank).toInt()}ml",
                              style: TextStyle(
                                color: status == HydrationStatus.completed
                                    ? Color(0xFF3FB7FF)
                                    : Color(0xFF3FB7FF),
                                fontSize: AppFontStyles.fontSize_12,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            if (!(status == HydrationStatus.completed))
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
                        height: 7.h,
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
                          height: 7.h,
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

  HydrationStatus _getSlotStatus(HydrationEntry entry) {
    final entries = context.read<HydrationCubit>().state.entries;

    // Sort slots by start time
    final sorted = [...entries]..sort(
        (a, b) => _toMinutes(a.startTime).compareTo(_toMinutes(b.startTime)));

    final now = TimeOfDay.now();
    final nowMin = _toMinutes(now);

    debugPrint("entry.amount :: ${entry.amount}");
    // 1️⃣ Completed has highest priority
    if (entry.waterDrank >= entry.amount) {
      return HydrationStatus.completed;
    }

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final startMin = _toMinutes(current.startTime);
      final endMin = _toMinutes(current.endTime);

      // ✅ Case 1: Inside slot
      if (nowMin >= startMin && nowMin <= endMin) {
        if (current == entry) {
          return HydrationStatus.ongoing;
        }
        continue;
      }

      // ✅ Case 2: Between slots → use previous
      if (nowMin < startMin) {
        if (i > 0) {
          final previous = sorted[i - 1];
          if (previous == entry && previous.waterDrank < previous.amount) {
            return HydrationStatus.ongoing;
          }
        }
        return HydrationStatus.pending;
      }
    }

    // ✅ Case 3: After last slot
    final last = sorted.last;
    if (nowMin > _toMinutes(last.endTime) &&
        last == entry &&
        last.waterDrank < last.amount) {
      return HydrationStatus.ongoing;
    }

    return HydrationStatus.pending;
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
                      height: 0.9,
                      color: AppColors.bluegray,
                      fontSize: AppFontStyles.fontSize_22,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  Text(
                    entry.formattedRange,
                    style: TextStyle(
                      color: AppColors.greyColorText1,
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
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
                              text: "${entry.waterDrank.toInt()}",
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_24,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            TextSpan(
                              // text: " ${entry.amount.toInt()}ml",
                              text: "ml",
                              style: TextStyle(
                                color: AppColors.greyColorText1,
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
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: isCompleted
                                  ? "Target Met"
                                  : "${(entry.amount - entry.waterDrank).toInt()}ml",
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
                            if (!isCompleted)
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
                        height: 7.h,
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
                          height: 7.h,
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

  Widget _getCompletedSlotIcon(String label, HydrationStatus status) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Stack(
          children: [
            if (status == HydrationStatus.ongoing)
              Image.asset(
                _getSlotIconPath(label, 3),
                width: AppDimensions.dim60,
                height: AppDimensions.dim60,
              ),
            if (status == HydrationStatus.completed)
              Image.asset(
                _getSlotIconPath(label, 1),
                width: AppDimensions.dim60,
                height: AppDimensions.dim60,
              ),
            if (status == HydrationStatus.pending)
              Image.asset(
                _getSlotIconPath(label, 2),
                width: AppDimensions.dim60,
                height: AppDimensions.dim60,
              ),
          ],
        ),
      ],
    );
  }

  Widget _getSlotIcon(String label, bool isCompleted) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Stack(
          children: [
            Image.asset(
              _getSlotIconPath(label, isCompleted ? 1 : 2),
              width: AppDimensions.dim60,
              height: AppDimensions.dim60,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntakeScheduleView(HydrationState state) {
    return Container(
      margin: EdgeInsets.only(bottom: 110.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColorText1.withValues(alpha: 0.7),
            blurRadius: 2,
            offset: Offset(1, 2),
          ),
        ],
        border: Border.all(color: AppColors.bluegray.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xffF7FAFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat("EEEE, d MMM yyyy").format(DateTime.now()),
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
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                  vertical: 10.h, horizontal: AppDimensions.dim5),
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                bool isExpanded = _expandedIndex == index;
                final key = _itemKeys.putIfAbsent(index, () => GlobalKey());

                return Column(
                  key: key,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 19.w, vertical: 12.h),
                      leading: Image.asset(
                        _getSlotIconPathForSchedule(
                            entry.slot.label, isExpanded ? 1 : 2),
                      ),
                      title: SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.slot.label.trim(),
                              style: TextStyle(
                                height: 0.9,
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_22,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            Text(
                              entry.formattedRange,
                              style: TextStyle(
                                color: AppColors.greyColorText1,
                                fontSize: 12.sp,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            )
                          ],
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

                                if (_expandedIndex != null) {
                                  _scrollToIndex(index);
                                }

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
                                radius: 16.w,
                                backgroundColor: AppColors.lightBlue400,
                                child: Icon(
                                  Icons.keyboard_arrow_up,
                                  color: AppColors.white,
                                  size: AppDimensions.dim25,
                                ),
                              ),
                            ),
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
                indent: AppDimensions.dim15,
                endIndent: AppDimensions.dim15,
                color: AppColors.gray400.withValues(alpha: 0.1),
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
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: Offset(0, 0)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _expandedIndex = null),
                child: Text(AppLocalizations.of(context)?.cancelUpper ?? "CANCEL",
                    style: TextStyle(
                        color: AppColors.greyColor,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation])),
              ),
              SizedBox(width: 20.w),
              MaterialButton(
                onPressed: () {
                  final isConflict = isOverlapping(
                    newStart: tempStartTime!,
                    newEnd: tempEndTime!,
                    excludeIndex: _expandedIndex,
                  );

                  if (isConflict) {
                    context
                        .read<HydrationCubit>()
                        .showError(AppLocalizations.of(context)?.timeSlotOverlapping ?? "Time slot overlapping!");
                    return;
                  }

                  // Actually logic to update would go here
                  context.read<HydrationCubit>().updateTimeSlot(
                        slot: entry.slot,
                        newStart: tempStartTime!,
                        newEnd: tempEndTime!,
                      );

                  SharedPrefsHelper.updateAndSaveDeviceConfig();
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
                  child: Text(AppLocalizations.of(context)?.updateUpper ?? "UPDATE",
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

  String _getSlotIconPath(String label, int currentTabIndex) {
    debugPrint("label: $label");
    // completed
    if (currentTabIndex == 1) {
      if (label.contains("Wakeup Time")) {
        return AssetsPath.wakeUpCompleted;
      } else if (label.contains("Breakfast Time")) {
        return AssetsPath.breakfastCompleted;
      } else if (label.contains("Lunch Time")) {
        return AssetsPath.lunchCompleted;
      } else if (label.contains("After Dinner")) {
        return AssetsPath.dinnerCompleted;
      } else if (label.contains("Mid-Afternoon")) {
        return AssetsPath.midAfternoonCompleted;
      } else if (label.contains("Evening")) {
        return AssetsPath.eveningCompleted;
      } else {
        return AssetsPath.midMorningCompleted;
      }

      // pending
    } else if (currentTabIndex == 2) {
      if (label.contains("Wakeup Time")) {
        return AssetsPath.wakeUpPending;
      } else if (label.contains("Breakfast Time")) {
        return AssetsPath.breakfastPending;
      } else if (label.contains("Lunch Time")) {
        return AssetsPath.lunchPending;
      } else if (label.contains("After Dinner")) {
        return AssetsPath.dinnerPending;
      } else if (label.contains("Mid-Afternoon")) {
        return AssetsPath.midAfternoonPending;
      } else if (label.contains("Evening")) {
        return AssetsPath.eveningPending;
      } else {
        return AssetsPath.midMorningPending;
      }

      // ongoing
    } else if (currentTabIndex == 3) {
      if (label.contains("Wakeup Time")) {
        return AssetsPath.wakeUpOngoing;
      } else if (label.contains("Breakfast Time")) {
        return AssetsPath.breakfastOngoing;
      } else if (label.contains("Lunch Time")) {
        return AssetsPath.lunchOngoing;
      } else if (label.contains("After Dinner")) {
        return AssetsPath.dinnerOngoing;
      } else if (label.contains("Mid-Afternoon")) {
        return AssetsPath.midAfternoonOngoing;
      } else if (label.contains("Evening")) {
        return AssetsPath.eveningOngoing;
      } else {
        return AssetsPath.midAfternoonOngoing;
      }
    } else {
      if (label.contains("Wakeup Time")) {
        return AssetsPath.wakeUpSelected;
      } else if (label.contains("Breakfast Time")) {
        return AssetsPath.breakfastSelected;
      } else if (label.contains("Lunch Time")) {
        return AssetsPath.lunchSelected;
      } else if (label.contains("After Dinner")) {
        return AssetsPath.dinnerSelected;
      } else if (label.contains("Mid-Afternoon")) {
        return AssetsPath.midAfternoonSelected;
      } else if (label.contains("Evening")) {
        return AssetsPath.eveningSelected;
      } else {
        return AssetsPath.midAfternoonSelected;
      }
    }
  }

  String _getSlotIconPathForSchedule(String label, int currentTabIndex) {
    debugPrint("label: $label");
    // completed
    if (currentTabIndex == 1) {
      if (label.contains("Wakeup Time")) {
        return AssetsPath.wakeUpSelected;
      } else if (label.contains("Breakfast Time")) {
        return AssetsPath.breakfastSelected;
      } else if (label.contains("Lunch Time")) {
        return AssetsPath.lunchSelected;
      } else if (label.contains("After Dinner")) {
        return AssetsPath.dinnerSelected;
      } else if (label.contains("Mid-Afternoon")) {
        return AssetsPath.midAfternoonSelected;
      } else if (label.contains("Evening")) {
        return AssetsPath.eveningSelected;
      } else {
        return AssetsPath.midAfternoonSelected;
      }
    } else {
      if (label.contains("Wakeup Time")) {
        return AssetsPath.wakeUpUnSelected;
      } else if (label.contains("Breakfast Time")) {
        return AssetsPath.breakfastUnSelected;
      } else if (label.contains("Lunch Time")) {
        return AssetsPath.lunchUnSelected;
      } else if (label.contains("After Dinner")) {
        return AssetsPath.dinnerUnSelected;
      } else if (label.contains("Mid-Afternoon")) {
        return AssetsPath.midAfternoonUnSelected;
      } else if (label.contains("Evening")) {
        return AssetsPath.eveningUnSelected;
      } else {
        return AssetsPath.midMorningUnSelected;
      }
    }
  }

  bool isOverlapping({
    required TimeOfDay newStart,
    required TimeOfDay newEnd,
    int? excludeIndex,
  }) {
    final newStartMin = _toMinutes(newStart);
    final newEndMin = _toMinutes(newEnd);

    // basic validation
    if (newStartMin >= newEndMin) return true;

    final entries = context.read<HydrationCubit>().state.entries;
    for (int i = 0; i < entries.length; i++) {
      if (excludeIndex != null && i == excludeIndex) continue;

      final entry = entries[i];
      final startMin = _toMinutes(entry.startTime);
      final endMin = _toMinutes(entry.endTime);

      // Overlap condition: (StartA < EndB) and (EndA > StartB)
      if (newStartMin < endMin && newEndMin > startMin) {
        return true;
      }
    }

    return false;
  }

  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
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
    return BlocBuilder<BleCubit, BleState>(
      buildWhen: (previous, current) {
        Console.log(
            tag: "home_Screen_biuld",
            value:
                "${previous.currentHydrationValue} : ${current.currentHydrationValue}");

        if (previous.currentHydrationValue != current.currentHydrationValue) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        return FutureBuilder<Map<String, Object?>>(
          future: () async {
            // 🔹 Fetch daily history data
            final history =
                await context.read<BottleDataCubit>().getCurrentDayHistory();

            // 🔹 Fetch user goal (in mL) dynamically from SharedPreferences
            final userGoalMl = await SharedPrefsHelper.getUserGoal() ?? 2000;

            // Compute expected cumulative slot-schedule target at current time
            double expectedPercent = 0.0;
            try {
              final dbHelper = DatabaseHelper();
              final slots = await dbHelper.getAllSlots();
              if (slots.isNotEmpty) {
                expectedPercent =
                    WaterConsumptionCalculator.calculateExpectedPercentage(
                  slots,
                  userGoalMl.toDouble(),
                );
              }
            } catch (_) {}

            return {
              'history': history,
              'userGoalLiters': userGoalMl / 1000.0,
              'expectedPercent': expectedPercent,
            };
          }(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                width: 100,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final history = (snapshot.data!['history'] as num?)?.toDouble() ?? 0.0;
            final userGoalMl =
                ((snapshot.data!['userGoalLiters'] as num?)?.toDouble() ?? 2.0) * 1000;
            final expectedPercent = (snapshot.data!['expectedPercent'] as num?)?.toDouble() ?? 0.0;

            double waterVolumeConsumed = history;
            double completionPercent = userGoalMl > 0
                ? ((waterVolumeConsumed / userGoalMl) * 100.0).clamp(0.0, 100.0)
                : 0.0;

            return SizedBox(
              width: 100.w,
              height: 100.w,
              child: CustomPaint(
                painter: _TimelineArcPainter(
                  percent: completionPercent,
                  expectedPercent: expectedPercent,
                  strokeWidth: strokeWidth > 0 ? strokeWidth : AppDimensions.dim8.w,
                  progressColor: progressColor ?? const Color(0xFF1C8DBB),
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

class _TimelineArcPainter extends CustomPainter {
  final double percent;
  final double expectedPercent;
  final double strokeWidth;
  final Color progressColor;

  _TimelineArcPainter({
    required this.percent,
    required this.expectedPercent,
    required this.strokeWidth,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflatedRect = rect.deflate(strokeWidth * 0.8);

    // Perfectly centered at 12 o'clock top center (gap is 60° centered at top)
    final startAngle = -pi / 3; // -60 degrees
    final sweepAngle = 5 * pi / 3; // 300 degrees total sweep

    // 1. Soft Drop Shadow for Base Arc
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0.r);

    canvas.drawArc(
      deflatedRect.translate(0, 2),
      startAngle,
      sweepAngle,
      false,
      shadowPaint,
    );

    // 2. Base Arc (Clean White)
    final baseArcPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      deflatedRect,
      startAngle,
      sweepAngle,
      false,
      baseArcPaint,
    );

    // 3. Expected Target Arc (Yellow FACC15)
    if (expectedPercent > 0) {
      final yellowArcPaint = Paint()
        ..color = const Color(0xFFFACC15)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final expectedSweep = sweepAngle * (expectedPercent.clamp(0.0, 100.0) / 100.0);
      canvas.drawArc(
        deflatedRect,
        startAngle,
        expectedSweep,
        false,
        yellowArcPaint,
      );
    }

    // 4. Progress Arc (Blue)
    if (percent > 0) {
      final progressArcPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final progressSweep = sweepAngle * (percent.clamp(0.0, 100.0) / 100.0);
      canvas.drawArc(
        deflatedRect,
        startAngle,
        progressSweep,
        false,
        progressArcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineArcPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.expectedPercent != expectedPercent ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor;
  }
}
