import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LogHydrationWidget extends StatefulWidget {
  const LogHydrationWidget({super.key});

  @override
  State<LogHydrationWidget> createState() => _LogHydrationWidgetState();
}

class _LogHydrationWidgetState extends State<LogHydrationWidget> {
  double _currentAmount = 500;
  double _maxAmount = 1000;
  double _dailyGoalTarget = 2500;
  String _selectedDrink = 'Water';
  List<Map<String, dynamic>> _recentLogs = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  double _dragTempAmount = 0;

  /// Hydration coefficients — how much effective water each ml of a drink
  /// contributes toward the daily goal.
  static const Map<String, double> _hydrationCoefficients = {
    'Water': 1.0,
    'Tea': 0.85,
    'Coffee': 0.8,
    'Juice': 0.9,
    'Milk': 1.5,
  };

  List<DateTime> get _dates {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (index) => today.subtract(Duration(days: index)));
  }

  final List<Map<String, dynamic>> _drinks = [
    {
      'name': 'Water',
      'icon': AssetsPath.awWater,
      'color': Color(0xFF369FFF),
      'glassPerMl': 250,
      'max': 1000,
      'drinkItemName': "Glass"
    },
    {
      'name': 'Coffee',
      'icon': AssetsPath.awCoffee,
      'color': Color(0xFFEA966F),
      'glassPerMl': 150,
      'max': 900,
      'drinkItemName': "Mug"
    },
    {
      'name': 'Tea',
      'icon': AssetsPath.awTea,
      'color': Color(0xFF7E6060),
      'glassPerMl': 250,
      'max': 1000,
      'drinkItemName': "Cup"
    },
    {
      'name': 'Juice',
      'icon': AssetsPath.awJuice,
      'color': Color(0xFF22C55E),
      'glassPerMl': 250,
      'max': 1000,
      'drinkItemName': "Glass"
    },
    {
      'name': 'Milk',
      'icon': AssetsPath.awMilk,
      'color': Color(0xFFB3B3B3),
      'glassPerMl': 200,
      'max': 1000,
      'drinkItemName': "Glass"
    },
  ];

  @override
  void initState() {
    super.initState();
    getdata();
  }

  getdata() async {
    var waterGoal = await SharedPrefsHelper.getWaterGoal();
    setState(() {
      // _drinks[0]['max'] = waterGoal!.toDouble();
      _dailyGoalTarget = waterGoal!.toDouble();
    });
    _fetchLogs();
  }

  _fetchLogs() async {
    final logs = await DatabaseHelper().getHydrationLogs(date: _selectedDate);
    setState(() {
      _recentLogs = logs;
    });
  }

  _deleteLog(int id, double amount, String type) async {
    await DatabaseHelper().deleteHydrationLog(id, amount, type);
    // Refresh home screen for all drink types since every beverage
    // now contributes to the day summary via its hydration coefficient.
    if (mounted) {
      context.read<BleCubit>().triggerRefresh();
    }
    Fluttertoast.showToast(msg: "Log deleted");
    _fetchLogs();
    context.read<HydrationCubit>().refreshAchievementStats();
  }

  _saveLog() async {
    if (_currentAmount <= 0) {
      Fluttertoast.showToast(msg: "Please select an amount");
      return;
    }

    final hydrationCubit = context.read<HydrationCubit>();
    final bleCubit = context.read<BleCubit>();

    await DatabaseHelper().insertHydrationLog(
      _selectedDrink,
      _currentAmount,
      DateTime.now(),
    );

    // All beverages contribute to hydration via their coefficient.
    // effectiveWater = actual ml × hydration coefficient.
    final double coefficient = _hydrationCoefficients[_selectedDrink] ?? 1.0;
    final double effectiveWater = _currentAmount * coefficient;

    await DatabaseHelper().updateHydrationDaySummary(effectiveWater);

    // Update the matching time slot with the effective water amount.
    final entries = hydrationCubit.state.entries;
    final now = DateTime.now();
    final nowTime = TimeOfDay.fromDateTime(now);
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;

    HydrationEntry? targetEntry;
    for (final entry in entries) {
      final startMin = entry.startTime.hour * 60 + entry.startTime.minute;
      final endMin = entry.endTime.hour * 60 + entry.endTime.minute;

      bool isWithin;
      if (startMin < endMin) {
        isWithin = nowMinutes >= startMin && nowMinutes < endMin;
      } else {
        // Crosses midnight
        isWithin = nowMinutes >= startMin || nowMinutes < endMin;
      }

      if (isWithin) {
        targetEntry = entry;
        break;
      }
    }

    if (targetEntry != null) {
      final updatedEntry = targetEntry.copyWith(
        waterDrank: targetEntry.waterDrank + effectiveWater,
      );
      await hydrationCubit.markCompletedByEntries([updatedEntry]);
    } else {
      // No slot matched — still refresh achievement stats.
      await hydrationCubit.markCompletedByEntries([]);
    }

    // Trigger Home Screen refresh for all drink types.
    bleCubit.triggerRefresh();
    hydrationCubit.refreshAchievementStats();
    DatabaseSyncService().syncAll();

    Fluttertoast.showToast(
        msg: "Logged ${_currentAmount.toInt()}ml of $_selectedDrink"
            " (${effectiveWater.toInt()}ml water equivalent)");
    _fetchLogs();
    if (mounted) {
      setState(() {
        _currentAmount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Color(0xffF7F9FB),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LOG HYDRATION",
            style: TextStyle(
              color: AppColors.bluegray,
              fontSize: 16.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Precise measurement tracking for high-performance fluid optimization and metabolic synchronization.",
            style: TextStyle(
              color: AppColors.darkgray,
              fontSize: 12.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              height: 2,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 25.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Progress & Gauge
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F3F3),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DAILY GOAL TARGET",
                          style: TextStyle(
                            color: AppColors.blueWaterIntake,
                            fontSize: 10.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        Text(
                          "${_dailyGoalTarget.toInt()}ml",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          height: 250.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Main Capsule
                              Container(
                                width: 80.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40.r),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40.r),
                                  child: WaterWaveWidget(
                                    fillPercent: _currentAmount / _maxAmount,
                                    speed: Duration(seconds: 3),
                                    amplitude: 4,
                                    waveCount: 3,
                                  ),
                                ),
                              ),
                              // Vertical Drag Handle
                              Padding(
                                padding:
                                    EdgeInsets.only(left: 10.w, right: 35.w),
                                child: GestureDetector(
                                  onVerticalDragStart: (details) {
                                    _dragTempAmount = _currentAmount;
                                  },
                                  onVerticalDragUpdate: (details) {
                                    setState(() {
                                      final drink = _drinks.firstWhere(
                                          (d) => d['name'] == _selectedDrink);
                                      final double step =
                                          drink['glassPerMl'].toDouble();

                                      double trackHeight = 250.h - 30.w;
                                      double delta =
                                          details.primaryDelta! / trackHeight;

                                      // Accumulate raw drag movement
                                      _dragTempAmount = (_dragTempAmount -
                                              (delta * _maxAmount))
                                          .clamp(0.0, _maxAmount);

                                      // Display the snapped amount
                                      _currentAmount = ((_dragTempAmount / step)
                                                  .roundToDouble() *
                                              step)
                                          .clamp(0.0, _maxAmount);
                                    });
                                  },
                                  child: Container(
                                    width: 40.w,
                                    height: 250.h,
                                    color: Colors.transparent,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Track Line
                                        Container(
                                          width: 2.5.w,
                                          height: 220.h,
                                          color: AppColors.blueWaterIntake
                                              .withValues(alpha: 0.8),
                                        ),
                                        // Dynamic Scale Markers
                                        ...(() {
                                          final drink = _drinks.firstWhere(
                                              (d) =>
                                                  d['name'] == _selectedDrink);
                                          final int step = drink['glassPerMl'];
                                          final List<Widget> markers = [];
                                          final double trackRange =
                                              250.h - 30.w;

                                          for (int i = 0;
                                              i <= (_maxAmount / step).floor();
                                              i++) {
                                            double ml = i * step.toDouble();
                                            if (ml > _maxAmount) break;
                                            double percent = ml / _maxAmount;
                                            double top =
                                                (1 - percent) * trackRange;

                                            markers.add(
                                              Positioned(
                                                top: top + 15.w - 5.h,
                                                left: 28.w,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                        width: 5.w,
                                                        height: 1.3.h,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 57, 57, 57)),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      "${ml.toInt()} mL",
                                                      style: TextStyle(
                                                        fontSize: 9.sp,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 31, 31, 31),
                                                        fontFamily: AppFontStyles
                                                            .urbanistFontFamily,
                                                        fontVariations: [
                                                          AppFontStyles
                                                              .boldFontVariation
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          return markers;
                                        })(),
                                        // Drag Handle
                                        Positioned(
                                          top: (1 -
                                                  (_currentAmount /
                                                      _maxAmount)) *
                                              (250.h - 30.w),
                                          child: Container(
                                            width: 30.w,
                                            height: 30.w,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color:
                                                      AppColors.blueWaterIntake,
                                                  width: 2.w),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                )
                                              ],
                                            ),
                                            child: Icon(Icons.drag_handle,
                                                size: 16.sp,
                                                color:
                                                    AppColors.blueWaterIntake),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${_currentAmount.toInt()}",
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.extraBoldFontVariation
                                ],
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "ml",
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Color(0xff6F7883),
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                          ],
                        ),
                        Builder(builder: (context) {
                          final drink = _drinks
                              .firstWhere((d) => d['name'] == _selectedDrink);
                          final double glassPerMl =
                              drink['glassPerMl'].toDouble();
                          final double glassCount = _currentAmount / glassPerMl;
                          final String glassDisplay = glassCount % 1 == 0
                              ? glassCount.toInt().toString()
                              : glassCount.toStringAsFixed(1);

                          final textStyle = TextStyle(
                            fontSize: 15.sp,
                            color: AppColors.blueWaterIntake,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          );

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                drink['icon'],
                                height: 25.h,
                                width: 25.w,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "${_currentAmount.toInt()}mL / ",
                                style: textStyle,
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return ScaleTransition(
                                    scale: Tween<double>(begin: 3, end: 1.0)
                                        .animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.bounceInOut)),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  glassDisplay,
                                  key: ValueKey<String>(glassDisplay),
                                  style: textStyle.copyWith(fontVariations: [
                                    AppFontStyles.extraBoldFontVariation
                                  ]),
                                ),
                              ),
                              Text(
                                " ${drink['drinkItemName']}",
                                style: textStyle,
                              ),
                            ],
                          );
                        })
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Right: Drink Options
                Expanded(
                  flex: 4,
                  child: Column(
                    children: _drinks.map((drink) {
                      bool isSelected = _selectedDrink == drink['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDrink = drink['name'];
                            _currentAmount = drink['glassPerMl'].toDouble();
                            _maxAmount = drink['max'].toDouble();
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.symmetric(
                              vertical: 8.h, horizontal: 8.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? drink['color'].withValues(alpha: 0.2)
                                : Color(0xFFEFF0F0),
                            borderRadius: BorderRadius.circular(50.r),
                            border: isSelected
                                ? Border.all(color: drink['color'])
                                : Border.all(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    width: 2,
                                  ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                drink['icon'],
                                width: 45.w,
                                height: 45.h,
                              ),
                              SizedBox(width: 4.h),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      drink['name'],
                                      style: TextStyle(
                                        fontSize: 17.sp,
                                        color: AppColors.bluegray,
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontVariations: [
                                          AppFontStyles.boldFontVariation
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "${drink['glassPerMl']} ML/${drink['drinkItemName']}",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isSelected
                                            ? drink['color']
                                            : Color(0xff515F74)
                                                .withValues(alpha: 0.5),
                                        fontFamily:
                                            AppFontStyles.urbanistFontFamily,
                                        fontVariations: [
                                          isSelected
                                              ? AppFontStyles
                                                  .extraBoldFontVariation
                                              : AppFontStyles.boldFontVariation
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          Text(
            "Quick Presets",
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [250, 500, 750].map((preset) {
              bool isSelected = _currentAmount.toInt() == preset;
              return GestureDetector(
                onTap: () => setState(() => _currentAmount = preset.toDouble()),
                child: Container(
                  width: 95.w,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFFE2EFFD) : Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.blueWaterIntake.withValues(alpha: 0.3)
                            : Colors.grey.shade100),
                  ),
                  child: Center(
                    child: Text(
                      "${preset}ml",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isSelected
                            ? AppColors.blueWaterIntake
                            : Colors.black,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: _saveLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A3FF),
              minimumSize: Size(double.infinity, 55.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 25.sp),
                SizedBox(width: 8.w),
                Text(
                  "Add to Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.extraBoldFontVariation],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          Container(
            height: 48.h,
            margin: EdgeInsets.only(bottom: 20.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = DateUtils.isSameDay(date, _selectedDate);
                final now = DateTime.now();

                String label;
                if (DateUtils.isSameDay(date, now)) {
                  label = "Today";
                } else if (DateUtils.isSameDay(
                    date, now.subtract(const Duration(days: 1)))) {
                  label = "Yesterday";
                } else {
                  label = DateFormat('EEE, MMM d').format(date);
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _fetchLogs();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: 12.w),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.blueWaterIntake : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.blueWaterIntake
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.blueWaterIntake
                                    .withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                          fontSize: 14.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            isSelected
                                ? AppFontStyles.boldFontVariation
                                : AppFontStyles.regularFontVariation
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Logs",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            height: 300.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: _recentLogs.isEmpty
                ? Center(
                    child: Text(
                      "No logs yet",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: ListView.separated(
                      padding: EdgeInsets.all(15.w),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _recentLogs.length,
                      separatorBuilder: (context, index) => Divider(
                        thickness: 1,
                        color: Colors.grey.shade100,
                        height: 30.h,
                      ),
                      itemBuilder: (context, index) {
                        final log = _recentLogs[index];
                        final id = log['id'] as int;
                        final type = log['type'] as String;
                        final amount = log['consumed'] as double;
                        final timestamp =
                            DateTime.parse(log['timestamp'] as String);
                        final timeStr = DateFormat('hh:mm a').format(timestamp);

                        Color color = const Color(0xFF369FFF);
                        String icon = AssetsPath.awWater;

                        String desc = "";
                        if (type == 'Coffee') {
                          color = const Color(0xFFEA966F);
                          icon = AssetsPath.awCoffee;
                          desc = "Alertness Boost";
                        } else if (type == 'Tea') {
                          color = const Color(0xFF4D758B);
                          icon = AssetsPath.awTea;
                          desc = "Relaxation and focus";
                        } else if (type == 'Juice') {
                          color = const Color(0xFF22C55E);
                          icon = AssetsPath.awJuice;
                          desc = "Morning routine";
                        } else if (type == 'Water') {
                          desc = "Refreshment";
                        }

                        return _buildRecentLog(
                          title: type,
                          time: timeStr,
                          desc: desc,
                          ml: amount.toInt(),
                          color: color,
                          iconPath: icon,
                          onDelete: () => _deleteLog(id, amount, type),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLog({
    required String title,
    required String time,
    required String desc,
    required int ml,
    required Color color,
    required String iconPath,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Image.asset(
            iconPath,
            height: 45.h,
            width: 45.w,
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                Text(
                  "$time • $desc",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${ml}ml",
            style: TextStyle(
              fontSize: 18.sp,
              color: Color(0xFF1E69B3),
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.extraBoldFontVariation],
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline,
              color: Colors.red.shade300,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }
}
