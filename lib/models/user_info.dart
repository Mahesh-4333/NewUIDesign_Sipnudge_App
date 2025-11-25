import 'package:flutter/material.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';

class UserInfo {
  Gender? gender;
  double? height;
  String heightUnit; // "cm" or "ft"
  double? weight;
  String weightUnit; // "kg" or "lb"
  int? age;
  TimeOfDay? wakeupTime;
  String wakeupTimeAmPm; // "AM" or "PM"
  TimeOfDay? bedTime;
  String bedTimeAmPm; // "AM" or "PM"
  ActivityLevel? activityLevel;

  UserInfo({
    this.gender,
    this.height,
    this.heightUnit = "cm",
    this.weight,
    this.weightUnit = "kg",
    this.age,
    this.wakeupTime,
    this.wakeupTimeAmPm = "AM",
    this.bedTime,
    this.bedTimeAmPm = "PM",
    this.activityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender?.toString(),
      'height': height,
      'heightUnit': heightUnit,
      'weight': weight,
      'weightUnit': weightUnit,
      'age': age,
      'wakeupTime': wakeupTime != null
          ? '${wakeupTime!.hour}:${wakeupTime!.minute}'
          : null,
      'wakeupTimeAmPm': wakeupTimeAmPm,
      'bedTime': bedTime != null ? '${bedTime!.hour}:${bedTime!.minute}' : null,
      'bedTimeAmPm': bedTimeAmPm,
      'activityLevel': activityLevel?.toString(),
    };
  }
}
