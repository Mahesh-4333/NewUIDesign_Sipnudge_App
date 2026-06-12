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
import 'package:hydrify/screens/widgets/autoScroll_GoalText.dart';
import 'package:hydrify/screens/widgets/ble_device_selection_sheet.dart';
import 'package:hydrify/screens/widgets/ble_retry_dialog.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrify/helpers/internet_connection_helper.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/home_widget_service.dart';

class HomeScreen extends StatefulWidget {
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
  StreamSubscription<bool>? _internetSubscription;

  bool _isPickerShown = false;
  bool _isRetryDialogShown = false;
  bool hasConnectedBefore = false;
  bool isGuest = false;
  String selectedBottle = 'purple';
  BottleInfo? bottleInfo;
  int? currentWaterGoal = 0;

  Timer? _statsToggleTimer;
  final ValueNotifier<bool> _showAmbientTemp = ValueNotifier<bool>(false);

  void _checkGuestStatus() async {
    final email = await SharedPrefsHelper.getUserEmail();
    setState(() {
      isGuest = email == "guest_user";
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SharedPrefsHelper.getWaterGoal().then((e) {
      setState(() {
        currentWaterGoal = e;
      });
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
      hasConnectedBefore = prefs.getBool('ble_connected_once') ?? false;

      final bottleState = context.read<BottleDataCubit>().state;
      final double currentVolume = bottleState.volume;

      if (hasConnectedBefore) {
        context.read<BleCubit>().start();
        var history =
            await context.read<BottleDataCubit>().getCurrentDayHistory();

        context.read<BleCubit>().updateCurrentHydrationValue(history);

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
      } else {
        await _showStartJourneyDialog(context);
        if (mounted) {
          context.read<BleCubit>().start();
        }
      }

      await _checkAndScheduleHydrationReminders();
      await _initializeTimezoneDetector();

      // ── AI Hydration Engine: runs every 6 s ──────────
      _aiHydrationEngineTimer =
          Timer.periodic(const Duration(seconds: 6), (timer) async {
        if (_isAiEngineRunning) return;
        _isAiEngineRunning = true;
        await _runAiHydrationEngine();
        _isAiEngineRunning = false;
      });

      _configSubscription =
          SharedPrefsHelper.configUpdateStream.stream.listen((_) {
        if (mounted) {
          setState(() {});
        }
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
          DatabaseSyncService().syncAll();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timezoneTimer?.cancel();
    _statsToggleTimer?.cancel();
    _aiHydrationEngineTimer?.cancel();
    _configSubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Console.log(
          tag: "HOME",
          value: "App resumed, refreshing weather and syncing data...");
      Provider.of<WeatherProvider>(context, listen: false)
          .fetchWeatherForCurrentLocation();
      DatabaseSyncService().syncAll();
      
      try {
        final bleCubit = context.read<BleCubit>();
        final waterGoal = currentWaterGoal ?? 2500;
        final currentIntake = bleCubit.state.currentHydrationValue ?? 0.0;
        HomeWidgetService.updateWidgetData(
          currentIntake: currentIntake.round(),
          dailyGoal: waterGoal,
        );
      } catch (e) {
        Console.log(tag: "HomeWidget", value: "Error updating widget on resume: $e");
      }
    }
  }

  Future<void> _initializeTimezoneDetector() async {
    await TimezoneChangeDetector().init();
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

  Future<void> _refreshTimezone() async {
    await TimezoneChangeDetector().updateTimezone();

    final dbHelper = DatabaseHelper();
    final waterGoal = await SharedPrefsHelper.getWaterGoal();

    if (waterGoal != null && waterGoal > 0) {
      final slots =
          HydrationHelper.generateHydrationSlots(waterGoal.toDouble());

      await dbHelper.clearHydrationSlots();
      await Future.delayed(Duration(seconds: 2));
      for (var slot in slots) {
        await dbHelper.insertOrUpdateSlot(slot);
      }

      final notificationService = NotificationService();
      await notificationService.resetAllHydrationReminders(slots);
      await notificationService.scheduleHydrationRemindersForFuture(slots);
      context.read<BleCubit>().queueHydrationSlots(slots);

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
    //final bottle = await SharedPrefsHelper.getBottle();
    final color = await SharedPrefsHelper.getBottleColor();

    if (!mounted) return;

    // Get current water data from BottleDataCubit
    final bottleState = context.read<BottleDataCubit>().state;

    setState(() {
      //selectedBottle = color ?? 'black';
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

        if (state.manualRetryRequired && !_isRetryDialogShown) {
          _isRetryDialogShown = true;
          Console.log(tag: "APP", value: "⚠️ Showing manual retry dialog...");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const BleRetryDialog(),
            ).then((_) {
              Console.log(tag: "APP", value: "❌ Retry dialog closed.");
              _isRetryDialogShown = false;
              if (context.mounted) {
                context.read<BleCubit>().dismissRetryDialog();
              }
            });
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  "assets/images/app_background.png"), // your image path
              fit: BoxFit.cover,
            ),
          ),
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
        // 🧪 TEMP TEST BUTTON — remove before production
        // floatingActionButton: Padding(
        //   padding: EdgeInsets.only(bottom: 100.h),
        //   child: FloatingActionButton.extended(
        //     heroTag: 'ai_engine_test',
        //     backgroundColor: const Color(0xFF0072FF),
        //     onPressed: () async {
        //       setState(() => _aiHydrationGoalShown = false);
        //       await _runAiHydrationEngine();
        //     },
        //     icon: const Text('🧠', style: TextStyle(fontSize: 18)),
        //     label: Text(
        //       'AI Goal',
        //       style: TextStyle(
        //         fontSize: 13.sp,
        //         fontWeight: FontWeight.bold,
        //         color: Colors.white,
        //       ),
        //     ),
        //   ),
        // ),
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
            var history =
                await context.read<BottleDataCubit>().getCurrentDayHistory();

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
            return _buildGoalText(
              completionPercent,
              isGuest,
              value: "${consumed.toInt()}/$goal mL",
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
          return _buildWeatherUnavailableWidget(
            onRefresh: () => weatherProvider.fetchWeatherForCurrentLocation(),
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
          return _buildWeatherUnavailableWidget(
            onRefresh: () => weatherProvider.fetchWeatherForCurrentLocation(),
          );
        }

        var iconPath = weatherProvider.getWeatherIcon();
        print('=== UI Widget Debug ===');
        print('Icon path received from provider: "$iconPath"');

        if (iconPath == "assets/images/01_sunny_color.svg") {
          iconPath = "assets/images/01_sunny_color.svg";
        }

        return Padding(
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
                              text: AppStrings.itsA,
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
                              text: AppStrings.today,
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
        );
      },
    );
  }

  Widget _buildBottleWidget(BuildContext context) {
    return SizedBox(
      height: AppDimensions.dim456.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: 0,
            bottom: -(AppDimensions.dim15.h),
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
            bottom: AppDimensions.dim55.h,
            left: AppDimensions.dim182.w,
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
                return FutureBuilder<(double, double)>(future: () async {
                  final history = await context
                      .read<BottleDataCubit>()
                      .getCurrentDayHistory();
                  // Console.log(
                  //     tag: "getCurrentDayHistory_progress",
                  //     value: history.toString());

                  double waterVolumeConsumed = history;
                  double completionPercent = await WaterConsumptionCalculator
                      .calculateCompletionPercentage(waterVolumeConsumed);

                  return (completionPercent, waterVolumeConsumed);
                }(), builder: (context, snapshot) {
                  final (completionPercent, waterVolumeConsumed) =
                      snapshot.data ?? (0.0, 0.0);

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _progressCircleWidget(
                      completionPercent, waterVolumeConsumed);
                });
              }),
            ),
          ),
          Positioned(
            bottom: AppDimensions.dim175.h,
            left: AppDimensions.dim184.w,
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
                        offset:
                            Offset(AppDimensions.dim4.w, AppDimensions.dim4.h),
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
            bottom: AppDimensions.dim238.h,
            left: AppDimensions.dim184.w,
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
            bottom: AppDimensions.dim185.h,
            left: AppDimensions.dim192.w,
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
                        "${value.toStringAsFixed(0)} ml",
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
    );
  }

  CustomCircularWaterProgressIndicator _progressCircleWidget(
      double completionPercent, double waterVolumeConsumed) {
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
      //needsInnerShadow: false,
      percentageValue: completionPercent,
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
    return Container(
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

    return SizedBox(
      width: AppDimensions.dim350.w,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
              fontSize: AppFontStyles.fontSize_19.sp,
              color: AppColors.bluegray,
              fontFamily: AppFontStyles.museoModernoFontFamily,
              fontVariations: [AppFontStyles.semiBoldFontVariation]),
          children: [
            TextSpan(
                text:
                    "You have reached  ${todayConsumptionPercentage.toStringAsFixed(0)}% of today's goal"),
            TextSpan(
              text: "\n(",
              style: TextStyle(
                letterSpacing: 0,
                color: AppColors.bluegray,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
              ),
            ),
            TextSpan(
                text: value.split("/")[0],
                style: TextStyle(
                  letterSpacing: 0,
                  color: AppColors.lightBlue400,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
                children: [
                  TextSpan(
                    text: "/${value.split("/")[1]})",
                    style: TextStyle(
                      letterSpacing: 0,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                ]),
            // const TextSpan(
            //     text: " of today's \ngoal, keep focusing on your health!"),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherUnavailableWidget({required VoidCallback onRefresh}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding),
      child: InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(12),
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
                      height:55.w,
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
            // Right: message
            Expanded(
              child: Text(
                'Turn on data/Wi-Fi to update weather.\nRemember to stay hydrated throughout the day',
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontFamily: AppFontStyles.museoModernoFontFamily,
                  fontSize: AppFontStyles.fontSize_14,
                  fontVariations: [AppFontStyles.regularFontVariation],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
                    "AMBIENT TEMPERATURE",
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
}
