import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_info.dart';
import 'package:hydrify/providers/weather_provider.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SizedBox(height: 0, width: 0,),
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
                      // Bottle Image Card
                      _bottleWidget(),

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
                  fontVariations: [AppFontStyles.boldFontVariation,],
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
                child: Column(
                  children: [
                    _buildHardwareInfoRow('Product Name', 'Sipnudge'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow('Model', 'SN-MB1'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow('Materials', 'SS 304',
                        subtitle: 'BPA-free & Food-grade'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow('Cleaning', 'UV Purification'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow('Connectivity', 'Bluetooth 5.0 LE'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow('Charging', 'USB-C (~2h Full)'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow(
                        'Estimated Battery \nLife Remaining', '25 Days Left'),
                    // Divider(
                    //     height: 1, color: Color(0xFFF1F5F9)),
                    _buildHardwareInfoRow('Weight', '~250g'),
                  ],
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
                  _buildSpecCard('BATTERY', context
                      .read<BottleDataCubit>()
                      .state
                      .battery
                      .toString(), '%', AssetsPath.sBattery,
                      subtitle: '30 days Left'),
                  Consumer<WeatherProvider>(
                      builder: (context, weatherProvider, child) {
                        if (weatherProvider.isLoading) {
                          return _buildSpecCard(
                              'TEMP', '18', '°C', AssetsPath.sTemperature,
                              subtitle: 'Range: 0-50°C');
                        }

                        final weatherData = weatherProvider.weatherData;
                        return _buildSpecCard(
                            'TEMP', weatherData!.temperature.toString(), '°C', AssetsPath.sTemperature,
                            subtitle: 'Range: 0-50°C');
                      })
                  ,
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
              final history = await context
                  .read<BottleDataCubit>()
                  .getCurrentDayHistory();

              double waterVolumeConsumed = history;
              double remainingIntakeWater = await WaterConsumptionCalculator
                  .calculateRemainingPercentage(waterVolumeConsumed);

              return (remainingIntakeWater, waterVolumeConsumed);
            }(), builder: (context, snapshot) {
              final (remainingIntakeWater, waterVolumeConsumed) =
                  snapshot.data ?? (0.0, 0.0);

              return _buildTopInfoItem('REMAINING',
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
                      'CONSUMED', '${completionPercent.toStringAsFixed(0)}%',
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

  Container _bottleWidget() {
    return Container(
      width: 280.w,
      height: 280.w,
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      decoration: BoxDecoration(
        color: Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          widget.bottleInfo.imagePath,
          height: 220.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHardwareInfoRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
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
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
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
                    textAlign: TextAlign.right,
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
