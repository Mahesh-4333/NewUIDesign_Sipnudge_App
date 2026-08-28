import 'dart:convert';
import 'dart:io';
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

  static bool _isSyncing = false;
  static DateTime? _lastSyncTime;

  Future<void> syncAll(
      {bool isFromBle = false, int? battery, bool force = false}) async {
    if (_isSyncing) {
      Console.log(
          tag: "SYNC",
          value:
              "DatabaseSyncService skipped: Another sync is already in progress.");
      return;
    }

    // Throttle syncAll calls within 45 seconds unless forced or from BLE
    if (!force && !isFromBle && _lastSyncTime != null) {
      final elapsed = DateTime.now().difference(_lastSyncTime!);
      if (elapsed.inSeconds < 45) {
        Console.log(
            tag: "SYNC",
            value:
                "DatabaseSyncService throttled: Last sync was ${elapsed.inSeconds}s ago (< 45s).");
        return;
      }
    }

    final isErasing = await SharedPrefsHelper.isErasingData();
    if (isErasing) {
      Console.log(
          tag: "SYNC",
          value: "DatabaseSyncService skipped: Erase operation in progress.");
      return;
    }

    _isSyncing = true;

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
        final List<Map<String, dynamic>> mappedScans = [];
        for (final s in foodScans) {
          String? serverImageUrl;
          var base64Str = s['image_base64'] as String?;
          final localPath = s['image_path'] as String?;

          // If image_path is already a remote URL (starts with http), skip file reading & uploading
          final bool isAlreadyRemote = localPath != null &&
              (localPath.startsWith('http://') ||
                  localPath.startsWith('https://'));

          if (!isAlreadyRemote) {
            // If base64 is missing, read bytes from local image file
            if ((base64Str == null || base64Str.isEmpty) && localPath != null) {
              try {
                final file = File(localPath);
                if (file.existsSync()) {
                  final bytes = await file.readAsBytes();
                  base64Str = base64Encode(bytes);
                }
              } catch (e) {
                Console.log(
                    tag: "SYNC", value: "[syncAll] Read file failed: $e");
              }
            }

            if (base64Str != null && base64Str.isNotEmpty) {
              try {
                final filename = localPath != null
                    ? localPath.split('/').last
                    : 'food_scan.jpg';
                serverImageUrl =
                    await _apiService.uploadFoodImage(base64Str, filename);
                if (serverImageUrl != null) {
                  final updated = Map<String, dynamic>.from(s);
                  updated['image_path'] = serverImageUrl;
                  await _dbHelper.upsertFoodScan(updated);
                }
              } catch (err) {
                Console.log(
                    tag: "SYNC", value: "Error uploading batch image: $err");
              }
            }
          }

          final pathStr = (serverImageUrl ?? s['image_path'])?.toString();
          final finalImagePath = (pathStr != null && (pathStr.startsWith('http') || pathStr.startsWith('/uploads/')))
              ? pathStr
              : null;

          mappedScans.add({
            'scanId': s['scan_id'] ?? s['scanId'],
            'dishName': s['dish_name'],
            'foodKey': s['food_key'] ?? s['foodKey'] ?? 'Meal',
            'imagePath': finalImagePath,
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
          DateTime? minDate;
          DateTime? maxDate;
          for (final scan in chunk) {
            final tsStr = scan['timestamp'] as String?;
            if (tsStr != null) {
              final date = DateTime.tryParse(tsStr);
              if (date != null) {
                if (minDate == null || date.isBefore(minDate)) minDate = date;
                if (maxDate == null || date.isAfter(maxDate)) maxDate = date;
              }
            }
          }
          final startDate = minDate != null
              ? DateTime.utc(minDate.year, minDate.month, minDate.day)
              : null;
          final endDate = maxDate != null
              ? DateTime.utc(
                  maxDate.year, maxDate.month, maxDate.day, 23, 59, 59)
              : null;

          final result = await _apiService.syncFoodScans(userId!, chunk,
              startDate: startDate, endDate: endDate);

          if (result != null && result['summaries'] != null) {
            final summaries =
                List<Map<String, dynamic>>.from(result['summaries']);
            for (final m in summaries) {
              final String dateStr = m['date'] as String;
              final datePart =
                  dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
              final targetDate = DateTime.parse(datePart);
              final targetVal = (m['target'] as num).toDouble();
              final consumedVal = (m['consumed'] as num).toDouble();
              final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;

              final localSummary =
                  await _dbHelper.getSummaryForDate(targetDate);
              if (localSummary == null || localSummary.consumed < consumedVal) {
                final updatedSummary = HydrationDaySummary(
                  date: targetDate,
                  dayIndex: m['dayIndex'] as int? ?? 0,
                  target: targetVal,
                  consumed: consumedVal,
                  deviceId: m['deviceId'] as String?,
                  isPerfect: isPerfectDay,
                );
                await _dbHelper.bulkUpsert30Days([updatedSummary]);
              }
            }
          }
        });
      }

      // 5. Sync Daily Summaries
      // First, pull daily summaries from the server to update the local SQLite database (in case background BLE sync updated the server)
      try {
        final now = DateTime.now();
        // Server stores logs in UTC — query with UTC day boundaries.
        final startDate = DateTime.utc(now.year, now.month, now.day);
        final endDate = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
        final todayLocalDateStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final serverSummaries =
            await _apiService.getDailySummaries(userId, startDate, endDate);

        Console.log(
            tag: "SYNC_DailySummaries_Fetch",
            value:
                "Querying range: startDate=$startDate, endDate=$endDate | serverSummaries count=${serverSummaries?.length ?? 0}");

        if (serverSummaries != null && serverSummaries.isNotEmpty) {
          for (final m in serverSummaries) {
            final String dateStr = m['date'] as String;
            // Parse only the YYYY-MM-DD portion as local time to avoid timezone offset shifts
            DateTime targetDate;
            try {
              final datePart =
                  dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
              targetDate = DateTime.parse(datePart);
            } catch (_) {
              targetDate = DateTime(now.year, now.month, now.day);
            }
            final String targetDateStr =
                '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

            final targetVal = (m['target'] as num).toDouble();
            final consumedVal = (m['consumed'] as num).toDouble();

            Console.log(
                tag: "SYNC_DailySummaries_Loop",
                value:
                    "Server Item: dateStr=$dateStr | parsedLocalStr=$targetDateStr | consumed=$consumedVal ml | dayIndex=${m['dayIndex']}");

            // Skip if the server record does not belong to today in local time.
            if (targetDateStr != todayLocalDateStr) {
              Console.log(
                  tag: "SYNC",
                  value:
                      "Skipping server summary for $targetDateStr (not today: $todayLocalDateStr)");
              continue;
            }

            final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;

            // Prevent overwriting a larger local SQLite consumed value.
            final localSummary = await _dbHelper.getSummaryForDate(targetDate);

            Console.log(
                tag: "SYNC_DailySummaries_Compare",
                value:
                    "Comparing for $targetDateStr: SQLite consumed=${localSummary?.consumed ?? 'null'} ml vs Server consumed=$consumedVal ml");

            // For TODAY: trust the local BLE bottle data over the server.
            // The server may have a stale or corrupted value (e.g. from a previous
            // fallback upload). Only apply the server value if local has no data (0)
            // — meaning the bottle hasn't reported anything yet today.
            final isToday = targetDateStr == todayLocalDateStr;
            final localConsumed = localSummary?.consumed ?? 0;
            if (isToday && localConsumed > 0) {
              Console.log(
                  tag: "SYNC",
                  value:
                      "Skipping server update for today ($targetDateStr): local BLE data ($localConsumed ml) takes precedence over server ($consumedVal ml)");
              continue;
            }

            if (localSummary == null || localSummary.consumed < consumedVal) {
              final updatedSummary = HydrationDaySummary(
                date: targetDate,
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
                      "Successfully pulled daily summary from server for $targetDate: $consumedVal ml");
            } else {
              Console.log(
                  tag: "SYNC",
                  value:
                      "Skipping update for $targetDateStr because local SQLite consumed is already greater or equal (${localSummary.consumed} ml >= $consumedVal ml)");
            }
          }
        }
      } catch (e) {
        Console.log(
            tag: "SYNC",
            value: "Failed to pull today's daily summary from server: $e");
      }

      // Background notification trigger if app is in background
      final today = await _dbHelper.getSummaryForDate(DateTime.now());
      if (today != null) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        final isInBackground =
            lifecycle != null && lifecycle != AppLifecycleState.resumed;
        if (isInBackground && today.consumed > 0) {
          Console.log(
              tag: "SYNC",
              value:
                  "App is in background (lifecycle=$lifecycle). Triggering sendBgConsumedNotification (${today.consumed}ml)...");
          await _apiService.sendBgConsumedNotification(
            userId,
            today.consumed,
            date: today.date.toIso8601String(),
          );
        }
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

      // // 7. Sync Today History
      // final todayHistory = await _dbHelper.getTodayHydrationHistory();
      // if (todayHistory.isNotEmpty) {
      //   final mappedHistory = todayHistory
      //       .map((h) => {
      //             'timestamp': h['timestamp'],
      //             'consumed': h['consumed'],
      //             'timezone': h['timezone'],
      //             'percentage': h['percentage'],
      //             'remaining': h['remaining'],
      //             'totalAtTime': h['total_at_time'],
      //           })
      //       .toList();
      //   await _syncInChunks<Map<String, dynamic>>(mappedHistory, 500,
      //       (chunk) async {
      //     await _apiService.syncTodayHistory(userId!, chunk);
      //   });
      // }

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
      _lastSyncTime = DateTime.now();

      // Notify chart widgets (and any other listeners) to refresh their data.
      SyncBus.instance.notifySyncComplete();

      // After every successful sync, check if a new achievement level was
      // unlocked and show the level-up dialog from anywhere in the app.
      AchievementNotifier.instance.checkAndShow(userId: userId);
    } catch (e) {
      Console.log(tag: "SYNC", value: "Sync failed: $e");
    } finally {
      _isSyncing = false;
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
                value:
                    "[syncFoodScan] Creating new user profile for email $email");
            final createResult = await _apiService.syncUserInfoData(syncData);
            if (createResult != null && createResult['_id'] != null) {
              userId = createResult['_id'];
              await SharedPrefsHelper.setUserId(userId!);
              Console.log(
                  tag: "SYNC",
                  value:
                      "[syncFoodScan] Created and saved new userId = $userId");
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
      var base64Str = scanData['image_base64'] as String?;

      // Fallback: Read file bytes if base64 is missing
      if ((base64Str == null || base64Str.isEmpty) &&
          scanData['image_path'] != null) {
        try {
          final file = File(scanData['image_path']);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            base64Str = base64Encode(bytes);
          }
        } catch (e) {
          Console.log(
              tag: "SYNC", value: "[syncFoodScan] Read file failed: $e");
        }
      }

      if (base64Str != null && base64Str.isNotEmpty) {
        final localPath = scanData['image_path'] as String?;
        final filename = localPath != null && localPath.isNotEmpty
            ? localPath.split('/').last
            : 'food_scan.jpg';
        try {
          serverImageUrl =
              await _apiService.uploadFoodImage(base64Str, filename);
          Console.log(
              tag: "SYNC",
              value:
                  "[syncFoodScan] Uploaded image to server, URL: $serverImageUrl");
          if (serverImageUrl != null) {
            final updatedData = Map<String, dynamic>.from(scanData);
            updatedData['image_path'] = serverImageUrl;
            await _dbHelper.upsertFoodScan(updatedData);
          }
        } catch (err) {
          Console.log(
              tag: "SYNC", value: "[syncFoodScan] Error uploading image: $err");
        }
      }

      final pathStr = (serverImageUrl ?? scanData['image_path'])?.toString();
      final finalImagePath = (pathStr != null && (pathStr.startsWith('http') || pathStr.startsWith('/uploads/')))
          ? pathStr
          : null;

      final payload = {
        'scanId': scanData['scan_id'] ?? scanData['scanId'],
        'dishName': scanData['dish_name'],
        'foodKey': scanData['food_key'] ?? scanData['foodKey'] ?? 'Meal',
        'imagePath': finalImagePath,
        'imageBase64':
            finalImagePath != null ? null : scanData['image_base64'],
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

      DateTime? scanDate;
      final tsStr = scanData['timestamp'] as String?;
      if (tsStr != null) {
        scanDate = DateTime.tryParse(tsStr);
      }
      final startDate = scanDate != null
          ? DateTime.utc(scanDate.year, scanDate.month, scanDate.day)
          : null;
      final endDate = scanDate != null
          ? DateTime.utc(
              scanDate.year, scanDate.month, scanDate.day, 23, 59, 59)
          : null;

      Console.log(
          tag: "SYNC",
          value:
              "[syncFoodScan] Sending food scan: ${payload['dishName']} (payload length: ${payload.toString().length} chars)");
      final result = await _apiService.syncFoodScans(userId, [payload],
          startDate: startDate, endDate: endDate);

      if (result != null && result['summaries'] != null) {
        final summaries = List<Map<String, dynamic>>.from(result['summaries']);
        for (final m in summaries) {
          final String dateStr = m['date'] as String;
          final datePart =
              dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
          final targetDate = DateTime.parse(datePart);
          final targetVal = (m['target'] as num).toDouble();
          final consumedVal = (m['consumed'] as num).toDouble();
          final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;

          final localSummary = await _dbHelper.getSummaryForDate(targetDate);
          if (localSummary == null || localSummary.consumed < consumedVal) {
            final updatedSummary = HydrationDaySummary(
              date: targetDate,
              dayIndex: m['dayIndex'] as int? ?? 0,
              target: targetVal,
              consumed: consumedVal,
              deviceId: m['deviceId'] as String?,
              isPerfect: isPerfectDay,
            );
            await _dbHelper.bulkUpsert30Days([updatedSummary]);
          }
        }
      }
      Console.log(
          tag: "SYNC",
          value: "[syncFoodScan] Completed. Sync status: ${result != null}");
    } catch (e, stack) {
      Console.log(
          tag: "SYNC",
          value: "[syncFoodScan] Exception occurred: $e\nStack: $stack");
    }
  }

  Future<void> pushTodayConsumed() async {
    final userId = await SharedPrefsHelper.getUserId();
    if (userId == null) return;

    final today = await _dbHelper.getSummaryForDate(DateTime.now());
    if (today != null) {
      // Send date as UTC midnight string (YYYY-MM-DDT00:00:00.000Z) so the
      // backend normalises it consistently regardless of server timezone.
      final dateUtc =
          '${today.date.toIso8601String().substring(0, 10)}T00:00:00.000Z';
      await _apiService.updateTodayConsumed(
        userId,
        dateUtc,
        today.consumed,
        today.isPerfect,
        target: today.target,
        dayIndex: today.dayIndex,
      );

      // // If the app is currently in background (lifecycle state != resumed)
      // // and today's consumed > 0, fire the background notification API.
      // final lifecycle = WidgetsBinding.instance.lifecycleState;
      // final isInBackground =
      //     lifecycle != null && lifecycle != AppLifecycleState.resumed;
      // if (isInBackground && today.consumed > 0) {
      //   Console.log(
      //       tag: "SYNC",
      //       value:
      //           "App is in background (lifecycle=$lifecycle). Triggering sendBgConsumedNotification (${today.consumed}ml)...");
      //   await _apiService.sendBgConsumedNotification(
      //     userId,
      //     today.consumed,
      //     date: today.date.toIso8601String(),
      //   );
      // }

      SyncBus.instance.notifySyncComplete();
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
