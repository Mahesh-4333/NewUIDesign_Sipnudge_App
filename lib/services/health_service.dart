import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:hydrify/services/pedometer_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
      final types = [
        HealthDataType.WATER,
        HealthDataType.STEPS,
      ];
      final permissions = [
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ,
      ];

      // On Android, check Health Connect status
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        Console.log(
            tag: "HealthService", value: "Health Connect SDK Status: $status");

        if (status != HealthConnectSdkStatus.sdkAvailable) {
          if (status ==
              HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
            Console.log(
                tag: "HealthService",
                value:
                    "Health Connect not installed. Redirecting to Play Store...");
            await _health.installHealthConnect();

            // Fallback: If the plugin's internal method fails to open the Play Store
            const playStoreUrl =
                "https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata";
            try {
              if (await canLaunchUrlString(playStoreUrl)) {
                await launchUrlString(playStoreUrl,
                    mode: LaunchMode.externalApplication);
              }
            } catch (e) {
              Console.log(
                  tag: "HealthService",
                  value: "Fallback redirection failed: $e");
            }
            return false;
          } else if (status ==
              HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
            Console.log(
                tag: "HealthService", value: "Health Connect update required.");
            await _health.installHealthConnect();
            return false;
          } else if (status == HealthConnectSdkStatus.sdkUnavailable) {
            Console.log(
                tag: "HealthService",
                value: "Health Connect is not supported on this device.");
            return false;
          }
        }
      }

      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      Console.log(tag: "authorized_123", value: authorized.toString());
      if (authorized) {
        permissionUpdateController.add(true);
      }
      return authorized;
    } catch (e) {
      Console.log(tag: "request Authorization Error", value: e.toString());
      return false;
    }
  }

  Future<bool> _ensurePermissions(List<HealthDataType> types,
      {bool force = false}) async {
    final permissions = types
        .map((t) => t == HealthDataType.WATER
            ? HealthDataAccess.READ_WRITE
            : HealthDataAccess.READ)
        .toList();

    bool? hasPermission =
        await _health.hasPermissions(types, permissions: permissions);

    Console.log(
        tag: "HealthService",
        value: "hasPermissions check for $types: $hasPermission");
    // If we definitely have permission, return true.
    if (hasPermission == true) return true;

    // If we haven't asked yet, or if we are being forced to ask again (e.g. via refresh button).
    bool alreadyRequested =
        await SharedPrefsHelper.getHasRequestedHealthPermission();

    Console.log(tag: "alreadyRequested", value: alreadyRequested);
    if (alreadyRequested) {
      return true;
    }
    if (force || !alreadyRequested) {
      // Mark as requested to prevent infinite loops if authorization fails or is inconclusive.
      await SharedPrefsHelper.setHasRequestedHealthPermission(true);
      Console.log(tag: "setHasRequestedHealthPermission", value: true);
      bool authorized = await requestAuthorization();
      return authorized;
    }

    // Default to false if we don't have permission and aren't allowed to ask.
    return false;
  }

  Future<double> getWaterIntakeLiters(
      {DateTime? start, DateTime? end, bool forcePermission = false}) async {
    try {
      final now = end ?? DateTime.now();
      final startOfDay = start ?? DateTime(now.year, now.month, now.day);

      final types = [HealthDataType.WATER];

      bool authorized = await _ensurePermissions(types, force: forcePermission);
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
    } catch (e) {
      Console.log(tag: "getWaterIntakeLiters Error", value: e.toString());
      return 0.0;
    }
  }

  Future<int> getStepCount(
      {DateTime? start, DateTime? end, bool forcePermission = false}) async {
    try {
      if (Platform.isAndroid) {
        // Request permission if not granted
        if (await Permission.activityRecognition.isDenied) {
          await Permission.activityRecognition.request();
        }
        return await PedometerService().getTodaySteps();
      }

      final now = end ?? DateTime.now();
      final startOfDay = start ?? DateTime(now.year, now.month, now.day);

      final types = [HealthDataType.STEPS];

      bool authorized = await _ensurePermissions(types, force: forcePermission);
      Console.log(tag: "authorized_124", value: authorized);
      if (!authorized) return 0;

      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      return steps!;
    } catch (e) {
      Console.log(tag: "getStepCount Error", value: e.toString());
      return 0;
    }
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
    try {
      if (amount <= 0) return false;
      final types = [HealthDataType.WATER];

      bool authorized = await _ensurePermissions(types);
      if (!authorized) return false;

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
