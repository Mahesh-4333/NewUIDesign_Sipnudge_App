import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/models/food_scan_data.dart';
import 'package:hydrify/screens/widgets/chart_widgets/food_scanner_widget.dart';
import 'package:hydrify/screens/widgets/chart_widgets/log_hydration_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/services/home_widget_service.dart';
import 'package:intl/intl.dart';

class LogTabScreen extends StatefulWidget {
  const LogTabScreen({super.key});

  @override
  State<LogTabScreen> createState() => _LogTabScreenState();
}

class _LogTabScreenState extends State<LogTabScreen> {
  int _selectedSubTab = 0; // 0: Food Intake, 1: Liquid Intake
  List<FoodScanData> _allFoodLogs = [];
  List<FoodScanData> _foodLogs = [];
  FoodScanData? _selectedFoodLog;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingLogs = false;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  List<DateTime> get _dates {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (index) => today.subtract(Duration(days: index)));
  }

  String _selectedUnit = 'mL';
  StreamSubscription? _configSubscription;

  @override
  void initState() {
    super.initState();
    _loadFoodLogs();
    SharedPrefsHelper.getSelectedUnit().then((unit) {
      if (mounted) {
        setState(() {
          _selectedUnit = unit;
        });
      }
    });
    _configSubscription =
        SharedPrefsHelper.configUpdateStream.stream.listen((_) {
      SharedPrefsHelper.getSelectedUnit().then((unit) {
        if (mounted) {
          setState(() {
            _selectedUnit = unit;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLogs = true;
    });
    try {
      final userEmail = await SharedPrefsHelper.getUserEmail();
      final userId = await SharedPrefsHelper.getUserId();
      List<Map<String, dynamic>> rawScans = [];
      if (userEmail != "guest_user" && userId != null) {
        // Fetch logs starting from 7 days ago to cover the 7-day selector scope
        final startDate = _dates.last;
        final apiScans =
            await ApiService().getFoodScans(userId, startDate: startDate);
        if (apiScans != null) {
          rawScans = apiScans;
        } else {
          // Fallback to local DB
          rawScans = await DatabaseHelper().getAllFoodScans();
        }
      } else {
        // Guest user, use local SQLite
        rawScans = await DatabaseHelper().getAllFoodScans();
      }
      if (mounted) {
        setState(() {
          _allFoodLogs = rawScans.map((m) => FoodScanData.fromMap(m)).toList();
          _filterFoodLogsForSelectedDate();
        });
      }
    } catch (e) {
      debugPrint("Error loading food logs: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  void _filterFoodLogsForSelectedDate() {
    _foodLogs = _allFoodLogs.where((log) {
      final logDate = DateUtils.dateOnly(log.timestamp);
      return DateUtils.isSameDay(logDate, _selectedDate);
    }).toList();
  }

  Future<void> _deleteFoodLog(FoodScanData log) async {
    final userId = await SharedPrefsHelper.getUserId();
    final userEmail = await SharedPrefsHelper.getUserEmail();

    // 1. Queue negative delta for BLE / live hydration value
    await SharedPrefsHelper.addPendingManualDelta(-log.waterContentMl.toInt());

    // 2. Delete locally from SQLite user_food_scanner
    await DatabaseHelper().deleteFoodScanById(
      log.id,
      dishName: log.dishName,
      timestamp: log.timestamp.toIso8601String(),
    );
    await DatabaseHelper().updateHydrationDaySummary(-log.waterContentMl);

    // 3. If it was logged as a beverage (Coffee, Tea, Juice, Milk, Water), also delete from log_hydration
    final String? foodKey = log.foodKey;
    if (foodKey != null && foodKey.toLowerCase() != 'meal') {
      final drinkType =
          foodKey[0].toUpperCase() + foodKey.substring(1).toLowerCase();
      await DatabaseHelper().deleteHydrationLogByTimestampAndType(
        log.timestamp.toIso8601String(),
        drinkType,
      );
      if (userId != null && userEmail != "guest_user") {
        final localDateStr =
            '${log.timestamp.year.toString().padLeft(4, '0')}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
        ApiService()
            .deleteManualLog(
          userId,
          drinkType,
          log.waterContentMl,
          log.timestamp.toIso8601String(),
          localDate: localDateStr,
        )
            .catchError((_) => false);
      }
    }

    // 4. Delete food scan on backend server
    if (userId != null && userEmail != "guest_user") {
      final String? validServerId = (log.serverId != null &&
              log.serverId!.isNotEmpty &&
              log.serverId!.length == 24)
          ? log.serverId
          : null;

      await ApiService().deleteFoodScan(
        userId,
        scanId: validServerId,
        dishName: log.dishName,
        timestamp: log.timestamp.toUtc().toIso8601String(),
        localTimestamp: log.timestamp.toIso8601String(),
      );
    }

    if (_selectedFoodLog?.id != null && _selectedFoodLog?.id == log.id) {
      _selectedFoodLog = null;
    }
    Fluttertoast.showToast(msg: "Food log deleted");

    // 5. Reload list
    await _loadFoodLogs();

    // 5. Notify all charts, cubits & UI listeners
    if (mounted) {
      context.read<BleCubit>().triggerRefresh();
      context.read<BleCubit>().syncPendingManualDelta();
      context.read<HydrationCubit>().loadSlotsFromDb();
      context.read<HydrationCubit>().refreshAchievementStats();
      context.read<BottleDataCubit>().getCurrentDayHistory();
      SyncBus.instance.notifySyncComplete();
      try {
        HomeWidgetService.updateWidgetData();
      } catch (_) {}
    }
  }

  Widget _buildFoodIcon(FoodScanData log) {
    Widget? imageWidget;

    // 1. Check base64 first (most reliable for offline & local scans)
    if (log.imageBase64 != null && log.imageBase64!.isNotEmpty) {
      try {
        final decodedBytes = base64Decode(log.imageBase64!);
        imageWidget = Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _defaultFoodIcon(),
        );
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
    }

    // 2. Fall back to image file/URL path
    if (imageWidget == null &&
        log.imagePath != null &&
        log.imagePath!.isNotEmpty) {
      if (log.imagePath!.startsWith('http')) {
        imageWidget = Image.network(
          log.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _defaultFoodIcon(),
        );
      } else if (log.imagePath!.startsWith('/uploads/')) {
        imageWidget = Image.network(
          "https://api.sipnudge.com${log.imagePath}",
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _defaultFoodIcon(),
        );
      } else {
        try {
          final file = File(log.imagePath!);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => _defaultFoodIcon(),
            );
          }
        } catch (_) {}
      }
    }

    imageWidget ??= _defaultFoodIcon();

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }

  Widget _defaultFoodIcon() {
    return Icon(
      Icons.restaurant_menu_rounded,
      color: const Color(0xFF003057),
      size: 20.sp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
            child: Column(
              children: [
                SizedBox(height: AppDimensions.dim16.h),
                // Pill Switcher Header
                _buildSubTabSwitcher(loc),
                SizedBox(height: AppDimensions.dim20.h),
                // Tab Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedSubTab,
                    children: [
                      _buildFoodIntakeView(loc),
                      _buildLiquidIntakeView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabSwitcher(AppLocalizations? loc) {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: const Color(0xFFDCDCE2), width: 1.5.w),
      ),
      child: Row(
        children: [
          // Food Intake tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubTab = 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: _selectedSubTab == 0
                      ? const Color(0xFFE8F4FD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.r),
                  border: _selectedSubTab == 0
                      ? Border.all(color: const Color(0xFFB1D5F6), width: 1.w)
                      : null,
                ),
                child: Row(
                  children: [
                    // Icon circle container on the left
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _selectedSubTab == 0
                            ? const Color(0xFFC2E7FF)
                            : const Color(0xFFE2E2E9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        AssetsPath.foodIntake,
                        width: 22.w,
                        height: 22.w,
                        color: _selectedSubTab == 0
                            ? const Color(0xFF004A77)
                            : const Color(0xFF3F474F),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          loc?.foodIntake ?? "Food Intake",
                          style: TextStyle(
                            color: const Color(0xFF191C1E),
                            fontSize: 15.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              _selectedSubTab == 0
                                  ? AppFontStyles.boldFontVariation
                                  : AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Dummy space to offset the icon size and perfectly center the text
                    // SizedBox(width: 44.w),
                  ],
                ),
              ),
            ),
          ),
          // Liquid Intake tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubTab = 1),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: _selectedSubTab == 1
                      ? const Color(0xFFE8F4FD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.r),
                  border: _selectedSubTab == 1
                      ? Border.all(color: const Color(0xFFB1D5F6), width: 1.w)
                      : null,
                ),
                child: Row(
                  children: [
                    // Dummy space to offset the icon size and perfectly center the text
                    // SizedBox(width: 30.w),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          loc?.liquidIntake ?? "Liquid Intake",
                          style: TextStyle(
                            color: const Color(0xFF191C1E),
                            fontSize: 15.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              _selectedSubTab == 1
                                  ? AppFontStyles.boldFontVariation
                                  : AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Icon circle container on the right
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _selectedSubTab == 1
                            ? const Color(0xFFC2E7FF)
                            : const Color(0xFFE2E2E9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        AssetsPath.liquidIntake,
                        width: 22.w,
                        height: 22.w,
                        color: _selectedSubTab == 1
                            ? const Color(0xFF004A77)
                            : const Color(0xFF3F474F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodIntakeView(AppLocalizations? loc) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 200.h),
      physics: const BouncingScrollPhysics(),
      children: [
        FoodScannerWidget(
          key: ValueKey(
              '${_selectedFoodLog?.id}_${_selectedFoodLog?.serverId}_${_selectedFoodLog?.dishName}_${_selectedFoodLog?.foodKey}_${_selectedFoodLog?.weightG}'),
          selectedScan: _selectedFoodLog,
          onScanCompleted: () {
            setState(() {
              _selectedDate = DateUtils.dateOnly(DateTime.now());
              _selectedFoodLog = null;
            });
            _loadFoodLogs();
          },
        ),
        SizedBox(height: AppDimensions.dim20.h),
        // 7 Days Date Selector
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
                  if (DateUtils.isSameDay(date, _selectedDate)) return;
                  setState(() {
                    _selectedDate = date;
                    _selectedFoodLog = null;
                    _foodLogs = []; // clear immediately so old data doesn't flash
                  });
                  _loadFoodLogs();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: 12.w,
                    left: index == 0 ? 0.w : 0,
                  ),
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
                              color: AppColors.blueWaterIntake.withOpacity(0.2),
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
                        color: isSelected ? Colors.white : Colors.grey.shade600,
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
        // Recent Logs Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc?.recentLogs ?? "Recent Logs",
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: 20.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     // Future enhancement: show all logs
            //   },
            //   child: Text(
            //     (loc?.viewAll ?? "View All"),
            //     style: TextStyle(
            //       color: const Color(0xFF007BFF),
            //       fontSize: 14.sp,
            //       fontFamily: AppFontStyles.urbanistFontFamily,
            //       fontVariations: [AppFontStyles.boldFontVariation],
            //     ),
            //   ),
            // ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_isLoadingLogs)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_foodLogs.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 30.h),
            alignment: Alignment.center,
            child: Text(
              loc?.noDataAvailable ?? "No data available",
              style: TextStyle(
                color: AppColors.greyColorText1,
                fontSize: 14.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 120.h),
            itemCount: _foodLogs.length,
            itemBuilder: (context, index) {
              final log = _foodLogs[index];
              final formattedTime = DateFormat('hh:mm a').format(log.timestamp);
              final isToday = log.timestamp.day == DateTime.now().day &&
                  log.timestamp.month == DateTime.now().month &&
                  log.timestamp.year == DateTime.now().year;

              final isSelected = _selectedFoodLog != null &&
                  ((log.id != null && _selectedFoodLog?.id == log.id) ||
                      (log.serverId != null &&
                          _selectedFoodLog?.serverId == log.serverId) ||
                      (_selectedFoodLog?.dishName == log.dishName &&
                          _selectedFoodLog?.timestamp == log.timestamp));

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedFoodLog = log;
                  });
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.blueWaterIntake
                          : AppColors.bluegray.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.blueWaterIntake.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                  children: [
                    _buildFoodIcon(log),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.dishName,
                            style: TextStyle(
                              color: AppColors.bluegray,
                              fontSize: 15.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "${isToday ? 'Today' : DateFormat('dd MMM').format(log.timestamp)} • $formattedTime • ${log.caloriesKcal.toInt()} kcal",
                            style: TextStyle(
                              color: AppColors.greyColorText1,
                              fontSize: 12.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      HydrationHelper.formatVolume(log.waterContentMl, _selectedUnit, showUnit: true),
                      style: TextStyle(
                        color: const Color(0xFF00A2FF),
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () => _deleteFoodLog(log),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.grey.shade400,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
      ],
    );
  }

  Widget _buildLiquidIntakeView() {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        const LogHydrationWidget(),
        SizedBox(height: 120.h),
      ],
    );
  }
}
