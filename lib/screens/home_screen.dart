import 'dart:async';
import 'dart:ui';
import 'package:glassmorphism/glassmorphism.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_info.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/providers/weather_provider.dart';
import 'package:hydrify/screens/hydration_30_day.dart';
import 'package:hydrify/screens/water_intake_timeline/water_intake_timeline_screen.dart';
import 'package:hydrify/screens/widgets/autoScroll_GoalText.dart';
import 'package:hydrify/screens/widgets/ble_device_selection_sheet.dart';
import 'package:hydrify/screens/widgets/custom_circular_loader/custom_circular_progress_indicator.dart';
import 'package:hydrify/screens/widgets/custom_circular_loader/custom_circular_water_progress_indicator.dart';
import 'package:hydrify/screens/widgets/greeting_widget.dart';
import 'package:hydrify/screens/widgets/timezone_change_dialog.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_beating_ble_status_indicator.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/timezone_change_detector.dart';
import 'package:hydrify/services/ai_hydration_engine.dart';
import 'package:hydrify/screens/widgets/ai_hydration_goal_dialog.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrify/helpers/internet_connection_helper.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/home_widget_service.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:hydrify/services/in_app_update_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:hydrify/helpers/showcase_keys.dart';
import 'package:hydrify/screens/widgets/custom_showcase.dart';

class HomeScreen extends StatefulWidget {
  static bool autoTriggerTimelineDrag = false;
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _timezoneTimer;
  Timer? _aiHydrationEngineTimer;
  bool _isTimezoneDialogOpen = false;
  bool _isAiEngineRunning = false;
  StreamSubscription? _configSubscription;
  StreamSubscription? _bottleColorSubscription;
  StreamSubscription<bool>? _internetSubscription;
  StreamSubscription<void>? _locationPermDeniedSubscription;
  bool _isLocationPermDialogShown = false;

  bool _isPickerShown = false;
  bool _isWifiConnectedDialogShown = false;
  bool _isWifiFailedDialogShown = false;
  BuildContext? _wifiProgressDialogContext;
  bool hasConnectedBefore = false;
  bool isGuest = false;
  String selectedBottle = 'purple';
  BottleInfo? bottleInfo;
  int? currentWaterGoal = 0;
  String _selectedUnit = 'mL';

  /// Guard so slot-integrity check runs only once per app session.
  bool _slotsChecked = false;

  Timer? _statsToggleTimer;
  final ValueNotifier<bool> _showAmbientTemp = ValueNotifier<bool>(false);
  final ValueNotifier<double> _timelineDragProgress =
      ValueNotifier<double>(0.0);

  void _checkGuestStatus() async {
    final email = await SharedPrefsHelper.getUserEmail();
    setState(() {
      isGuest = email == "guest_user";
    });
  }

  bool _shouldAutoTrigger = false;

