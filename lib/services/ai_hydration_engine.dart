import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';

import 'package:hydrify/models/food_scan_data.dart';
import 'package:hydrify/providers/weather_provider.dart';

import 'package:hydrify/cubit/user_info/user_info_cubit.dart';

/// Result model holding every component of the AI calculation.
class AiHydrationResult {
  final double weightKg;
  final double baseGoalMl;
  final int steps;
  final double stepsAdjMl;
  final double temperatureC;
  final double tempAdjMl;
  final double beverageCups;
  final double beverageAdjMl;
  final double foodWaterMl;
  final double totalGoalMl;
  final bool shouldShowDialog;

  const AiHydrationResult({
    required this.weightKg,
    required this.baseGoalMl,
    required this.steps,
    required this.stepsAdjMl,
    required this.temperatureC,
    required this.tempAdjMl,
    required this.beverageCups,
    required this.beverageAdjMl,
    required this.foodWaterMl,
    required this.totalGoalMl,
    required this.shouldShowDialog,
  });

  Map<String, dynamic> toDbMap(String date) => {
        'date': date,
        'weight_kg': weightKg,
        'base_goal_ml': baseGoalMl,
        'steps': steps,
        'steps_adj_ml': stepsAdjMl,
        'temperature_c': temperatureC,
        'temp_adj_ml': tempAdjMl,
        'caffeine_mg': beverageCups * 60, // Keep legacy field name for DB
        'caffeine_adj_ml': beverageAdjMl, // Keep legacy field name for DB
        'food_water_ml': foodWaterMl,
        'total_goal_ml': totalGoalMl,
        'created_at': DateTime.now().toIso8601String(),
      };
}

