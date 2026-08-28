import 'dart:async';
import 'package:hydrify/helpers/logger.dart';

import 'package:flutter/material.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:health/health.dart';
import 'package:hydrify/services/pedometer_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hydrify/models/food_scan_data.dart';
import 'dart:io';

class DatabaseHelper {
  static Database? _database;

  // ADD THIS LINE
  static Completer<Database>? _initCompleter;

  static const String tableName = 'bottle_history';
  static const String hydrationSummaryTableName = 'hydration_day_summaries';
  static const String todayHydrationHistoryTableName =
      'today_hydration_history';
  static const String foodScannerTableName = 'user_food_scanner';
  static const String aiHydrationTableName = 'ai_hydration_engine';
  static const String dailyWaterGoalsTableName = 'daily_water_goals';
  static const String appMetadataTableName = 'app_metadata';
  static const String dailyStepsTableName = 'daily_steps';
  static const String logHydrationTableName = 'log_hydration';

  static const Map<String, double> hydrationCoefficients = {
    'Water': 1.0,
    'Tea': 0.85,
    'Coffee': 0.8,
    'Juice': 0.9,
    'Milk': 1.5,
  };

  // REPLACE your old getter with this one:
  Future<Database> get database async {
    // Already initialized?
    if (_database != null) return _database!;

    // Already initializing? Await same future
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Start initialization
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();

      // Complete for other awaiters
      _initCompleter!.complete(_database);
      _initCompleter = null;

      return _database!;
    } catch (e, st) {
      if (!(_initCompleter!.isCompleted)) {
        _initCompleter!.completeError(e, st);
      }
      _initCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String finalPath = path.join(await getDatabasesPath(), 'bottle_history.db');
    final db = await openDatabase(
      finalPath,
      version: 22,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE user ADD COLUMN stepGoal INTEGER');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $todayHydrationHistoryTableName(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              consumed REAL NOT NULL,
              timezone TEXT
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE $tableName ADD COLUMN refills REAL DEFAULT 0.0');
        }
        if (oldVersion < 5) {
          await db.execute(
              'ALTER TABLE $todayHydrationHistoryTableName ADD COLUMN timezone TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $foodScannerTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              dish_name TEXT,
              image_path TEXT,
              weight_g REAL,
              water_content_ml REAL,
              water_percentage REAL,
              calories_kcal REAL,
              protein_g REAL,
              carbs_g REAL,
              fat_g REAL,
              sodium_mg REAL,
              fiber_g REAL,
              confidence_score TEXT,
              ingredients TEXT,
              reasoning TEXT,
              timestamp TEXT
            )
          ''');
        }
        if (oldVersion < 7) {
          await db.execute(
              'ALTER TABLE $foodScannerTableName ADD COLUMN image_base64 TEXT');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $aiHydrationTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              weight_kg REAL NOT NULL,
              base_goal_ml REAL NOT NULL,
              steps INTEGER NOT NULL,
              steps_adj_ml REAL NOT NULL,
              temperature_c REAL NOT NULL,
              temp_adj_ml REAL NOT NULL,
              caffeine_mg REAL NOT NULL,
              caffeine_adj_ml REAL NOT NULL,
              food_water_ml REAL NOT NULL,
              total_goal_ml REAL NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 9) {
          // Re-apply image_base64 safely — some devices missed the v7 migration.
          // SQLite has no ADD COLUMN IF NOT EXISTS, so we catch the duplicate error.
          try {
            await db.execute(
                'ALTER TABLE $foodScannerTableName ADD COLUMN image_base64 TEXT');
          } catch (_) {
            // Column already exists — safe to ignore.
          }
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $dailyWaterGoalsTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              goal INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 11) {
          try {
            await db.execute('ALTER TABLE user ADD COLUMN coffeeIntake TEXT');
            await db.execute('ALTER TABLE user ADD COLUMN teaIntake TEXT');
          } catch (_) {
            // Safe to ignore if columns already exist
          }
        }
        if (oldVersion < 13) {
          try {
            await db.execute(
                'ALTER TABLE $todayHydrationHistoryTableName ADD COLUMN percentage REAL');
            await db.execute(
                'ALTER TABLE $todayHydrationHistoryTableName ADD COLUMN remaining REAL');
            await db.execute(
                'ALTER TABLE $todayHydrationHistoryTableName ADD COLUMN total_at_time REAL');
          } catch (_) {
            // Safe to ignore if columns already exist
          }
        }
        if (oldVersion < 14) {
          try {
            await db
                .execute('ALTER TABLE user ADD COLUMN typicalWaterIntake REAL');
            await db.execute('ALTER TABLE user ADD COLUMN waterUnit TEXT');
          } catch (_) {
            // Safe to ignore if columns already exist
          }
        }
        if (oldVersion < 15) {
          try {
            await db.execute(
                'ALTER TABLE $tableName ADD COLUMN temp REAL DEFAULT 0');
            await db.execute(
                'ALTER TABLE $tableName ADD COLUMN bqTemp REAL DEFAULT 0');
          } catch (_) {
            // Safe to ignore if columns already exist
          }
        }
        if (oldVersion < 16) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $dailyStepsTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT UNIQUE,
              steps INTEGER
            )
          ''');
        }
        if (oldVersion < 17) {
          try {
            await db.execute(
                'ALTER TABLE $foodScannerTableName ADD COLUMN image_base64 TEXT');
          } catch (_) {
            // Already exists
          }
        }
        if (oldVersion < 18) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $logHydrationTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              consumed REAL NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 20) {
          try {
            await db.execute('ALTER TABLE user ADD COLUMN name TEXT');
          } catch (_) {
            // Already exists
          }
        }
        if (oldVersion < 21) {
          try {
            await db.execute(
                'ALTER TABLE $logHydrationTableName ADD COLUMN server_id TEXT');
          } catch (_) {
            // Already exists — safe to ignore.
          }
        }
        if (oldVersion < 22) {
          try {
            await db.execute(
                'ALTER TABLE $foodScannerTableName ADD COLUMN food_key TEXT');
          } catch (_) {
            // Already exists — safe to ignore.
          }
        }
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
         CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            liquidVolume REAL NOT NULL,
            liquidPercent INTEGER NOT NULL,
            battery INTEGER NOT NULL,
            refills REAL DEFAULT 0.0,
            temp REAL DEFAULT 0,
            bqTemp REAL DEFAULT 0,
            timestamp TEXT NOT NULL
          )
        ''');

        await db.execute('''
