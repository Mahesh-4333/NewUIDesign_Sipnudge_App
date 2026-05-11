import 'package:hydrify/helpers/logger.dart';

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
      Console.log(
          tag: "APP", value: "Exception occurred : signIn || ${e.toString()} ");
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
      Console.log(
          tag: "APP", value: "Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await _dio.get('/api/user/email/$email');
      return response.data;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : getUserByEmail || ${e.toString()} ");
      return null;
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
      Console.log(
          tag: "APP", value: "Exception occurred : signIn || ${e.toString()} ");
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
      Console.log(
          tag: "APP", value: "Exception occurred : signIn || ${e.toString()} ");
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
      Console.log(
          tag: "APP", value: "Exception occurred : signIn || ${e.toString()} ");
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
      Console.log(
          tag: "APP",
          value: "Exception occurred : submitLoginDetails || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  // --- Database Sync Methods ---

  Future<Map<String, dynamic>?> syncUserInfoData(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-user',
        data: data,
      );
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncUserInfoData: $e");
      return null;
    }
  }

  Future<bool> syncUserInfo(
      String userId, Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-user',
        data: {'userId': userId, ...userData},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncUserInfo: $e");
      return false;
    }
  }

  Future<bool> syncBottleHistory(
      String userId, List<Map<String, dynamic>> logs) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-bottle-history',
        data: {'userId': userId, 'logs': logs},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncBottleHistory: $e");
      return false;
    }
  }

  Future<bool> syncManualLogs(
      String userId, List<Map<String, dynamic>> logs) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-manual-logs',
        data: {'userId': userId, 'logs': logs},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncManualLogs: $e");
      return false;
    }
  }

  Future<bool> syncDailySummaries(
      String userId, List<Map<String, dynamic>> summaries) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-daily-summaries',
        data: {'userId': userId, 'summaries': summaries},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncDailySummaries: $e");
      return false;
    }
  }

  Future<bool> syncFoodScans(
      String userId, List<Map<String, dynamic>> scans) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-food-scans',
        data: {'userId': userId, 'scans': scans},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncFoodScans: $e");
      return false;
    }
  }

  Future<bool> syncAiLogs(
      String userId, List<Map<String, dynamic>> logs) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-ai-logs',
        data: {'userId': userId, 'logs': logs},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncAiLogs: $e");
      return false;
    }
  }

  Future<bool> syncDailyGoals(
      String userId, List<Map<String, dynamic>> goals) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-daily-goals',
        data: {'userId': userId, 'goals': goals},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncDailyGoals: $e");
      return false;
    }
  }

  Future<bool> syncDailySteps(
      String userId, List<Map<String, dynamic>> steps) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-daily-steps',
        data: {'userId': userId, 'steps': steps},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncDailySteps: $e");
      return false;
    }
  }

  Future<bool> syncTodayHistory(
      String userId, List<Map<String, dynamic>> history) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-today-history',
        data: {'userId': userId, 'history': history},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncTodayHistory: $e");
      return false;
    }
  }

  Future<bool> syncSlots(
      String userId, List<Map<String, dynamic>> slots) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-slots',
        data: {'userId': userId, 'slots': slots},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncSlots: $e");
      return false;
    }
  }

  Future<bool> syncMetadata(
      String userId, List<Map<String, dynamic>> metadata) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-metadata',
        data: {'userId': userId, 'metadata': metadata},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncMetadata: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAnalytics(String userId, int year, {int? month}) async {
    try {
      final queryParams = {'year': year.toString()};
      if (month != null) queryParams['month'] = month.toString();
      
      final response = await _dio.get(
        '/api/database/analytics/$userId',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in getAnalytics: $e");
      return null;
    }
  }
}
