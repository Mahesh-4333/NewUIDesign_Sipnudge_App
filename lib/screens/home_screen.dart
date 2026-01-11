import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
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
import 'package:hydrify/models/bottle_info.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/providers/weather_provider.dart';
import 'package:hydrify/screens/hydration_30_day.dart';
import 'package:hydrify/screens/notification.dart';
import 'package:hydrify/screens/qr_scanning.dart';
import 'package:hydrify/screens/widgets/autoScroll_GoalText.dart';
import 'package:hydrify/screens/widgets/ble_device_selection_sheet.dart';
import 'package:hydrify/screens/widgets/custom_circular_loader/custom_circular_progress_indicator.dart';
import 'package:hydrify/screens/widgets/custom_circular_loader/custom_circular_water_progress_indicator.dart';
import 'package:hydrify/screens/widgets/greeting_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_beating_ble_status_indicator.dart';
import 'package:hydrify/screens/widgets/water_wave_widget.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // late AnimationController _controller;
  // late Animation<double> _shadowOffsetAnimation;
  bool _isPickerShown = false;
  bool hasConnectedBefore = false;
  bool isGuest = false;
  double userGoalLiters = 0;
  String selectedBottle = 'purple';
  BottleInfo? bottleInfo;

  void _checkGuestStatus() async {
    final email = await SharedPrefsHelper.getUserEmail();
    setState(() {
      isGuest = email == "guest_user";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadBottle();
    _checkGuestStatus();

    NotificationService().init(
      onTap: (slot) {},
    );
    //==================================================================
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      hasConnectedBefore = prefs.getBool('ble_connected_once') ?? false;

      // 🔹 read current bottle volume from cubit
      final bottleState = context.read<BottleDataCubit>().state;
      final double currentVolume = bottleState.volume;

      if (hasConnectedBefore) {
        context.read<BleCubit>().start();
      } else {
        // if (currentVolume < 600) {
        _showStartJourneyDialog(context);
        // } else {

        // Removing dialog as it causes bottle data to not come
        context.read<BleCubit>().start();
        await prefs.setBool('ble_connected_once', true);
        // }
      }
    });
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

  void _showStartJourneyDialog(BuildContext context) async {
    // Check if user is logged in as guest by checking email
    final userEmail = await SharedPrefsHelper.getUserEmail();
    final isGuest = userEmail == "guest_user";

    // Add debug print to verify
    print('🔍 DEBUG: userEmail = $userEmail, isGuest = $isGuest');

    if (!context.mounted) return;

    showDialog(
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
                                      context.read<BleCubit>().start();
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<BleCubit, BleState>(
      listener: (context, state) async {
        if (state.status == BleStatus.scanning &&
            state.scannedDevices.isNotEmpty &&
            !_isPickerShown &&
            state.isFirstConnection) {
          _isPickerShown = true;
          log("✅ Showing picker...");

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
              log("❌ Picker closed.");
              _isPickerShown = false;
            });
          });
        }
        if (state.status == BleStatus.connected &&
            ((state.volume ?? 0) < 600)) {
          // _showStartJourneyDialog(context);
          // Removing as this causes error
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
              //_buildBleStatus(context),
              SizedBox(
                height: AppDimensions.dim12.h,
              ),
              BlocBuilder<HydrationCubit, HydrationState>(
                buildWhen: (p, c) =>
                    p.currentSlotConsumption != c.currentSlotConsumption ||
                    p.currentSlotPercentage != c.currentSlotPercentage ||
                    p.currentSlotEntry != c.currentSlotEntry,
                builder: (context, state) {
                  final slotName =
                      state.currentSlotEntry?.slot.label ?? "Off-Slot Time";

                  final consumption = state.currentSlotConsumption;
                  final percentage = state.currentSlotPercentage;

                  return _buildTodayStats(
                    consumption,
                    percentage,
                    slotName,
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
              BlocBuilder<BottleDataCubit, BottleDataState>(
                buildWhen: (previous, current) =>
                    previous.volumePercent != current.volumePercent,
                builder: (context, state) {
                  return FutureBuilder(future: () {
                    DateTime now = DateTime.now();

                    DateTime startDate = DateTime(now.year, now.month, now.day);

                    DateTime endDate = startDate
                        .add(const Duration(days: 1))
                        .subtract(const Duration(milliseconds: 1));

                    return context
                        .read<BottleDataCubit>()
                        .getHistoryForDateRange(startDate, endDate);
                  }(), builder: (context, snapshot) {
                    double completionPercent = 0;
                    double waterVolumeConsumed = 0;

                    if (snapshot.hasData || snapshot.data?.isNotEmpty == true) {
                      waterVolumeConsumed =
                          WaterConsumptionCalculator.calculateDailyConsumption(
                              snapshot.data!);

                      completionPercent = WaterConsumptionCalculator
                          .calculateCompletionPercentage(
                              waterVolumeConsumed, userGoalLiters * 1000);
                      // .calculateCompletionPercentage(waterVolumeConsumed);
                    }
                    return _buildGoalText(completionPercent, isGuest);
                    // return _buildGoalText(completionPercent);
                  });
                },
              ),
            ],
          ),
        ),
      ),
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
              /// 📷 QR Scanner Button
              // IconButton(
              //   onPressed: () {
              //     Navigator.of(context, rootNavigator: true).pushReplacement(
              //       //context,
              //       MaterialPageRoute(
              //         builder: (_) => const QrScanner(),
              //       ),
              //     );
              //   },
              //   icon: Icon(
              //     Icons.qr_code_scanner,
              //     color: AppColors.black,
              //     size: AppDimensions.dim28.sp,
              //   ),
              //   tooltip: "Rescan Bottle",
              // ),

              SizedBox(width: AppDimensions.dim8.w),
              Column(
                children: [
                  CustomBeatingBleStatusIndicator(),
                  SizedBox(height: AppDimensions.dim5.h),
                  BlocBuilder<BottleDataCubit, BottleDataState>(
                    buildWhen: (previous, current) =>
                        previous.battery != current.battery,
                    builder: (context, state) {
                      return CustomCircularProgressIndicator(
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
            ],
          );
        }

        final weatherData = weatherProvider.weatherData;
        if (weatherData == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            weatherProvider.fetchWeatherForCurrentLocation();
          });
          return const Center(child: CircularProgressIndicator());
        }

        var iconPath = weatherProvider.getWeatherIcon();
        print('=== UI Widget Debug ===');
        print('Icon path received from provider: "$iconPath"');

        // if (iconPath == "assets/images/sunny_ic.svg") {
        //   iconPath = "assets/images/sunny_ic.png";
        // }

        if (iconPath == "assets/images/01_sunny_color.svg") {
          iconPath = "assets/images/01_sunny_color.svg";
        }

        // if (iconPath == "assets/weather/03_cloud_color.png") {
        //   iconPath = "assets/weather/03_cloud_color.png";
        // }

        return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding),
          child: Row(
            children: [
              Column(
                children: [
                  // Wrap SvgPicture.asset with error handling
                  SizedBox(
                    height: AppDimensions.dim45.h,
                    width: AppDimensions.dim45.h, // Add width for debugging

                    child: _buildWeatherIconWidget(iconPath),
                  ),
                  SizedBox(
                      height:
                          AppDimensions.dim8.h), // Changed from width to height
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
            bottom: -(AppDimensions.dim20.h),
            child: GestureDetector(
              onTap: () async {
                // await context.read<BleCubit>().forceFlushSlots();
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
              child: BlocBuilder<BottleDataCubit, BottleDataState>(
                  buildWhen: (previous, current) =>
                      previous.volumePercent != current.volumePercent ||
                      previous.volume != current.volume,
                  builder: (context, state) {
                    return FutureBuilder(future: () {
                      DateTime now = DateTime.now();

                      DateTime startDate =
                          DateTime(now.year, now.month, now.day);

                      DateTime endDate = startDate
                          .add(const Duration(days: 1))
                          .subtract(const Duration(milliseconds: 1));

                      return context
                          .read<BottleDataCubit>()
                          .getHistoryForDateRange(startDate, endDate);
                    }(), builder: (context, snapshot) {
                      double completionPercent = 0;
                      double waterVolumeConsumed = 0;

                      if (snapshot.hasData ||
                          snapshot.data?.isNotEmpty == true) {
                        waterVolumeConsumed = WaterConsumptionCalculator
                            .calculateDailyConsumption(snapshot.data!);

                        completionPercent = WaterConsumptionCalculator
                            .calculateCompletionPercentage(
                                waterVolumeConsumed, userGoalLiters * 1000);
                        //.calculateCompletionPercentage(waterVolumeConsumed,);
                      }

                      return CustomCircularWaterProgressIndicator(
                        height: AppDimensions.dim70.h,
                        width: AppDimensions.dim70.w,
                        // radius: AppDimensions.dim32.w,
                        // lineWidth: AppDimensions.dim7.w,
                        // backgroundNeedsGradient: true,
                        // linearGradient: LinearGradient(
                        //   begin: Alignment.centerLeft,
                        //   end: Alignment.centerRight,
                        //   transform: GradientRotation(-10 * pi / 180),
                        //   colors: [
                        //     Color(0XFFFFFFFF),
                        //     Color(0XFFFFFFFF),
                        //     Color(0XFF369FFF), //0XFF48CAFF
                        //     Color(0XFF369FFF), //0XFF48CAFF
                        //   ],
                        // ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: AppDimensions.dim4.r,
                            spreadRadius: AppDimensions.dim1.r,
                            color: Colors.black.withOpacity(.3),
                            offset: Offset(
                                AppDimensions.dim2.w, AppDimensions.dim2.h),
                          ),
                          BoxShadow(
                            blurRadius: AppDimensions.dim4.r,
                            spreadRadius: AppDimensions.dim1.r,
                            color: Colors.black.withOpacity(.3),
                            offset: Offset(
                                -AppDimensions.dim1.w, -AppDimensions.dim1.h),
                          ),
                        ],
                        backgroundColor: Color(0xFF767676),
                        progressBackgroundColor:
                            Color(0XFFFFFFFF).withOpacity(0.50),
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
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: waterVolumeConsumed / 1000,
                                ),
                                duration: Duration(milliseconds: 500),
                                curve: Curves.fastEaseInToSlowEaseOut,
                                builder: (context, value, child) {
                                  return Text(
                                    "${value.toStringAsFixed(1)}L",
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: AppFontStyles.fontSize_18,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation
                                      ],
                                    ),
                                  );
                                },
                              ),
                              FutureBuilder<int?>(
                                future: SharedPrefsHelper.getUserGoal(),
                                builder: (context, snapshot) {
                                  double userGoalLiters = 0.0;

                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    userGoalLiters = snapshot.data! / 1000.0;
                                  }

                                  return Text(
                                    "/${userGoalLiters.toStringAsFixed(1)}L",
                                    style: TextStyle(
                                      color: AppColors.lightSkyBlue,
                                      fontSize: AppFontStyles.fontSize_10,
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation,
                                      ],
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    });
                  }),
            ),
          ),
          Positioned(
            bottom: AppDimensions.dim195.h,
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
                  height: AppDimensions.dim117.h,
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
                          color: AppColors.black,
                          fontSize: AppFontStyles.fontSize_24,
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
          Positioned(
            bottom: AppDimensions.dim205.h,
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
                          color: AppColors.black,
                          fontSize: AppFontStyles.fontSize_10,
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
        ],
      ),
    );
  }

  Widget _buildBleStatus(BuildContext context) {
    return Container(
      height: AppDimensions.dim60.h,
      alignment: Alignment.center,
      child: BlocBuilder<BleCubit, BleState>(
        builder: (context, state) {
          final connectionState = state.status;

          switch (connectionState) {
            case BleStatus.disconnected:
              return Text(
                "Bottle disconnected",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_12,
                  color: AppColors.redColor,
                  fontVariations: [
                    AppFontStyles.semiBoldFontVariation,
                  ],
                ),
              );

            case BleStatus.scanning:
              return Text(
                "Scanning for bottle",
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_12,
                  color: AppColors.white,
                  fontVariations: [
                    AppFontStyles.semiBoldFontVariation,
                  ],
                ),
              );

            case BleStatus.connecting:
              return Text(
                "Initiating connection",
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_12,
                  color: AppColors.white,
                  fontVariations: [
                    AppFontStyles.semiBoldFontVariation,
                  ],
                ),
              );

            case BleStatus.connected:
              return Text(
                "Bottle connected",
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_12,
                  color: AppColors.white,
                  fontVariations: [
                    AppFontStyles.semiBoldFontVariation,
                  ],
                ),
              );

            default:
              return Text(
                "Bluetooth status unknown",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontStyles.fontSize_12,
                  color: AppColors.redColor,
                  fontVariations: [
                    AppFontStyles.semiBoldFontVariation,
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildTodayStats(double todayConsumption,
      double todayConsumptionPercentage, String slotName) {
    return InkWell(
      onTap: () async {},
      child: Container(
        height: AppDimensions.dim80.h,
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.dim4.r,
              spreadRadius: 0,
              color: Colors.black.withOpacity(.25),
              offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
            )
          ],
          border:
              // GradientBoxBorder(
              //   gradient: LinearGradient(
              //     begin: Alignment.topCenter,
              //     end: Alignment.bottomCenter,
              //     colors: [
              //       Colors.white,
              //       const Color(0XFF3F3F3F),
              //     ],
              //   ),
              //   width: AppDimensions.dim1.w,
              // ),
              Border.all(
                  color: AppColors.greywith80, width: AppDimensions.dim1),
          borderRadius: BorderRadius.circular(AppDimensions.dim90.r),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim16.w,
          vertical: AppDimensions.dim13.h,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppDimensions.dim28.w,
              height: AppDimensions.dim28.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 1.3.w),
                      child: Transform.translate(
                        offset: Offset(0, AppDimensions.dim3.h),
                        child: Opacity(
                          opacity: 0.3,
                          child: SvgPicture.asset(
                            'assets/images/water_drop_ic_new.svg',
                            color: AppColors.bluegray,
                            width: AppDimensions.dim28.w,
                            height: AppDimensions.dim28.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/water_drop_ic_new.svg',
                    fit: BoxFit.contain,
                    width: AppDimensions.dim28.w,
                    height: AppDimensions.dim28.h,
                  ),
                ],
              ),
            ),
            Container(
              width: AppDimensions.dim70.w,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Water",
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.bluegray,
                      fontSize: AppFontStyles.fontSize_12,
                      fontVariations: [
                        AppFontStyles.semiBoldFontVariation,
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: 0,
                      end: todayConsumption.toInt(),
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastEaseInToSlowEaseOut,
                    builder: (context, value, child) {
                      String displayValue;

                      if (value < 1000) {
                        displayValue = "$value ml";
                      } else {
                        displayValue = "${(value / 1000).toStringAsFixed(1)} L";
                      }
                      return Text(
                        displayValue,
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
            SizedBox(
              width: AppDimensions.dim25.w,
            ),
            Container(
              width: AppDimensions.dim118.w,
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
              width: AppDimensions.dim40.w,
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
                        AppFontStyles.semiBoldFontVariation,
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
    );
  }

  // Widget _buildGoalText(double todayConsumptionPercentage, bool isGuest) {
  //   final goalText = isGuest
  //       ? "If you have purchased the bottle and accidentally entered the guest page, you can log out from the settings page and log in normally.\n"
  //           "If you don’t have the bottle and want to use the basic water-reminder feature, you can schedule reminders from the settings page > Drink Reminder > Water Intake Timeline.\n"
  //           "You can also place your bottle order directly from the settings page."
  //       : AppStrings.getGoalString(todayConsumptionPercentage);

  //   final textStyle = TextStyle(
  //     fontSize: AppFontStyles.fontSize_16,
  //     color: AppColors.bluegray,
  //     height: AppFontStyles.getLineHeight(
  //       AppFontStyles.fontSize_16,
  //       120,
  //     ),
  //     fontVariations: [
  //       AppFontStyles.semiBoldFontVariation,
  //     ],
  //   );

  //   return SizedBox(
  //     width: AppDimensions.dim350.w,
  //     height: isGuest ? 70.h : null, // enough space to center vertically
  //     child: isGuest
  //         ? Align(
  //             alignment: Alignment.center,
  //             child: Marquee(
  //               text: goalText,
  //               style: textStyle,
  //               scrollAxis: Axis.vertical,

  //               // 🔥 Smooth, readable scroll
  //               velocity: 8.0,
  //               blankSpace: 40.0,
  //               startPadding: 30.0,
  //               pauseAfterRound: const Duration(seconds: 3),
  //               accelerationDuration: const Duration(seconds: 1),
  //               decelerationDuration: const Duration(seconds: 1),
  //             ),
  //           )
  //         : Text(
  //             goalText,
  //             style: textStyle,
  //             textAlign: TextAlign.center,
  //           ),
  //   );
  // }

  Widget _buildGoalText(double todayConsumptionPercentage, bool isGuest) {
    final goalText = isGuest
        ? "If you have purchased the bottle and accidentally entered the guest page, you can log out from the settings page and log in normally.\n"
            "If you don’t have the bottle and want to use the basic water-reminder feature, you can schedule reminders from the settings page > Drink Reminder > Water Intake Timeline.\n"
            "You can also place your bottle order directly from the settings page."
        : AppStrings.getGoalString(todayConsumptionPercentage);

    return isGuest
        ? AutoScrollGoalText(text: goalText) // ✅ image-style scroll
        : SizedBox(
            width: AppDimensions.dim350.w,
            child: Text(
              goalText,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: AppFontStyles.fontSize_16,
                  color: AppColors.bluegray,
                  fontFamily: AppFontStyles.museoModernoFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation]),
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
}