CREATE TABLE hydration_slots(
  slotIndex INTEGER PRIMARY KEY,
  slotName TEXT,
  startEpoch INTEGER,
  endEpoch INTEGER,
  waterGoal INTEGER,
  waterDrank INTEGER,
  status TEXT
);
''');

        await db.execute('''
CREATE TABLE user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  gender TEXT,
  height REAL,
  heightUnit TEXT,
  weight REAL,
  weightUnit TEXT,
  age INTEGER,
  wakeupHour INTEGER,
  wakeupMinute INTEGER,
  wakeupPeriod TEXT,
  bedtimeHour INTEGER,
  bedtimeMinute INTEGER,
  bedtimePeriod TEXT,
  activityLevel TEXT,
  dietType TEXT,
  stepGoal INTEGER,
  coffeeIntake TEXT,
  teaIntake TEXT,
  typicalWaterIntake REAL,
  waterUnit TEXT,
  name TEXT
)
''');

        await db.execute('''
CREATE TABLE IF NOT EXISTS $hydrationSummaryTableName (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,         -- epoch millis at local midnight (start of day)
  day_index INTEGER NOT NULL,
  target REAL NOT NULL,
  consumed REAL NOT NULL,
  is_perfect INTEGER DEFAULT 0,
  device_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  UNIQUE(date, device_id) ON CONFLICT REPLACE
);
''');

        await db.execute('''
