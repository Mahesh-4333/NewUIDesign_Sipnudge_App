import 'dart:async';
import 'package:hydrify/helpers/logger.dart';

import 'package:flutter/material.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:health/health.dart';
import 'package:hydrify/services/pedometer_service.dart';
import 'package:permission_handler/permission_handler.dart';
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
    return await openDatabase(
      finalPath,
      version: 17,
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
              'ALTER TABLE $tableName ADD COLUMN refills INTEGER DEFAULT 0');
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
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
         CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            liquidVolume REAL NOT NULL,
            liquidPercent INTEGER NOT NULL,
            battery INTEGER NOT NULL,
            refills INTEGER DEFAULT 0,
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
  waterUnit TEXT
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
              dish_name TEXT,
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
      },
    );
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

    // Console.log(
    //     tag: "APP",
    //     value:
    //         "[DB] Inserting slot: ${entry.slot.label}, amount: ${entry.amount} mL ${entry.waterDrank} mL startEpoch ${startEpoch} endEpoch ${endEpoch}");
    await db.insert(
      'hydration_slots',
      {
        'slotName': entry.slot.label,
        'slotIndex': entry.slot.index,
        'startEpoch': startEpoch,
        'endEpoch': endEpoch,
        'waterGoal': entry.amount,
        'waterDrank': entry.waterDrank,
        'status': entry.status.toString().split('.').last,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final allSlots = await db.query('hydration_slots');
    //Console.log(tag: "APP", value: "[DB] Current slots in DB:");
    for (var s in allSlots) {
      Console.log(
          tag: "APP",
          value:
              "  ${s['slotName']} - waterGoal: ${s['waterGoal']}, status: ${s['status']}");
    }
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

  Future<List<HydrationEntry>> getAllSlots() async {
    final db = await database;
    final maps = await db.query('hydration_slots');

    return List.generate(maps.length, (i) {
      final row = maps[i];
      return HydrationEntry(
        slot: HydrationSlot.values[row['slotIndex'] as int],
        startTime: _epochToTimeOfDay(row['startEpoch'] as int),
        endTime: _epochToTimeOfDay(row['endEpoch'] as int),
        waterDrank: (row['waterDrank'] as num?)?.toDouble() ?? 0.0,
        amount: (row['waterGoal'] as num).toDouble(),
        status: row['status'] == 'completed'
            ? HydrationStatus.completed
            : HydrationStatus.pending,
      );
    });
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

  Future<void> clearAllSlots() async {
    // You can also clear `bottle_history` or `user` table if needed
    final db = await database;
    await db.delete('bottle_history');
    Console.log(
        tag: "APP", value: "[DB] Cleared all data in bottle_history table.");
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

// Bulk upsert list (fast)
  Future<void> bulkUpsert30Days(List<HydrationDaySummary> list) async {
    if (list.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final s in list) {
      Console.log(
          tag: "inserting30Day",
          value: "${s.dayIndex} : ${s.date.toIso8601String()} : ${s.consumed}");
      batch.insert(
        '$hydrationSummaryTableName',
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
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

  Future<int> insertFoodScan(Map<String, dynamic> data) async {
    final db = await database;
    final id = await db.insert(
      foodScannerTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Console.log(
        tag: "APP",
        value: "[DB] Inserted food scan data for ${data['dish_name']} with id $id");
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllFoodScans() async {
    final db = await database;
    return await db.query(foodScannerTableName, orderBy: 'timestamp DESC');
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
    Console.log(tag: "getDailySteps", value: "DB steps for $dateString: $dbSteps");

    // 2. If it's today and we want real-time data, try to fetch and compare
    if (isToday && fetchFromHealth) {
      try {
        int healthSteps = 0;
        if (Platform.isAndroid) {
          // Android: Use PedometerService (silently)
          final status = await Permission.activityRecognition.status;
          if (status.isGranted) {
            healthSteps = await PedometerService().getTodaySteps();
            Console.log(tag: "getDailySteps", value: "Pedometer steps: $healthSteps");
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
}
