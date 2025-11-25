// To parse this JSON data, do
//
//     final otpVerifyResponseModel = otpVerifyResponseModelFromJson(jsonString);

import 'dart:convert';

OtpVerifyResponseModel otpVerifyResponseModelFromJson(String str) =>
    OtpVerifyResponseModel.fromJson(json.decode(str));

String otpVerifyResponseModelToJson(OtpVerifyResponseModel data) =>
    json.encode(data.toJson());

class OtpVerifyResponseModel {
  String status;
  int statusCode;
  String message;

  OtpVerifyResponseModel({
    required this.status,
    required this.statusCode,
    required this.message,
  });

  factory OtpVerifyResponseModel.fromJson(Map<String, dynamic> json) =>
      OtpVerifyResponseModel(
        status: json["status"],
        statusCode: json["status_code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "status_code": statusCode,
        "message": message,
      };
}
