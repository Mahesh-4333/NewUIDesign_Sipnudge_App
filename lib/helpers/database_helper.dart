import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
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
      version: 1,
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
  dietType TEXT
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

    log('[DB] Last hydration sync saved: ${date.toIso8601String()}');
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

    if (clearTable == true) {
      log("[DB] Clearing hydration_slots table...");
      await clearHydrationSlots();
    }

    log("[DB] Inserting slot: ${entry.slot.label}, amount: ${entry.amount} mL");
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
    log("[DB] Current slots in DB:");
    for (var s in allSlots) {
      log("  ${s['slotName']} - waterGoal: ${s['waterGoal']}, status: ${s['status']}");
    }
  }

  Future<void> clearHydrationSlots() async {
    try {
      final db = await database;
      final count = await db.delete('hydration_slots');
      log("[DB] Cleared hydration_slots table. Rows deleted: $count");
    } catch (e) {
      log("[DB] Error clearing hydration_slots table: $e");
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
    };

    // Ensure only one user row
    await db.delete('user');
    await db.insert('user', data);
  }

  Future<UserInfoState?> getUserInfo() async {
    final db = await database;
    final result = await db.query('user', limit: 1);

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
    log("[DB] Cleared all data in bottle_history table.");
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

    // Build WHERE clause & args dynamically
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'date BETWEEN ? AND ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ];
    } else if (startDate != null) {
      whereClause = 'date >= ?';
      whereArgs = [startDate.millisecondsSinceEpoch];
    } else if (endDate != null) {
      whereClause = 'date <= ?';
      whereArgs = [endDate.millisecondsSinceEpoch];
    }

    final result = await db.query(
      '$hydrationSummaryTableName',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date ASC',
    );

    return result.map((r) {
      print(r);
      return HydrationDaySummary.fromMap(r);
    }).toList();
  }

  Future<void> clearHydrationDaySummaries() async {
    final db = await database;

    try {
      final deletedRows = await db.delete('$hydrationSummaryTableName');
      log("[DB] Cleared hydration_day_summaries table. Rows deleted: $deletedRows");
    } catch (e) {
      log("[DB] Error clearing hydration_day_summaries table: $e");
    }
  }

  Future<bool> isDayPerfect() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query('hydration_slots');

      if (maps.isEmpty) return false;

      for (var row in maps) {
        final double consumed = (row['waterDrank'] as num?)?.toDouble() ?? 0.0;
        final double target = (row['waterGoal'] as num?)?.toDouble() ?? 0.0;
        final String status = row['status'] as String? ?? 'pending';

        if (status != 'completed' || consumed < target) {
          return false;
        }
      }
      return true;
    } catch (e) {
      log("[DB] Error checking perfect day: $e");
      return false;
    }
  }
}
