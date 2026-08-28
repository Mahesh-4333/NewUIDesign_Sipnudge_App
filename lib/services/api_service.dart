import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

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
          'user_type': 'trail',
        },
      );

      return SigninResponseModel.fromJson(response.data);
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

      return SignUpResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      Console.log(
          tag: "APP", value: "Exception occurred : signIn || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> checkTrialStatus(String email) async {
    try {
      final response = await _dio.post(
        'checkTrialStatus',
        data: {
          'email': email,
          'user_type': 'trail',
        },
      );
      return response.data;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in checkTrialStatus: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> shutdownTrialUser(String email) async {
    try {
      final response = await _dio.post(
        'shutdownTrialUser',
        data: {
          'email': email,
        },
      );
      return response.data;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in shutdownTrialUser: $e");
      return null;
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

  Future<Map<String, dynamic>> requestSignupOTP(
      String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/user/otp/send',
        data: {
          'email': email,
          'password': password,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : requestSignupOTP || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifySignupOTP(String email, int otp) async {
    try {
      final response = await _dio.post(
        '/api/user/otp/verify',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : verifySignupOTP || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resendSignupOTP(String email) async {
    try {
      final response = await _dio.post(
        '/api/user/otp/send',
        data: {
          'email': email,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : resendSignupOTP || ${e.toString()} ");
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

      return OtpResponseModel.fromJson(response.data);
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

      return OtpResponseModel.fromJson(response.data);
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

      return OtpResponseModel.fromJson(response.data);
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

  Future<bool> checkNameUniqueness(String name, String? userId) async {
    try {
      final response = await _dio.get(
        '/api/database/check-name/${Uri.encodeComponent(name)}',
        queryParameters: userId != null ? {'userId': userId} : null,
      );
      return response.data['unique'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in checkNameUniqueness: $e");
      return true;
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

  /// Creates a single manual log on the server and returns its MongoDB _id (serverId).
  /// Returns null on failure.
  Future<String?> createManualLog(
      String userId, String type, double consumed, String utcTimestamp,
      {String? localDate}) async {
    try {
      final response = await _dio.post(
        '/api/database/create-manual-log-v2',
        data: {
          'userId': userId,
          'type': type,
          'consumed': consumed,
          'timestamp': utcTimestamp,
          if (localDate != null) 'localDate': localDate,
        },
      );
      if (response.data['success'] == true) {
        return response.data['serverId']?.toString();
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in createManualLog: $e");
      return null;
    }
  }

  /// Deletes a manual log from the server.
  /// Prefers [serverId] (MongoDB _id) for reliable matching.
  /// Falls back to (type, consumed, timestamp) if serverId is not available.
  Future<bool> deleteManualLog(
      String userId, String type, double consumed, String timestamp,
      {String? serverId, String? localDate}) async {
    try {
      final response = await _dio.post(
        '/api/database/delete-manual-log-v2',
        data: {
          'userId': userId,
          if (serverId != null) 'serverId': serverId,
          'type': type,
          'consumed': consumed,
          'timestamp': timestamp,
          if (localDate != null) 'localDate': localDate,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in deleteManualLog: $e");
      return false;
    }
  }

  Future<bool> deleteFoodScan(String userId,
      {String? scanId,
      String? dishName,
      String? timestamp,
      String? localTimestamp}) async {
    try {
      final response = await _dio.post(
        '/api/database/delete-food-scan',
        data: {
          'userId': userId,
          if (scanId != null && scanId.isNotEmpty) 'scanId': scanId,
          if (dishName != null && dishName.isNotEmpty) 'dishName': dishName,
          if (timestamp != null && timestamp.isNotEmpty) 'timestamp': timestamp,
          if (localTimestamp != null && localTimestamp.isNotEmpty)
            'localTimestamp': localTimestamp,
        },
      );
      Console.log(
          tag: "APP",
          value:
              "[deleteFoodScan] Response: ${response.statusCode} - ${response.data}");
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value:
              "Exception in deleteFoodScan: $e, response: ${e.response?.data}");
      return false;
    }
  }

  /// Fetches manual logs for a user. Pass [date] as 'YYYY-MM-DD' to filter
  /// by a specific day. Without [date], all logs are returned.
  Future<List<Map<String, dynamic>>?> getManualLogs(String userId,
      {String? date}) async {
    try {
      final response = await _dio.get(
        '/api/database/manual-logs/$userId',
        queryParameters: date != null ? {'date': date} : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in getManualLogs: $e");
      return null;
    }
  }

  Future<bool> submitSupportTicket(String userId, String message) async {
    try {
      final response = await _dio.post(
        '/api/database/support-ticket',
        data: {'userId': userId, 'message': message},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in submitSupportTicket: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getSupportTickets(String userId) async {
    try {
      final response = await _dio.get('/api/database/support-tickets',
          queryParameters: {'userId': userId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in getSupportTickets: $e");
      return null;
    }
  }

  Future<bool> replySupportTicket(String ticketId, String message) async {
    try {
      final response = await _dio.post(
        '/api/database/support-ticket/$ticketId/reply',
        data: {'message': message, 'from': 'user'},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in replySupportTicket: $e");
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

  /// Lightweight patch — only sends today's consumed + isPerfect.
  /// Used on every hydration event after the initial 30-day seed.
  Future<bool> updateTodayConsumed(
    String userId,
    String date,
    double consumed,
    bool isPerfect, {
    double? target,
    int? dayIndex,
    int? battery,
    bool force = false,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/database/update-today-consumed',
        data: {
          'userId': userId,
          'date': date,
          'consumed': consumed,
          'isPerfect': isPerfect,
          if (target != null) 'target': target,
          if (dayIndex != null) 'dayIndex': dayIndex,
          if (battery != null) 'battery': battery,
          if (force) 'force': true,
        },
      );

      Console.log(
          tag: "update-today-consumed",
          value:
              "$consumed - $date - $isPerfect - $target - $dayIndex - $battery - $force");
      return response.statusCode == 204 ||
          (response.data != null && response.data['success'] == true);
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in updateTodayConsumed: $e");
      return false;
    }
  }

  Future<bool> sendBgConsumedNotification(
    String userId,
    double consumed, {
    String? date,
  }) async {
    try {
      final response = await _dio.post(
        '/api/database/send-bg-consumed-notification',
        data: {
          'userId': userId,
          'consumed': consumed,
          if (date != null) 'date': date,
        },
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(
          tag: "APP", value: "Exception in sendBgConsumedNotification: $e");
      return false;
    }
  }

  Future<String?> uploadFoodImage(String imageBase64, String filename) async {
    try {
      final response = await _dio.post(
        '/api/database/upload-image',
        data: {'imageBase64': imageBase64, 'filename': filename},
      );
      if (response.data != null) {
        final data = response.data;
        if (data is Map) {
          final nestedData = data['data'];
          String? url;
          if (nestedData is Map) {
            url = (nestedData['url'] ??
                    nestedData['imageUrl'] ??
                    nestedData['path'] ??
                    nestedData['filePath'])
                ?.toString();
          }
          url ??= (data['url'] ??
                  data['imageUrl'] ??
                  data['path'] ??
                  data['filePath'] ??
                  (nestedData is String ? nestedData : null))
              ?.toString();

          Console.log(
              tag: "API", value: "[uploadFoodImage] Response URL: $url");
          return url;
        }
      }
      return null;
    } on DioException catch (e) {
      Console.log(
          tag: "API",
          value:
              "Exception in uploadFoodImage: $e, response: ${e.response?.data}, status: ${e.response?.statusCode}");
      return null;
    } catch (e) {
      Console.log(tag: "API", value: "Generic exception in uploadFoodImage: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> syncFoodScans(
      String userId, List<Map<String, dynamic>> scans,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _dio.post(
        '/api/database/sync-food-scans',
        data: {
          'userId': userId,
          'scans': scans,
          if (startDate != null)
            'startDate': startDate.toUtc().toIso8601String(),
          if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        },
      );
      if (response.data['success'] == true) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncFoodScans: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getFoodScans(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (startDate != null) {
        queryParameters['startDate'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        queryParameters['endDate'] = endDate.toUtc().toIso8601String();
      }

      final response = await _dio.get(
        '/api/database/food-scans/$userId',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in getFoodScans: $e");
      return null;
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

  /// Fetches achievement / badge data from the server for [userId].
  /// Returns the payload map on success, or null on failure / no connectivity.
  Future<Map<String, dynamic>?> getAchievements(String userId) async {
    try {
      final response = await _dio.get('/api/database/achievements/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: 'APP', value: 'Exception in getAchievements: $e');
      return null;
    }
  }

  /// Persists [level] as the last acknowledged level-up dialog on the server.
  /// This survives app reinstalls since it's stored in the Metadata collection.
  Future<bool> acknowledgeAchievementLevel(String userId, int level) async {
    try {
      final response = await _dio.post(
        '/api/database/achievements/$userId/acknowledge',
        data: {'level': level},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(
          tag: 'APP', value: 'Exception in acknowledgeAchievementLevel: $e');
      return false;
    }
  }

  /// Fetches HydrationDaySummary records from the server for [userId] in the
  /// given [startDate]..[endDate] window.  Returns the list of raw maps on
  /// success, or null when the call fails / no connectivity.
  Future<List<Map<String, dynamic>>?> getDailySummaries(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    DateTime? currentDate,
  }) async {
    try {
      final now = currentDate ?? DateTime.now();
      final response = await _dio.post(
        '/api/database/daily-summaries-v2/$userId',
        data: {
          'userId': userId,
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
          'currentDate': now.toUtc().toIso8601String(),
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: 'APP', value: 'Exception in getDailySummaries: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHydrationAnalysis(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toUtc().toIso8601String();
      }

      final response = await _dio.get(
        '/api/database/hydration-analysis/$userId',
        queryParameters: queryParams,
      );

      Console.log(
          tag: "getHydrationAnalysis_api",
          value: "${queryParams['startDate']} ${queryParams['endDate']}");
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: 'APP', value: 'Exception in getHydrationAnalysis: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAnalytics(String userId, int year,
      {int? month}) async {
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

  // Fetch User Messages
  Future<Map<String, dynamic>> getUserMessages(String userId) async {
    try {
      final response = await _dio.get('/api/user-messages/$userId');
      return response.data;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : getUserMessages || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  // Mark Message as Read
  Future<void> markMessageRead(String messageId) async {
    try {
      await _dio.put('/api/user-messages/$messageId/read');
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : markMessageRead || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  /// Permanently deletes the user account and all associated data from the server.
  /// [userId] — MongoDB user ID
  /// [firebaseUid] — Firebase Auth UID (optional, for Firebase deletion)
  Future<bool> deleteAccount(String userId, {String? firebaseUid}) async {
    try {
      final data = <String, dynamic>{'userId': userId};
      if (firebaseUid != null) data['firebaseUid'] = firebaseUid;

      final response = await _dio.delete(
        '/api/user/delete-account',
        data: data,
      );
      return response.statusCode == 200 &&
          (response.data['status'] == 'success' ||
              response.data['status'] == 'SUCCESS');
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : deleteAccount || ${e.toString()} ");
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> getLeaderboard(String userId) async {
    try {
      final response = await _dio.get('/api/database/leaderboard/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in getLeaderboard: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUsersLocations() async {
    try {
      final response = await _dio.get('/api/database/users-locations');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawList = response.data['data'] ?? [];
        return rawList.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'userId': map['userId']?.toString() ?? '',
            'latitude': (map['latitude'] as num).toDouble(),
            'longitude': (map['longitude'] as num).toDouble(),
            'bottlesSaved': (map['bottlesSaved'] as num? ?? 0).toInt(),
            'carbonReduced': (map['carbonReduced'] as num? ?? 0.0).toDouble(),
            'totalConsumed': (map['totalConsumed'] as num? ?? 0).toInt(),
          };
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in getUsersLocations: $e");
      return [];
    }
  }

  Future<bool> syncUserLocation(
      String userId, double latitude, double longitude) async {
    try {
      final isGhost = await SharedPrefsHelper.getGhostMode();
      if (isGhost) {
        // Ghost Mode ON: Privacy protected - do not sync location to server
        return true;
      }

      double syncLat = latitude;
      double syncLng = longitude;

      final isFuzzy = await SharedPrefsHelper.getFuzzyLocation();
      if (isFuzzy) {
        // Fuzzy Location ON: Send offset coordinates (~1km away) to server
        syncLat += 0.008;
        syncLng += 0.008;
      }

      final response = await _dio.post(
        '/api/database/sync-user-location',
        data: {
          'userId': userId,
          'latitude': syncLat,
          'longitude': syncLng,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      Console.log(tag: "APP", value: "Exception in syncUserLocation: $e");
      return false;
    }
  }

  // Fetch active subscription plans from the backend
  Future<List<dynamic>?> getSubscriptionPlans() async {
    try {
      final response = await _dio.get('/api/products',
          queryParameters: {'type': 'subscription', 'active': 'true'});
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value:
              "Exception occurred : getSubscriptionPlans || ${e.toString()} ");
      return null;
    }
  }

  // Create a new subscription on the backend
  Future<Map<String, dynamic>?> createSubscription({
    required String userId,
    required String planId,
    required String billingCycle,
    required double price,
    required String gatewaySubscriptionId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/subscriptions',
        data: {
          'userId': userId,
          'planId': planId,
          'billingCycle': billingCycle,
          'price': price,
          'gatewaySubscriptionId': gatewaySubscriptionId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : createSubscription || ${e.toString()} ");
      return null;
    }
  }

  // Cancel an active subscription
  Future<Map<String, dynamic>?> cancelSubscription(
      String subscriptionId) async {
    try {
      final response =
          await _dio.post('/api/subscriptions/$subscriptionId/cancel');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value: "Exception occurred : cancelSubscription || ${e.toString()} ");
      return null;
    }
  }

  // Get active subscriptions for a user
  Future<Map<String, dynamic>?> getUserSubscriptions(String userId) async {
    try {
      final response = await _dio.get('/api/subscriptions/user/$userId');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      Console.log(
          tag: "APP",
          value:
              "Exception occurred : getUserSubscriptions || ${e.toString()} ");
      return null;
    }
  }
}
