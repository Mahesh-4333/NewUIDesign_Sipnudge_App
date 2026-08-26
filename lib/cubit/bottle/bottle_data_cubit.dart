import 'dart:async';
import 'package:hydrify/helpers/logger.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/helpers/internet_connection_helper.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:sqflite/sqflite.dart';

part 'bottle_data_state.dart';

class BottleDataCubit extends Cubit<BottleDataState> {
  final BleCubit _bleCubit;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late final StreamSubscription _bleSub;

  static const int pageSize = 50;

  BottleDataCubit(this._bleCubit) : super(BottleDataState.initial()) {
    _restoreLastValues();
    _bleSub = _bleCubit.stream.listen(_handleBleStateChange);
  }

  Future<void> _restoreLastValues() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableName,
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    Console.log(
        tag: "BottleDataCubit", value: "🔍 Last record query result: $maps");

    if (maps.isNotEmpty) {
      final lastData = BottleData.fromMap(maps.first);
      final now = DateTime.now();
      final lastDate = DateTime(lastData.timestamp.year,
          lastData.timestamp.month, lastData.timestamp.day);
      final today = DateTime(now.year, now.month, now.day);

      double refills = lastData.refills;
      if (lastDate.isBefore(today)) {
        refills = 0.0;
        Console.log(
            tag: "BottleDataCubit",
            value:
                "📅 New day detected in _restoreLastValues. Resetting refills to 0.");
      }

      Console.log(
          tag: "BottleDataCubit",
          value: "✅ Restoring from last record: "
              "volume=${lastData.liquidVolume}, "
              "percent=${lastData.liquidPercent}, "
              "battery=${lastData.battery}, "
              "refills=$refills, "
              "timestamp=${lastData.timestamp}"
              "temp=${lastData.temp},"
              "bq_temp=${lastData.bqTemp}");

      emit(state.copyWith(
        volume: lastData.liquidVolume,
        volumePercent: lastData.liquidPercent,
        battery: lastData.battery,
        refills: refills,
        temp: lastData.temp,
        bqTemp: lastData.bqTemp,
      ));
    } else {
      Console.log(
          tag: "BottleDataCubit",
          value: "⚠️ No previous bottle data found in DB.");
    }
  }

  Future<void> _handleBleStateChange(BleState bleState) async {
    Console.log(
        tag: "BottleDataCubit", value: "BLE state changed: ${bleState.temp}");
    // if (bleState.status != BleStatus.connected &&
    //     bleState.status != BleStatus.ready) {
    //   Console.log(
    //       tag: "APP",
    //       value:
    //           "⚠️ Skipping DB insert — BLE not connected (state: ${bleState.status})");
    //   return;
    // }

    // Fall back to the last known value when the BLE packet omits a field.
    // This prevents a null battery/volume from resetting the UI and DB to 0.
    final newVolume = bleState.volume ?? state.volume;
    final newPercent = bleState.percent ?? state.volumePercent;
    final newBattery = bleState.battery ?? state.battery;
    final newRefills = bleState.refill ?? state.refills;
    final newTemp = bleState.temp ?? state.temp;
    final newBqTemp = bleState.bqTemp ?? state.bqTemp;

    final newData = BottleData(
      liquidVolume: newVolume,
      liquidPercent: newPercent,
      battery: newBattery,
      refills: newRefills,
      temp: newTemp ?? 0,
      bqTemp: newBqTemp ?? 0,
      timestamp: DateTime.now(),
    );

    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableName,
      newData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    List<BottleData> pageData = state.currentPage == 0
        ? await fetchPageInternal(0)
        : state.currentPageData;

    emit(state.copyWith(
      volume: newVolume,
      volumePercent: newPercent,
      battery: newBattery,
      refills: newRefills,
      temp: newTemp,
      bqTemp: newBqTemp,
      currentPage: state.currentPage,
      currentPageData: pageData,
    ));
    // }
  }

  Future<List<BottleData>> fetchPage(int page) async {
    final data = await fetchPageInternal(page);
    emit(state.copyWith(
      currentPage: page,
      currentPageData: data,
    ));
    return data;
  }

  Future<List<BottleData>> fetchPageInternal(int page) async {
    final db = await _dbHelper.database;
    final offset = page * pageSize;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableName,
      orderBy: 'timestamp DESC',
      limit: pageSize,
      offset: offset,
    );

    return List.generate(
      maps.length,
      (i) => BottleData.fromMap(maps[i]),
    );
  }

  Future<int> getTotalRecords() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableName}'),
    );
    return count ?? 0;
  }

  Future<List<HydrationDaySummary>> getHydrationSummariesForRange(
      DateTime startDate, DateTime endDate) async {
    Console.log(
        tag: "BottleDataCubit",
        value: "Fetching summaries from $startDate to $endDate");
    return await _dbHelper.getHydrationSummariesForRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<BottleData>> getHistoryForDateRange(
      DateTime start, DateTime end) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableName,
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    Console.log(tag: "getHistoryForDateRange", value: maps.toString());

    return List.generate(
      maps.length,
      (i) => BottleData.fromMap(maps[i]),
    );
  }

  Future<double> getCurrentDayHistory({bool localOnly = false}) async {
    final now = DateTime.now();

    if (!localOnly) {
      try {
        final hasInternet =
            await InternetConnectionHelper().hasInternetConnection();
        if (hasInternet) {
          final userId = await SharedPrefsHelper.getUserId();
          if (userId != null && userId.isNotEmpty) {
            // Server stores logs in UTC — query with UTC day boundaries.
            final startDate = DateTime.utc(now.year, now.month, now.day);
            final endDate =
                DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
            final summaries =
                await ApiService().getDailySummaries(userId, startDate, endDate);
            if (summaries != null && summaries.isNotEmpty) {
              final summaryMap = summaries.first;
              final serverConsumed = (summaryMap['consumed'] as num).toDouble();
              return serverConsumed;
            }
          }
        }
      } catch (e) {
        Console.log(
            tag: "getCurrentDayHistory",
            value: "Failed fetching from server, falling back to local DB: $e");
      }
    }

    final localSummary = await _dbHelper.getSummaryForDate(now);
    if (localSummary != null) {
      Console.log(
          tag: "consumedThings", value: "${localSummary.toMap()}");
      return localSummary.consumed;
    }

    return 0.0;
  }

  Future<void> clearOldRecords(int daysToKeep) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await db.delete(
      DatabaseHelper.tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    final refreshedPage = await fetchPageInternal(state.currentPage);
    emit(state.copyWith(currentPageData: refreshedPage));
  }

  Future<void> clearAllBottleData() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(DatabaseHelper.tableName);
      await db.delete(DatabaseHelper.hydrationSummaryTableName);

      // Ensure BleCubit's local state is cleared before emitting initial state
      // to avoid re-insertion of old values in _handleBleStateChange
      await _bleCubit.clearData();

      await Future.delayed(
          Duration(seconds: 1)); // Small delay for DB stability
      // emit(_bleCubit.state.copyWith(currentHydrationValue: 0));

      final dbEntry = await _dbHelper.getAllSlots();
      for (final updatedEntry in dbEntry) {
        await _dbHelper.insertOrUpdateSlot(updatedEntry.copyWith(
            waterDrank: 0.0, status: HydrationStatus.pending));
      }

      emit(BottleDataState.initial());
      Console.log(
          tag: "BottleDataCubit",
          value: "✅ All bottle tracking data cleared successfully.");
    } catch (e) {
      Console.error(
          "BottleDataCubit", "❌ Error clearing bottle tracking data: $e");
    }
  }

  Future<void> clearTodayBottleData() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay =
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
              .toIso8601String();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await db.delete(
        DatabaseHelper.tableName,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startOfDay, endOfDay],
      );
      await db.delete(
        DatabaseHelper.hydrationSummaryTableName,
        where: 'date LIKE ?',
        whereArgs: ['$dateStr%'],
      );

      await _bleCubit.clearData();

      await Future.delayed(
          const Duration(seconds: 1)); // Small delay for DB stability

      final dbEntry = await _dbHelper.getAllSlots();
      for (final updatedEntry in dbEntry) {
        await _dbHelper.insertOrUpdateSlot(updatedEntry.copyWith(
            waterDrank: 0.0, status: HydrationStatus.pending));
      }

      await _restoreLastValues();
      refresh();
      Console.log(
          tag: "BottleDataCubit",
          value: "✅ Today's bottle tracking data cleared successfully.");
    } catch (e) {
      Console.error(
          "BottleDataCubit", "❌ Error clearing today's bottle data: $e");
    }
  }

  void refresh() {
    emit(state.copyWith(lastRefreshed: DateTime.now()));
  }

  @override
  Future<void> close() {
    _bleSub.cancel();
    return super.close();
  }
}
