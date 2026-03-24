import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

class ConfigTestScreen extends StatefulWidget {
  const ConfigTestScreen({super.key});

  @override
  State<ConfigTestScreen> createState() => _ConfigTestScreenState();
}

class _ConfigTestScreenState extends State<ConfigTestScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  int _targetWater = 0;
  double _lightIntensity = 50;
  double _hapticsIntensity = 50;
  bool _reminderState = true;
  bool _stopOnCompletion = true;
  int _alarmRepetition = 1;

  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final goal = await SharedPrefsHelper.getWaterGoal();
    setState(() {
      _targetWater = goal ?? 2000;
      _targetController.text = _targetWater.toString();
    });
  }

  int _timeOfDayToEpoch(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  void _submit() {
    final startEpoch = _timeOfDayToEpoch(_startTime);
    final endEpoch = _timeOfDayToEpoch(_endTime);

    final payload = '0/$startEpoch/$endEpoch|'
        '1/$_targetWater|'
        '2/${_lightIntensity.toInt()}|'
        '3/${_hapticsIntensity.toInt()}|'
        '4/${_reminderState ? 1 : 0}|'
        '5/${_stopOnCompletion ? 1 : 0}|'
        '6/$_alarmRepetition';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Config Data Sent',
          style: TextStyle(
            color: AppColors.black,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
        content: Text(
          payload,
          style: TextStyle(
            color: AppColors.charcoalGrey,
            fontFamily: AppFontStyles.museoModernoFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.aztecpurple,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    context.read<BleCubit>().sendConfigData(payload);
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.aztecpurple,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        border: Border.all(color: AppColors.lightgray.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildRow(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: AppColors.eerieBlack,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                  fontSize: 16.sp),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.paleblue,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                value,
                style: TextStyle(
                    color: AppColors.aztecpurple,
                    fontFamily: AppFontStyles.museoModernoFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
        color: AppColors.eerieBlack,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [AppFontStyles.semiBoldFontVariation],
        fontSize: 16.sp);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Config Test',
          style: TextStyle(
            color: AppColors.eerieBlack,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
            fontSize: 22.sp,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.eerieBlack),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                _buildCard(
                  child: Column(
                    children: [
                      _buildRow('Start Time', _startTime.format(context),
                          () => _pickTime(context, true)),
                      Divider(color: AppColors.lightgray.withOpacity(0.5), height: 24.h),
                      _buildRow('End Time', _endTime.format(context),
                          () => _pickTime(context, false)),
                    ],
                  ),
                ),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Target (ml)', style: titleStyle),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _targetController,
                        enabled: false,
                        style: TextStyle(
                          color: AppColors.charcoalGrey,
                          fontFamily: AppFontStyles.museoModernoFontFamily,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.paleblue,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          prefixIcon: Icon(Icons.water_drop,
                              color: AppColors.aztecpurple, size: 20.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Light Intensity', style: titleStyle),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.lightSkyBlue,
                          inactiveTrackColor: AppColors.lightgray,
                          thumbColor: AppColors.white,
                          overlayColor:
                              AppColors.lightSkyBlue.withOpacity(0.2),
                          valueIndicatorColor: AppColors.lightSkyBlue,
                        ),
                        child: Slider(
                          value: _lightIntensity,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _lightIntensity.round().toString(),
                          onChanged: (val) {
                            setState(() {
                              _lightIntensity = val;
                            });
                          },
                        ),
                      ),
                      Divider(color: AppColors.lightgray.withOpacity(0.5), height: 24.h),
                      Text('Haptics Intensity', style: titleStyle),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.mangoorange,
                          inactiveTrackColor: AppColors.lightgray,
                          thumbColor: AppColors.white,
                          overlayColor: AppColors.mangoorange.withOpacity(0.2),
                          valueIndicatorColor: AppColors.mangoorange,
                        ),
                        child: Slider(
                          value: _hapticsIntensity,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _hapticsIntensity.round().toString(),
                          onChanged: (val) {
                            setState(() {
                              _hapticsIntensity = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reminder', style: titleStyle),
                          Switch(
                            value: _reminderState,
                            activeColor: AppColors.white,
                            activeTrackColor: AppColors.aztecpurple,
                            inactiveThumbColor: AppColors.white,
                            inactiveTrackColor: AppColors.lightgray,
                            onChanged: (val) {
                              setState(() {
                                _reminderState = val;
                              });
                            },
                          ),
                        ],
                      ),
                      Divider(color: AppColors.lightgray.withOpacity(0.5), height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stop on Completion', style: titleStyle),
                          Switch(
                            value: _stopOnCompletion,
                            activeColor: AppColors.white,
                            activeTrackColor: AppColors.aztecpurple,
                            inactiveThumbColor: AppColors.white,
                            inactiveTrackColor: AppColors.lightgray,
                            onChanged: (val) {
                              setState(() {
                                _stopOnCompletion = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Alarm Repetition', style: titleStyle),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.paleblue,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            dropdownColor: AppColors.white,
                            value: _alarmRepetition,
                            isDense: true,
                            style: TextStyle(
                              color: AppColors.aztecpurple,
                              fontFamily: AppFontStyles.museoModernoFontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            icon: Icon(Icons.arrow_drop_down,
                                color: AppColors.aztecpurple, size: 24.sp),
                            items: [1, 3, 5].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value Times'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _alarmRepetition = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: _submit,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: const LinearGradient(
                        colors: [AppColors.aztecpurple, AppColors.purplemimosa],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.aztecpurple.withOpacity(0.4),
                          blurRadius: 12.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Send Configuration',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
