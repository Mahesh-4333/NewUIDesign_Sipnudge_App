import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/data_analytics/data_analytics_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';
import 'package:hydrify/services/home_widget_service.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:hydrify/l10n/app_localizations.dart';

class LogHydrationWidget extends StatefulWidget {
  const LogHydrationWidget({super.key});

  @override
  State<LogHydrationWidget> createState() => _LogHydrationWidgetState();
}

class _LogHydrationWidgetState extends State<LogHydrationWidget> {
  double _currentAmount = 500;
  double _maxAmount = 1000;
  String _selectedUnit = 'mL';
  late StreamSubscription _configSubscription;
  String _selectedDrink = 'Water';
  List<Map<String, dynamic>> _recentLogs = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  double _dragTempAmount = 0;
  bool _isLoadingLogs = false;

  String _getDrinkName(String name, AppLocalizations? l10n) {
    switch (name.toLowerCase()) {
      case 'water':
        return l10n?.water ?? 'Water';
      case 'coffee':
        return l10n?.coffee ?? 'Coffee';
      case 'tea':
        return l10n?.tea ?? 'Tea';
      case 'juice':
        return l10n?.juice ?? 'Juice';
      case 'milk':
        return l10n?.milk ?? 'Milk';
      default:
        return name;
    }
  }

  String _getDrinkItemName(String itemName, AppLocalizations? l10n) {
    switch (itemName.toLowerCase()) {
      case 'glass':
        return l10n?.glass ?? 'Glass';
      case 'mug':
        return l10n?.mug ?? 'Mug';
      case 'cup':
        return l10n?.cup ?? 'Cup';
      default:
        return itemName;
    }
  }