class AiHydrationEngine {
  /// Calculates dynamic daily water goal.
  ///
  /// [weightKg]        – user's weight in kg (from UserInfoCubit / DB)
  /// [weatherProvider] – live WeatherProvider for temperature reading
  ///
  /// Caffeine is currently a fixed dummy value (60 mg, equivalent to
  /// one instant coffee). Replace with a real input once the UI is ready.
  static Future<AiHydrationResult> calculate({
    required double weightKg,
    required WeatherProvider weatherProvider,
    double? surroundingTemp,
  }) async {
    // ------------------------------------------------------------------
    // Step A: Baseline  Gbase = weight × 32.5 ml
    // ------------------------------------------------------------------
    final double baseGoalMl = weightKg * 32.5;

    // ------------------------------------------------------------------
    // Step B1: Steps adjustment  Stepsadj = (steps / 3000) × 250 ml
    // ------------------------------------------------------------------
    final int steps = await DatabaseHelper().getDailySteps(DateTime.now()) ?? 0;
    Console.log(tag: "AI_ENGINE", value: "Steps: $steps");
    final double stepsAdjMl = (steps / 3000) * 250.0;

    // ------------------------------------------------------------------
    // Step B2: Temperature adjustment  IF temp > 25 → (temp-25) × 50 ml
    // ------------------------------------------------------------------
    final double temperatureC =
        _fetchTemperature(weatherProvider, surroundingTemp);
    final double tempAdjMl =
        temperatureC > 25 ? (temperatureC - 25) * 50.0 : 0.0;

    // ------------------------------------------------------------------
    // Step B3: Beverage hydration adjustment
    // ------------------------------------------------------------------
    double beverageAdjMl = 0.0;
    double beverageCups = 0.0;

    final List<Map<String, dynamic>> todayLogs =
        await DatabaseHelper().getHydrationLogs(date: DateTime.now());

    if (todayLogs.isNotEmpty) {
      for (final log in todayLogs) {
        final type = log['type'] as String;
        final consumedMl = (log['consumed'] as num).toDouble();
        final coef = _beverageCoefficients[type] ?? 1.0;

        // Adjustment = Volume * (1 - Coef)
        // If Coef < 1, Adj is positive (increases goal)
        // If Coef > 1, Adj is negative (decreases goal)
        beverageAdjMl += consumedMl * (1.0 - coef);

        if (type != 'Water') {
          // Estimate cups based on standard sizes used in LogHydrationWidget
          double cupSize = 250.0; // Default for Tea
          if (type == 'Coffee') cupSize = 150.0;
          if (type == 'Milk') cupSize = 200.0;
          if (type == 'Juice') cupSize = 250.0;
          beverageCups += consumedMl / cupSize;

          Console.log(
            tag: 'AI_ENGINE',
            value:
                'Beverage Logged: $type, Vol: $consumedMl mL, Coef: $coef, Adj: ${(consumedMl * (1.0 - coef)).toInt()} mL',
          );
        }
      }
    } else {
      // Fallback: use user preferences if no manual logs exist today
      final userInfo = await DatabaseHelper().getUserInfo();
      if (userInfo != null) {
        // Coffee Adjustment (Coef: 0.8)
        double coffeeCupSize = 150.0;
        switch (userInfo.coffeeIntake) {
          case BeverageIntake.oneToTwo:
            beverageAdjMl += 1.5 * coffeeCupSize * (1.0 - 0.8);
            beverageCups += 1.5;
            break;
          case BeverageIntake.threeToFour:
            beverageAdjMl += 3.5 * coffeeCupSize * (1.0 - 0.8);
            beverageCups += 3.5;
            break;
          case BeverageIntake.fivePlus:
            beverageAdjMl += 5.0 * coffeeCupSize * (1.0 - 0.8);
            beverageCups += 5.0;
            break;
          default:
            break;
        }

        // Tea Adjustment (Coef: 0.85)
        double teaCupSize = 250.0;
        switch (userInfo.teaIntake) {
          case BeverageIntake.oneToTwo:
            beverageAdjMl += 1.5 * teaCupSize * (1.0 - 0.85);
            beverageCups += 1.5;
            break;
          case BeverageIntake.threeToFour:
            beverageAdjMl += 3.5 * teaCupSize * (1.0 - 0.85);
            beverageCups += 3.5;
            break;
          case BeverageIntake.fivePlus:
            beverageAdjMl += 5.0 * teaCupSize * (1.0 - 0.85);
            beverageCups += 5.0;
            break;
          default:
            break;
        }
      }
    }

    // ------------------------------------------------------------------
    // Step B4: Food water deduction (today's scans only)
    // ------------------------------------------------------------------
    final double foodWaterMl = await _fetchTodayFoodWater();

    // ------------------------------------------------------------------
    // Total  Gtotal = Gbase + Stepsadj + Tempadj + Beverageadj - Foodwater
    // ------------------------------------------------------------------
    final double totalGoalMl =
        baseGoalMl + stepsAdjMl + tempAdjMl + beverageAdjMl - foodWaterMl;

    final result = AiHydrationResult(
      weightKg: weightKg,
      baseGoalMl: baseGoalMl,
      steps: steps,
      stepsAdjMl: stepsAdjMl,
      temperatureC: temperatureC,
      tempAdjMl: tempAdjMl,
      beverageCups: beverageCups,
      beverageAdjMl: beverageAdjMl,
      foodWaterMl: foodWaterMl,
      totalGoalMl: totalGoalMl > 0 ? totalGoalMl : 1500.0,
      shouldShowDialog: steps > 0,
    );

    Console.log(
        tag: 'AI_ENGINE',
        value:
            'Steps: $steps, Temp: $temperatureC, ShouldShow: ${result.shouldShowDialog}');
    Console.log(
        tag: 'AI_ENGINE',
        value:
            'Calculation → Base: ${baseGoalMl.toInt()} | Steps(+${stepsAdjMl.toInt()}) | '
            'Temp(+${tempAdjMl.toInt()}) | Beverages(+${beverageAdjMl.toInt()}) | '
            'Food(-${foodWaterMl.toInt()}) = TOTAL: ${result.totalGoalMl.toInt()} mL');

    // ------------------------------------------------------------------
    // Persist to the ai_hydration_engine table
    // ------------------------------------------------------------------
    final String dateKey = _todayKey();
    await DatabaseHelper().insertAiHydrationLog(result.toDbMap(dateKey));

    // ------------------------------------------------------------------
    // Persist the new goal to SharedPrefs so the rest of the app sees it
    // ------------------------------------------------------------------

    return result;
  }

  // ────────────────────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────────────────────

  static double _fetchTemperature(
      WeatherProvider weatherProvider, double? surroundingTemp) {
    if (surroundingTemp != null && surroundingTemp > 0) {
      return surroundingTemp;
    }
    final temp = weatherProvider.weatherData?.temperature;
    if (temp == null) {
      Console.log(
          tag: 'AI_ENGINE',
          value: 'Temperature unavailable, defaulting to 25°C');
      return 25.0; // neutral – zero adjustment
    }
    return temp;
  }

  static Future<double> _fetchTodayFoodWater() async {
    try {
      final scans = await DatabaseHelper().getAllFoodScans();
      final now = DateTime.now();
      Console.log(tag: "AI_ENGINE", value: "Total scans: ${scans.length}");
      double total = 0.0;
      for (final scanMap in scans) {
        final scan = FoodScanData.fromMap(scanMap);
        if (scan.timestamp.year == now.year &&
            scan.timestamp.month == now.month &&
            scan.timestamp.day == now.day) {
          total += scan.waterContentMl;
        }
      }
      return total;
    } catch (e) {
      Console.log(tag: 'AI_ENGINE', value: 'Food water fetch failed: $e');
      return 0.0;
    }
  }

  static const Map<String, double> _beverageCoefficients = {
    'Tea': 0.85,
    'Coffee': 0.8,
    'Juice': 0.9,
    'Milk': 1.5,
    'Water': 1.0,
  };

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
