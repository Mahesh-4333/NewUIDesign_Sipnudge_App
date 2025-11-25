// To parse this JSON data, do
//
//     final loginDetailsRequestModel = loginDetailsRequestModelFromJson(jsonString);

import 'dart:convert';

LoginDetailsRequestModel loginDetailsRequestModelFromJson(String str) =>
    LoginDetailsRequestModel.fromJson(json.decode(str));

String loginDetailsRequestModelToJson(LoginDetailsRequestModel data) =>
    json.encode(data.toJson());

class LoginDetailsRequestModel {
  String email;
  String password;
  String firstName;
  String lastName;
  String gender;
  int heightCm;
  String heightUnit;
  int weightKg;
  String weightUnit;
  int age;
  String wakeupTime;
  String bedtime;
  String timeFormat;
  String activityLevel;
  String dietType;
  bool hapticFeedback;
  bool wakeupAlarm;
  bool ledFeedback;

  LoginDetailsRequestModel({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.heightCm,
    required this.heightUnit,
    required this.weightKg,
    required this.weightUnit,
    required this.age,
    required this.wakeupTime,
    required this.bedtime,
    required this.timeFormat,
    required this.activityLevel,
    required this.dietType,
    required this.hapticFeedback,
    required this.wakeupAlarm,
    required this.ledFeedback,
  });

  factory LoginDetailsRequestModel.fromJson(Map<String, dynamic> json) =>
      LoginDetailsRequestModel(
        email: json["email"],
        password: json["password"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        gender: json["gender"],
        heightCm: json["height_cm"],
        heightUnit: json["height_unit"],
        weightKg: json["weight_kg"],
        weightUnit: json["weight_unit"],
        age: json["age"],
        wakeupTime: json["wakeup_time"],
        bedtime: json["bedtime"],
        timeFormat: json["time_format"],
        activityLevel: json["activity_level"],
        dietType: json["diet_type"],
        hapticFeedback: json["haptic_feedback"],
        wakeupAlarm: json["wakeup_alarm"],
        ledFeedback: json["led_feedback"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender,
        "height_cm": heightCm,
        "height_unit": heightUnit,
        "weight_kg": weightKg,
        "weight_unit": weightUnit,
        "age": age,
        "wakeup_time": wakeupTime,
        "bedtime": bedtime,
        "time_format": timeFormat,
        "activity_level": activityLevel,
        "diet_type": dietType,
        "haptic_feedback": hapticFeedback,
        "wakeup_alarm": wakeupAlarm,
        "led_feedback": ledFeedback,
      };
}
