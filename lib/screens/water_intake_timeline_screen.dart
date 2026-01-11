import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
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

  @override
  void initState() {
    super.initState();
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
          extendBody: true,
          appBar: AppBar(
            elevation: 0.0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              AppStrings.waterintaketimeline,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_AppBar,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          ),
          body: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: AppDimensions.dim120.h,
              left: AppDimensions.dim20.w,
              right: AppDimensions.dim20.w,
            ),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/app_background.png"), // your image path
                fit: BoxFit.cover,
              ),
              // gradient: LinearGradient(
              //   begin: Alignment.topCenter,
              //   end: Alignment.bottomCenter,
              //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
              // ),
            ),
            child: Column(
              children: [
                _getCurrentGoalProgressAndDateWidget(state, context),
                SizedBox(height: AppDimensions.dim20.h),
                buildHydrationTable(context, state),
                SizedBox(height: AppDimensions.dim20.h),
                // const AnimatedBottomNavBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildHydrationTable(BuildContext context, HydrationState state) {
    return Container(
      height: AppDimensions.dim580.h,
      width: double.maxFinite.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            blurRadius: AppDimensions.dim20,
            spreadRadius: AppDimensions.dim2,
            color: Colors.black.withOpacity(.25),
            offset: Offset(0, AppDimensions.dim4.h),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 11.w,
              vertical: 11.h,
            ),
            decoration: BoxDecoration(
              color: Color(0xFFDCF3FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Time",
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_16,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                  Text(
                    //"Water",
                    "Target/Consumed",
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_16,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                  Text(
                    "Status",
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_16,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ListView Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // gradient: LinearGradient(
                //   begin: Alignment.topCenter,
                //   end: Alignment.bottomCenter,
                //   colors: [Color(0XFF917497), Color(0XFF413142)],
                // ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                // physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: false,
                itemCount: state.entries.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white24,
                  height: 1,
                  thickness: 1,
                ),
                itemBuilder: (context, index) {
                  final item = state.entries[index];
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _showTimeEditBottomSheet(context, item.slot);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.slot.label,
                                  style: TextStyle(
                                    color: AppColors.bluegray,
                                    fontSize: AppFontStyles.fontSize_16,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.semiBoldFontVariation
                                    ],
                                    letterSpacing: 0.40.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                // GestureDetector(
                                //   onTap: () {
                                //     _showTimeEditBottomSheet(context, item.slot);
                                //   },
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.formattedRange,
                                      style: TextStyle(
                                        color: AppColors.bluegray,
                                        fontSize: AppFontStyles.fontSize_12,
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontVariations: [
                                          AppFontStyles.semiBoldFontVariation
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 1.w),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom: AppDimensions.dim2.h),
                                      child: GestureDetector(
                                        onTap: () {
                                          _showTimeEditBottomSheet(
                                              context, item.slot);
                                        },
                                        child: SvgPicture.asset(
                                          "assets/images/edit_ic.svg",
                                          fit: BoxFit.fill,
                                          color: AppColors.bluegray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                //),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.only(top: AppDimensions.dim3.h),
                            //child: Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              padding:
                                  EdgeInsets.only(top: AppDimensions.dim3.h),
                              child: Text(
                                // "${item.amount.toInt()} ml / ${item.waterDrank.toInt()} ml",
                                "${item.amount.toInt()} ml / ${item.waterDrank.toInt()} ml",

                                style: TextStyle(
                                  color: AppColors.bluegray,
                                  fontSize: AppFontStyles.fontSize_14,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.semiBoldFontVariation
                                  ],
                                ),
                              ),
                            ),
                            //),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: AppDimensions.dim3.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  item.waterDrank.toInt() >= item.amount.toInt()
                                      ? Icons.check
                                      : Icons.radio_button_unchecked,
                                  size: 16.sp,
                                  color: item.waterDrank.toInt() >=
                                          item.amount.toInt()
                                      ? Color(0xFF0CAE00)
                                      : Color(0xFFC1B50F),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  item.waterDrank.toInt() >= item.amount.toInt()
                                      ? "Completed"
                                      : "Pending",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: AppFontStyles.fontSize_14,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.semiBoldFontVariation
                                    ],
                                    color: item.waterDrank.toInt() >=
                                            item.amount.toInt()
                                        ? Color(0xFF0CAE00)
                                        : Color(0xFFC1B50F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentGoalProgressAndDateWidget(
      HydrationState state, BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat("d MMM yyyy").format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: AppDimensions.dim100.w,
          width: AppDimensions.dim100.w,
          child: BlocBuilder<BottleDataCubit, BottleDataState>(
            buildWhen: (previous, current) =>
                previous.volumePercent != current.volumePercent,
            builder: (context, state) {
              return FutureBuilder(
                future: () async {
                  DateTime startDate = DateTime(now.year, now.month, now.day);
                  DateTime endDate = startDate
                      .add(const Duration(days: 1))
                      .subtract(const Duration(milliseconds: 1));

                  final history = await context
                      .read<BottleDataCubit>()
                      .getHistoryForDateRange(startDate, endDate);

                  final waterVolumeConsumed =
                      WaterConsumptionCalculator.calculateDailyConsumption(
                          history);

                  final userGoalMl =
                      (await SharedPrefsHelper.getUserGoal()) ?? 2000;

                  return {"drank": waterVolumeConsumed, "goal": userGoalMl};
                }(),
                builder: (context, snapshot) {
                  double drank = 0;
                  double goal = 2000;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data as Map<String, dynamic>;
                    drank = data["drank"];
                    goal = data["goal"].toDouble();
                  }

                  return ProgressCircle(
                    // drank: drank.toInt(),
                    // goal: goal.toInt(),
                    gradientColors: const [
                      Colors.white,
                      Color(0xFF9FDCFF),
                      Color(0xFF3FBAFF)
                    ],
                    backgroundColor: Color(0x95FFFFFF),
                    elevation: 8,
                    shadowOffset: Offset(6, 4),
                    strokeWidth: AppDimensions.dim10.w,
                    labelStyle: TextStyle(
                      fontSize: AppFontStyles.fontSize_18,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      shadows: [
                        Shadow(
                            blurRadius: 10,
                            color: AppColors.black.withOpacity(0.25),
                            offset: Offset(0, 2)),
                      ],
                    ),
                    subLabelStyle: TextStyle(
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: Color(0xFF00A5FF),
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                      shadows: [
                        Shadow(
                            blurRadius: 10,
                            color: Colors.black38,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(width: AppDimensions.dim70.w),
        GestureDetector(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Today, $formattedDate",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_20,
                  color: Colors.blueGrey,
                  fontVariations: [AppFontStyles.extraBoldFontVariation],
                  shadows: [
                    Shadow(
                      blurRadius: AppDimensions.dim4,
                      color: Colors.black.withOpacity(.25),
                      offset: Offset(0, AppDimensions.dim2),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: AppDimensions.dim6.h,
              ),
              Text("Touch your Bottle to sync data",
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_14,
                    color: AppColors.touchToBottle,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  )),
            ],
          ),
        ),
      ],
    );
  }

  void _showTimeEditBottomSheet(
    BuildContext context,
    HydrationSlot slot,
  ) {
    final entry = context
        .read<HydrationCubit>()
        .state
        .entries
        .firstWhere((e) => e.slot == slot);

    showModalBottomSheet(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        TimeOfDay? selectedStartTime = entry.startTime;
        TimeOfDay? selectedEndTime = entry.endTime;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart
                    ? (selectedStartTime ?? TimeOfDay.now())
                    : (selectedEndTime ?? TimeOfDay.now()),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF2196F3),
                        onPrimary: Colors.white,
                        surface: AppColors.gradientEnd,
                        onSurface: Colors.white,
                        secondary: Color(0xFFB586BE),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  if (isStart) {
                    selectedStartTime = picked;
                  } else {
                    selectedEndTime = picked;
                  }
                });
              }
            }

            return FractionallySizedBox(
              //heightFactor: 0.55, // Adjust height as needed
              child: Container(
                padding: EdgeInsets.only(
                  left: 25.w,
                  right: 30.w,
                  top: 15.h,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 30.h,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30.r)),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          // "${slot.label} Slot",
                          slot.label,
                          style: TextStyle(
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation
                            ],
                            color: AppColors.black,
                            fontSize: AppFontStyles.fontSize_24,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context, rootNavigator: true)
                                  .pop(context),
                          child: Icon(
                            Icons.close,
                            color: AppColors.black,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Start
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Start Time",
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.semiBoldFontVariation
                                ],
                                color: Colors.black,
                                fontSize: AppFontStyles.fontSize_16,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            GestureDetector(
                              onTap: () => pickTime(true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 14.h),
                                decoration: BoxDecoration(
                                  color: const Color(0x90000000),
                                  borderRadius: BorderRadius.circular(50.r),
                                  border: Border.all(
                                      color: const Color(0x40000000)),
                                ),
                                child: Text(
                                  selectedStartTime != null
                                      ? selectedStartTime!.format(context)
                                      : "Pick Start Time",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppFontStyles.fontSize_16,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.semiBoldFontVariation
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // End
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "End Time",
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.semiBoldFontVariation
                                ],
                                color: Colors.black,
                                fontSize: AppFontStyles.fontSize_16,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            GestureDetector(
                              onTap: () => pickTime(false),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: const Color(0x90000000),
                                  borderRadius: BorderRadius.circular(50.r),
                                  border: Border.all(
                                      color: const Color(0x40000000)),
                                ),
                                child: Text(
                                  selectedEndTime != null
                                      ? selectedEndTime!.format(context)
                                      : "Pick End Time",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppFontStyles.fontSize_16,
                                    fontFamily:
                                        AppFontStyles.urbanistFontFamily,
                                    fontVariations: [
                                      AppFontStyles.semiBoldFontVariation
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.r),
                              ),
                              minimumSize: Size(AppDimensions.dim183.w,
                                  AppDimensions.dim60.h),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                                color: const Color(0xFF2196F3),
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: AppDimensions.dim20.w,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.r),
                              ),
                              minimumSize: Size(AppDimensions.dim183.w,
                                  AppDimensions.dim60.h),
                            ),
                            onPressed: () {
                              if (selectedStartTime != null &&
                                  selectedEndTime != null) {
                                context.read<HydrationCubit>().updateTimeSlot(
                                      slot: slot,
                                      newStart: selectedStartTime!,
                                      newEnd: selectedEndTime!,
                                    );
                              }
                              Navigator.pop(context);
                            },
                            child: Text(
                              "OK",
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

            // ✅ Type-safe casting
            final history =
                snapshot.data!['history'] as List<BottleData>? ?? [];
            final userGoalLiters =
                (snapshot.data!['userGoalLiters'] as double?) ?? 2.0;

            double waterVolumeConsumed = 0; // drank in ml

            if (history.isNotEmpty) {
              waterVolumeConsumed =
                  WaterConsumptionCalculator.calculateDailyConsumption(history);
            }

            double drankLiters = waterVolumeConsumed / 1000; // ml → L
            double percent = (drankLiters / userGoalLiters).clamp(0.0, 1.0);

            return SizedBox(
              width: 200,
              height: 200,
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
                        "${drankLiters.toStringAsFixed(1)}L",
                        style: labelStyle,
                      ),
                      Text(
                        "/${userGoalLiters.toStringAsFixed(1)}L",
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
