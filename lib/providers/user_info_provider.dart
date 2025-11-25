import 'package:flutter/material.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/models/user_info.dart';

class UserInfoProvider extends ChangeNotifier {
  final UserInfo _userInfo = UserInfo();

  UserInfo get userInfo => _userInfo;

  void setGender(Gender? gender) {
    _userInfo.gender = gender;
    notifyListeners();
  }

  void setHeight(double? height) {
    _userInfo.height = height;
    notifyListeners();
  }

  void setHeightUnit(String unit) {
    _userInfo.heightUnit = unit;
    notifyListeners();
  }

  void setWeight(double? weight) {
    _userInfo.weight = weight;
    notifyListeners();
  }

  void setWeightUnit(String unit) {
    _userInfo.weightUnit = unit;
    notifyListeners();
  }

  void setAge(int? age) {
    _userInfo.age = age;
    notifyListeners();
  }

  void setWakeupTime(TimeOfDay? time) {
    _userInfo.wakeupTime = time;
    notifyListeners();
  }

  void setWakeupTimeAmPm(String amPm) {
    _userInfo.wakeupTimeAmPm = amPm;
    notifyListeners();
  }

  void setBedTime(TimeOfDay? time) {
    _userInfo.bedTime = time;
    notifyListeners();
  }

  void setBedTimeAmPm(String amPm) {
    _userInfo.bedTimeAmPm = amPm;
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel? level) {
    _userInfo.activityLevel = level;
    notifyListeners();
  }

  // Convert between time formats as needed
  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';

    String hour = time.hourOfPeriod.toString().padLeft(2, '0');
    if (hour == '00') hour = '12';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
