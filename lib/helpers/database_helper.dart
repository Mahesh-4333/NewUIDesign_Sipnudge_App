import 'dart:async';
import 'package:hydrify/helpers/logger.dart';

import 'package:flutter/material.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  // ADD THIS LINE
  static Completer<Database>? _initCompleter;

  static const String tableName = 'bottle_history';
  static const String hydrationSummaryTableName = 'hydration_day_summaries';

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
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE user ADD COLUMN stepGoal INTEGER');
        }
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
         CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            liquidVolume REAL NOT NULL,
            liquidPercent INTEGER NOT NULL,
            battery INTEGER NOT NULL,
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
  stepGoal INTEGER
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
CREATE TABLE IF NOT EXISTS app_metadata (
  key TEXT PRIMARY KEY,
  value TEXT
);
''');
      },
    );
  }

  Future<void> saveLastSyncDate(DateTime date) async {
    final db = await database;

    await db.insert(
      'app_metadata',
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
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['last_hydration_sync'],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DateTime.parse(result.first['value'] as String);
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
    };

    Console.log(
        tag: "APP",
        value: "[DB] Saving User Info: height=${state.height}, weight=${state.weight}, age=${state.age}");

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
    final result = await db.query('user', where: 'id = ?', whereArgs: [1], limit: 1);

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
      stepGoal: row['stepGoal'] as int?,
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

  int _timeOfDayToEpoch(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  TimeOfDay _epochToTimeOfDay(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
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
        whereArgs: [firstDayOfMonth.millisecondsSinceEpoch, midnightToday.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );

      if (result.isEmpty) return 0;

      final summaries = result.map((r) => HydrationDaySummary.fromMap(r)).toList();
      int currentStreak = 0;
      DateTime checkDate = midnightToday;

      // Special handling for today: if goal is met today, it starts/continues the streak.
      // If not met today, we check if yesterday was met.
      for (var summary in summaries) {
        final normalizedSummaryDate = DateTime(summary.date.year, summary.date.month, summary.date.day);
        
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
      Console.log(tag: "APP", value: "[DB] Error calculating consistency streak: $e");
      return 0;
    }
  }
}