CREATE TABLE IF NOT EXISTS $appMetadataTableName (
  key TEXT PRIMARY KEY,
  value TEXT
);
''');

        await db.execute('''
            CREATE TABLE IF NOT EXISTS $todayHydrationHistoryTableName(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              consumed REAL NOT NULL,
              timezone TEXT,
              percentage REAL,
              remaining REAL,
              total_at_time REAL
            )
          ''');

        await db.execute('''
            CREATE TABLE IF NOT EXISTS $foodScannerTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              scan_id TEXT,
              dish_name TEXT,
              food_key TEXT,
              image_path TEXT,
              image_base64 TEXT,
              weight_g REAL,
              water_content_ml REAL,
              water_percentage REAL,
              calories_kcal REAL,
              protein_g REAL,
              carbs_g REAL,
              fat_g REAL,
              sodium_mg REAL,
              fiber_g REAL,
              confidence_score TEXT,
              ingredients TEXT,
              reasoning TEXT,
              timestamp TEXT
            )
          ''');

        await db.execute('''
            CREATE TABLE IF NOT EXISTS $aiHydrationTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              weight_kg REAL NOT NULL,
              base_goal_ml REAL NOT NULL,
              steps INTEGER NOT NULL,
              steps_adj_ml REAL NOT NULL,
              temperature_c REAL NOT NULL,
              temp_adj_ml REAL NOT NULL,
              caffeine_mg REAL NOT NULL,
              caffeine_adj_ml REAL NOT NULL,
              food_water_ml REAL NOT NULL,
              total_goal_ml REAL NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $dailyWaterGoalsTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            goal INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $dailyStepsTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            steps INTEGER
          )
        ''');

        await db.execute('''
            CREATE TABLE IF NOT EXISTS $logHydrationTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              consumed REAL NOT NULL,
              timestamp TEXT NOT NULL,
              server_id TEXT
            )
          ''');
      },
    );

    try {
      await db.execute('''
        DELETE FROM hydration_day_summaries 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM hydration_day_summaries 
          GROUP BY date
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('ALTER TABLE $foodScannerTableName ADD COLUMN scan_id TEXT');
    } catch (_) {}

    return db;
  }

  Future<void> saveLastSyncDate(DateTime date) async {
    final db = await database;

    await db.insert(
      appMetadataTableName,
      {
        'key': 'last_hydration_sync',
        'value': date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    Console.log(
        tag: "APP",
        value: '[DB] Last hydration sync saved: ${date.toIso8601String()}');
  }

  Future<DateTime?> getLastSyncDate() async {
    final db = await database;

    final result = await db.query(
      appMetadataTableName,
      where: 'key = ?',
      whereArgs: ['last_hydration_sync'],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DateTime.parse(result.first['value'] as String);
  }

  Future<void> saveLastResetDate(DateTime date) async {
    final db = await database;

    await db.insert(
      appMetadataTableName,
      {
        'key': 'last_reset_date',
        'value': date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    Console.log(
        tag: "APP",
        value: '[DB] Last reset date saved: ${date.toIso8601String()}');
  }

  Future<DateTime?> getLastResetDate() async {
    final db = await database;

    final result = await db.query(
      appMetadataTableName,
      where: 'key = ?',
      whereArgs: ['last_reset_date'],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DateTime.parse(result.first['value'] as String);
  }

  Future<double> getManualWaterDrankForRange(
      TimeOfDay startTime, TimeOfDay endTime) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> todayLogs =
        await getHydrationLogs(date: now);
    double manualWaterDrank = 0.0;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    for (final log in todayLogs) {
      final logTimestamp = DateTime.parse(log['timestamp'] as String);
      final logTime = TimeOfDay.fromDateTime(logTimestamp);
      final logMinutes = logTime.hour * 60 + logTime.minute;
      final logConsumed = (log['consumed'] as num).toDouble();

      bool isWithin;
      if (startMinutes <= endMinutes) {
        isWithin = logMinutes >= startMinutes && logMinutes <= endMinutes;
      } else {
        // Crosses midnight
        isWithin = logMinutes >= startMinutes || logMinutes <= endMinutes;
      }

      if (isWithin) {
        final type = log['type'] as String;
        final coefficient = hydrationCoefficients[type] ?? 1.0;
        manualWaterDrank += (logConsumed * coefficient);
      }
    }

    // Also include water content from food scans
    try {
      final List<Map<String, dynamic>> allFoodScans = await getAllFoodScans();
      for (final food in allFoodScans) {
        if (food['timestamp'] == null) continue;
        final foodTimestamp = DateTime.tryParse(food['timestamp'] as String);
        if (foodTimestamp != null &&
            foodTimestamp.year == now.year &&
            foodTimestamp.month == now.month &&
            foodTimestamp.day == now.day) {
          final foodTime = TimeOfDay.fromDateTime(foodTimestamp);
          final foodMinutes = foodTime.hour * 60 + foodTime.minute;
          final foodWater = (food['water_content_ml'] as num?)?.toDouble() ?? 0.0;

          bool isWithin;
          if (startMinutes <= endMinutes) {
            isWithin = foodMinutes >= startMinutes && foodMinutes <= endMinutes;
          } else {
            isWithin = foodMinutes >= startMinutes || foodMinutes <= endMinutes;
          }

          if (isWithin) {
            manualWaterDrank += foodWater;
          }
        }
      }
    } catch (_) {}

    return manualWaterDrank;
  }

  Future<void> clearAppMetadata() async {
    try {
      final db = await database;
      final count = await db.delete(appMetadataTableName);
      Console.log(
          tag: "APP",
          value:
              "[DB] Cleared $appMetadataTableName table. Rows deleted: $count");
    } catch (e) {
      Console.log(
          tag: "APP",
          value: "[DB] Error clearing $appMetadataTableName table: $e");
    }
  }

  Future<void> insertOrUpdateSlot(HydrationEntry entry,
      {bool? clearTable = false}) async {
    final db = await database;
    final startEpoch = _timeOfDayToEpoch(entry.startTime);
    final endEpoch = _timeOfDayToEpoch(entry.endTime);
    await Future.delayed(Duration(milliseconds: 300));

    if (clearTable == true) {
      Console.log(tag: "APP", value: "[DB] Clearing hydration_slots table...");
      await clearHydrationSlots();
    }

    final manualWaterDrank =
        await getManualWaterDrankForRange(entry.startTime, entry.endTime);

    // We store only the BOTTLE component in the hydration_slots table.
    // The total displayed in UI is (bottleDrank + manualWaterDrank).
    final double bottleDrank =
        (entry.waterDrank - manualWaterDrank).clamp(0, entry.waterDrank);

    await db.insert(
      'hydration_slots',
      {
        'slotName': entry.slot.label,
        'slotIndex': entry.slot.index,
        'startEpoch': startEpoch,
        'endEpoch': endEpoch,
        'waterGoal': entry.amount,
        'waterDrank': bottleDrank,
        'status': (bottleDrank + manualWaterDrank) >= entry.amount
            ? 'completed'
            : 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    Console.log(
        tag: "APP",
        value:
            "  ${entry.slot.label} - waterGoal: ${entry.amount}, bottleDrank: $bottleDrank, manualDrank: $manualWaterDrank, status: ${(bottleDrank + manualWaterDrank) >= entry.amount}");
  }

  Future<void> clearHydrationSlots() async {
    try {
      final db = await database;
      final count = await db.delete('hydration_slots');
      Console.log(
          tag: "APP",
          value: "[DB] Cleared hydration_slots table. Rows deleted: $count");
    } catch (e) {
      Console.log(
          tag: "APP", value: "[DB] Error clearing hydration_slots table: $e");
    }
  }

  /// Resets daily progress for all existing slots without changing their custom startTime or endTime.
  Future<void> resetSlotProgressForNewDay() async {
    try {
      final db = await database;
      final count = await db.update(
        'hydration_slots',
        {
          'waterDrank': 0,
          'status': 'pending',
        },
      );
      Console.log(
          tag: "APP",
          value:
              "[DB] resetSlotProgressForNewDay: Updated $count slots to waterDrank=0 and status=pending");
    } catch (e) {
      Console.log(
          tag: "APP",
          value: "[DB] Error in resetSlotProgressForNewDay: $e");
    }
  }

  Future<List<HydrationEntry>> getAllSlots() async {
    final db = await database;
    final maps = await db.query('hydration_slots');

    final List<HydrationEntry> entries = [];
    for (var i = 0; i < maps.length; i++) {
      final row = maps[i];
      final startTime = _epochToTimeOfDay(row['startEpoch'] as int);
      final endTime = _epochToTimeOfDay(row['endEpoch'] as int);
      final bottleDrank = (row['waterDrank'] as num?)?.toDouble() ?? 0.0;

      // Add manual logs to the bottle data for UI display
      final manualWaterDrank =
          await getManualWaterDrankForRange(startTime, endTime);
      final totalDrank = bottleDrank + manualWaterDrank;

      entries.add(HydrationEntry(
        slot: HydrationSlot.values[row['slotIndex'] as int],
        startTime: startTime,
        endTime: endTime,
        waterDrank: totalDrank,
        amount: (row['waterGoal'] as num).toDouble(),
        status: totalDrank >= (row['waterGoal'] as num).toDouble()
            ? HydrationStatus.completed
            : HydrationStatus.pending,
      ));
    }
    return entries;
  }

  Future<void> saveUserInfo(UserInfoState state) async {
    final db = await database;

    final data = {
      'id': 1, // Ensure only one user row exists with fixed ID
      'gender': state.gender?.toString().split('.').last,
      'height': state.height,
      'heightUnit': state.heightUnit,
      'weight': state.weight,
      'weightUnit': state.weightUnit,
      'age': state.age,
      'wakeupHour': state.wakeupHour,
      'wakeupMinute': state.wakeupMinute,
      'wakeupPeriod': state.wakeupPeriod,
      'bedtimeHour': state.bedtimeHour,
      'bedtimeMinute': state.bedtimeMinute,
      'bedtimePeriod': state.bedtimePeriod,
      'activityLevel': state.activityLevel?.toString().split('.').last,
      'dietType': state.dietType?.toString().split('.').last,
      'stepGoal': state.stepGoal,
      'coffeeIntake': state.coffeeIntake?.toString().split('.').last,
      'teaIntake': state.teaIntake?.toString().split('.').last,
      'typicalWaterIntake': state.typicalWaterIntake,
      'waterUnit': state.waterUnit,
      'name': state.name,
    };

    Console.log(
        tag: "APP",
        value:
            "[DB] Saving User Info: height=${state.height}, weight=${state.weight}, age=${state.age}");

    // Atomic insert or replace
    await db.insert(
      'user',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserInfoState?> getUserInfo() async {
    final db = await database;
    // Explicitly query for our singleton row with ID 1
    final result =
        await db.query('user', where: 'id = ?', whereArgs: [1], limit: 1);

    if (result.isEmpty) return null;
    final row = result.first;

    return UserInfoState(
      gender: _parseGender(row['gender'] as String?),
      height: row['height'] as double?,
      heightUnit: row['heightUnit'] as String?,
      weight: row['weight'] as double?,
      weightUnit: row['weightUnit'] as String?,
      age: row['age'] as int?,
      wakeupHour: row['wakeupHour'] as int?,
      wakeupMinute: row['wakeupMinute'] as int?,
      wakeupPeriod: row['wakeupPeriod'] as String?,
      bedtimeHour: row['bedtimeHour'] as int?,
      bedtimeMinute: row['bedtimeMinute'] as int?,
      bedtimePeriod: row['bedtimePeriod'] as String?,
      activityLevel: _parseActivityLevel(row['activityLevel'] as String?),
      dietType: _parseDietType(row['dietType'] as String?),
      coffeeIntake: _parseBeverageIntake(row['coffeeIntake'] as String?),
      teaIntake: _parseBeverageIntake(row['teaIntake'] as String?),
      stepGoal: row['stepGoal'] as int?,
      typicalWaterIntake: row['typicalWaterIntake'] as double?,
      waterUnit: row['waterUnit'] as String?,
      name: row['name'] as String?,
    );
  }

// Helpers to parse enums
  Gender? _parseGender(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (g) => g.toString().split('.').last == value,
      orElse: () => Gender.male,
    );
  }

  ActivityLevel? _parseActivityLevel(String? value) {
    if (value == null) return null;
    return ActivityLevel.values.firstWhere(
      (a) => a.toString().split('.').last == value,
      orElse: () => ActivityLevel.lightActivity,
    );
  }

  DietType? _parseDietType(String? value) {
    if (value == null) return null;
    return DietType.values.firstWhere(
      (d) => d.toString().split('.').last == value,
      orElse: () => DietType.balanced,
    );
  }

  BeverageIntake? _parseBeverageIntake(String? value) {
    if (value == null) return null;
    return BeverageIntake.values.firstWhere(
      (b) => b.toString().split('.').last == value,
      orElse: () => BeverageIntake.none,
    );
  }

  int _timeOfDayToEpoch(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  TimeOfDay _epochToTimeOfDay(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  Future<void> insertTodayHydration(double consumed, DateTime timestamp,
      {double? percentage, double? remaining, double? totalAtTime}) async {
    final db = await database;
    final timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    await db.insert(
      todayHydrationHistoryTableName,
      {
        'timestamp': timestamp.toIso8601String(),
        'consumed': consumed,
        'timezone': timezone,
        if (percentage != null) 'percentage': percentage,
        if (remaining != null) 'remaining': remaining,
        if (totalAtTime != null) 'total_at_time': totalAtTime,
      },
    );

    Console.log(
        tag: "APP",
        value:
            "[DB] Inserted today history: $consumed mL at $timestamp [Timezone: $timezone] [Percentage: $percentage] [Remaining: $remaining] [TotalAtTime: $totalAtTime]");
  }

  Future<List<Map<String, dynamic>>> getTodayHydrationHistory() async {
    final db = await database;
    return await db.query(todayHydrationHistoryTableName,
        orderBy: 'timestamp DESC');
  }

  Future<void> clearTodayHydrationHistory() async {
    try {
      final db = await database;
      final count = await db.delete(todayHydrationHistoryTableName);
      Console.log(
          tag: "APP",
          value: "[DB] Cleared today_hydration_history. Rows deleted: $count");
    } catch (e) {
      Console.log(
          tag: "APP", value: "[DB] Error clearing today_hydration_history: $e");
    }
  }

  /// Inserts a manual hydration log and returns the new local row id.
  /// [timestamp] is always stored as UTC ISO-8601 for consistency with server.
  /// [serverId] is the MongoDB _id returned after syncing to server.
  Future<int> insertHydrationLog(
      String type, double consumed, DateTime timestamp,
      {String? serverId}) async {
    final db = await database;
    // Store as local time — all DB queries use local boundaries.
    final localTimestamp = timestamp.toLocal().toIso8601String();
    final id = await db.insert(
      logHydrationTableName,
      {
        'type': type,
        'consumed': consumed,
        'timestamp': localTimestamp,
        if (serverId != null) 'server_id': serverId,
      },
    );
    Console.log(
        tag: "APP",
        value:
            "[DB] Inserted hydration log id=$id: $consumed mL of $type at $localTimestamp (local)");
    return id;
  }

  /// Updates the server_id for a local log after successful server sync.
  Future<void> updateLogServerId(int localId, String serverId) async {
    final db = await database;
    await db.update(
      logHydrationTableName,
      {'server_id': serverId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Updates the consumed liquid amount for an existing hydration log.
  Future<void> updateHydrationLogAmount(int id, double newAmount) async {
    final db = await database;
    await db.update(
      logHydrationTableName,
      {'consumed': newAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getHydrationLogs({DateTime? date}) async {
    final db = await database;
    if (date != null) {
      // Timestamps are stored as local time strings in the DB.
      final startOfDay =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
              .toIso8601String();
      return await db.query(
        logHydrationTableName,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay, endOfDay],
        orderBy: 'timestamp DESC',
      );
    }
    return await db.query(logHydrationTableName, orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>?> getHydrationLogById(int id) async {
    final db = await database;
    final res = await db.query(
      logHydrationTableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> deleteHydrationLog(int id, double amount, String type) async {
    final db = await database;
    await db.delete(
      logHydrationTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteHydrationLogByTimestampAndType(
      String timestamp, String type) async {
    final db = await database;
    // Allow matching timestamp exactly or prefix (e.g. up to seconds)
    final tsPrefix =
        timestamp.length >= 19 ? timestamp.substring(0, 19) : timestamp;
    await db.delete(
      logHydrationTableName,
      where: 'timestamp LIKE ? AND type = ?',
      whereArgs: ['$tsPrefix%', type],
    );
  }

  Future<double> getTodayLoggedHydration() async {
    final db = await database;
    final now = DateTime.now();
    // Timestamps are stored as local time — use local boundary.
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(consumed) as total FROM $logHydrationTableName WHERE timestamp >= ? AND type = ?',
      [startOfDay, 'Water'],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<int> getTodayCoffeeIntake() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(consumed) as total FROM $logHydrationTableName WHERE timestamp >= ? AND type = ?',
      [startOfDay, 'Coffee'],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).round();
    }
    return 0;
  }

  Future<void> clearHydrationLogs() async {
    try {
      final db = await database;
      final count = await db.delete(logHydrationTableName);
      Console.log(
          tag: "APP",
          value: "[DB] Cleared $logHydrationTableName. Rows deleted: $count");
    } catch (e) {
      Console.log(
          tag: "APP", value: "[DB] Error clearing $logHydrationTableName: $e");
    }
  }

  Future<void> clearTodayHydrationLogs([DateTime? date]) async {
    try {
      final db = await database;
      final target = date ?? DateTime.now();
      final startOfDay =
          DateTime(target.year, target.month, target.day).toIso8601String();
      final endOfDay =
          DateTime(target.year, target.month, target.day, 23, 59, 59, 999)
              .toIso8601String();
      final count = await db.delete(
        logHydrationTableName,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay, endOfDay],
      );
      Console.log(
          tag: "APP",
          value:
              "[DB] Cleared today's $logHydrationTableName. Rows deleted: $count");
    } catch (e) {
      Console.log(
          tag: "APP",
          value: "[DB] Error clearing today's $logHydrationTableName: $e");
    }
  }

  Future<Map<String, dynamic>?> getLatestHydrationLog() async {
    final db = await database;
    final result = await db.query(
      logHydrationTableName,
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<double> getTodayBeverageCaffeine() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    // Query logs for today that are 'Coffee' or 'Tea'
    final logs = await db.query(
      logHydrationTableName,
      where: 'timestamp >= ? AND (type = ? OR type = ?)',
      whereArgs: [startOfDay, 'Coffee', 'Tea'],
    );

    double totalCaffeineMg = 0.0;
    for (var log in logs) {
      final type = log['type'] as String;
      final consumedMl = (log['consumed'] as num).toDouble();

      if (type == 'Coffee') {
        // Standard: 80mg caffeine per 200ml -> 0.4mg per ml
        totalCaffeineMg += consumedMl * 0.4;
      } else if (type == 'Tea') {
        // Standard: 40mg caffeine per 200ml -> 0.2mg per ml
        totalCaffeineMg += consumedMl * 0.2;
      }
    }
    return totalCaffeineMg;
  }

  Future<void> clearAllSlots() async {
    // You can also clear `bottle_history` or `user` table if needed
    final db = await database;
    await db.delete('bottle_history');
    Console.log(
        tag: "APP", value: "[DB] Cleared all data in bottle_history table.");
  }

  Future<void> clearAllDatabaseData() async {
    try {
      final db = await database;
      final batch = db.batch();
      batch.delete(tableName);
      batch.delete(hydrationSummaryTableName);
      batch.delete(todayHydrationHistoryTableName);
      batch.delete(foodScannerTableName);
      batch.delete(aiHydrationTableName);
      batch.delete(dailyWaterGoalsTableName);
      batch.delete(dailyStepsTableName);
      batch.delete(logHydrationTableName);
      batch.delete('hydration_slots');
      batch.delete('user');
      batch.delete(appMetadataTableName);
      await batch.commit(noResult: true);
      Console.log(
          tag: "APP",
          value: "[DB] Cleared all database tables successfully on logout.");
    } catch (e) {
      Console.log(
          tag: "APP", value: "[DB] Error clearing all database tables: $e");
    }
  }

  Future<void> insertBottleData(BottleData data) async {
    final db = await database;
    await db.insert(
      tableName,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Console.log(
        tag: "APP",
        value:
            "[DB] Inserted bottle data: ${data.liquidVolume} mL at ${data.timestamp}");
  }

  Future<List<BottleData>> getBottleDataForDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'bottle_history',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    return result.map((e) => BottleData.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllBottleHistory({int? limit}) async {
    final db = await database;
    return await db.query('bottle_history',
        orderBy: 'timestamp DESC', limit: limit);
  }

  Future<void> cleanupDuplicateDateSummaries() async {
    final db = await database;
    try {
      await db.execute('''
        DELETE FROM $hydrationSummaryTableName 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM $hydrationSummaryTableName 
          GROUP BY date
        )
      ''');
    } catch (e) {
      Console.log(
          tag: "DB_CLEANUP", value: "Failed to clean up duplicates: $e");
    }
  }

// Bulk upsert list (fast)
  Future<void> bulkUpsert30Days(List<HydrationDaySummary> list) async {
    if (list.isEmpty) return;
    final db = await database;

    await cleanupDuplicateDateSummaries();

    final batch = db.batch();
    for (final s in list) {
      final midnight = DateTime(s.date.year, s.date.month, s.date.day)
          .millisecondsSinceEpoch;
      Console.log(
          tag: "inserting30Day",
          value: "${s.dayIndex} : ${s.date.toIso8601String()} : ${s.consumed}");

      batch.delete(
        hydrationSummaryTableName,
        where: 'date = ?',
        whereArgs: [midnight],
      );

      final map = s.toMap();
      map['date'] = midnight;

      batch.insert(
        '$hydrationSummaryTableName',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    await cleanupDuplicateDateSummaries();
  }

  /// Optimized single-pass replacement for the old three-line pattern:
  ///   `await bulkUpsert30Days(list);`
  ///   `await Future.delayed(Duration(seconds: 1));`
  ///   `await syncAllSummariesWithLogs();`
  ///
  /// Instead of two separate DB passes with an artificial delay, this method:
  ///  1. Reads all log_hydration rows once and aggregates them per day in memory.
  ///  2. For each BLE summary, adds that day's manual log total before writing.
  ///  3. Writes everything in a single batch commit (2 DB round-trips total).
  Future<void> bulkUpsert30DaysWithLogs(List<HydrationDaySummary> list) async {
    if (list.isEmpty) return;
    final db = await database;

    await cleanupDuplicateDateSummaries();

    // ── Step 1: Read & aggregate all manual logs in one DB query ──
    final logs = await db.query(logHydrationTableName);
    final Map<int, double> logTotalsByMidnight = {};
    for (final log in logs) {
      try {
        final type = log['type'] as String;
        final timestamp = DateTime.parse(log['timestamp'] as String);
        final midnight =
            DateTime(timestamp.year, timestamp.month, timestamp.day)
                .millisecondsSinceEpoch;
        final consumed = (log['consumed'] as num).toDouble();
        final coefficient = hydrationCoefficients[type] ?? 1.0;
        logTotalsByMidnight[midnight] =
            (logTotalsByMidnight[midnight] ?? 0.0) + (consumed * coefficient);
      } catch (e) {
        Console.log(
            tag: "BULK_UPSERT", value: "Error aggregating log for merge: $e");
      }
    }

    // ── Step 2: Build the batch with merged bottle + log totals ──
    final batch = db.batch();
    final Set<int> bleEpochs = {};

    for (final s in list) {
      final midnight = DateTime(s.date.year, s.date.month, s.date.day)
          .millisecondsSinceEpoch;
      bleEpochs.add(midnight);

      final manualTotal = logTotalsByMidnight[midnight] ?? 0.0;
      final mergedConsumed = s.consumed + manualTotal;
      final mergedIsPerfect = s.target > 0 && mergedConsumed >= s.target;

      Console.log(
          tag: "BULK_UPSERT",
          value:
              "${s.dayIndex} : ${s.date.toIso8601String()} : bottle=${s.consumed} + logs=$manualTotal = $mergedConsumed");

      batch.delete(
        hydrationSummaryTableName,
        where: 'date = ?',
        whereArgs: [midnight],
      );

      final map = s
          .copyWith(consumed: mergedConsumed, isPerfect: mergedIsPerfect)
          .toMap();
      map['date'] = midnight;

      batch.insert(
        hydrationSummaryTableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // ── Step 3: Handle days with manual logs but no BLE data ──
    final waterGoal = await SharedPrefsHelper.getWaterGoal() ?? 2500;
    for (final entry in logTotalsByMidnight.entries) {
      if (!bleEpochs.contains(entry.key)) {
        final logTotal = entry.value;
        final orphanSummary = HydrationDaySummary(
          date: DateTime.fromMillisecondsSinceEpoch(entry.key),
          dayIndex: 0,
          target: waterGoal.toDouble(),
          consumed: logTotal,
          isPerfect: logTotal >= waterGoal,
          createdAt: DateTime.now(),
        );

        batch.delete(
          hydrationSummaryTableName,
          where: 'date = ?',
          whereArgs: [entry.key],
        );

        final map = orphanSummary.toMap();
        map['date'] = entry.key;

        batch.insert(
          hydrationSummaryTableName,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);

    await cleanupDuplicateDateSummaries();
  }

  Future<List<HydrationDaySummary>> getHydrationSummariesForRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    // Fetch all records to support legacy String dates and new epoch millis.
    // Given this is a 30-day history table, filtering in Dart is efficient enough.
    final result = await db.query(
      hydrationSummaryTableName,
      orderBy: 'date ASC',
    );

    final List<HydrationDaySummary> summaries = result.map((r) {
      return HydrationDaySummary.fromMap(r);
    }).toList();

    if (startDate == null && endDate == null) return summaries;

    // Normalize input range to UTC midnight for matching against stable database entries
    final normalizedStart = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : null;
    final normalizedEnd = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
        : null;

    return summaries.where((s) {
      if (normalizedStart != null && s.date.isBefore(normalizedStart)) {
        return false;
      }
      if (normalizedEnd != null && s.date.isAfter(normalizedEnd)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Returns the stored [HydrationDaySummary] for [date] (matched by local
  /// midnight epoch), or `null` if no record exists yet.
  Future<HydrationDaySummary?> getSummaryForDate(DateTime date) async {
    final db = await database;
    final midnight =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

    final result = await db.query(
      hydrationSummaryTableName,
      where: 'date = ?',
      whereArgs: [midnight],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return HydrationDaySummary.fromMap(result.first);
  }

  Future<void> updateHydrationDaySummary(double consumedDelta) async {
    final db = await database;
    final now = DateTime.now();
    final midnight =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    // 1. Check if record exists
    final result = await db.query(
      hydrationSummaryTableName,
      where: 'date = ?',
      whereArgs: [midnight],
      limit: 1,
    );

    if (result.isNotEmpty) {
      // 2. Update existing
      final currentConsumed = (result.first['consumed'] as num).toDouble();
      final target = (result.first['target'] as num).toDouble();
      final newConsumed = (currentConsumed + consumedDelta).clamp(0.0, double.infinity);
      final isPerfect = newConsumed >= target ? 1 : 0;
      await db.update(
        hydrationSummaryTableName,
        {
          'consumed': newConsumed,
          'is_perfect': isPerfect,
          'updated_at': DateTime.now().millisecondsSinceEpoch
        },
        where: 'date = ?',
        whereArgs: [midnight],
      );

      Console.log(tag: "mappedHistory_consumed_Curent", value: newConsumed);

      Console.log(
          tag: "APP", value: "[DB] Updated daily consumption: $newConsumed");
    } else {
      // 3. Create new if missing (should normally be handled by sync/init)
      final waterGoal = await SharedPrefsHelper.getWaterGoal() ?? 2500;
      final safeConsumed = consumedDelta.clamp(0.0, double.infinity);
      final newSummary = HydrationDaySummary(
        date: DateTime(now.year, now.month, now.day),
        dayIndex: 0,
        target: waterGoal.toDouble(),
        consumed: safeConsumed,
        isPerfect: safeConsumed >= waterGoal.toDouble(),
        createdAt: DateTime.now(),
      );
      await db.insert(hydrationSummaryTableName, newSummary.toMap());
      Console.log(tag: "mappedHistory_consumed_Curent", value: safeConsumed);
      Console.log(
          tag: "APP",
          value: "[DB] Created new daily summary with: $safeConsumed");
    }
  }

  Future<void> clearHydrationDaySummaries() async {
    final db = await database;

    try {
      final deletedRows = await db.delete('$hydrationSummaryTableName');
      Console.log(
          tag: "APP",
          value:
              "[DB] Cleared hydration_day_summaries table. Rows deleted: $deletedRows");
    } catch (e) {
      Console.log(
          tag: "APP",
          value: "[DB] Error clearing hydration_day_summaries table: $e");
    }
  }

  Future<int> getConsistencyStreak() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final midnightToday = DateTime(now.year, now.month, now.day);

      // Fetch all summaries for the current month
      final result = await db.query(
        hydrationSummaryTableName,
        where: 'date >= ? AND date <= ?',
        whereArgs: [
          firstDayOfMonth.millisecondsSinceEpoch,
          midnightToday.millisecondsSinceEpoch
        ],
        orderBy: 'date DESC',
      );

      if (result.isEmpty) return 0;

      final summaries =
          result.map((r) => HydrationDaySummary.fromMap(r)).toList();
      int currentStreak = 0;
      DateTime checkDate = midnightToday;

      // Special handling for today: if goal is met today, it starts/continues the streak.
      // If not met today, we check if yesterday was met.
      for (var summary in summaries) {
        final normalizedSummaryDate =
            DateTime(summary.date.year, summary.date.month, summary.date.day);

        if (normalizedSummaryDate.isAtSameMomentAs(midnightToday)) {
          if (summary.consumed >= summary.target) {
            currentStreak++;
          }
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }

        // If there's a gap in days (missing record for a day), the streak breaks.
        while (checkDate.isAfter(normalizedSummaryDate)) {
          return currentStreak;
        }

        if (summary.consumed >= summary.target) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // Streak broken
          break;
        }
      }

      return currentStreak;
    } catch (e) {
      Console.log(
          tag: "APP", value: "[DB] Error calculating consistency streak: $e");
      return 0;
    }
  }

  Future<void> deleteFoodScans() async {
    final db = await database;
    await db.delete(foodScannerTableName);
    Console.log(
        tag: "APP", value: "[DB] Cleared all data in $foodScannerTableName");
  }

  Future<void> deleteTodayFoodScans([DateTime? date]) async {
    try {
      final db = await database;
      final target = date ?? DateTime.now();
      final startOfDay =
          DateTime(target.year, target.month, target.day).toIso8601String();
      final endOfDay =
          DateTime(target.year, target.month, target.day, 23, 59, 59, 999)
              .toIso8601String();
      final count = await db.delete(
        foodScannerTableName,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay, endOfDay],
      );
      Console.log(
          tag: "APP",
          value:
              "[DB] Cleared today's $foodScannerTableName. Rows deleted: $count");
    } catch (e) {
      Console.log(
          tag: "APP",
          value: "[DB] Error clearing today's $foodScannerTableName: $e");
    }
  }

  Future<void> deleteFoodScanById(int? id,
      {String? dishName, String? timestamp}) async {
    final db = await database;
    if (id != null && id > 0) {
      await db.delete(
        foodScannerTableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    if (dishName != null && timestamp != null) {
      final tsPrefix =
          timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;
      await db.delete(
        foodScannerTableName,
        where: 'dish_name = ? AND timestamp LIKE ?',
        whereArgs: [dishName, '$tsPrefix%'],
      );
    } else if (dishName != null) {
      await db.delete(
        foodScannerTableName,
        where: 'dish_name = ?',
        whereArgs: [dishName],
      );
    }
  }

  Future<int> insertFoodScan(Map<String, dynamic> data) async {
    final db = await database;
    final normalized = (data.containsKey('_id') || data.containsKey('dishName'))
        ? FoodScanData.fromMap(data).toMap()
        : data;
    final id = await db.insert(
      foodScannerTableName,
      normalized,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Console.log(
        tag: "APP",
        value:
            "[DB] Inserted food scan data for ${normalized['dish_name']} with id $id");
    return id;
  }

  Future<int> upsertFoodScan(Map<String, dynamic> data) async {
    final db = await database;
    final normalized = (data.containsKey('_id') || data.containsKey('dishName'))
        ? FoodScanData.fromMap(data).toMap()
        : Map<String, dynamic>.from(data);
    final scanId = normalized['scan_id'] as String?;
    final id = normalized['id'] as int?;

    // 1. Check by integer primary key id
    if (id != null && id > 0) {
      final existing = await db.query(
        foodScannerTableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final existingBase64 = existing.first['image_base64'] as String?;
        final updatedData = Map<String, dynamic>.from(normalized);
        if ((updatedData['image_base64'] == null ||
                updatedData['image_base64'].toString().isEmpty) &&
            existingBase64 != null &&
            existingBase64.isNotEmpty) {
          updatedData['image_base64'] = existingBase64;
        }
        await db.update(
          foodScannerTableName,
          updatedData,
          where: 'id = ?',
          whereArgs: [id],
        );
        return id;
      }
      return await db.insert(
        foodScannerTableName,
        normalized,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Check by unique string scan_id
    if (scanId != null && scanId.isNotEmpty) {
      final existing = await db.query(
        foodScannerTableName,
        where: 'scan_id = ?',
        whereArgs: [scanId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        final existingBase64 = existing.first['image_base64'] as String?;
        final updatedData = Map<String, dynamic>.from(normalized);
        updatedData['id'] = existingId;
        if ((updatedData['image_base64'] == null ||
                updatedData['image_base64'].toString().isEmpty) &&
            existingBase64 != null &&
            existingBase64.isNotEmpty) {
          updatedData['image_base64'] = existingBase64;
        }
        await db.update(
          foodScannerTableName,
          updatedData,
          where: 'id = ?',
          whereArgs: [existingId],
        );
        return existingId;
      }
    }

    // 3. Otherwise insert as brand new meal scan
    return await db.insert(
      foodScannerTableName,
      normalized,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllFoodScans({DateTime? date}) async {
    final db = await database;
    List<Map<String, dynamic>> rawList;
    if (date != null) {
      final startOfDay =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
              .toIso8601String();
      rawList = await db.query(
        foodScannerTableName,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay, endOfDay],
        orderBy: 'timestamp DESC',
      );
    } else {
      rawList =
          await db.query(foodScannerTableName, orderBy: 'timestamp DESC');
    }

    // Deduplicate only when the exact same scan_id appears multiple times
    final Map<String, Map<String, dynamic>> deduplicated = {};
    for (final scan in rawList) {
      final sId = scan['scan_id']?.toString();
      final key = (sId != null && sId.isNotEmpty)
          ? sId
          : (scan['id']?.toString() ?? UniqueKey().toString());
      if (!deduplicated.containsKey(key)) {
        deduplicated[key] = scan;
      } else {
        // Keep the one with image_base64 if current duplicate has it
        final existing = deduplicated[key]!;
        if ((existing['image_base64'] == null ||
                existing['image_base64'].toString().isEmpty) &&
            scan['image_base64'] != null &&
            scan['image_base64'].toString().isNotEmpty) {
          deduplicated[key] = scan;
        }
      }
    }
    return deduplicated.values.toList();
  }

  /// Insert or replace the AI hydration calculation log for a given date.
  Future<void> insertAiHydrationLog(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      aiHydrationTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Console.log(
        tag: 'AI_ENGINE',
        value:
            '[DB] AI log saved: goal=${data['total_goal_ml']} mL on ${data['date']}');
  }

  /// Returns today's AI hydration log, or null if none exists yet.
  Future<Map<String, dynamic>?> getAiHydrationLogForDate(String date) async {
    final db = await database;
    final result = await db.query(
      aiHydrationTableName,
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> saveDailyWaterGoal(DateTime date, int goal) async {
    final db = await database;
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    await db.insert(
      dailyWaterGoalsTableName,
      {
        'date': dateString,
        'goal': goal,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Console.log(
        tag: "APP", value: "[DB] Saved daily goal $goal for $dateString");
  }

  Future<int?> getDailyWaterGoal(DateTime date) async {
    final db = await database;
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final result = await db.query(
      dailyWaterGoalsTableName,
      where: 'date = ?',
      whereArgs: [dateString],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['goal'] as int;
    }
    return null;
  }

  Future<void> saveDailySteps(DateTime date, int steps) async {
    final db = await database;
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // Check existing steps - avoid recursion by setting fetchFromHealth: false
    final existing = await getDailySteps(date, fetchFromHealth: false);
    if (existing != null && steps <= existing) {
      Console.log(
          tag: "APP",
          value:
              "[DB] Skipping steps update: $steps <= $existing for $dateString");
      return;
    }

    await db.insert(
      dailyStepsTableName,
      {
        'date': dateString,
        'steps': steps,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Console.log(
        tag: "APP", value: "[DB] Saved daily steps $steps for $dateString");
  }

  Future<int?> getDailySteps(DateTime date,
      {bool fetchFromHealth = true}) async {
    final db = await database;
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final today = DateTime.now();
    final isToday = dateString ==
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // 1. Get current DB value
    final result = await db.query(
      dailyStepsTableName,
      where: 'date = ?',
      whereArgs: [dateString],
      limit: 1,
    );
    int dbSteps = 0;
    if (result.isNotEmpty) {
      dbSteps = result.first['steps'] as int;
    }
    Console.log(
        tag: "getDailySteps", value: "DB steps for $dateString: $dbSteps");

    // 2. If it's today and we want real-time data, try to fetch and compare
    if (isToday && fetchFromHealth) {
      try {
        int healthSteps = 0;
        if (Platform.isAndroid) {
          // Android: Use PedometerService (silently)
          final status = await Permission.activityRecognition.status;
          if (status.isGranted) {
            healthSteps = await PedometerService().getTodaySteps();
            Console.log(
                tag: "getDailySteps", value: "Pedometer steps: $healthSteps");
          }
        } else {
          // iOS: Use Health package (silently check)
          final Health health = Health();
          final types = [HealthDataType.STEPS];
          bool? hasPermission = await health.hasPermissions(types);
          if (hasPermission == true) {
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final steps = await health.getTotalStepsInInterval(startOfDay, now);
            healthSteps = steps ?? 0;
          }
        }

        if (healthSteps > dbSteps) {
          await saveDailySteps(date, healthSteps);
          return healthSteps;
        }
      } catch (e) {
        Console.log(tag: "DB_STEPS", value: "Error fetching health steps: $e");
      }
    }

    return result.isNotEmpty ? dbSteps : null;
  }

  Future<List<Map<String, dynamic>>> getAllDailyWaterGoals() async {
    final db = await database;
    return await db.query(dailyWaterGoalsTableName, orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getAllDailySteps() async {
    final db = await database;
    return await db.query(dailyStepsTableName, orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getAllMetadata() async {
    final db = await database;
    return await db.query(appMetadataTableName);
  }
}
