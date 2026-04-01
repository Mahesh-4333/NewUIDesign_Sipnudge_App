import 'package:health/health.dart';
import 'package:hydrify/helpers/logger.dart';

class HealthService {
  final Health _health = Health();

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestAuthorization() async {
    final types = [HealthDataType.WATER, HealthDataType.STEPS];
    return await _health.requestAuthorization(types);
  }

  Future<double> getWaterIntakeLiters({DateTime? start, DateTime? end}) async {
    final now = end ?? DateTime.now();
    final startOfDay = start ?? DateTime(now.year, now.month, now.day);

    final types = [HealthDataType.WATER];

    bool? hasPermission = await _health.hasPermissions(types);
    Console.log(tag: "apple step permission", value: hasPermission);
    if (hasPermission != true) {
      bool authorized = await requestAuthorization();
      if (!authorized) {
        return 0.0;
      }
    }

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

    bool? hasPermission = await _health.hasPermissions(types);
    if (hasPermission != true) {
      bool authorized = await requestAuthorization();
      if (!authorized) {
        return 0;
      }
    }

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
}
