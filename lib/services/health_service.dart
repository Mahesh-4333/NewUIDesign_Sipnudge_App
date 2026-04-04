import 'dart:async';
import 'package:health/health.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

class HealthService {
  final Health _health = Health();

  // Stream to notify widgets when health permission is granted
  static final StreamController<bool> permissionUpdateController =
      StreamController<bool>.broadcast();
  static Stream<bool> get onPermissionUpdate =>
      permissionUpdateController.stream;

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestAuthorization() async {
    try {
      final types = [HealthDataType.WATER, HealthDataType.STEPS];
      final permissions = [
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ,
      ];

      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      if (authorized) {
        permissionUpdateController.add(true);
      }
      return authorized;
    } catch (e) {
      Console.log(tag: "request Authorization Error", value: e.toString());
      return false;
    }
  }

  Future<bool> _ensurePermissions(List<HealthDataType> types) async {
    final permissions = types
        .map((t) => t == HealthDataType.WATER
            ? HealthDataAccess.READ_WRITE
            : HealthDataAccess.READ)
        .toList();

    bool? hasPermission =
        await _health.hasPermissions(types, permissions: permissions);
    if (hasPermission == true) return true;

    bool alreadyRequested = await SharedPrefsHelper.getHasRequestedHealthPermission();
    if (alreadyRequested) return true;

    bool authorized = await requestAuthorization();
    if (authorized) {
      await SharedPrefsHelper.setHasRequestedHealthPermission(true);
    }
    return authorized;
  }

  Future<double> getWaterIntakeLiters({DateTime? start, DateTime? end}) async {
    final now = end ?? DateTime.now();
    final startOfDay = start ?? DateTime(now.year, now.month, now.day);

    final types = [HealthDataType.WATER];

    bool authorized = await _ensurePermissions(types);
    if (!authorized) return 0.0;

    final healthData = await _health.getHealthDataFromTypes(
      types: types,
      startTime: startOfDay,
      endTime: now,
    );

    double totalLiters = 0.0;
    for (final dataPoint in healthData) {
      if (dataPoint.value is NumericHealthValue) {
        final numericValue =
            (dataPoint.value as NumericHealthValue).numericValue;
        totalLiters += numericValue;
      }
    }

    return totalLiters;
  }

  Future<int> getStepCount({DateTime? start, DateTime? end}) async {
    final now = end ?? DateTime.now();
    final startOfDay = start ?? DateTime(now.year, now.month, now.day);

    final types = [HealthDataType.STEPS];

    bool authorized = await _ensurePermissions(types);
    if (!authorized) return 0;

    final steps = await _health.getTotalStepsInInterval(startOfDay, now);
    return steps ?? 0;
  }

  Future<double> getWaterIntakePercentage({
    required double dailyGoalLiters,
    DateTime? start,
    DateTime? end,
  }) async {
    final waterIntake = await getWaterIntakeLiters(start: start, end: end);
    if (dailyGoalLiters <= 0) return 0.0;
    return (waterIntake / dailyGoalLiters) * 100;
  }

  Future<bool> addWaterIntake(double amount, DateTime timestamp) async {
    if (amount <= 0) return false;
    final types = [HealthDataType.WATER];

    bool authorized = await _ensurePermissions(types);
    if (!authorized) return false;

    try {
      // NOTE: amount is in Liters as required by the Health package for WATER
      return await _health.writeHealthData(
        value: amount,
        type: HealthDataType.WATER,
        startTime: timestamp.subtract(const Duration(seconds: 1)),
        endTime: timestamp,
      );
    } catch (e) {
      Console.log(tag: "addWaterIntake Error", value: e.toString());
      return false;
    }
  }
}
