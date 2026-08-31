import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/models/bottle_info.dart';
import 'package:hydrify/models/device_other_data.dart';
import 'package:hydrify/providers/weather_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BottleInfoScreen extends StatefulWidget {
  final BottleInfo bottleInfo;

  const BottleInfoScreen({
    Key? key,
    required this.bottleInfo,
  }) : super(key: key);

  @override
  State<BottleInfoScreen> createState() => _BottleInfoScreenState();
}

class _BottleInfoScreenState extends State<BottleInfoScreen> {
  bool _isGeneralExpanded = true;
  bool _isHardwareExpanded = true;
  int _selectedIndex = 1; // Default: Midnight Black (index 1)
  String? _savedFwVersion;
  int? _savedHwVersion;
  int? _savedProgrammedAt;

  @override
  void initState() {
    super.initState();
    _loadSavedBottleColor();
    _loadSavedDeviceData();
    try {
      context.read<BleCubit>().readOtherData();
    } catch (_) {}
  }

  String _calculateEstimatedBatteryDays(int? batteryPercentage) {
    final int pct = batteryPercentage ?? 0;
    if (pct <= 0) return '0 Days Left';
    final double days = (pct * 20) / 100.0;
    final int roundedDays = days.round();
    if (roundedDays <= 0) return '< 1 Day Left';
    if (roundedDays == 1) return '1 Day Left';
    return '$roundedDays Days Left';
  }

