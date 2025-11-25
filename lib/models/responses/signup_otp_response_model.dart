// To parse this JSON data, do
//
//     final signupOtpResponse = signupOtpResponseFromJson(jsonString);

import 'dart:convert';

OtpResponseModel otpResponseModelFromJson(String str) =>
    OtpResponseModel.fromJson(json.decode(str));

String otpResponseToJson(OtpResponseModel data) => json.encode(data.toJson());

class OtpResponseModel {
  String status;
  int statusCode;
  String message;
  OtpResponseModelData data;

  OtpResponseModel({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) =>
      OtpResponseModel(
        status: json["status"],
        statusCode: json["status_code"],
        message: json["message"],
        data: OtpResponseModelData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "status_code": statusCode,
        "message": message,
        "data": data.toJson(),
      };
}

class OtpResponseModelData {
  String expiresIn;
  String sentTo;

  OtpResponseModelData({
    required this.expiresIn,
    required this.sentTo,
  });

  factory OtpResponseModelData.fromJson(Map<String, dynamic> json) =>
      OtpResponseModelData(
        expiresIn: json["expires_in"],
        sentTo: json["sent_to"],
      );

  Map<String, dynamic> toJson() => {
        "expires_in": expiresIn,
        "sent_to": sentTo,
      };
}
