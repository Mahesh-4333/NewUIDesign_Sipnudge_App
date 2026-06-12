import 'dart:math';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/achievement_notifier.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:hydrify/helpers/logger.dart';

class DatabaseSyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();

  Future<void> syncAll({bool isFromBle = false}) async {
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
        tag: "SYNC", value: "Starting full database sync for user: $userId (isFromBle: $isFromBle)");

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
          'name': userInfo.name,
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
        final mappedScans = foodScans
            .map((s) => {
                  'dishName': s['dish_name'],
                  'imagePath': s['image_path'],
                  'imageBase64': s['image_base64'],
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
                })
            .toList();
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
      final String todayDateStr = DateTime.now().toIso8601String().split('T').first;
      final String? lastSummarySyncDate = await SharedPrefsHelper.getLastSummarySyncDate();
      final bool alreadySynced30 = await SharedPrefsHelper.hasSynced30Days();

      final bool shouldDoFullSync = !alreadySynced30 || (lastSummarySyncDate != todayDateStr && isFromBle);

      if (shouldDoFullSync) {
        // Fetch manual logs from server on first install
        if (!alreadySynced30) {
          try {
            final serverManualLogs = await _apiService.getManualLogs(userId!);
            if (serverManualLogs != null && serverManualLogs.isNotEmpty) {
              final localLogs = await _dbHelper.getHydrationLogs();
              final localLogKeys = localLogs.map((l) {
                final timestampStr = l['timestamp'] as String;
                final typeStr = l['type'] as String;
                final consumedVal = (l['consumed'] as num).toDouble();
                return "$timestampStr|$typeStr|$consumedVal";
              }).toSet();

              for (var log in serverManualLogs) {
                final String logTimestamp = log['timestamp'];
                final String logType = log['type'];
                final double logConsumed = (log['consumed'] as num).toDouble();
                final String key = "$logTimestamp|$logType|$logConsumed";

                if (!localLogKeys.contains(key)) {
                  await _dbHelper.insertHydrationLog(
                    logType,
                    logConsumed,
                    DateTime.parse(logTimestamp),
                  );
                }
              }
            }
          } catch (e) {
            Console.log(tag: "SYNC", value: "Failed to fetch manual logs: $e");
          }
          await SharedPrefsHelper.setHasSynced30Days(true);
        }

        final summaries = await _dbHelper.getHydrationSummariesForRange();
        if (summaries.isNotEmpty) {
          final mappedSummaries = summaries
              .map((e) => {
                    'date': e.date.toIso8601String(),
                    'dayIndex': e.dayIndex,
                    'target': e.target,
                    'consumed': e.consumed,
                    'isPerfect': e.isPerfect,
                    'deviceId': e.deviceId,
                    'createdAt': e.createdAt.toIso8601String(),
                    'updatedAt': e.updatedAt?.toIso8601String(),
                  })
              .toList();
          
          final success = await _apiService.syncDailySummaries(userId!, mappedSummaries);
          if (success) {
            await SharedPrefsHelper.setLastSummarySyncDate(todayDateStr);
            Console.log(tag: "SYNC", value: "Full daily summaries sync complete (total: ${summaries.length})");
          } else {
            Console.log(tag: "SYNC", value: "Full daily summaries sync failed");
          }
        }
      } else {
        // ── Lightweight today-only update ───────────────────────────────────
        final today = await _dbHelper.getSummaryForDate(DateTime.now());
        if (today != null) {
          await _apiService.updateTodayConsumed(
            userId!,
            today.date.toIso8601String(),
            today.consumed,
            today.isPerfect,
          );
        }
        Console.log(tag: "SYNC", value: "Today-only consumed sync complete");
      }

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
    var userId = await SharedPrefsHelper.getUserId();

    // If userId is missing, try to fetch it using the saved email
    if (userId == null) {
      final email = await SharedPrefsHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        final userData = await _apiService.getUserByEmail(email);
        if (userData != null && userData['_id'] != null) {
          userId = userData['_id'];
          await SharedPrefsHelper.setUserId(userId!);
        } else {
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
            });
          }
          final createResult = await _apiService.syncUserInfoData(syncData);
          if (createResult != null && createResult['_id'] != null) {
            userId = createResult['_id'];
            await SharedPrefsHelper.setUserId(userId!);
          }
        }
      }
    }

    if (userId == null) return;

    await _apiService.syncFoodScans(userId, [
      {
        'dishName': scanData['dish_name'],
        'imagePath': scanData['image_path'],
        'imageBase64': scanData['image_base64'],
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
      }
    ]);
  }

  Future<void> _syncInChunks<T>(List<T> data, int chunkSize,
      Future<void> Function(List<T>) syncFunction) async {
    for (var i = 0; i < data.length; i += chunkSize) {
      int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      await syncFunction(data.sublist(i, end));
    }
  }
}
