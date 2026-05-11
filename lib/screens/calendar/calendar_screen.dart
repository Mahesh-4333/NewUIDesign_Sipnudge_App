import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/calendar/calendar_cubit.dart';
import 'package:hydrify/helpers/common.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/models/google_event.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/schedule_timeline_item.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _selectedMonth = DateTime.now().month - 1;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    context.read<CalendarCubit>().init(DateTime.now());
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarCubit, CalendarState>(
        listenWhen: (previous, current) =>
            previous.isSyncing != current.isSyncing,
        listener: (context, state) {
          if (state.isSyncing) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
            _rotationController.reset();
          }
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            // padding: EdgeInsets.only(
            //   top: AppDimensions.dim100.h,
            // ),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/app_background.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _titleWidget(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SizedBox(
                          //   height: AppDimensions.dim33.h,
                          // ),
                          // Align(
                          //   alignment: Alignment.center,
                          //   child: getTitleCard(),
                          // ),
                          SizedBox(
                            height: AppDimensions.dim49.h,
                          ),
                          CalendarWidget(
                            onCalendarTap: _handleCalendarSelection,
                          ),
                          SizedBox(
                            height: AppDimensions.dim42.h,
                          ),
                          getDailyScheduleTitle(
                              context.read<CalendarCubit>().state.selectedDate),
                          SizedBox(
                            height: AppDimensions.dim19.h,
                          ),
                          getTimeLine(),
                          SizedBox(
                            height: AppDimensions.dim150.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Padding _titleWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Color(0xFF475569)),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ],
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: Color(0xFF5D7B91),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: 48.w), // To balance the back button
        ],
      ),
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
        "Calendar",
        style: TextStyle(
          color: AppColors.bluegray,
          fontSize: AppFontStyles.fontSize_AppBar,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontVariations: [AppFontStyles.boldFontVariation],
        ),
      ),
    );
  }

  Widget getTitleCard() {
    return InkWell(
      onTap: () {
        context.read<CalendarCubit>().syncGoogleCalendar();
        // Navigator.pop(context);
      },
      child: SizedBox(
        height: AppDimensions.dim75.h,
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                "assets/images/calendar_sync_bg_image.svg",
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppDimensions.dim16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/images/google_calendar_image.svg",
                    width: AppDimensions.dim38.w,
                    height: AppDimensions.dim38.w,
                  ),
                  SizedBox(
                    width: AppDimensions.dim16.w,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sync Google Calendar",
                        style: TextStyle(
                          color: AppColors.color_1E293B,
                          fontSize: AppFontStyles.fontSize_14,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      Text(
                        "Add latest events to your workspace schedules",
                        style: TextStyle(
                          color: AppColors.color_64748B,
                          fontSize: AppFontStyles.fontSize_11,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.semiBoldFontVariation],
                        ),
                      )
                    ],
                  ),
                  Spacer(),
                  RotationTransition(
                    turns: _rotationController,
                    child: Icon(
                      Icons.autorenew,
                      color: AppColors.color_1A73E8,
                      size: 22.w,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getDailyScheduleTitle(DateTime selectedDate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Daily Schedule",
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontSize: AppFontStyles.fontSize_30,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
        Spacer(),
        Text(
          selectedDate.toIso8601String(),
          style: TextStyle(
            color: AppColors.color_4D758B,
            fontSize: AppFontStyles.fontSize_12,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.fontWeightVariation600],
          ),
        ),
      ],
    );
  }

  Widget getTimeLine() {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        if (state.status == CalendarStatus.loading) {
          return Padding(
            padding: EdgeInsets.only(top: AppDimensions.dim49.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 1. Consolidate and sort the timeline data dynamically
        List<Map<String, dynamic>> combinedList = [];
        Set<String> overlappingEventIds = {};

        // A. Add all hydration slots
        for (var item in state.dailySchedule) {
          // Keep track of overlapping events so we don't list them twice
          for (var event in item.overlappingEvents) {
            overlappingEventIds.add(event.id);
          }

          final slotTime = DateTime(
            state.selectedDate.year,
            state.selectedDate.month,
            state.selectedDate.day,
            item.entry.startTime.hour,
            item.entry.startTime.minute,
          );

          combinedList.add({
            'isSlot': true,
            'slotItem': item,
            'sortTime': slotTime,
          });
        }

        // B. Add standalone (non-overlapping) Google Events
        for (var event in state.selectedDayEvents) {
          if (!overlappingEventIds.contains(event.id)) {
            combinedList.add({
              'isSlot': false,
              'googleEvent': event,
              'sortTime': event.startTime,
            });
          }
        }

        // C. Sort chronologically
        combinedList.sort((a, b) =>
            (a['sortTime'] as DateTime).compareTo(b['sortTime'] as DateTime));

        if (combinedList.isEmpty) {
          return Center(
            child: Text(
              "No schedule for this day.",
              style: TextStyle(
                fontSize: AppFontStyles.fontSize_16,
                color: AppColors.color_64748B,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
          );
        }

        return Timeline.tileBuilder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          theme: TimelineThemeData(
            nodePosition: .12,
            indicatorTheme: const IndicatorThemeData(
              position: .4,
              color: AppColors.color_D9D9D9,
              size: AppDimensions.dim6,
            ),
            connectorTheme: const ConnectorThemeData(
              color: AppColors.color_D9D9D9,
              thickness: 1,
            ),
          ),
          builder: TimelineTileBuilder.fromStyle(
            contentsAlign: ContentsAlign.basic,
            itemCount: combinedList.length,
            contentsBuilder: (context, index) {
              final itemData = combinedList[index];

              return Padding(
                padding: EdgeInsets.only(
                    left: AppDimensions.dim12.w, bottom: AppDimensions.dim20.h),
                child: _buildRightSideContent(itemData),
              );
            },
            oppositeContentsBuilder: (context, index) {
              final itemData = combinedList[index];
              final isSlot = itemData['isSlot'] as bool;
              String timeText = "";

              if (isSlot) {
                final slotItem = itemData['slotItem'] as ScheduleTimelineItem;
                final start = slotItem.entry.startTime.format(context);
                final end = slotItem.entry.endTime.format(context);
                // timeText = "$start - \n$end";
                timeText = "$start";
              } else {
                final event = itemData['googleEvent'] as GoogleEvent;
                final start = DateFormat('HH:mm').format(event.startTime);
                final end = DateFormat('HH:mm').format(event.endTime);
                timeText = "$start";
              }

              return Padding(
                padding: EdgeInsets.only(
                    bottom: AppDimensions.dim14.h, right: AppDimensions.dim6.w),
                child: Text(
                  timeText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: AppFontStyles.fontSize_12,
                    color: AppColors.color_00050C,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [
                      AppFontStyles.semiBoldFontVariation,
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRightSideContent(Map<String, dynamic> itemData) {
    final isSlot = itemData['isSlot'] as bool;

    if (isSlot) {
      final slotItem = itemData['slotItem'] as ScheduleTimelineItem;

      if (slotItem.overlappingEvents.isEmpty) {
        return getSlotDataContainer(slotData: slotItem.entry);
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            getSlotDataContainer(slotData: slotItem.entry),
            SizedBox(height: AppDimensions.dim8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: getGoogleEventContainer(
                      events: slotItem.overlappingEvents),
                ),
                SizedBox(width: AppDimensions.dim8.w),
                 BlocBuilder<CalendarCubit, CalendarState>(
                  buildWhen: (p, c) => p.unsilencedSlots != c.unsilencedSlots,
                  builder: (context, state) {
                    final isUnsilenced =
                        state.unsilencedSlots.contains(slotItem.entry.slot);

                    return GestureDetector(
                      onTap: isUnsilenced
                          ? null
                          : () async {
                              await NotificationService()
                                  .updateSlotSilenceState(
                                      slotItem.entry, false);
                              if (mounted) {
                                context
                                    .read<CalendarCubit>()
                                    .unsnoozeSlot(slotItem.entry);
                                Fluttertoast.showToast(
                                    msg:
                                        "${slotItem.entry.slot.label} reminder unsilenced");
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.dim12.w,
                            vertical: AppDimensions.dim8.h),
                        decoration: BoxDecoration(
                          color: isUnsilenced
                              ? AppColors.color_22C55E
                              : AppColors.color_3B82F6,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.dim20.w),
                        ),
                        child: Text(
                          isUnsilenced ? "Unsilenced" : "Unsnooze",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: AppFontStyles.fontSize_12,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.boldFontVariation,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      }
    } else {
      final event = itemData['googleEvent'] as GoogleEvent;
      return getGoogleEventContainer(events: [event]);
    }
  }

  Widget getGoogleEventContainer({required List<GoogleEvent> events}) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
          radius: Radius.circular(AppDimensions.dim15.w),
          color: AppColors.color_3B82F6.withOpacity(0.5),
          strokeWidth: AppDimensions.dim2.w,
          dashPattern: [6, 3]),
      child: Container(
        padding: EdgeInsets.all(AppDimensions
            .dim16.w), // Slightly reduced from 22 for better list fit
        decoration: BoxDecoration(
          color: AppColors.color_80EFF6FF,
          // Adding border radius here prevents the background color from bleeding outside the dotted corners
          borderRadius: BorderRadius.circular(AppDimensions.dim15.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          // Loop through all events and render them inside the single container
          children: events.asMap().entries.map((entry) {
            int index = entry.key;
            GoogleEvent event = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: AppColors.color_2563EB,
                      size: AppDimensions.dim16.w,
                    ),
                    SizedBox(width: AppDimensions.dim4.w),
                    Expanded(
                      child: Text(
                        "Google Event",
                        style: TextStyle(
                          fontSize: AppFontStyles.fontSize_8,
                          color: AppColors.color_2563EB,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: AppDimensions.dim8.h),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontStyles.fontSize_14,
                    color: AppColors.color_00050C,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  SizedBox(height: AppDimensions.dim4.h),
                  Text(
                    event.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontStyles.fontSize_10,
                      color: AppColors.color_64748B,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                ],
                if (index < events.length - 1) ...[
                  SizedBox(height: AppDimensions.dim12.h),
                  Divider(
                    color: AppColors.color_3B82F6.withOpacity(0.3),
                    height: 1,
                    thickness: 1,
                  ),
                  SizedBox(height: AppDimensions.dim12.h),
                ]
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget getSlotDataContainer({required HydrationEntry slotData}) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.dim21.w),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(
            AppDimensions.dim15.w,
          ),
          border: Border.all(
              color: AppColors.color_F1F5F9, width: AppDimensions.dim1.w),
          boxShadow: [
            BoxShadow(
                offset: Offset(0, 0),
                blurRadius: AppDimensions.dim7.w,
                color: AppColors.black.withOpacity(.1))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: AppColors.color_3B82F6,
                size: AppDimensions.dim20.w,
              ),
              SizedBox(
                width: AppDimensions.dim12.w,
              ),
              Text(
                "Hydration Goal",
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_8,
                  color: AppColors.color_2563EB,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: AppDimensions.dim13.h,
          ),
          Text(
            "${slotData.slot.label} - intake",
            style: TextStyle(
                fontSize: AppFontStyles.fontSize_15,
                color: AppColors.color_00050C,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [
                  AppFontStyles.boldFontVariation,
                ]),
          ),
          SizedBox(
            height: AppDimensions.dim4.h,
          ),
          Text(
            "Intake : ${slotData.amount.toStringAsFixed(0)}ml",
            style: TextStyle(
                fontSize: AppFontStyles.fontSize_15,
                color: AppColors.color_64748B,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [
                  AppFontStyles.boldFontVariation,
                ]),
          ),
        ],
      ),
    );
  }

  void _handleCalendarSelection() async {
    final currentState = context.read<CalendarCubit>().state;
    final int pickerInitialMonth = currentState.displayedMonth.month - 1;

    final result = await showMonthYearPickerBottomSheet(
      context: context,
      title: "Select Month",
      initialMonth: pickerInitialMonth,
      initialYear: currentState.displayedMonth.year,
    );

    if (result != null) {
      int year = result['year'];
      int rawMonthFromPicker = result['month'];
      final newMonthDate = DateTime(year, rawMonthFromPicker + 1, 1);

      context.read<CalendarCubit>().changeMonthNYear(newMonthDate);
    }
  }

  Future<Map<String, dynamic>?> showMonthYearPickerBottomSheet({
    required BuildContext context,
    required String title,
    required int initialMonth,
    required int initialYear,
    int startYear = 2000,
    int endYear = 2100,
  }) async {
    int selectedMonth = initialMonth;
    int selectedYear = initialYear;
    final completer = Completer<Map<String, dynamic>?>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.dim32),
                  topRight: Radius.circular(AppDimensions.dim32),
                ),
                color: AppColors.white,
              ),
              padding: EdgeInsets.all(AppDimensions.defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppFontStyles.fontSize_24,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: AppColors.black,
                          fontVariations: [
                            AppFontStyles.fontWeightVariation600
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final result = {
                            'month': selectedMonth, // 0-indexed
                            'year': selectedYear,
                            'monthName': CommonHelper.getMonthNameFromZeroIndex(
                                selectedMonth),
                          };
                          Navigator.pop(context);
                          if (!completer.isCompleted)
                            completer.complete(result);
                        },
                        child: Text(
                          AppStrings.done,
                          style: TextStyle(
                            fontSize: AppFontStyles.fontSize_24,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: AppColors.black,
                            fontVariations: [
                              AppFontStyles.fontWeightVariation600
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.dim20.h),

                  // Pickers
                  Expanded(
                    child: Row(
                      children: [
                        // MONTH PICKER
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: initialMonth,
                            ),
                            onSelectedItemChanged: (int index) {
                              VibrationHelper.vibrate(
                                  duration: 15,
                                  amplitude: 100,
                                  playSound: true);
                              setState(() => selectedMonth = index);
                            },
                            selectionOverlay: _buildSelectionOverlay(),
                            children: List<Widget>.generate(12, (int index) {
                              return Center(
                                child: Text(
                                  CommonHelper.getMonthNameFromZeroIndex(index),
                                  style: const TextStyle(
                                      fontSize: 20, color: AppColors.black),
                                ),
                              );
                            }),
                          ),
                        ),

                        // YEAR PICKER
                        Expanded(
                          flex: 1,
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: initialYear - startYear,
                            ),
                            onSelectedItemChanged: (int index) {
                              VibrationHelper.vibrate(
                                  duration: 15,
                                  amplitude: 100,
                                  playSound: true);
                              setState(() => selectedYear = startYear + index);
                            },
                            selectionOverlay: _buildSelectionOverlay(),
                            children: List<Widget>.generate(
                              endYear - startYear + 1,
                              (int index) {
                                final year = startYear + index;
                                return Center(
                                  child: Text(
                                    '$year',
                                    style: const TextStyle(
                                        fontSize: 20, color: AppColors.black),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!completer.isCompleted) completer.complete(null);
    return completer.future;
  }

// Helper to keep selection overlay consistent
  Widget _buildSelectionOverlay() {
    return Center(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.gray400.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class CalendarWidget extends StatelessWidget {
  final VoidCallback? onCalendarTap;
  const CalendarWidget({
    Key? key,
    required this.onCalendarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        SizedBox(height: AppDimensions.dim24.h),
        _buildCalendarBody(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final String currentMonthYear =
            DateFormat('MMMM yyyy').format(state.displayedMonth);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onCalendarTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Schedule View',
                    style: TextStyle(
                      fontSize: AppFontStyles.fontSize_12,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                      color: AppColors.color_4D758B,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        currentMonthYear,
                        style: TextStyle(
                          fontSize: AppFontStyles.fontSize_30,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          color: AppColors.color_4D758B,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        size: 28,
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.color_007AFF,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await context.read<CalendarCubit>().goToToday();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0XFF1E3A8A).withOpacity(.3),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(AppDimensions.dim360.w),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.dim8.h,
                      horizontal: AppDimensions.dim20.w),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: AppFontStyles.fontSize_14,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      color: AppColors.color_007AFF,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarBody() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim24.w, vertical: AppDimensions.dim24.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.dim32.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDaysOfWeek(),
          _buildDatesGrid(),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        return SizedBox(
          width: AppDimensions.dim41.w,
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: AppColors.color_4D758B,
                fontFamily: AppFontStyles.interFontFamily,
                fontSize: AppFontStyles.fontSize_10,
                fontVariations: [AppFontStyles.boldFontVariation],
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatesGrid() {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final DateTime displayDate = state.displayedMonth;

        // 1. Calculate dates for the grid
        final int daysInMonth =
            DateUtils.getDaysInMonth(displayDate.year, displayDate.month);
        final DateTime firstDayOfMonth =
            DateTime(displayDate.year, displayDate.month, 1);

        // weekday returns 1 (Mon) to 7 (Sun).
        // If your grid starts on Monday, use: (firstDayOfMonth.weekday - 1)
        // If your grid starts on Sunday, use: (firstDayOfMonth.weekday % 7)
        final int offset = firstDayOfMonth.weekday % 7;

        // 2. Calculate previous month's trailing dates
        final prevMonth = DateTime(displayDate.year, displayDate.month - 1);
        final int daysInPrevMonth =
            DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

        final List<DateTime> allDates = [];

        // Add trailing days from previous month
        for (int i = offset - 1; i >= 0; i--) {
          allDates.add(
              DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i));
        }

        // Add current month days
        for (int i = 1; i <= daysInMonth; i++) {
          allDates.add(DateTime(displayDate.year, displayDate.month, i));
        }

        // Add leading days for next month to fill the 6x7 grid (42 cells)
        final int remaining = 42 - allDates.length;
        for (int i = 1; i <= remaining; i++) {
          allDates.add(DateTime(displayDate.year, displayDate.month + 1, i));
        }

        return GridView.builder(
          padding: EdgeInsets.only(top: AppDimensions.dim10.h),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allDates.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6.w,
            crossAxisSpacing: 1.w,
          ),
          itemBuilder: (context, index) {
            final dateObj = allDates[index];
            final bool isCurrentMonth = dateObj.month == displayDate.month;

            final bool isSelected = isCurrentMonth &&
                dateObj.day == state.selectedDate.day &&
                dateObj.month == state.selectedDate.month &&
                dateObj.year == state.selectedDate.year;

            final List<GoogleEvent>? googleEventsForSelectedDay =
                state.selectedDayEvents;

            return GestureDetector(
              onTap: () {
                context.read<CalendarCubit>().selectDate(dateObj);
              },
              child: _buildDateCell(dateObj.day, isCurrentMonth, isSelected,
                  googleEventsForSelectedDay?.length ?? 0),
            );
          },
        );
      },
    );
  }

  Widget _buildDateCell(
      int date, bool isCurrentMonth, bool isSelected, int eventsForThisDay) {
    return Center(
      child: Container(
        width: AppDimensions.dim41.h,
        height: AppDimensions.dim41.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.color_007AFF : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.color_007AFF.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.color_007AFF.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: -3,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.toString(),
              style: TextStyle(
                fontFamily: isSelected
                    ? AppFontStyles.interFontFamily
                    : AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_16,
                fontVariations: isSelected
                    ? [AppFontStyles.boldFontVariation]
                    : [AppFontStyles.semiBoldFontVariation],
                color: isSelected
                    ? Colors.white
                    : (isCurrentMonth
                        ? AppColors.color_4D758B.withOpacity(.82)
                        : AppColors.color_CBD5E1D1),
              ),
            ),
            if (eventsForThisDay > 0 || isSelected) ...[
              _buildEventDots(eventsForThisDay),
            ] else ...[
              SizedBox(height: AppDimensions.dim8.h)
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEventDots(int eventCount) {
    if (eventCount <= 0) {
      return SizedBox(height: AppDimensions.dim8.h);
    }

    final displayCount = eventCount.clamp(0, 4);

    return SizedBox(
      height: 8.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(),
              if (displayCount > 1) ...[
                SizedBox(width: 2.w),
                _dot(),
              ],
            ],
          ),
          if (displayCount != 2) ...[
            SizedBox(height: 1.5.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(),
                if (displayCount == 4) ...[
                  SizedBox(width: 2.w),
                  _dot(),
                ],
                if (displayCount == 3) ...[
                  SizedBox(width: 2.w + 3.w),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 3.w,
      height: 3.h,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