  @override
  void initState() {
    super.initState();
    if (HomeScreen.autoTriggerTimelineDrag) {
      _shouldAutoTrigger = true;
      HomeScreen.autoTriggerTimelineDrag = false;
    }
    SyncBus.instance.addListener(_onSyncComplete);
    WidgetsBinding.instance.addObserver(this);
    SharedPrefsHelper.getWaterGoal().then((e) {
      setState(() {
        currentWaterGoal = e;
      });
    });
    SharedPrefsHelper.getSelectedUnit().then((unit) {
      if (mounted) {
        setState(() {
          _selectedUnit = unit;
        });
      }
    });
    _timezoneTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkTimezoneChange();
    });

    _loadBottle();
    _checkGuestStatus();

    _statsToggleTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _showAmbientTemp.value = !_showAmbientTemp.value;
      }
    });

    NotificationService().init();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var waterGoal = await SharedPrefsHelper.getWaterGoal();
      await DatabaseHelper().saveDailyWaterGoal(DateTime.now(), waterGoal ?? 0);

      final prefs = await SharedPreferences.getInstance();

      final bool hasShownShowcase =
          await SharedPrefsHelper.hasShownHomeShowcase();
      final bool isFirstTimeConfig =
          prefs.getBool('is_first_time_config') ?? true;
      if (hasShownShowcase && isFirstTimeConfig && waterGoal != null) {
        await SharedPrefsHelper.updateAndSaveDeviceConfig(
          waterGoal: waterGoal,
          triggerStream: false,
        );
      }

      hasConnectedBefore = prefs.getBool('ble_connected_once') ?? false;

      if (mounted) {
        context.read<BleCubit>().start();
      }

      // Always trigger full database sync from server to populate local DB on launch
      DatabaseSyncService().syncAll(force: true);

      // Always fetch current day history (from server & local DB) and update BleCubit + HomeWidget
      try {
        var history =
            await context.read<BottleDataCubit>().getCurrentDayHistory();
        if (mounted) {
          context.read<BleCubit>().updateCurrentHydrationValue(history);
          context.read<BleCubit>().triggerRefresh();
        }
        await HomeWidgetService.updateWidgetData();

        final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();
        if (stopWhenFull) {
          double completionPercent =
              await WaterConsumptionCalculator.calculateCompletionPercentage(
                  history);
          Console.log(
              tag: "initState_stopWhenFull",
              value: "completionPercent: $completionPercent");
          if (completionPercent >= 100) {
            final notificationService = NotificationService();
            for (final slot in HydrationSlot.values) {
              await notificationService.cancelSlotReminders(slot, 0);
            }
          }
        }
      } catch (e) {
        Console.log(tag: "HOME", value: "Error during initial data load: $e");
      }

      await _checkAndScheduleHydrationReminders();
      await _initializeTimezoneDetector();
      await _ensureAllSlotsExist();
      InAppUpdateService().checkAndTriggerUpdate();

      // ── AI Hydration Engine: runs every 6 s ──────────
      _aiHydrationEngineTimer =
          Timer.periodic(const Duration(seconds: 6), (timer) async {
        if (_isAiEngineRunning) return;

        if (mounted) {
          try {
            if (ShowCaseWidget.of(context).isShowcaseRunning) {
              return;
            }
          } catch (_) {}
        }

        _isAiEngineRunning = true;
        await _runAiHydrationEngine();
        _isAiEngineRunning = false;
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

      _bottleColorSubscription =
          SharedPrefsHelper.bottleColorUpdateStream.stream.listen((_) {
        _loadBottle();
      });

      // Listen for internet restored to refresh weather and sync data
      _internetSubscription = InternetConnectionHelper()
          .onInternetStatusChanged
          .listen((hasInternet) {
        if (hasInternet && mounted) {
          Console.log(
              tag: "HOME",
              value:
                  "Internet restored, refreshing weather and syncing data...");
          // Refresh weather
          Provider.of<WeatherProvider>(context, listen: false)
              .fetchWeatherForCurrentLocation();
          // Sync database data
          DatabaseSyncService().syncAll(force: true);
        }
      });

      // Listen for permanent location permission denial → show popup
      final weatherProvider =
          Provider.of<WeatherProvider>(context, listen: false);
      _locationPermDeniedSubscription =
          weatherProvider.onPermissionPermanentlyDenied.listen((_) {
        if (mounted && !_isLocationPermDialogShown) {
          _showLocationPermissionDialog();
        }
      });
    });
  }

  void _onSyncComplete() async {
    if (!mounted) return;
    try {
      final history =
          await context.read<BottleDataCubit>().getCurrentDayHistory();
      if (!mounted) return;
      context.read<BleCubit>().updateCurrentHydrationValue(history);
      context.read<BleCubit>().triggerRefresh();
      await HomeWidgetService.updateWidgetData();
      if (mounted) setState(() {});
    } catch (e) {
      Console.log(tag: "HOME", value: "Error in _onSyncComplete: $e");
    }
  }

  @override
  void dispose() {
    SyncBus.instance.removeListener(_onSyncComplete);
    WidgetsBinding.instance.removeObserver(this);
    _timezoneTimer?.cancel();
    _statsToggleTimer?.cancel();
    _aiHydrationEngineTimer?.cancel();
    _configSubscription?.cancel();
    _bottleColorSubscription?.cancel();
    _internetSubscription?.cancel();
    _locationPermDeniedSubscription?.cancel();
    super.dispose();
  }

  void _startShowcaseIfNeeded() async {
    try {
      final bool hasShown = await SharedPrefsHelper.hasShownHomeShowcase();
      if (!hasShown && mounted) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([
            ShowcaseKeys.messageNotificationKey,
            ShowcaseKeys.batteryIndicatorKey,
            ShowcaseKeys.weatherInfoKey,
            ShowcaseKeys.refillsSlotKey,
            ShowcaseKeys.bottleProgressKey,
            ShowcaseKeys.bottomNavKey,
          ]);
          await SharedPrefsHelper.setHasShownHomeShowcase(true);
        }
      }
    } catch (e) {
      debugPrint("Error starting showcase: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Console.log(
          tag: "HOME",
          value: "App resumed, clearing stale image cache, refreshing weather and syncing data...");

      // 1. Clear stale iOS Metal / GPU texture cache purged during long background sleep
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Reset timeline drag progress so dimming/blur overlay is removed
      _timelineDragProgress.value = 0.0;

      // 3. Reload bottle info & graphics
      _loadBottle();

      // 4. Refresh weather and database sync
      Provider.of<WeatherProvider>(context, listen: false)
          .fetchWeatherForCurrentLocation();
      DatabaseSyncService().syncAll();

      () async {
        try {
          await HomeWidgetService.processPendingWidgetLogs();
          await HomeWidgetService.updateWidgetData();
          if (mounted) {
            context.read<HydrationCubit>().loadSlotsFromDb();
            context.read<HydrationCubit>().refreshAchievementStats();
            context.read<BottleDataCubit>().getCurrentDayHistory();
            setState(() {});
          }
        } catch (e) {
          Console.log(
              tag: "HomeWidget", value: "Error updating widget on resume: $e");
        }
      }();
    }
  }

  Future<void> _initializeTimezoneDetector() async {
    await TimezoneChangeDetector().init();
  }

  /// Ensures all 7 hydration slots are present in the DB.
  /// Runs only once per app session. Preserves existing waterDrank,
  /// startTime, and endTime — only inserts slots that are missing.
  Future<void> _ensureAllSlotsExist() async {
    if (_slotsChecked) return;
    _slotsChecked = true;

    try {
      final waterGoal = await SharedPrefsHelper.getWaterGoal();
      if (waterGoal == null || waterGoal <= 0) return;

      final dbHelper = DatabaseHelper();
      final existingSlotsInDb = await dbHelper.getAllSlots();

      // Build a map of what's already in DB
      final existingSlotMap = {
        for (var s in existingSlotsInDb) s.slot: s,
      };

      // Generate the full expected 7-slot list
      final expectedSlots =
          HydrationHelper.generateHydrationSlots(waterGoal.toDouble());

      // Find slots that are missing from DB
      final missingSlots = expectedSlots
          .where((s) => !existingSlotMap.containsKey(s.slot))
          .toList();

      if (missingSlots.isNotEmpty) {
        Console.log(
            tag: "HOME",
            value:
                "[SlotCheck] ${missingSlots.length} missing slot(s) detected. Inserting...");

        for (var slot in missingSlots) {
          await dbHelper.insertOrUpdateSlot(slot);
          Console.log(
              tag: "HOME",
              value: "[SlotCheck] Inserted missing slot: ${slot.slot.label}");
        }
      }

      final allSlots = await dbHelper.getAllSlots();
      final totalTarget = allSlots.fold<double>(0.0, (sum, s) => sum + s.amount);
      if ((totalTarget - waterGoal).abs() > 1) {
        Console.log(
            tag: "HOME",
            value:
                "[SlotCheck] Goal mismatch (slots: $totalTarget mL, goal: $waterGoal mL). Updating slot targets...");
        await dbHelper.updateSlotTargetsForGoal(waterGoal.toDouble());
      }

      Console.log(tag: "HOME", value: "[SlotCheck] Slot integrity restored. ✅");
    } catch (e) {
      Console.log(tag: "HOME", value: "[SlotCheck] Error: $e");
    }
  }

  /// Runs the AI Hydration Engine and shows the goal-breakdown dialog.
  Future<void> _runAiHydrationEngine() async {
    try {
      final goalShown = await SharedPrefsHelper.getAiHydrationGoalShown();
      if (!goalShown) return;
      // Fetch user weight from DB
      final userInfo = await DatabaseHelper().getUserInfo();
      if (userInfo == null || userInfo.weight == null) {
        Console.log(
            tag: 'AI_ENGINE', value: 'Skipping: user weight not available.');
        return;
      }

      // Weight is always stored in kg in the DB (UI handles unit display)
      double weightKg = userInfo.weight!;
      if (userInfo.weightUnit == 'lbs') {
        weightKg = weightKg * 0.453592;
      }

      if (!mounted) return;
      final weatherProvider =
          Provider.of<WeatherProvider>(context, listen: false);
      final surroundingTemp = context.read<BottleDataCubit>().state.temp;

      final result = await AiHydrationEngine.calculate(
        weightKg: weightKg,
        weatherProvider: weatherProvider,
        surroundingTemp: surroundingTemp,
      );

      if (!result.shouldShowDialog) {
        return;
      }

      final dbHelper = DatabaseHelper();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final previousDayGoal = await dbHelper.getDailyWaterGoal(yesterday) ?? 0;

      var waterGoal = await SharedPrefsHelper.getWaterGoal();

      Console.log(
          tag: "check_water_goal_equal",
          value: "${result.totalGoalMl.toInt()} ${waterGoal}");

      if ((result.totalGoalMl.toInt() - waterGoal!.toInt()).abs() <= 500) {
        return;
      }

      if (!mounted) return;
      final bool? keepCurrent = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AiHydrationGoalDialog(
          result: result,
          previousDayGoal: previousDayGoal,
        ),
      );

      if (keepCurrent == true) {
        await SharedPrefsHelper.setAiHydrationGoalShown(false);
      } else {
        Future.delayed(Duration(seconds: 2), () async {
          final updatedGoal = await SharedPrefsHelper.getWaterGoal();
          Console.log(tag: "keepCurrent", value: "${updatedGoal}");
          context.read<HydrationCubit>().setGoal(updatedGoal!);
        });
      }
    } catch (e) {
      Console.log(tag: 'AI_ENGINE', value: 'Engine error: $e');
    }
  }

  Future<void> _checkTimezoneChange() async {
    if (_isTimezoneDialogOpen) return;
    final hasChanged = await TimezoneChangeDetector().hasTimezoneChanged();
    Console.log(tag: "TimezoneChangeDetector_hasChanged", value: hasChanged);
    if (hasChanged && mounted) {
      _showTimezoneChangeDialog();
    }
  }

  void _showTimezoneChangeDialog() {
    if (!mounted || _isTimezoneDialogOpen) return;

    setState(() {
      _isTimezoneDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TimezoneChangeDialog(
          onRefresh: _refreshTimezone,
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isTimezoneDialogOpen = false;
        });
      }
    });
  }

  void _showLocationPermissionDialog() {
    if (!mounted || _isLocationPermDialogShown) return;
    _isLocationPermDialogShown = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: Color(0xFF007AFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location Access Required',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Location permission has been permanently denied.\n\n'
            'To enable weather data and personalized hydration, please go to '
            'Settings and allow location access for this app.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF555555),
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                AppFontStyles.fontWeightVariation600,
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.fontWeightVariation600,
                  ],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        _isLocationPermDialogShown = false;
      }
    });
  }

  Future<void> _refreshTimezone() async {
    await TimezoneChangeDetector().updateTimezone();

    final dbHelper = DatabaseHelper();
    final waterGoal = await SharedPrefsHelper.getWaterGoal();

    if (waterGoal != null && waterGoal > 0) {
      final existingSlots = await dbHelper.getAllSlots();
      final List<HydrationEntry> slotsToUse;

      if (existingSlots.isNotEmpty) {
        slotsToUse = existingSlots;
      } else {
        slotsToUse =
            HydrationHelper.generateHydrationSlots(waterGoal.toDouble());
        for (var slot in slotsToUse) {
          await dbHelper.insertOrUpdateSlot(slot);
        }
      }

      final notificationService = NotificationService();
      await notificationService.resetAllHydrationReminders(slotsToUse);
      await notificationService.scheduleHydrationRemindersForFuture(slotsToUse);
      context.read<BleCubit>().queueHydrationSlots(slotsToUse);

      if (mounted) {
        context.read<HydrationCubit>().loadSlotsFromDb();
        context.read<HydrationCubit>().refreshAchievementStats();
        context.read<BottleDataCubit>().refresh();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hydration schedule refreshed for new timezone'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _checkAndScheduleHydrationReminders() async {
    final notificationService = NotificationService();
    final bool alreadyScheduled =
        await notificationService.hasScheduledNotifications();

    if (!alreadyScheduled) {
      Console.log(
          tag: "Notifications",
          value: "No notifications scheduled. Checking database for slots...");
      final dbHelper = DatabaseHelper();
      var slots = await dbHelper.getAllSlots();

      if (slots.isEmpty) {
        Console.log(
            tag: "Notifications",
            value: "Database slots empty. Generating from water goal...");
        final waterGoal = await SharedPrefsHelper.getWaterGoal();
        if (waterGoal != null && waterGoal > 0) {
          slots = HydrationHelper.generateHydrationSlots(waterGoal.toDouble());
          for (var slot in slots) {
            await dbHelper.insertOrUpdateSlot(slot);
          }
        }
      }

      if (slots.isNotEmpty) {
        Console.log(
            tag: "Notifications",
            value: "Scheduling hydration reminders for ${slots.length} slots.");

        // Request notification permissions before scheduling
        await notificationService.resetAllHydrationReminders(slots);
        await notificationService.scheduleHydrationRemindersForFuture(slots);
      }
    } else {
      Console.log(
          tag: "Notifications",
          value: "Notifications already scheduled. Skipping.");
    }
  }

  Future<void> _loadBottle() async {
    final color = await SharedPrefsHelper.getBottleColor();

    if (!mounted) return;

    // Get current water data from BottleDataCubit
    final bottleState = context.read<BottleDataCubit>().state;

    setState(() {
      selectedBottle = color;
      bottleInfo = BottleInfo.getByColor(
        color,
        currentWater: bottleState.volume,
        waterPercentage: bottleState.volumePercent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BleCubit, BleState>(
      listener: (context, state) async {
        if (state.status == BleStatus.scanning &&
            state.scannedDevices.isNotEmpty &&
            !_isPickerShown &&
            state.isFirstConnection) {
          _isPickerShown = true;
          Console.log(tag: "APP", value: "✅ Showing picker...");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 3.0,
                          sigmaY: 3.0,
                        ),
                        child: Container(
                          color: Colors.white.withOpacity(0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: const BleDeviceSelectionSheet(),
                      ),
                    ],
                  ),
                );
              },
            ).then((_) {
              Console.log(tag: "APP", value: "❌ Picker closed.");
              _isPickerShown = false;
            });
          });
        }
        if (state.status == BleStatus.connected &&
            ((state.volume ?? 0) < 600)) {
          // _showStartJourneyDialog(context);
          // Removing as this causes error
        }

        // 1. Wi-Fi Provisioning Progress Dialog
        if (state.isWifiProvisioning && _wifiProgressDialogContext == null) {
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (!context.read<BleCubit>().state.isWifiProvisioning) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  _wifiProgressDialogContext = ctx;
                  return PopScope(
                    canPop: false,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.white,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF007AFF)),
                            strokeWidth: 4,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Configuring Wi-Fi",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "SipNudge is setting up your Wi-Fi connection. Please keep your bottle close.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF555555),
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ).then((_) {
                _wifiProgressDialogContext = null;
              });
            });
          }
        }

        if (!state.isWifiProvisioning && _wifiProgressDialogContext != null) {
          final dialogContext = _wifiProgressDialogContext!;
          _wifiProgressDialogContext = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          });
        }

        // 2. Wi-Fi Connected Success Dialog
        if (state.showWifiConnectedDialog && !_isWifiConnectedDialogShown) {
          _isWifiConnectedDialogShown = true;
          context.read<BleCubit>().dismissWifiConnectedDialog();
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_tethering_rounded,
                              color: Color(0xFF34C759),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Wi-Fi Connected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your SipNudge bottle is now connected!",
                        style: TextStyle(
                          color: const Color(0xFF555555),
                          fontSize: 14,
                          height: 1.5,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            buildInfoRow(
                              "Network SSID",
                              state.wifiConnectedSsid ?? "Connected",
                              Icons.wifi,
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            buildInfoRow(
                              "IP Address",
                              state.wifiConnectedIp ?? "0.0.0.0",
                              Icons.lan_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            "Awesome",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).then((_) {
                _isWifiConnectedDialogShown = false;
              });
            });
          }
        }

        // 3. Wi-Fi Connection Failed Dialog
        if (state.showWifiFailedDialog && !_isWifiFailedDialogShown) {
          _isWifiFailedDialogShown = true;
          context.read<BleCubit>().dismissWifiFailedDialog();
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              color: Color(0xFFFF3B30),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Connection Failed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your SipNudge bottle could not connect to Wi-Fi.",
                        style: TextStyle(
                          color: const Color(0xFF555555),
                          fontSize: 14,
                          height: 1.5,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFEE2E2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reason",
                              style: TextStyle(
                                color: const Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.wifiFailedReason ?? "Unknown Error",
                              style: TextStyle(
                                color: const Color(0xFF991B1B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            "Close",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).then((_) {
                _isWifiFailedDialogShown = false;
              });
            });
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/app_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: ValueListenableBuilder<double>(
            valueListenable: _timelineDragProgress,
            builder: (context, progress, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: (1.0 - (progress * 0.25)).clamp(0.75, 1.0),
                      child: child!,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: progress * 3.0,
                          sigmaY: progress * 3.0,
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(progress * 0.4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.5,
                    child: AnimatedSideTimelineButton(
                      dragProgressNotifier: _timelineDragProgress,
                      autoTrigger: _shouldAutoTrigger,
                    ),
                  ),
                ],
              );
            },
            child: Column(
              children: [
                SizedBox(
                  height: AppDimensions.dim69.h,
                ),
                _buildAppBar(context),
                _buildWeatherInfo(),
                SizedBox(
                  height: AppDimensions.dim12.h,
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _showAmbientTemp,
                  builder: (context, showAmbient, child) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: showAmbient
                          ? _buildAmbientTempStats()
                          : _currentSlotInfoWidget(),
                    );
                  },
                ),
                SizedBox(
                  height: AppDimensions.dim9.h,
                ),
                _buildBottleWidget(context),
                SizedBox(
                  height: AppDimensions.dim10.h,
                ),
                _otherInfoWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentSlotInfoWidget() {
    // Compute totalRefill here — outside the BlocBuilders — so it always
    // reflects the latest currentWaterGoal regardless of buildWhen filtering.

    return BlocBuilder<HydrationCubit, HydrationState>(
      buildWhen: (p, c) {
        Console.log(
            tag: "_currentSlotInfoWidget_buildWhen",
            value:
                "${p.goal} :: ${c.goal} :: ${c.currentSlotConsumption} :: ${c.currentSlotPercentage} :: ${c.currentSlotEntry}");
        return p.goal != c.goal ||
            p.currentSlotConsumption != c.currentSlotConsumption ||
            p.currentSlotPercentage != c.currentSlotPercentage ||
            p.currentSlotEntry != c.currentSlotEntry;
      },
      builder: (context, hydrationState) {
        final slotName =
            hydrationState.currentSlotEntry?.slot.label ?? "Off-Slot Time";

        final totalRefill =
            ((hydrationState.goal ?? 0) / 600).toStringAsFixed(1);

        final percentage = (hydrationState.currentSlotPercentage);

        Console.log(
            tag: "_currentSlotInfoWidget",
            value: "slotName : $slotName  , percentage : $percentage");

        return _buildTodayStats(percentage, slotName, totalRefill);
      },
    );
  }

  BlocBuilder<BleCubit, BleState> _otherInfoWidget() {
    return BlocBuilder<BleCubit, BleState>(
      buildWhen: (previous, current) {
        Console.log(
            tag: "home_Screen_biuld",
            value:
                "${previous.currentHydrationValue} : ${current.currentHydrationValue} : ${current.refreshTrigger}");

        if (previous.currentHydrationValue != current.currentHydrationValue ||
            previous.refreshTrigger != current.refreshTrigger) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        return FutureBuilder<(double, double, int)>(
          future: () async {
            var history = await context
                .read<BottleDataCubit>()
                .getCurrentDayHistory(localOnly: true);

            Console.log(tag: "home_screen_history", value: history.toString());
            double consumed = history;
            int goal = await SharedPrefsHelper.getUserGoal() ?? 0;
            double percent =
                await WaterConsumptionCalculator.calculateCompletionPercentage(
                    consumed);

            return (percent, consumed, goal);
          }(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? (0.0, 0.0, 0);
            double completionPercent = data.$1;
            double consumed = data.$2;
            int goal = data.$3;

            Console.log(
                tag: "snapshot_ble_cubit", value: snapshot.data.toString());
            final formattedConsumed =
                HydrationHelper.formatVolume(consumed, _selectedUnit);
            final formattedGoal = HydrationHelper.formatVolume(
                goal.toDouble(), _selectedUnit,
                showUnit: true);
            return _buildGoalText(
              completionPercent,
              isGuest,
              value: "$formattedConsumed/$formattedGoal",
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GreetingWidget(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: AppDimensions.dim8.w),
              Column(
                children: [
                  CustomBeatingBleStatusIndicator(),
                  SizedBox(height: AppDimensions.dim5.h),
                  BlocBuilder<BottleDataCubit, BottleDataState>(
                    buildWhen: (previous, current) =>
                        previous.battery != current.battery,
                    builder: (context, state) {
                      return InkWell(
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (builder) {
                            return Hydration30DayPage();
                          }));
                        },
                        child: CustomShowcase(
                          showcaseKey: ShowcaseKeys.batteryIndicatorKey,
                          title: 'Bottle Battery Status',
                          description:
                              'Indicates your bottle battery percentage. Tap to view 30-day battery stats.',
                          targetShapeBorder: const CircleBorder(),
                          child: CustomCircularProgressIndicator(
                            height: AppDimensions.dim60.w,
                            width: AppDimensions.dim60.w,
                            backgroundColor: AppColors.bluegray,
                            progressBackgroundColor: const Color(0XFFDDECDC),
                            progressColor: state.battery <= 20
                                ? const Color(0xFFFF0000)
                                : const Color(0XFF43E73E),
                            percentageValue: state.battery.toDouble(),
                            center: Text(
                              "${state.battery}%",
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: AppFontStyles.fontSize_12,
                                fontVariations: [
                                  AppFontStyles.fontWeightVariation600,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Loading weather data',
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_16,
                  color: AppColors.bluegray,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
            ],
          );
        }

        if (weatherProvider.error != null) {
          return CustomShowcase(
            showcaseKey: ShowcaseKeys.weatherInfoKey,
            title: 'Weather Information',
            description:
                'Shows current weather. When you step outside, it guides you to consume extra water based on temperature and humidity.',
            child: _buildWeatherUnavailableWidget(
              isPermanentlyDenied: weatherProvider.isLocationPermanentlyDenied,
              onRefresh: () => weatherProvider.fetchWeatherForCurrentLocation(),
            ),
          );
        }

        final weatherData = weatherProvider.weatherData;
        if (weatherData == null) {
          // Only fetch once on build, don't keep retrying
          if (!weatherProvider.isLoading && weatherProvider.error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              weatherProvider.fetchWeatherForCurrentLocation();
            });
          }
          return CustomShowcase(
            showcaseKey: ShowcaseKeys.weatherInfoKey,
            title: 'Weather Information',
            description:
                'Shows current weather. When you step outside, it guides you to consume extra water based on temperature and humidity.',
            child: _buildWeatherUnavailableWidget(
              isPermanentlyDenied: false,
              onRefresh: () => weatherProvider.fetchWeatherForCurrentLocation(),
            ),
          );
        }

        var iconPath = weatherProvider.getWeatherIcon();
        print('=== UI Widget Debug ===');
        print('Icon path received from provider: "$iconPath"');

        if (iconPath == "assets/images/01_sunny_color.svg") {
          iconPath = "assets/images/01_sunny_color.svg";
        }

        return CustomShowcase(
          showcaseKey: ShowcaseKeys.weatherInfoKey,
          title: 'Weather Information',
          description:
              'Shows current weather. When you step outside, it guides you to consume extra water based on temperature and humidity.',
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding),
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    Console.log(
                        tag: "APP", value: '=== WEATHER WIDGET TAPPED ===');
                    await weatherProvider.fetchWeatherForCurrentLocation();
                    Console.log(
                        tag: "APP", value: '=== WEATHER FETCH COMPLETED ===');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Location permission requested. Weather will update shortly.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        height: AppDimensions.dim45.h,
                        width: AppDimensions.dim45.h,
                        child: _buildWeatherIconWidget(iconPath),
                      ),
                      SizedBox(height: AppDimensions.dim8.h),
                      Text(
                        '${weatherData.temperature.round()}°C / ${weatherData.humidity.round()}%',
                        style: TextStyle(
                          fontSize: AppFontStyles.fontSize_16,
                          fontFamily: AppFontStyles.poppinsFamily,
                          color: AppColors.bluegray,
                          fontVariations: [
                            AppFontStyles.boldFontVariation,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppDimensions.dim12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(height: 1.2.h),
                            children: [
                              TextSpan(
                                text: AppLocalizations.of(context)?.itsA ??
                                    AppStrings.itsA,
                                style: TextStyle(
                                  color: AppColors.bluegray,
                                  fontFamily:
                                      AppFontStyles.museoModernoFontFamily,
                                  fontSize: AppFontStyles.fontSize_14,
                                  fontVariations: [
                                    AppFontStyles.regularFontVariation,
                                  ],
                                ),
                              ),
                              TextSpan(
                                text: weatherProvider.getWeatherDescription(),
                                style: TextStyle(
                                  color: AppColors.bluegray,
                                  fontFamily:
                                      AppFontStyles.museoModernoFontFamily,
                                  fontSize: AppFontStyles.fontSize_14,
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation,
                                  ],
                                ),
                              ),
                              TextSpan(
                                text: AppLocalizations.of(context)?.today ??
                                    AppStrings.today,
                                style: TextStyle(
                                  color: AppColors.bluegray,
                                  fontFamily:
                                      AppFontStyles.museoModernoFontFamily,
                                  fontSize: AppFontStyles.fontSize_14,
                                  fontVariations: [
                                    AppFontStyles.regularFontVariation,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.dim5.h),
                      SizedBox(
                        width: AppDimensions.dim330.w,
                        child: Text(
                          AppLocalizations.of(context)?.waterBottleReminder ??
                              AppStrings.waterBottleReminder,
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_14,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottleWidget(BuildContext context) {
    return CustomShowcase(
      showcaseKey: ShowcaseKeys.bottleProgressKey,
      title: 'Bottle Status & Intake Progress',
      description:
          'The middle of the bottle displays the current water fill level inside the bottle. The outer circle progress indicator tracks your daily water consumption progress.',
      child: SizedBox(
        height: AppDimensions.dim456.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 0,
              bottom: -(AppDimensions.dim1.h),
              child: GestureDetector(
                onTap: () async {
                  // if (kDebugMode) {
                  //   final dummyData =
                  //       HydrationTestHelper.generatePerfectDayString();
                  //
                  //   context.read<BleCubit>().testFullWeeklyStreak();
                  // }
                },
                child: Image.asset(
                  //'assets/images/bottle_image1.png',
                  bottleInfo?.imagePath ?? "assets/images/bottle_image1.png",
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            Positioned(
              bottom: AppDimensions.dim50.h,
              left: AppDimensions.dim187.w,
              child: SizedBox(
                child: BlocBuilder<BleCubit, BleState>(
                    buildWhen: (previous, current) {
                  Console.log(
                      tag: "current_hyderation_buildWhen",
                      value:
                          "${previous.currentHydrationValue} :: ${current.currentHydrationValue} :: ${current.refreshTrigger}");
                  if (previous.currentHydrationValue !=
                          current.currentHydrationValue ||
                      previous.refreshTrigger != current.refreshTrigger) {
                    return true;
                  }
                  return false;
                }, builder: (context, state) {
                  return FutureBuilder<(double, double, double)>(
                      future: () async {
                    final history = await context
                        .read<BottleDataCubit>()
                        .getCurrentDayHistory(localOnly: true);

                    double waterVolumeConsumed = history;
                    double completionPercent = await WaterConsumptionCalculator
                        .calculateCompletionPercentage(waterVolumeConsumed);

                    // Compute expected cumulative slot-schedule target at current time
                    double expectedPercent = 0.0;
                    try {
                      final dbHelper = DatabaseHelper();
                      final goalMl =
                          await dbHelper.getDailyWaterGoal(DateTime.now()) ??
                              2500;
                      var slots = await dbHelper.getAllSlots();
                      if (slots.isEmpty) {
                        slots = HydrationHelper.generateHydrationSlots(goalMl.toDouble());
                      }
                      expectedPercent = WaterConsumptionCalculator
                          .calculateExpectedPercentage(
                        slots,
                        goalMl.toDouble(),
                      );
                    } catch (_) {}

                    return (
                      completionPercent,
                      waterVolumeConsumed,
                      expectedPercent
                    );
                  }(), builder: (context, snapshot) {
                    final (
                      completionPercent,
                      waterVolumeConsumed,
                      expectedPercent
                    ) = snapshot.data ?? (0.0, 0.0, 0.0);

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _progressCircleWidget(completionPercent,
                        waterVolumeConsumed, expectedPercent);
                  });
                }),
              ),
            ),
            Positioned(
              bottom: AppDimensions.dim150.h,
              left: AppDimensions.dim188.w,
              child: BlocBuilder<BottleDataCubit, BottleDataState>(
                buildWhen: (previous, current) =>
                    previous.volumePercent != current.volumePercent,
                builder: (context, state) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.dim187),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: AppDimensions.dim4.r,
                          spreadRadius: AppDimensions.dim1.r,
                          color: Colors.black.withOpacity(.25),
                          offset: Offset(
                              AppDimensions.dim4.w, AppDimensions.dim4.h),
                        )
                      ],
                    ),
                    width: AppDimensions.dim65.w,
                    height: AppDimensions.dim160.h,
                    child: WaterWaveWidget(
                      orientation: Axis.horizontal,
                      fillPercent: state.volumePercent / 100,
                      speed: Duration(seconds: 3),
                      amplitude: 4,
                      waveCount: 3,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: AppDimensions.dim215.h,
              left: AppDimensions.dim187.w,
              child: Container(
                width: AppDimensions.dim66.w,
                alignment: Alignment.center,
                child: BlocBuilder<BottleDataCubit, BottleDataState>(
                  buildWhen: (previous, current) =>
                      previous.volumePercent != current.volumePercent,
                  builder: (context, state) {
                    return TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: 0,
                        end: state.volumePercent,
                      ),
                      duration: Duration(milliseconds: 500),
                      curve: Curves.fastEaseInToSlowEaseOut,
                      builder: (context, value, child) {
                        return Text(
                          "$value%",
                          style: TextStyle(
                            color: Color(0xff252525),
                            fontSize: value >= 100
                                ? AppFontStyles.fontSize_20
                                : AppFontStyles.fontSize_24,
                            fontVariations: [
                              AppFontStyles.boldFontVariation,
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: AppDimensions.dim160.h,
              left: AppDimensions.dim195.w,
              child: Container(
                width: AppDimensions.dim50.w,
                alignment: Alignment.center,
                child: BlocBuilder<BottleDataCubit, BottleDataState>(
                  buildWhen: (previous, current) =>
                      previous.volume != current.volume,
                  builder: (context, state) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: state.volume,
                      ),
                      duration: Duration(milliseconds: 500),
                      curve: Curves.fastEaseInToSlowEaseOut,
                      builder: (context, value, child) {
                        return Text(
                          HydrationHelper.formatVolume(value, _selectedUnit,
                              showUnit: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xff252525),
                            fontSize: AppFontStyles.fontSize_13,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation,
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCircleWidget(double completionPercent,
      double waterVolumeConsumed, double expectedPercent) {
    return CustomCircularWaterProgressIndicator(
      height: AppDimensions.dim70.h,
      width: AppDimensions.dim70.w,
      boxShadow: [
        BoxShadow(
          blurRadius: AppDimensions.dim20.r,
          spreadRadius: AppDimensions.dim10.r,
          color: Colors.black.withOpacity(.2),
          offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
        ),
      ],
      backgroundColor: Color(0xffB8B8B8),
      progressBackgroundColor: Color(0xffB3FF4A),
      percentageValue: completionPercent,
      expectedPercentage: expectedPercent,
      center: Container(
        width: AppDimensions.dim50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<int?>(
              future: SharedPrefsHelper.getUserGoal(),
              builder: (context, snapshot) {
                double userGoalLiters = 0.0;

                if (snapshot.hasData && snapshot.data != null) {
                  userGoalLiters = snapshot.data! / 1000.0;
                }

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: completionPercent,
                  ),
                  duration: Duration(milliseconds: 500),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  builder: (context, value, child) {
                    return Text(
                      "${(value).toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: value >= 100 ? 13.sp : 15.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats(
      double todayConsumptionPercentage, String slotName, String totalRefill) {
    return CustomShowcase(
      showcaseKey: ShowcaseKeys.refillsSlotKey,
      title: 'Refills & Slots Info',
      description:
          'Check how many times your bottle was refilled today, current active time slot, and completion percentage.',
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.dim90.r),
          border: Border.all(
              color: AppColors.blueWaterIntake.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 196, 196, 196).withOpacity(0.3),
              Colors.white.withOpacity(0.1),
            ],
          ),
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: AppDimensions.dim70.h,
          borderRadius: AppDimensions.dim90.r,
          blur: 20,
          alignment: Alignment.center,
          border: 0,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.1),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.2),
            ],
          ),
          child: InkWell(
            onTap: () async {},
            borderRadius: BorderRadius.circular(AppDimensions.dim90.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.dim16.w,
                vertical: AppDimensions.dim13.h,
              ),
              child: Row(
                children: [
                  Image.asset(
                    AssetsPath.refill,
                    width: AppDimensions.dim22.w,
                    height: AppDimensions.dim22.h,
                  ),
                  Container(
                    width: AppDimensions.dim100.w,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.todaysRefills ??
                              "Today's Refills",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontVariations: [
                              AppFontStyles.boldFontVariation,
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BlocBuilder<BottleDataCubit, BottleDataState>(
                                buildWhen: (p, c) => p.refills != c.refills,
                                builder: (context, bleState) {
                                  // Refill count from BLE state
                                  final refillCount =
                                      (bleState.refills ?? 0).toDouble();
                                  return Text(
                                    refillCount % 1 == 0
                                        ? refillCount.toInt().toString()
                                        : refillCount.toStringAsFixed(1),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      color: AppColors.blueWaterIntake,
                                      fontSize: AppFontStyles.fontSize_15,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation,
                                      ],
                                    ),
                                  );
                                }),
                            Text(
                              "/",
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  color: AppColors.bluegray,
                                  fontSize: AppFontStyles.fontSize_16,
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation,
                                  ],
                                  fontStyle: FontStyle.italic),
                            ),
                            Text(
                              " " + totalRefill,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_15,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation,
                                ],
                              ),
                            ),
                            Text(
                              " Times",
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_14,
                                fontVariations: [
                                  AppFontStyles.extraBoldFontVariation,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: AppDimensions.dim10.w,
                  ),
                  Container(
                    width: AppDimensions.dim110.w,
                    height: AppDimensions.dim26.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bluegray,
                      // border: Border.all(
                      //   color: AppColors.white,
                      //   width: AppDimensions.dim1,
                      // ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: AppDimensions.dim5.r,
                          spreadRadius: 0,
                          color: Colors.black.withOpacity(.38),
                          offset: Offset(0, 0),
                        )
                      ],
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius_40,
                      ),
                    ),
                    child: Text(
                      // 🔥 Displays the current slot's name dynamically
                      slotName,
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.white,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: AppFontStyles.fontSize_14,
                        fontVariations: [
                          AppFontStyles.boldFontVariation,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppDimensions.dim20.w,
                  ),
                  Container(
                    width: AppDimensions.dim80.w,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.completed ??
                              "Completed",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: AppColors.bluegray,
                            fontSize: AppFontStyles.fontSize_12,
                            fontVariations: [
                              AppFontStyles.boldFontVariation,
                            ],
                          ),
                        ),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(
                            begin: 0,
                            end: todayConsumptionPercentage.toInt(),
                          ),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          builder: (context, value, child) {
                            return Text(
                              "$value%",
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: AppColors.bluegray,
                                fontSize: AppFontStyles.fontSize_16,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation,
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalText(double todayConsumptionPercentage, bool isGuest,
      {String value = ""}) {
    if (isGuest) {
      final goalText =
          "If you have purchased the bottle and accidentally entered the guest page, you can log out from the settings page and log in normally.\n"
          "If you don’t have the bottle and want to use the basic water-reminder feature, you can schedule reminders from the settings page > Drink Reminder > Water Intake Timeline.\n"
          "You can also place your bottle order directly from the settings page.";
      return AutoScrollGoalText(text: goalText);
    }

    final splitValues = value.split("/");
    final consumedPart = splitValues.isNotEmpty ? splitValues[0] : "";
    final goalPart = splitValues.length > 1 ? splitValues[1] : "";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
                fontSize: AppFontStyles.fontSize_18.sp,
                color: AppColors.bluegray,
                fontFamily: AppFontStyles.museoModernoFontFamily,
                fontVariations: [AppFontStyles.semiBoldFontVariation]),
            children: [
              TextSpan(
                  text: AppLocalizations.of(context)?.youHaveReachedGoal(
                          todayConsumptionPercentage.toStringAsFixed(0)) ??
                      "You have reached ${todayConsumptionPercentage.toStringAsFixed(0)}% of today's goal"),
              TextSpan(
                text: "\n(",
                style: TextStyle(
                  letterSpacing: 0,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
              ),
              TextSpan(
                  text: consumedPart,
                  style: TextStyle(
                    letterSpacing: 0,
                    color: AppColors.lightBlue400,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  ),
                  children: [
                    TextSpan(
                      text: "/$goalPart)",
                      style: TextStyle(
                        letterSpacing: 0,
                        color: AppColors.bluegray,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                      ),
                    ),
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherUnavailableWidget({
    required VoidCallback onRefresh,
    bool isPermanentlyDenied = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding),
      child: Row(
        children: [
          // Left: N/A icon + placeholder temp/humidity
          Column(
            children: [
              SizedBox(
                height: AppDimensions.dim45.h,
                width: AppDimensions.dim45.h,
                child: Center(
                  child: Image.asset(
                    AssetsPath.NAIcon,
                    width: 55.w,
                    height: 55.w,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.dim8.h),
              Text(
                'NA°C/NA%',
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.poppinsFamily,
                  color: AppColors.bluegray.withOpacity(0.45),
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ],
          ),
          SizedBox(width: AppDimensions.dim12.w),
          // Right: message + optional Open Settings link
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPermanentlyDenied
                      ? 'Location access is required for AI Hydration Engine. Please enable it in Settings.'
                      : 'Turn on data/Wi-Fi to update weather.\nRemember to stay hydrated throughout the day',
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontFamily: AppFontStyles.museoModernoFontFamily,
                    fontSize: AppFontStyles.fontSize_14,
                    fontVariations: [AppFontStyles.regularFontVariation],
                    height: 1.4,
                  ),
                ),
                if (isPermanentlyDenied) ...[
                  SizedBox(height: 6.h),
                  // ✅ Apple compliant: user explicitly taps to open Settings
                  GestureDetector(
                    onTap: () => Geolocator.openAppSettings(),
                    child: Text(
                      'Open Settings',
                      style: TextStyle(
                        color: const Color(0xFF007AFF), // iOS blue
                        fontFamily: AppFontStyles.museoModernoFontFamily,
                        fontSize: AppFontStyles.fontSize_14,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: onRefresh,
                    child: Text(
                      'Tap to retry',
                      style: TextStyle(
                        color: AppColors.bluegray.withOpacity(0.6),
                        fontFamily: AppFontStyles.museoModernoFontFamily,
                        fontSize: AppFontStyles.fontSize_13,
                        fontVariations: [AppFontStyles.regularFontVariation],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIconWidget(String iconPath) {
    print('Building icon widget for: $iconPath');

    // Check if it's a PNG file
    if (iconPath.toLowerCase().endsWith('.png')) {
      print('Loading as PNG image');
      return Image.asset(
        iconPath,
        height: AppDimensions.dim45.h,
        width: AppDimensions.dim45.h,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('PNG Error loading: $iconPath');
          print('Error: $error');
          return Container(
            height: AppDimensions.dim45.h,
            width: AppDimensions.dim45.h,
            color: Colors.orange,
            child: Icon(Icons.warning, color: Colors.white),
          );
        },
      );
    }
    // Otherwise treat as SVG
    else {
      print('Loading as SVG image');
      return SvgPicture.asset(
        iconPath,
        height: AppDimensions.dim45.h,
        width: AppDimensions.dim45.h,
        fit: BoxFit.contain,
        placeholderBuilder: (BuildContext context) {
          print('SVG Placeholder shown for: $iconPath');
          return Container(
            height: AppDimensions.dim45.h,
            width: AppDimensions.dim45.h,
            color: Colors.grey,
            child: Icon(Icons.error, color: Colors.red),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('SVG Error loading: $iconPath');
          print('Error: $error');
          return Container(
            height: AppDimensions.dim45.h,
            width: AppDimensions.dim45.h,
            color: Colors.orange,
            child: Icon(Icons.warning, color: Colors.white),
          );
        },
      );
    }
  }

  Future<void> _showStartJourneyDialog(BuildContext context) async {
    // Check if user is logged in as guest by checking email
    final userEmail = await SharedPrefsHelper.getUserEmail();
    final isGuest = userEmail == "guest_user";

    // Add debug print to verify
    print('🔍 DEBUG: userEmail = $userEmail, isGuest = $isGuest');

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background Blur + Dismiss Area
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withOpacity(0)),
                ),
              ),
            ),

            // Center Card
            Center(
              child: Container(
                width: AppDimensions.dim310.w,
                height: isGuest
                    ? AppDimensions.dim375.h // Increased for guest message
                    : AppDimensions.dim210.h,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radius_10.r),
                  border: Border.all(
                    color: AppColors.startJourneyPopupBorderColor,
                    width: AppDimensions.dim1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.25),
                      blurRadius: AppDimensions.dim4.r,
                      offset:
                          Offset(AppDimensions.dim4.w, AppDimensions.dim4.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radius_16.r),
                  child: Stack(
                    children: [
                      Positioned(
                        top: isGuest
                            ? AppDimensions.dim19.h
                            : AppDimensions.dim17.h,
                        bottom: isGuest
                            ? AppDimensions.dim10.h
                            : AppDimensions.dim8.h,
                        left: 0,
                        right: 0,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.dim10.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //if (isGuest) // Show bottle image only for non-guest
                              Image.asset(
                                'assets/images/black_bottle.png',
                                width: AppDimensions.dim150.w,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(
                                height: isGuest
                                    ? AppDimensions.dim15.h
                                    : AppDimensions.dim15.h,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppDimensions.dim10.w),
                                child: RichText(
                                  textAlign: isGuest
                                      ? TextAlign.start
                                      : TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: AppColors.bluegray,
                                      fontFamily:
                                          AppFontStyles.museoModernoFontFamily,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation,
                                      ],
                                      fontSize: isGuest
                                          ? AppFontStyles.fontSize_13.sp
                                          : AppFontStyles.fontSize_13.sp,
                                      height: isGuest ? 1.4.sp : 1.5.sp,
                                    ),
                                    children: isGuest
                                        ? [
                                            TextSpan(
                                              text:
                                                  "If you have purchased the bottle and accidentally entered the guest page, you can log out from the settings page and log in normally.\n",
                                              style: TextStyle(
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation,
                                                ],
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  "If you don't have the bottle and want to use the basic water-reminder feature, you can schedule reminders from the settings page",
                                              style: TextStyle(
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation,
                                                ],
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  "> Drink Reminder > Water Intake",
                                              style: TextStyle(
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation,
                                                ],
                                              ),
                                            ),
                                            TextSpan(
                                              text: "\nTimeline.\n",
                                              style: TextStyle(
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation,
                                                ],
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  "You can also place your bottle order directly from the settings page.",
                                              style: TextStyle(
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation,
                                                ],
                                              ),
                                            ),
                                          ]
                                        : [
                                            TextSpan(
                                              text:
                                                  "Start your journey right fill your bottle till 600ml to ensure accurate data.",
                                              style: TextStyle(
                                                fontVariations: [
                                                  AppFontStyles
                                                      .boldFontVariation,
                                                ],
                                              ),
                                            ),
                                          ],
                                  ),
                                ),
                              ),
                              SizedBox(height: AppDimensions.dim18.h),
                              SizedBox(
                                width: AppDimensions.dim118.w,
                                height: AppDimensions.dim26.h,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.bluegray,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.radius_40.r),
                                    ),
                                    side: BorderSide(
                                      color: const Color(0xFF98DAFF),
                                      width: AppDimensions.dim1.w,
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.of(context).pop();

                                    if (!isGuest) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool(
                                          'ble_connected_once', true);
                                    } else {}

                                    _startShowcaseIfNeeded();
                                  },
                                  child: Text(
                                    isGuest ? "OK" : "Start",
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontFamily:
                                          AppFontStyles.museoModernoFontFamily,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation
                                      ],
                                      fontSize: AppFontStyles.fontSize_14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmbientTempStats() {
    return Container(
      key: const ValueKey('ambient_temp_stats'),
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.dim90.r),
        border:
            Border.all(color: AppColors.blueWaterIntake.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 196, 196, 196).withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: AppDimensions.dim70.h,
        borderRadius: AppDimensions.dim90.r,
        blur: 20,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.dim16.w,
            vertical: AppDimensions.dim13.h,
          ),
          child: Row(
            children: [
              Center(
                child: Image.asset(
                  AssetsPath.temperature_ambient,
                  width: AppDimensions.dim45.w,
                  height: AppDimensions.dim45.h,
                ),
              ),
              SizedBox(width: AppDimensions.dim16.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (AppLocalizations.of(context)?.ambientTemperature ??
                            "AMBIENT TEMPERATURE")
                        .toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: Color(0xff515F74),
                      fontSize: AppFontStyles.fontSize_12,
                      fontVariations: [
                        AppFontStyles.extraBoldFontVariation,
                      ],
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)?.roomTemperature ??
                            "Room Temperature: ",
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: AppColors.black,
                          fontSize: AppFontStyles.fontSize_18,
                          fontVariations: [
                            AppFontStyles.boldFontVariation,
                          ],
                        ),
                      ),
                      BlocBuilder<BottleDataCubit, BottleDataState>(
                        builder: (context, state) {
                          // Display actual temperature or fallback to "--" if null
                          final tempDisplay =
                              (state.temp != null && state.temp != 0)
                                  ? "${state.temp}°C"
                                  : "--°C";
                          return Text(
                            tempDisplay,
                            style: TextStyle(
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              color: AppColors.blueWaterIntake,
                              fontSize: AppFontStyles.fontSize_18,
                              fontVariations: [
                                AppFontStyles.boldFontVariation,
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF007AFF), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 12,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;
  SlideLeftRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

class AnimatedSideTimelineButton extends StatefulWidget {
  final ValueNotifier<double>? dragProgressNotifier;
  final bool autoTrigger;
  const AnimatedSideTimelineButton({
    super.key,
    this.dragProgressNotifier,
    this.autoTrigger = false,
  });

  @override
  State<AnimatedSideTimelineButton> createState() =>
      _AnimatedSideTimelineButtonState();
}

class _AnimatedSideTimelineButtonState extends State<AnimatedSideTimelineButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0.0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            _animateForwardAndNavigate();
          }
        });
      });
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: -0.22, end: 0.22).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = const AlwaysStoppedAnimation(0.0);
    _slideController.addListener(() {
      setState(() {
        _dragOffset = _slideAnimation.value;
        widget.dragProgressNotifier?.value =
            (_dragOffset.abs() / 100.0).clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _animateBack() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );
    _slideController.forward(from: 0.0);
  }

  void _animateForwardAndNavigate() {
    if (_isNavigating) return;
    _isNavigating = true;
    _slideAnimation = Tween<double>(begin: _dragOffset, end: -100.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideController.forward(from: 0.0).then((_) {
      if (mounted) {
        Navigator.of(context)
            .push(
          SlideLeftRoute(page: const WaterIntakeTimelineScreen()),
        )
            .then((_) {
          _isNavigating = false;
          if (mounted) {
            _animateBack();
          }
        });
      } else {
        _isNavigating = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const double maxDrag = 150.0;
    final double progress = (_dragOffset.abs() / 100.0).clamp(0.0, 1.0);
    final double buttonSize = 72.h;
    final double borderRadiusVal = buttonSize / 2;

    // Squeezing effect: height shrinks from 72.h to 52.h as drag progress increases
    final double trackHeight = buttonSize - (20.h * progress);
    final double verticalInset = (80.h - trackHeight) / 2;
    final double trackRadius = trackHeight / 2;

    // Dynamic button width: starts at 88.h to give arrow space, shrinks to 72.h for perfect circle
    final double currentButtonWidth = buttonSize + (16.h * (1.0 - progress));

    return GestureDetector(
      onTap: () {
        _animateForwardAndNavigate();
      },
      onHorizontalDragUpdate: (details) {
        if (_isNavigating) return;
        _slideController.stop();
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(-maxDrag, 0.0);
          widget.dragProgressNotifier?.value =
              (_dragOffset.abs() / 100.0).clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_isNavigating) return;
        if (_dragOffset <= -100.0) {
          _isNavigating = true;
          Navigator.of(context)
              .push(
            SlideLeftRoute(page: const WaterIntakeTimelineScreen()),
          )
              .then((_) {
            _isNavigating = false;
            _animateBack();
          });
        } else {
          _animateBack();
        }
      },
      child: SizedBox(
        width: 88.h,
        height: 80.h,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            // 1. Background Track
            Positioned(
              right: 0,
              top: verticalInset,
              bottom: verticalInset,
              child: Container(
                width: currentButtonWidth + _dragOffset.abs(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3FBAFF).withOpacity(0.9),
                      const Color(0xFF007BFF).withOpacity(0.9),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(trackRadius),
                    bottomLeft: Radius.circular(trackRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007BFF).withOpacity(0.3),
                      blurRadius: 10.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: (progress - 0.2).clamp(0.0, 1.0) / 0.8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Animated pulse chevrons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              double val =
                                  (_controller.value - (index * 0.25)) % 1.0;
                              double op = val.clamp(0.1, 1.0);
                              return Icon(
                                Icons.keyboard_arrow_left_rounded,
                                color: Colors.white.withOpacity(op),
                                size: 18.sp,
                              );
                            },
                          );
                        }),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _dragOffset <= -100.0 ? "Release" : "Slide",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 20.w),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Dragging Button itself
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                width: currentButtonWidth,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white, Colors.white, progress),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadiusVal),
                    bottomLeft: Radius.circular(borderRadiusVal),
                    topRight: Radius.circular(borderRadiusVal * progress),
                    bottomRight: Radius.circular(borderRadiusVal * progress),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08 + (progress * 0.05)),
                      blurRadius: AppDimensions.radius_10.r,
                      spreadRadius: progress * 2.r,
                      offset:
                          Offset(-AppDimensions.dim2.w, AppDimensions.dim4.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.scale(
                    scale: 1.0 + (progress * 0.1),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: -5.w,
                          child: Opacity(
                            opacity: (1.0 - progress).clamp(0.0, 1.0),
                            child: Icon(
                              Icons.keyboard_arrow_left_rounded,
                              color: AppColors.bluegray.withOpacity(0.5),
                              size: 16.sp,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(left: progress > 0.8 ? 0.w : 4.w),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                AssetsPath.timelineCircle,
                                width: 64.h,
                                height: 64.h,
                                fit: BoxFit.contain,
                              ),
                              AnimatedBuilder(
                                animation: _rotationAnimation,
                                builder: (context, child) {
                                  double angle = _rotationAnimation.value;
                                  if (progress > 0.0) {
                                    angle += progress * 0.5;
                                  }
                                  return Transform.rotate(
                                    angle: angle,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  );
                                },
                                child: Image.asset(
                                  AssetsPath.bellIcon,
                                  width: 24.w,
                                  height: 24.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