  Future<void> _loadSavedDeviceData() async {
    final raw = await SharedPrefsHelper.getDeviceOtherDataRaw();
    if (raw != null && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final parsed = DeviceOtherData.fromJson(decoded, rawData: raw);
          if (mounted) {
            setState(() {
              _savedFwVersion = parsed.version;
              _savedHwVersion = parsed.hwVersion;
              _savedProgrammedAt = parsed.programmedAt;
            });
            return;
          }
        }
      } catch (_) {}
    }

    final fw = await SharedPrefsHelper.getDeviceFirmwareVersion();
    final hw = await SharedPrefsHelper.getDeviceHardwareVersion();
    final prog = await SharedPrefsHelper.getDeviceProgrammedAt();
    if (mounted) {
      setState(() {
        _savedFwVersion = fw;
        _savedHwVersion = hw;
        _savedProgrammedAt = prog;
      });
    }
  }

  Future<void> _loadSavedBottleColor() async {
    final savedColor = await SharedPrefsHelper.getBottleColor();
    int index = 1;
    if (savedColor == 'red') {
      index = 0;
    } else if (savedColor == 'black') {
      index = 1;
    } else if (savedColor == 'purple') {
      index = 2;
    }
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _onSelectBottle(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    final colorKeys = ['red', 'black', 'purple'];
    await SharedPrefsHelper.setBottleColor(colorKeys[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SizedBox(
        height: 0,
        width: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_background.png'),
            // Assuming a background texture exists or using a subtle gradient
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _titleWidget(context),

              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      // Interactive Bottle Selection Widget
                      _bottleSelectionWidget(),

                      SizedBox(height: 20.h),

                      // Horizontal Info Bar
                      _horizontalInfoWidget(),

                      SizedBox(height: 20.h),

                      // General Specification Card
                      _generalSpecificationWidget(),

                      SizedBox(height: 20.h),

                      // Hardware Specification Card
                      _hardWareSpecificationWidget(),

                      SizedBox(height: 30.h),

                      _infoWidget(),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                'Sipnudge Bottle',
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

  Container _infoWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: AppStyle.boxShadowVariation2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                AssetsPath.info,
                width: 30.w,
                height: 15.w,
              ),
              SizedBox(
                width: 4.w,
              ),
              Text(
                "About This Bottle",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  color: Color(0xff32A6E9),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              "A premium obsidian black smart bottle designed for elite hydration tracking. Features, UV purification and real-time intake monitoring.",
              style: TextStyle(
                fontSize: 10.sp,
                fontVariations: [AppFontStyles.semiBoldFontVariation],
                color: AppColors.greyColorText1,
              ),
            ),
          )
        ],
      ),
    );
  }

  Container _hardWareSpecificationWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppStyle.boxShadowVariation2,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isHardwareExpanded = !_isHardwareExpanded;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Color(0xffF7FAFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                    bottomLeft: _isHardwareExpanded
                        ? Radius.zero
                        : Radius.circular(24.r),
                    bottomRight: _isHardwareExpanded
                        ? Radius.zero
                        : Radius.circular(24.r),
                  )),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hardware Specification',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 15.w),
                      child: Image.asset(
                        _isHardwareExpanded
                            ? AssetsPath.downArrow
                            : AssetsPath.upperArrow,
                        color: Color(0xFF5D7B91),
                        width: 15.sp,
                        height: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isHardwareExpanded) ...[
            Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: AppStyle.boxShadowVariation2),
                child: BlocBuilder<BleCubit, BleState>(
                  builder: (context, bleState) {
                    final parsed = bleState.parsedOtherData;
                    final parsedFromOther = (parsed?.version != null ||
                            parsed?.hwVersion != null ||
                            parsed?.programmedAt != null)
                        ? parsed
                        : (bleState.otherData != null
                            ? DeviceOtherData.fromString(
                                bleState.otherData.toString())
                            : null);

                    final fwVersion = parsedFromOther?.version != null
                        ? (parsedFromOther!.version!.startsWith('v')
                            ? parsedFromOther.version!
                            : 'v${parsedFromOther.version}')
                        : (_savedFwVersion != null
                            ? (_savedFwVersion!.startsWith('v')
                                ? _savedFwVersion!
                                : 'v$_savedFwVersion')
                            : 'v1.0.0');
                    final hwVersion = parsedFromOther?.hwVersion != null
                        ? 'HW ${parsedFromOther!.hwVersion}'
                        : (_savedHwVersion != null
                            ? 'HW $_savedHwVersion'
                            : 'HW 2.0');

                    DateTime? progTime = parsedFromOther?.programmedAtDateTime;
                    if (progTime == null &&
                        _savedProgrammedAt != null &&
                        _savedProgrammedAt! > 0) {
                      final int ms = _savedProgrammedAt! < 10000000000
                          ? (_savedProgrammedAt! * 1000)
                          : _savedProgrammedAt!;
                      progTime = DateTime.fromMillisecondsSinceEpoch(ms);
                    }

                    String programmedAtStr = '—';
                    if (progTime != null) {
                      programmedAtStr =
                          DateFormat('dd MMM yyyy, hh:mm a').format(progTime);
                    }

                    final currentBattery = bleState.battery ??
                        context.read<BottleDataCubit>().state.battery;
                    final estimatedBatteryStr =
                        _calculateEstimatedBatteryDays(currentBattery);

                    return Column(
                      children: [
                        _buildHardwareInfoRow('Product Name', 'Sipnudge'),
                        _buildHardwareInfoRow('Model', 'SN-MB1'),
                        _buildHardwareInfoRow('Firmware Version', fwVersion),
                        _buildHardwareInfoRow('Hardware Version', hwVersion),
                        _buildHardwareInfoRow(
                            'Programmed At', programmedAtStr.trim()),
                        _buildHardwareInfoRow('Materials', 'SS 304',
                            subtitle: 'BPA-free & Food-grade'),
                        _buildHardwareInfoRow('Cleaning', 'UV Purification'),
                        _buildHardwareInfoRow(
                            'Connectivity', 'Bluetooth 5.0 LE'),
                        _buildHardwareInfoRow('Charging', 'USB-C (~2h Full)'),
                        _buildHardwareInfoRow(
                            'Estimated Battery \nLife Remaining',
                            estimatedBatteryStr),
                        _buildHardwareInfoRow('Weight', '~250g'),
                      ],
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }

  Container _generalSpecificationWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppStyle.boxShadowVariation2,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isGeneralExpanded = !_isGeneralExpanded;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Color(0xffF7FAFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                    bottomLeft: _isGeneralExpanded
                        ? Radius.zero
                        : Radius.circular(24.r),
                    bottomRight: _isGeneralExpanded
                        ? Radius.zero
                        : Radius.circular(24.r),
                  )),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'General Specifiaction',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 15.w),
                      child: Image.asset(
                        _isGeneralExpanded
                            ? AssetsPath.downArrow
                            : AssetsPath.upperArrow,
                        color: Color(0xFF5D7B91),
                        width: 15.sp,
                        height: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isGeneralExpanded) ...[
            Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Specs Grid
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.w, horizontal: 4.w),
              child: Wrap(
                spacing: 20.w,
                runSpacing: 23.h,
                children: [
                  _buildSpecCard(
                      'FILL LEVEL',
                      '${widget.bottleInfo.waterPercentage}',
                      '%',
                      AssetsPath.sFill_level),
                  _buildSpecCard('VOLUME', '${BottleInfo.capacity.toInt()}',
                      'ml', AssetsPath.sVolume),
                  // Using Capacity as per screenshot example 650
                  BlocBuilder<BottleDataCubit, BottleDataState>(
                    builder: (context, bottleState) {
                      final battery = bottleState.battery;
                      return _buildSpecCard(
                        'BATTERY',
                        battery.toString(),
                        '%',
                        AssetsPath.sBattery,
                        subtitle: _calculateEstimatedBatteryDays(battery),
                      );
                    },
                  ),
                  BlocBuilder<BottleDataCubit, BottleDataState>(
                    builder: (context, state) {
                      // Display actual temperature or fallback to "--" if null
                      final tempDisplay =
                          state.bqTemp != 0 ? "${state.bqTemp}" : "--";
                      return _buildSpecCard(
                          'TEMP', tempDisplay, '°C', AssetsPath.sTemperature,
                          subtitle: 'Range: 0-50°C');
                    },
                  ),
                  _buildSpecCard('MATERIAL', 'SS304', '', AssetsPath.sMaterial,
                      isTextValue: true),
                  _buildSpecCard('WEIGHT', '250', 'g', AssetsPath.sWeight),
                ],
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }

  Container _horizontalInfoWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 7.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppStyle.boxShadowVariation1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BlocBuilder<BleCubit, BleState>(buildWhen: (previous, current) {
            if (previous.currentHydrationValue !=
                current.currentHydrationValue) {
              return true;
            }
            return false;
          }, builder: (context, state) {
            return FutureBuilder<(double, double)>(future: () async {
              final history =
                  await context.read<BottleDataCubit>().getCurrentDayHistory();

              double waterVolumeConsumed = history;
              double remainingIntakeWater =
                  await WaterConsumptionCalculator.calculateRemainingPercentage(
                      waterVolumeConsumed);

              return (remainingIntakeWater, waterVolumeConsumed);
            }(), builder: (context, snapshot) {
              final (remainingIntakeWater, waterVolumeConsumed) =
                  snapshot.data ?? (0.0, 0.0);

              return _buildTopInfoItem(
                  'REMAINING',
                  '${remainingIntakeWater.toStringAsFixed(0)}ml',
                  Color(0xFF5D7B91));
            });
          }),
          Container(height: 30.h, width: 1, color: Color(0xFFE2E8F0)),
          BlocBuilder<BleCubit, BleState>(buildWhen: (previous, current) {
            if (previous.currentHydrationValue !=
                current.currentHydrationValue) {
              return true;
            }
            return false;
          }, builder: (context, state) {
            return FutureBuilder<(double, double)>(future: () async {
              final history =
                  await context.read<BottleDataCubit>().getCurrentDayHistory();

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
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildTopInfoItem(
                      'CONSUMED',
                      '${completionPercent.toStringAsFixed(0)}%',
                      Color(0xFF5D7B91)),
                ],
              );
            });
          }),
          Container(height: 30.h, width: 1, color: Color(0xFFE2E8F0)),
          BlocBuilder<BleCubit, BleState>(
            builder: (context, bleState) {
              Color syncColor = bleState.status != BleStatus.connected
                  ? AppColors.redColor
                  : Color(0xff46E73D);
              return _buildStatusItem('STATUS', 'Connected', syncColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _bottleSelectionWidget() {
    final List<Map<String, dynamic>> bottleOptions = [
      {
        'key': 'red',
        'name': AppLocalizations.of(context)?.candyRed ?? 'Candy Red',
        'color': const Color(0xFF9E1F27),
        'asset': AssetsPath.onboardingRed,
        'description': AppLocalizations.of(context)?.descCandyRed ??
            '“Bold, Energetic, and Impossible to ignore”',
      },
      {
        'key': 'black',
        'name': AppLocalizations.of(context)?.midnightBlack ?? 'Midnight Black',
        'color': const Color(0xFF2B2E33),
        'asset': AssetsPath.onboardingBlack,
        'description': AppLocalizations.of(context)?.descMidnightBlack ??
            '“Minimal, Timeless. Built for every environment”',
      },
      {
        'key': 'purple',
        'name': AppLocalizations.of(context)?.deepPurple ?? 'Deep Purple',
        'color': const Color(0xFF56396F),
        'asset': AssetsPath.onboardingPurple,
        'description': AppLocalizations.of(context)?.descDeepPurple ??
            '“Creative, Premium, and uniquely yours”',
      },
    ];

    return Column(
      children: [
        // 3 Bottles Display Side-by-Side
        SizedBox(
          height: 310.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(bottleOptions.length, (index) {
              final isSelected = index == _selectedIndex;
              return GestureDetector(
                onTap: () => _onSelectBottle(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: isSelected ? 300.h : 240.h,
                  width: 95.w,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isSelected ? 1.0 : 0.7,
                    child: isSelected
                        ? Image.asset(
                            bottleOptions[index]['asset'],
                            fit: BoxFit.contain,
                          )
                        : ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: 1.3,
                              sigmaY: 1.3,
                              tileMode: ui.TileMode.decal,
                            ),
                            child: Image.asset(
                              bottleOptions[index]['asset'],
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ),

        SizedBox(height: 16.h),

        // Color Description Quote Text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            bottleOptions[_selectedIndex]['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5D7B91),
              fontSize: 15.sp,
              fontStyle: FontStyle.italic,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Color Selection Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(bottleOptions.length, (index) {
            final isSelected = index == _selectedIndex;
            final color = bottleOptions[index]['color'] as Color;

            return GestureDetector(
              onTap: () => _onSelectBottle(index),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2.w,
                  ),
                ),
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),

        SizedBox(height: 10.h),

        // Selected Color Name Label Text
        Text(
          bottleOptions[_selectedIndex]['name'],
          style: TextStyle(
            color: const Color(0xFF2C434C),
            fontSize: 16.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareInfoRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 9,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontVariations: [AppFontStyles.boldFontVariation],
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: Color(0xff94A3B8),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.bluegray),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.greyColorText1,
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

  Widget _buildTopInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontVariations: [AppFontStyles.boldFontVariation],
            color: AppColors.greyColorText1,
            fontFamily: AppFontStyles.urbanistFontFamily,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontVariations: [AppFontStyles.boldFontVariation],
            fontFamily: AppFontStyles.urbanistFontFamily,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color statusColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontVariations: [AppFontStyles.boldFontVariation],
            fontFamily: AppFontStyles.urbanistFontFamily,
            color: AppColors.greyColorText1,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontVariations: [AppFontStyles.boldFontVariation],
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: Color(0xFF5D7B91),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecCard(String label, String value, String unit, String icon,
      {String? subtitle, bool isTextValue = false}) {
    return Container(
      width: 170.w,
      height: 90.h,
      padding: EdgeInsets.only(top: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 30.w),
            child: Row(
              children: [
                Image.asset(icon,
                    color: Color(0xFF3B82F6), width: 18.sp, height: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.greyColorText1,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 7.h,
          ),
          Padding(
            padding: EdgeInsets.only(left: 30.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: isTextValue ? 23.sp : 29.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.bluegray,
                      height: 0),
                ),
                if (unit.isNotEmpty) ...[
                  SizedBox(width: 4.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 8.sp,
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w500,
                  height: 1),
            ),
          ],
        ],
      ),
    );
  }
}