  String _getDrinkDesc(String type, AppLocalizations? l10n) {
    switch (type.toLowerCase()) {
      case 'coffee':
        return l10n?.alertnessBoost ?? 'Alertness Boost';
      case 'tea':
        return l10n?.relaxationAndFocus ?? 'Relaxation and focus';
      case 'juice':
        return l10n?.morningRoutine ?? 'Morning routine';
      case 'water':
      default:
        return l10n?.refreshment ?? 'Refreshment';
    }
  }

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
    SyncBus.instance.addListener(_onSyncComplete);
    // Initialize selected unit from shared preferences
    SharedPrefsHelper.getSelectedUnit().then((unit) {
      if (unit != null) {
        setState(() => _selectedUnit = unit);
      }
    });
    // Listen for unit changes globally
    _configSubscription =
        SharedPrefsHelper.configUpdateStream.stream.listen((_) async {
      final unit = await SharedPrefsHelper.getSelectedUnit();
      if (unit != null && unit != _selectedUnit) {
        setState(() => _selectedUnit = unit);
      }
    });
  }

  void _onSyncComplete() {
    if (mounted) {
      _fetchLogs();
    }
  }

  @override
  void dispose() {
    SyncBus.instance.removeListener(_onSyncComplete);
    _configSubscription.cancel();
    super.dispose();
  }

  getdata() async {
    _fetchLogs();
  }

  bool _isSaving = false;

  _fetchLogs({bool forceServerPull = false}) async {
    setState(() {
      _isLoadingLogs = true;
    });
    try {
      List<Map<String, dynamic>> logs =
          await DatabaseHelper().getHydrationLogs(date: _selectedDate);

      final hasPulled = await SharedPrefsHelper.hasPulledManualLogs();
      if ((!hasPulled || forceServerPull) && logs.isEmpty) {
        final userId = await SharedPrefsHelper.getUserId();
        final userEmail = await SharedPrefsHelper.getUserEmail();
        if (userId != null && userEmail != "guest_user") {
          final dateStr = '${_selectedDate.year.toString().padLeft(4, '0')}-'
              '${_selectedDate.month.toString().padLeft(2, '0')}-'
              '${_selectedDate.day.toString().padLeft(2, '0')}';
          final serverLogs =
              await ApiService().getManualLogs(userId, date: dateStr);

          if (serverLogs != null && serverLogs.isNotEmpty) {
            final db = await DatabaseHelper().database;
            await db.transaction((txn) async {
              for (final log in serverLogs) {
                final type = log['type']?.toString() ?? 'Water';
                final consumed = log['consumed'] != null
                    ? (double.tryParse(log['consumed'].toString()) ?? 0.0)
                    : 0.0;
                final serverId = log['_id']?.toString();

                final rawTimestamp = log['timestamp'];
                final DateTime parsedTs = rawTimestamp is String
                    ? (DateTime.tryParse(rawTimestamp)?.toLocal() ??
                        DateTime.now())
                    : DateTime.now();
                final localTimestampStr = parsedTs.toLocal().toIso8601String();

                List<Map<String, dynamic>> matches = [];
                if (serverId != null) {
                  matches = await txn.query(
                    DatabaseHelper.logHydrationTableName,
                    where: 'server_id = ?',
                    whereArgs: [serverId],
                  );
                }
                if (matches.isEmpty) {
                  matches = await txn.query(
                    DatabaseHelper.logHydrationTableName,
                    where: 'type = ? AND consumed = ? AND timestamp = ?',
                    whereArgs: [type, consumed, localTimestampStr],
                  );
                }

                if (matches.isEmpty) {
                  await txn.insert(
                    DatabaseHelper.logHydrationTableName,
                    {
                      'type': type,
                      'consumed': consumed,
                      'timestamp': localTimestampStr,
                      if (serverId != null) 'server_id': serverId,
                    },
                  );
                } else if (serverId != null &&
                    matches.first['server_id'] == null) {
                  await txn.update(
                    DatabaseHelper.logHydrationTableName,
                    {'server_id': serverId},
                    where: 'id = ?',
                    whereArgs: [matches.first['id']],
                  );
                }
              }
            });

            await SharedPrefsHelper.setHasPulledManualLogs(true);
            logs = await DatabaseHelper().getHydrationLogs(date: _selectedDate);
          }
        }
      }

      if (mounted) {
        setState(() {
          _recentLogs = List<Map<String, dynamic>>.from(logs);
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }

    // Trigger background sync for any unsynced offline logs
    _syncPendingLogs();
  }

  /// Synchronizes any pending offline logs (server_id == null) in the background.
  Future<void> _syncPendingLogs() async {
    try {
      final userId = await SharedPrefsHelper.getUserId();
      final userEmail = await SharedPrefsHelper.getUserEmail();
      if (userId == null || userEmail == "guest_user") return;

      final db = await DatabaseHelper().database;
      final unsynced = await db.query(
        DatabaseHelper.logHydrationTableName,
        where: 'server_id IS NULL',
      );

      for (final log in unsynced) {
        final localId = log['id'] as int;
        final type = log['type']?.toString() ?? 'Water';
        final consumed = (log['consumed'] as num?)?.toDouble() ?? 0.0;
        final rawTs = log['timestamp']?.toString();
        final dt = rawTs != null
            ? (DateTime.tryParse(rawTs) ?? DateTime.now())
            : DateTime.now();
        final utcTs = dt.toUtc().toIso8601String();
        final localDate =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

        final serverId = await ApiService().createManualLog(
          userId,
          type,
          consumed,
          utcTs,
          localDate: localDate,
        );
        if (serverId != null) {
          await DatabaseHelper().updateLogServerId(localId, serverId);
          if (mounted) {
            setState(() {
              final idx = _recentLogs.indexWhere((l) => l['id'] == localId);
              if (idx != -1) {
                final updated = Map<String, dynamic>.from(_recentLogs[idx]);
                updated['server_id'] = serverId;
                _recentLogs[idx] = updated;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error syncing pending logs in background: $e");
    }
  }

  _deleteLog(int localId, double amount, String type, String utcTimestamp,
      String? serverId) async {
    final hydrationCubit = context.read<HydrationCubit>();
    final bleCubit = context.read<BleCubit>();

    final double coefficient =
        DatabaseHelper.hydrationCoefficients[type] ?? 1.0;
    final double effectiveWater = amount * coefficient;

    // Look up server_id from DB if not present in UI model
    String? finalServerId = serverId;
    if (finalServerId == null) {
      final db = await DatabaseHelper().database;
      final dbRecord = await db.query(
        DatabaseHelper.logHydrationTableName,
        where: 'id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (dbRecord.isNotEmpty) {
        finalServerId = dbRecord.first['server_id']?.toString();
      }
    }

    // 1. Optimistic UI update: Remove item from local list instantly
    setState(() {
      _recentLogs.removeWhere((l) => l['id'] == localId);
    });

    Fluttertoast.showToast(msg: AppLocalizations.of(context)?.logDeleted ?? "Log deleted");

    // Queue negative delta for BLE 000A
    await SharedPrefsHelper.addPendingManualDelta(-effectiveWater.toInt());

    // 2. Delete from local SQLite and update daily summary (clamped to >= 0)
    await DatabaseHelper().deleteHydrationLog(localId, amount, type);
    await DatabaseHelper().updateHydrationDaySummary(-effectiveWater);

    // 3. Immediately trigger Cubit & BLE UI updates and notify all chart/graph listeners
    if (mounted) {
      bleCubit.triggerRefresh();
      bleCubit.syncPendingManualDelta();
      hydrationCubit.refreshAchievementStats();
      SyncBus.instance.notifySyncComplete();
    }

    // 4. Background Server Deletion (non-blocking)
    final userId = await SharedPrefsHelper.getUserId();
    final userEmail = await SharedPrefsHelper.getUserEmail();
    if (userId != null && userEmail != "guest_user") {
      final parsedTime =
          DateTime.tryParse(utcTimestamp)?.toLocal() ?? DateTime.now();
      final localDateStr =
          '${parsedTime.year.toString().padLeft(4, '0')}-${parsedTime.month.toString().padLeft(2, '0')}-${parsedTime.day.toString().padLeft(2, '0')}';

      ApiService()
          .deleteManualLog(
        userId,
        type,
        amount,
        utcTimestamp,
        serverId: finalServerId,
        localDate: localDateStr,
      )
          .then((_) {
        if (mounted) {
          context.read<BottleDataCubit>().getCurrentDayHistory();
          context.read<DataAnalyticsCubit>().fetchAnalytics();
        }
      }).catchError((e) {
        debugPrint("Background deleteManualLog error: $e");
      });
    }
  }

  _saveLog() async {
    if (_isSaving) return;

    if (_currentAmount <= 0) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)?.pleaseSelectAnAmount ?? "Please select an amount");
      return;
    }

    final drinkType = _selectedDrink;
    final drinkAmount = _currentAmount;
    final hydrationCubit = context.read<HydrationCubit>();
    final bleCubit = context.read<BleCubit>();
    final now = DateTime.now();
    final utcTimestamp = now.toUtc().toIso8601String();
    final localTimestampStr = now.toLocal().toIso8601String();
    final localDateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final double coefficient =
        DatabaseHelper.hydrationCoefficients[drinkType] ?? 1.0;
    final double effectiveWater = drinkAmount * coefficient;

    setState(() {
      _isSaving = true;
    });

    // 1. Queue positive delta for BLE 000A
    await SharedPrefsHelper.addPendingManualDelta(effectiveWater.toInt());

    // 2. Insert locally first (instant)
    final localId = await DatabaseHelper().insertHydrationLog(
      drinkType,
      drinkAmount,
      now,
    );

    // 2.5. Update local today summary
    await DatabaseHelper().updateHydrationDaySummary(effectiveWater);

    // 3. Optimistic UI update: Insert directly into recent logs list if today is selected
    if (DateUtils.isSameDay(_selectedDate, now)) {
      setState(() {
        _recentLogs.insert(0, {
          'id': localId,
          'type': drinkType,
          'consumed': drinkAmount,
          'timestamp': localTimestampStr,
          'server_id': null,
        });
      });
    }

    // 4. Instant Visual & Haptic Feedback to User
    final l10n = AppLocalizations.of(context);
    final localizedDrink = _getDrinkName(drinkType, l10n);
    final loggedPrefix = l10n?.logged ?? "Logged";
    Fluttertoast.showToast(
      msg:
          "$loggedPrefix ${HydrationHelper.formatVolume(drinkAmount, _selectedUnit, showUnit: true)} of $localizedDrink",
    );

    // 5. Trigger instant Cubit, Chart & Widget refreshes
    if (mounted) {
      bleCubit.triggerRefresh();
      bleCubit.syncPendingManualDelta();
      hydrationCubit.refreshAchievementStats();
      SyncBus.instance.notifySyncComplete();
      try {
        HomeWidgetService.updateWidgetData();
      } catch (_) {}
    }

    // Re-enable button after short debounce
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    });

    // 6. Background Server Sync (Non-blocking - does not freeze UI)
    _syncSingleLogToServer(
      localId: localId,
      type: drinkType,
      amount: drinkAmount,
      utcTimestamp: utcTimestamp,
      localDateStr: localDateStr,
    );
  }

  /// Sends the newly added log to the server in background without blocking UI.
  Future<void> _syncSingleLogToServer({
    required int localId,
    required String type,
    required double amount,
    required String utcTimestamp,
    required String localDateStr,
  }) async {
    try {
      final userId = await SharedPrefsHelper.getUserId();
      final userEmail = await SharedPrefsHelper.getUserEmail();
      if (userId != null && userEmail != "guest_user") {
        final serverId = await ApiService().createManualLog(
          userId,
          type,
          amount,
          utcTimestamp,
          localDate: localDateStr,
        );

        if (serverId != null) {
          await DatabaseHelper().updateLogServerId(localId, serverId);

          if (mounted) {
            setState(() {
              final idx = _recentLogs.indexWhere((l) => l['id'] == localId);
              if (idx != -1) {
                final updated = Map<String, dynamic>.from(_recentLogs[idx]);
                updated['server_id'] = serverId;
                _recentLogs[idx] = updated;
              }
            });
            // Update Cubits with server status in background and notify graph listeners
            context.read<BottleDataCubit>().getCurrentDayHistory();
            context.read<DataAnalyticsCubit>().fetchAnalytics();
            SyncBus.instance.notifySyncComplete();
          }
        }
      }

      // Check for any remaining pending logs
      _syncPendingLogs();
    } catch (e) {
      debugPrint("Background sync error for log id=$localId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w),
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
            (l10n?.logHydration ?? "LOG HYDRATION").toUpperCase(),
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
            l10n?.logHydrationSubtitle ?? "Log every sip from your morning coffee to your workout water to optimize your daily intake.",
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
                          (l10n?.selectedDrink ?? "SELECTED DRINK").toUpperCase(),
                          style: TextStyle(
                            color: AppColors.blueWaterIntake,
                            fontSize: 10.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        Text(
                          _getDrinkName(_selectedDrink, l10n),
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
                                                      "${HydrationHelper.formatVolume(ml, _selectedUnit, showUnit: true)}",
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
                              HydrationHelper.formatVolume(
                                  _currentAmount.toDouble(), _selectedUnit,
                                  showUnit: false),
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
                              _selectedUnit,
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
                                "${HydrationHelper.formatVolume(_currentAmount, _selectedUnit, showUnit: true)} / ",
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
                                " ${_getDrinkItemName(drink['drinkItemName'], l10n)}",
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
                                      _getDrinkName(drink['name'], l10n),
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
                                      "${HydrationHelper.formatVolume(drink['glassPerMl'].toDouble(), _selectedUnit, showUnit: true)}/${_getDrinkItemName(drink['drinkItemName'], l10n)}",
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
            l10n?.quickPresets ?? "Quick Presets",
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
                      "${HydrationHelper.formatVolume(preset.toDouble(), _selectedUnit, showUnit: true)}",
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
            onPressed: _isSaving ? null : _saveLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSaving
                  ? Color(0xFF00A3FF).withValues(alpha: 0.6)
                  : Color(0xFF00A3FF),
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
                  l10n?.addToProgress ?? "Add to Progress",
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
                  label = l10n?.todayText ?? "Today";
                } else if (DateUtils.isSameDay(
                    date, now.subtract(const Duration(days: 1)))) {
                  label = l10n?.yesterday ?? "Yesterday";
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
                  l10n?.recentLogs ?? "Recent Logs",
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
            child: _isLoadingLogs
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _recentLogs.isEmpty
                    ? Center(
                        child: Text(
                          l10n?.noLogsYet ?? "No logs yet",
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
                            final id = log['id'] != null
                                ? (int.tryParse(log['id'].toString()) ?? 0)
                                : 0;
                            final type = log['type']?.toString() ?? 'Water';
                            final amount = log['consumed'] != null
                                ? (double.tryParse(
                                        log['consumed'].toString()) ??
                                    0.0)
                                : 0.0;
                            // server_id for reliable server-side deletion
                            final serverId = log['server_id']?.toString();

                            // Timestamps are stored as UTC in SQLite
                            final rawTimestamp = log['timestamp'];
                            final DateTime timestamp = rawTimestamp is String
                                ? (DateTime.tryParse(rawTimestamp)?.toUtc() ??
                                    DateTime.now().toUtc())
                                : DateTime.now().toUtc();
                            final utcTimestampStr =
                                timestamp.toUtc().toIso8601String();
                            // Display in local time
                            final timeStr = DateFormat('hh:mm a')
                                .format(timestamp.toLocal());

                            Color color = const Color(0xFF369FFF);
                            String icon = AssetsPath.awWater;

                            String desc = _getDrinkDesc(type, l10n);
                            if (type == 'Coffee') {
                              color = const Color(0xFFEA966F);
                              icon = AssetsPath.awCoffee;
                            } else if (type == 'Tea') {
                              color = const Color(0xFF4D758B);
                              icon = AssetsPath.awTea;
                            } else if (type == 'Juice') {
                              color = const Color(0xFF22C55E);
                              icon = AssetsPath.awJuice;
                            } else if (type == 'Milk') {
                              color = const Color(0xFFB3B3B3);
                              icon = AssetsPath.awMilk;
                            }

                            return _buildRecentLog(
                              title: _getDrinkName(type, l10n),
                              time: timeStr,
                              desc: desc,
                              ml: amount.toInt(),
                              color: color,
                              iconPath: icon,
                              onDelete: () => _deleteLog(
                                  id, amount, type, utcTimestampStr, serverId),
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
            HydrationHelper.formatVolume(ml.toDouble(), _selectedUnit,
                showUnit: true),
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
