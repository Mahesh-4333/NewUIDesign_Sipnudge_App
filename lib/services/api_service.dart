import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:hydrify/models/requests/login_details_request_model.dart';
import 'package:hydrify/models/responses/signin_response_model.dart';
import 'package:hydrify/models/responses/signup_otp_response_model.dart';
import 'package:hydrify/models/responses/signup_response_model.dart';
import 'package:hydrify/services/api_client.dart';

class ApiService {
  final Dio _dio = ApiClient().dio;

  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return Exception("Connection timeout. Please try again.");
    } else if (error.type == DioExceptionType.sendTimeout) {
      return Exception("Request timeout. Please try again.");
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return Exception("Response timeout. Please try again.");
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode ?? 0;
      final message = error.response?.data['message'] ?? 'Something went wrong';

      return Exception("[$statusCode] $message");
    } else if (error.type == DioExceptionType.cancel) {
      return Exception("Request was cancelled.");
    } else if (error.type == DioExceptionType.unknown) {
      return Exception("No Internet connection or unknown error.");
    } else {
      return Exception("Unexpected error occurred.");
    }
  }

  Future<SigninResponseModel> signIn(String email, String password) async {
    try {
      final response = await _dio.post(
        'signIn',
        data: {
          'email': email,
          'password': password,
        },
      );

      return signinResponseModelFromJson(response.data);
    } on DioException catch (e) {
      log("Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<SignUpResponseModel> signUp(String email, String password) async {
    try {
      final response = await _dio.post(
        'signUp',
        data: {
          'email': email,
          'password': password,
        },
      );

      return signUpResponseModelFromJson(response.data);
    } on DioException catch (e) {
      log("Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<OtpResponseModel> getSignUpOTP(String email) async {
    try {
      final response = await _dio.post(
        'otp/send?skip_verify=true',
        data: {
          'email': email,
        },
      );

      return otpResponseModelFromJson(response.data);
    } on DioException catch (e) {
      log("Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<OtpResponseModel> getOTP(String email) async {
    try {
      final response = await _dio.post(
        'otp/send',
        data: {
          'email': email,
        },
      );

      return otpResponseModelFromJson(response.data);
    } on DioException catch (e) {
      log("Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<OtpResponseModel> verifyOTP(String email, String submittedOTP) async {
    try {
      final response = await _dio.post(
        'otp/verify',
        data: {'email': email, 'otp': submittedOTP},
      );

      return otpResponseModelFromJson(response.data);
    } on DioException catch (e) {
      log("Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<SignUpResponseModel> submitLoginDetails(
      LoginDetailsRequestModel requestModel) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': '••••••'
      };
      final response = await _dio.request(
        '/api/v1/user/login-details',
        queryParameters: {
          'email': requestModel.email,
        },
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        data: requestModel.toJson(),
      );

      return SignUpResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      log("Exception occurred : submitLoginDetails || ${e.toString()} ");
      throw _handleError(e);
    }
  }
}
