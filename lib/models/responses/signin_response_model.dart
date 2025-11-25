import 'dart:convert';

SigninResponseModel signinResponseModelFromJson(String str) =>
    SigninResponseModel.fromJson(json.decode(str));

String signinResponseModelToJson(SigninResponseModel data) =>
    json.encode(data.toJson());

class SigninResponseModel {
  String? status;
  int? statusCode;
  String? message;
  Data? data;

  SigninResponseModel({this.status, this.message, this.data, this.statusCode});

  factory SigninResponseModel.fromJson(Map<String, dynamic> json) =>
      SigninResponseModel(
        status: json["status"],
        message: json["message"],
        statusCode: json["status_code"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "status_code": statusCode,
        "data": data?.toJson(),
      };
}

class Data {
  String? token;
  String? refreshToken;
  UserDetails? userDetails;

  Data({
    this.token,
    this.refreshToken,
    this.userDetails,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        token: json["token"],
        refreshToken: json["refresh_token"],
        userDetails: json["user_details"] == null
            ? null
            : UserDetails.fromJson(json["user_details"]),
      );

  Map<String, dynamic> toJson() => {
        "token": token,
        "refresh_token": refreshToken,
        "user_details": userDetails?.toJson(),
      };
}

class UserDetails {
  String? gender;
  String? firstName;
  String? lastName;
  int? age;
  String? profilePicture;
  int? heightCm;
  String? heightUnit;
  int? weightKg;
  String? weightUnit;
  int? calculatedWater;
  String? wakeupTime;
  String? wakeupTimePeriod;
  String? bedtime;
  String? bedtimePeriod;
  String? timeFormat;
  String? activityLevel;
  String? dietType;
  bool? hapticFeedback;
  bool? wakeupAlarm;
  bool? ledFeedback;
  dynamic city;
  dynamic latitude;
  dynamic longitude;
  dynamic googleId;
  dynamic appleId;
  bool? hasBiometrics;

  UserDetails({
    this.gender,
    this.firstName,
    this.lastName,
    this.age,
    this.profilePicture,
    this.heightCm,
    this.heightUnit,
    this.weightKg,
    this.weightUnit,
    this.calculatedWater,
    this.wakeupTime,
    this.wakeupTimePeriod,
    this.bedtime,
    this.bedtimePeriod,
    this.timeFormat,
    this.activityLevel,
    this.dietType,
    this.hapticFeedback,
    this.wakeupAlarm,
    this.ledFeedback,
    this.city,
    this.latitude,
    this.longitude,
    this.googleId,
    this.appleId,
    this.hasBiometrics,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) => UserDetails(
        gender: json["gender"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        age: json["age"],
        profilePicture: json["profile_picture"],
        heightCm: json["height_cm"],
        heightUnit: json["height_unit"],
        weightKg: json["weight_kg"],
        weightUnit: json["weight_unit"],
        calculatedWater: json["calculated_water"],
        wakeupTime: json["wakeup_time"],
        wakeupTimePeriod: json["wakeup_time_period"],
        bedtime: json["bedtime"],
        bedtimePeriod: json["bedtime_period"],
        timeFormat: json["time_format"],
        activityLevel: json["activity_level"],
        dietType: json["diet_type"],
        hapticFeedback: json["haptic_feedback"],
        wakeupAlarm: json["wakeup_alarm"],
        ledFeedback: json["led_feedback"],
        city: json["city"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        googleId: json["google_id"],
        appleId: json["apple_id"],
        hasBiometrics: json["has_biometrics"],
      );

  Map<String, dynamic> toJson() => {
        "gender": gender,
        "first_name": firstName,
        "last_name": lastName,
        "age": age,
        "profile_picture": profilePicture,
        "height_cm": heightCm,
        "height_unit": heightUnit,
        "weight_kg": weightKg,
        "weight_unit": weightUnit,
        "calculated_water": calculatedWater,
        "wakeup_time": wakeupTime,
        "wakeup_time_period": wakeupTimePeriod,
        "bedtime": bedtime,
        "bedtime_period": bedtimePeriod,
        "time_format": timeFormat,
        "activity_level": activityLevel,
        "diet_type": dietType,
        "haptic_feedback": hapticFeedback,
        "wakeup_alarm": wakeupAlarm,
        "led_feedback": ledFeedback,
        "city": city,
        "latitude": latitude,
        "longitude": longitude,
        "google_id": googleId,
        "apple_id": appleId,
        "has_biometrics": hasBiometrics,
      };
}
