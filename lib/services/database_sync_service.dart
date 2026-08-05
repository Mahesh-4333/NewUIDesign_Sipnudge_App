import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/achievement_notifier.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/models/hydration_summary.dart';

class DatabaseSyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();

  Future<void> syncAll({bool isFromBle = false, int? battery}) async {
    final isErasing = await SharedPrefsHelper.isErasingData();
    if (isErasing) {
      Console.log(
          tag: "SYNC",
          value: "DatabaseSyncService skipped: Erase operation in progress.");
      return;
    }

    var userId = await SharedPrefsHelper.getUserId();

    // If userId is missing, try to fetch it using the saved email
    if (userId == null) {
      final email = await SharedPrefsHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        Console.log(
            tag: "SYNC",
            value: "UserId missing. Attempting to fetch using email: $email");
        final userData = await _apiService.getUserByEmail(email);
        if (userData != null && userData['_id'] != null) {
          userId = userData['_id'];
          await SharedPrefsHelper.setUserId(userId!);
          Console.log(
              tag: "SYNC",
              value: "Successfully recovered and saved userId: $userId");
        } else {
          Console.log(
              tag: "SYNC",
              value:
                  "User not found on server. Creating from local database data...");
          final userInfo = await _dbHelper.getUserInfo();

          final random = Random.secure();
          final newUserId = List<int>.generate(12, (i) => random.nextInt(256))
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();

          Map<String, dynamic> syncData = {'email': email, 'userId': newUserId};

          if (userInfo != null) {
            syncData.addAll({
              'gender': userInfo.gender?.toString().split('.').last,
              'height': userInfo.height,
              'heightUnit': userInfo.heightUnit,
              'weight': userInfo.weight,
              'weightUnit': userInfo.weightUnit,
              'age': userInfo.age,
              'wakeupHour': userInfo.wakeupHour,
              'wakeupMinute': userInfo.wakeupMinute,
              'wakeupPeriod': userInfo.wakeupPeriod,
              'bedtimeHour': userInfo.bedtimeHour,
              'bedtimeMinute': userInfo.bedtimeMinute,
              'bedtimePeriod': userInfo.bedtimePeriod,
              'activityLevel':
                  userInfo.activityLevel?.toString().split('.').last,
              'dietType': userInfo.dietType?.toString().split('.').last,
              'stepGoal': userInfo.stepGoal,
              'coffeeIntake': userInfo.coffeeIntake?.toString().split('.').last,
              'teaIntake': userInfo.teaIntake?.toString().split('.').last,
              'typicalWaterIntake': userInfo.typicalWaterIntake,
              'waterUnit': userInfo.waterUnit,
              'user_type': "regular",
              'shutdown_app': false
            });
          }

          final createResult = await _apiService.syncUserInfoData(syncData);
          if (createResult != null && createResult['_id'] != null) {
            userId = createResult['_id'];
            await SharedPrefsHelper.setUserId(userId!);
            Console.log(
                tag: "SYNC",
                value: "Successfully created user and saved userId: $userId");
          }
        }
      }
    }

    if (userId == null) {
      Console.log(tag: "SYNC", value: "Sync skipped: No userId found");
      return;
    }

    Console.log(
        tag: "SYNC",
        value:
            "Starting full database sync for user: $userId (isFromBle: $isFromBle)");

    try {
      // 1. Sync User Info
      final userInfo = await _dbHelper.getUserInfo();
      if (userInfo != null) {
        await _apiService.syncUserInfo(userId, {
          'gender': userInfo.gender?.toString().split('.').last,
          'height': userInfo.height,
          'heightUnit': userInfo.heightUnit,
          'weight': userInfo.weight,
          'weightUnit': userInfo.weightUnit,
          'age': userInfo.age,
          'wakeupHour': userInfo.wakeupHour,
          'wakeupMinute': userInfo.wakeupMinute,
          'wakeupPeriod': userInfo.wakeupPeriod,
          'bedtimeHour': userInfo.bedtimeHour,
          'bedtimeMinute': userInfo.bedtimeMinute,
          'bedtimePeriod': userInfo.bedtimePeriod,
          'activityLevel': userInfo.activityLevel?.toString().split('.').last,
          'dietType': userInfo.dietType?.toString().split('.').last,
          'stepGoal': userInfo.stepGoal,
          'coffeeIntake': userInfo.coffeeIntake?.toString().split('.').last,
          'teaIntake': userInfo.teaIntake?.toString().split('.').last,
          'typicalWaterIntake': userInfo.typicalWaterIntake,
          'waterUnit': userInfo.waterUnit,
          'userName': userInfo.name,
        });
      }

      // Also ensure FCM token is synced on full database sync
      await FirebaseMessagingService().syncTokenToBackend();

      // 2. Sync Bottle History
      final bottleHistory = await _dbHelper.getAllBottleHistory(limit: 1);
      if (bottleHistory.isNotEmpty) {
        final mappedLogs = bottleHistory
            .map((l) => {
                  'logId': l['id'],
                  'liquidVolume': l['liquidVolume'],
                  'liquidPercent': l['liquidPercent'],
                  'battery': l['battery'],
                  'refills': l['refills'],
                  'temp': l['temp'],
                  'bqTemp': l['bqTemp'],
                  'timestamp': l['timestamp'],
                })
            .toList();
        await _syncInChunks<Map<String, dynamic>>(mappedLogs, 500,
            (chunk) async {
          await _apiService.syncBottleHistory(userId!, chunk);
        });
      }

      // 3. Sync Food Scans
      final foodScans = await _dbHelper.getAllFoodScans();
      if (foodScans.isNotEmpty) {
        // Map keys to match backend model (camelCase if needed, but backend routes often use snake_case or specific names)
        // Backend model has: dishName, imagePath, imageBase64, weightG, waterContentMl, etc.
        // Local DB has: dish_name, image_path, image_base64, weight_g, water_content_ml, etc.
        final List<Map<String, dynamic>> mappedScans = [];
        for (final s in foodScans) {
          String? serverImageUrl;
          final base64Str = s['image_base64'];
          if (base64Str != null && base64Str.toString().isNotEmpty) {
            try {
              final localPath = s['image_path'] as String?;
              final filename = localPath != null ? localPath.split('/').last : 'food_scan.jpg';
              serverImageUrl = await _apiService.uploadFoodImage(base64Str, filename);
            } catch (err) {
              Console.log(tag: "SYNC", value: "Error uploading batch image: $err");
            }
          }

          mappedScans.add({
            'dishName': s['dish_name'],
            'imagePath': serverImageUrl ?? s['image_path'],
            'imageBase64': null, // No need to send base64 anymore
            'weightG': s['weight_g'],
            'waterContentMl': s['water_content_ml'],
            'waterPercentage': s['water_percentage'],
            'caloriesKcal': s['calories_kcal'],
            'proteinG': s['protein_g'],
            'carbsG': s['carbs_g'],
            'fatG': s['fat_g'],
            'sodiumMg': s['sodium_mg'],
            'fiberG': s['fiber_g'],
            'confidenceScore': s['confidence_score'],
            'ingredients': s['ingredients'],
            'reasoning': s['reasoning'],
            'timestamp': s['timestamp'],
          });
        }

        await _syncInChunks<Map<String, dynamic>>(mappedScans, 10,
            (chunk) async {
          await _apiService.syncFoodScans(userId!, chunk);
        });
      }

      // 4. Sync Manual Logs
      final manualLogs = await _dbHelper.getHydrationLogs();
      if (manualLogs.isNotEmpty) {
        await _syncInChunks<Map<String, dynamic>>(manualLogs, 500,
            (chunk) async {
          await _apiService.syncManualLogs(userId!, chunk);
        });
      }

      // 5. Sync Daily Summaries
      // First, pull daily summaries from the server to update the local SQLite database (in case background BLE sync updated the server)
      try {
        final now = DateTime.now();
        // Use local-date boundaries converted to UTC for the server query so
        // the server returns only records that belong to *today* in the local
        // timezone, not UTC midnight.
        final startDate = DateTime(now.year, now.month, now.day).toUtc();
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc();
        final todayLocalDateStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final serverSummaries =
            await _apiService.getDailySummaries(userId, startDate, endDate);
        if (serverSummaries != null && serverSummaries.isNotEmpty) {
          for (final m in serverSummaries) {
            final String dateStr = m['date'] as String;
            // Parse as UTC first, then convert to local so we get the correct
            // local calendar date (avoids UTC+5:30 date-shift bug).
            DateTime parsedUtc;
            try {
              parsedUtc = DateTime.parse(dateStr).toUtc();
            } catch (_) {
              parsedUtc = DateTime.now().toUtc();
            }
            final DateTime rawDateLocal = parsedUtc.toLocal();
            final String rawDateLocalStr =
                '${rawDateLocal.year.toString().padLeft(4, '0')}-${rawDateLocal.month.toString().padLeft(2, '0')}-${rawDateLocal.day.toString().padLeft(2, '0')}';

            // Skip if the server record does not belong to today in local time.
            if (rawDateLocalStr != todayLocalDateStr) {
              Console.log(
                  tag: "SYNC",
                  value:
                      "Skipping server summary for $rawDateLocalStr (not today: $todayLocalDateStr)");
              continue;
            }

            // Use local-midnight as the canonical date key for SQLite.
            final DateTime rawDate = DateTime(
                rawDateLocal.year, rawDateLocal.month, rawDateLocal.day);

            final targetVal = (m['target'] as num).toDouble();
            final consumedVal = (m['consumed'] as num).toDouble();
            final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;

            // Prevent overwriting a larger local SQLite consumed value.
            final localSummary = await _dbHelper.getSummaryForDate(rawDate);
            if (localSummary == null || localSummary.consumed < consumedVal) {
              final updatedSummary = HydrationDaySummary(
                date: rawDate,
                dayIndex: m['dayIndex'] as int? ?? 0,
                target: targetVal,
                consumed: consumedVal,
                deviceId: m['deviceId'] as String?,
                isPerfect: isPerfectDay,
              );
              await _dbHelper.bulkUpsert30Days([updatedSummary]);
              Console.log(
                  tag: "SYNC",
                  value:
                      "Successfully pulled daily summary from server for $rawDate: $consumedVal ml");
            }
          }
        }
      } catch (e) {
        Console.log(
            tag: "SYNC",
            value: "Failed to pull today's daily summary from server: $e");
      }

      // ── Push today's consumed to server ─────────────────────────────────
      final today = await _dbHelper.getSummaryForDate(DateTime.now());
      if (today != null) {
        // Send date as UTC midnight string (YYYY-MM-DDT00:00:00.000Z) so the
        // backend normalises it consistently regardless of server timezone.
        final dateUtc =
            '${today.date.toIso8601String().substring(0, 10)}T00:00:00.000Z';
        await _apiService.updateTodayConsumed(
          userId!,
          dateUtc,
          today.consumed,
          today.isPerfect,
          target: today.target,
          dayIndex: today.dayIndex,
          battery: battery,
        );

        // If the app is currently in background (lifecycle state != resumed)
        // and today's consumed > 0, fire the background notification API.
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        final isInBackground =
            lifecycle != null && lifecycle != AppLifecycleState.resumed;
        if (isInBackground && today.consumed > 0) {
          Console.log(
              tag: "SYNC",
              value:
                  "App is in background (lifecycle=$lifecycle). Triggering sendBgConsumedNotification (${today.consumed}ml)...");
          await _apiService.sendBgConsumedNotification(
            userId!,
            today.consumed,
            date: today.date.toIso8601String(),
          );
        }
      }
      Console.log(tag: "SYNC", value: "Today-only consumed sync complete");

      // 6. Sync AI Logs
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final todayAiLog = await _dbHelper.getAiHydrationLogForDate(todayStr);
      if (todayAiLog != null) {
        // AI log fields in backend: date, weightKg, baseGoalMl, steps, stepsAdjMl, temperatureC, tempAdjMl, caffeineMg, caffeineAdjMl, foodWaterMl, totalGoalMl
        // Local DB fields: date, weight_kg, base_goal_ml, steps, steps_adj_ml, temperature_c, temp_adj_ml, caffeine_mg, caffeine_adj_ml, food_water_ml, total_goal_ml
        await _apiService.syncAiLogs(userId, [
          {
            'date': todayAiLog['date'],
            'weightKg': todayAiLog['weight_kg'],
            'baseGoalMl': todayAiLog['base_goal_ml'],
            'steps': todayAiLog['steps'],
            'stepsAdjMl': todayAiLog['steps_adj_ml'],
            'temperatureC': todayAiLog['temperature_c'],
            'tempAdjMl': todayAiLog['temp_adj_ml'],
            'caffeineMg': todayAiLog['caffeine_mg'],
            'caffeineAdjMl': todayAiLog['caffeine_adj_ml'],
            'foodWaterMl': todayAiLog['food_water_ml'],
            'totalGoalMl': todayAiLog['total_goal_ml'],
            'createdAt': todayAiLog['created_at'],
          }
        ]);
      }

      // 7. Sync Today History
      final todayHistory = await _dbHelper.getTodayHydrationHistory();
      if (todayHistory.isNotEmpty) {
        final mappedHistory = todayHistory
            .map((h) => {
                  'timestamp': h['timestamp'],
                  'consumed': h['consumed'],
                  'timezone': h['timezone'],
                  'percentage': h['percentage'],
                  'remaining': h['remaining'],
                  'totalAtTime': h['total_at_time'],
                })
            .toList();
        await _syncInChunks<Map<String, dynamic>>(mappedHistory, 500,
            (chunk) async {
          await _apiService.syncTodayHistory(userId!, chunk);
        });
      }

      // 8. Sync Slots
      final slots = await _dbHelper.getAllSlots();
      if (slots.isNotEmpty) {
        final mappedSlots = slots
            .map((e) => {
                  'slotName': e.slot.name,
                  'slotIndex': e.slot.index,
                  'startEpoch': (e.startTime.hour * 3600 +
                      e.startTime.minute *
                          60), // Simplified, usually handled in DB
                  'endEpoch': (e.endTime.hour * 3600 + e.endTime.minute * 60),
                  'waterGoal': e.amount,
                  'waterDrank': e.waterDrank,
                  'status': e.status.toString().split('.').last,
                })
            .toList();
        await _syncInChunks<Map<String, dynamic>>(mappedSlots, 500,
            (chunk) async {
          await _apiService.syncSlots(userId!, chunk);
        });
      }

      // 9. Sync Daily Goals
      final goals = await _dbHelper.getAllDailyWaterGoals();
      if (goals.isNotEmpty) {
        await _syncInChunks<Map<String, dynamic>>(goals, 500, (chunk) async {
          await _apiService.syncDailyGoals(userId!, chunk);
        });
      }

      // 10. Sync Daily Steps
      final steps = await _dbHelper.getAllDailySteps();
      if (steps.isNotEmpty) {
        await _syncInChunks<Map<String, dynamic>>(steps, 500, (chunk) async {
          await _apiService.syncDailySteps(userId!, chunk);
        });
      }

      // 11. Sync Metadata
      final metadata = await _dbHelper.getAllMetadata();
      if (metadata.isNotEmpty) {
        await _syncInChunks<Map<String, dynamic>>(metadata, 500, (chunk) async {
          await _apiService.syncMetadata(userId!, chunk);
        });
      }

      Console.log(tag: "SYNC", value: "Sync completed successfully");

      // Notify chart widgets (and any other listeners) to refresh their data.
      SyncBus.instance.notifySyncComplete();

      // After every successful sync, check if a new achievement level was
      // unlocked and show the level-up dialog from anywhere in the app.
      AchievementNotifier.instance.checkAndShow(userId: userId);
    } catch (e) {
      Console.log(tag: "SYNC", value: "Sync failed: $e");
    }
  }

  // Helper for one-off sync of a food scan
  Future<void> syncFoodScan(Map<String, dynamic> scanData) async {
    try {
      var userId = await SharedPrefsHelper.getUserId();
      Console.log(
          tag: "SYNC", value: "[syncFoodScan] Initial userId = $userId");

      // If userId is missing, try to fetch it using the saved email
      if (userId == null) {
        final email = await SharedPrefsHelper.getUserEmail();
        Console.log(tag: "SYNC", value: "[syncFoodScan] Email = $email");
        if (email != null && email.isNotEmpty) {
          final userData = await _apiService.getUserByEmail(email);
          if (userData != null && userData['_id'] != null) {
            userId = userData['_id'];
            await SharedPrefsHelper.setUserId(userId!);
            Console.log(
                tag: "SYNC",
                value: "[syncFoodScan] Fetched existing userId = $userId");
          } else {
            final userInfo = await _dbHelper.getUserInfo();
            final random = Random.secure();
            final newUserId = List<int>.generate(12, (i) => random.nextInt(256))
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join();

            Map<String, dynamic> syncData = {
              'email': email,
              'userId': newUserId
            };
            if (userInfo != null) {
              syncData.addAll({
                'gender': userInfo.gender?.toString().split('.').last,
                'height': userInfo.height,
                'heightUnit': userInfo.heightUnit,
                'weight': userInfo.weight,
                'weightUnit': userInfo.weightUnit,
                'age': userInfo.age,
                'wakeupHour': userInfo.wakeupHour,
                'wakeupMinute': userInfo.wakeupMinute,
                'wakeupPeriod': userInfo.wakeupPeriod,
                'bedtimeHour': userInfo.bedtimeHour,
                'bedtimeMinute': userInfo.bedtimeMinute,
                'bedtimePeriod': userInfo.bedtimePeriod,
                'activityLevel':
                    userInfo.activityLevel?.toString().split('.').last,
                'dietType': userInfo.dietType?.toString().split('.').last,
                'stepGoal': userInfo.stepGoal,
                'coffeeIntake':
                    userInfo.coffeeIntake?.toString().split('.').last,
                'teaIntake': userInfo.teaIntake?.toString().split('.').last,
                'typicalWaterIntake': userInfo.typicalWaterIntake,
                'waterUnit': userInfo.waterUnit,
              });
            }
            Console.log(
                tag: "SYNC",
                value: "[syncFoodScan] Creating new user profile for email $email");
            final createResult = await _apiService.syncUserInfoData(syncData);
            if (createResult != null && createResult['_id'] != null) {
              userId = createResult['_id'];
              await SharedPrefsHelper.setUserId(userId!);
              Console.log(
                  tag: "SYNC",
                  value: "[syncFoodScan] Created and saved new userId = $userId");
            }
          }
        }
      }

      if (userId == null) {
        Console.log(
            tag: "SYNC", value: "[syncFoodScan] Aborted: userId is null");
        return;
      }

      String? serverImageUrl;
      final base64Str = scanData['image_base64'];
      if (base64Str != null && base64Str.toString().isNotEmpty) {
        final localPath = scanData['image_path'] as String?;
        final filename = localPath != null ? localPath.split('/').last : 'food_scan.jpg';
        try {
          serverImageUrl = await _apiService.uploadFoodImage(base64Str, filename);
          Console.log(
              tag: "SYNC",
              value: "[syncFoodScan] Uploaded image to server, URL: $serverImageUrl");
        } catch (err) {
          Console.log(tag: "SYNC", value: "[syncFoodScan] Error uploading image: $err");
        }
      }

      final payload = {
        'dishName': scanData['dish_name'],
        'imagePath': serverImageUrl ?? scanData['image_path'],
        'imageBase64': null, // No need to send base64 anymore
        'weightG': scanData['weight_g'],
        'waterContentMl': scanData['water_content_ml'],
        'waterPercentage': scanData['water_percentage'],
        'caloriesKcal': scanData['calories_kcal'],
        'proteinG': scanData['protein_g'],
        'carbsG': scanData['carbs_g'],
        'fatG': scanData['fat_g'],
        'sodiumMg': scanData['sodium_mg'],
        'fiberG': scanData['fiber_g'],
        'confidenceScore': scanData['confidence_score'],
        'ingredients': scanData['ingredients'],
        'reasoning': scanData['reasoning'],
        'timestamp': scanData['timestamp'],
      };

      Console.log(
          tag: "SYNC",
          value:
              "[syncFoodScan] Sending food scan: ${payload['dishName']} (payload length: ${payload.toString().length} chars)");
      final success = await _apiService.syncFoodScans(userId, [payload]);
      Console.log(
          tag: "SYNC",
          value: "[syncFoodScan] Completed. Sync status: $success");
    } catch (e, stack) {
      Console.log(
          tag: "SYNC",
          value: "[syncFoodScan] Exception occurred: $e\nStack: $stack");
    }
  }

  Future<void> _syncInChunks<T>(List<T> data, int chunkSize,
      Future<void> Function(List<T>) syncFunction) async {
    for (var i = 0; i < data.length; i += chunkSize) {
      int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      await syncFunction(data.sublist(i, end));
    }
  }
}
