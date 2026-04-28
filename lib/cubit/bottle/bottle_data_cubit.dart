import 'dart:async';
import 'package:hydrify/helpers/logger.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
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
      Console.log(
          tag: "BottleDataCubit",
          value: "✅ Restoring from last record: "
              "volume=${lastData.liquidVolume}, "
              "percent=${lastData.liquidPercent}, "
              "battery=${lastData.battery}, "
              "timestamp=${lastData.timestamp}"
              "temp=${lastData.temp},"
              "bq_temp=${lastData.bqTemp}");

      emit(state.copyWith(
        volume: lastData.liquidVolume,
        volumePercent: lastData.liquidPercent,
        battery: lastData.battery,
        refills: lastData.refills,
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

  Future<double> getCurrentDayHistory() async {
    final db = await _dbHelper.database;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day, 00, 00, 00);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.hydrationSummaryTableName,
    );

    //Console.log(tag: "getCurrentDayHistory", value: maps.toString());

    var hyderationData = List.generate(
      maps.length,
      (i) => HydrationDaySummary.fromMap(maps[i]),
    );

    // Normalize input range to start and end of day
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    var hydrationDataTemp = hyderationData.where((s) {
      if (s.date.isBefore(normalizedStart)) {
        return false;
      }
      if (s.date.isAfter(normalizedEnd)) {
        return false;
      }
      return true;
    }).toList();
    if (hydrationDataTemp.isEmpty) {
      return 0;
    }

    Console.log(
        tag: "consumedThings", value: "${hydrationDataTemp.first.toMap()}");
    return hydrationDataTemp.first.consumed;
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

  void refresh() {
    emit(state.copyWith(lastRefreshed: DateTime.now()));
  }

  @override
  Future<void> close() {
    _bleSub.cancel();
    return super.close();
  }
}
