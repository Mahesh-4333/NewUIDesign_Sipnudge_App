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
  final double caffeineMg;
  final double caffeineAdjMl;
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
    required this.caffeineMg,
    required this.caffeineAdjMl,
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
        'caffeine_mg': caffeineMg,
        'caffeine_adj_ml': caffeineAdjMl,
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
    // Step B3: Caffeine adjustment  Cadj = caffeine(mg) × 2.0 ml
    // Prioritize today's manual logs, fallback to user preferences.
    // ------------------------------------------------------------------
    double caffeineMg = await DatabaseHelper().getTodayBeverageCaffeine();

    // If no manual logs for today, use fallback from userInfo preferences
    if (caffeineMg == 0.0) {
      final userInfo = await DatabaseHelper().getUserInfo();
      if (userInfo != null) {
        // 1 Cup = 200ml.
        // Standard caffeine: Coffee ~80mg/200ml, Tea ~40mg/200ml.
        switch (userInfo.coffeeIntake) {
          case BeverageIntake.oneToTwo:
            caffeineMg += 1.5 * 80;
            break;
          case BeverageIntake.threeToFour:
            caffeineMg += 3.5 * 80;
            break;
          case BeverageIntake.fivePlus:
            caffeineMg += 5.0 * 80;
            break;
          case BeverageIntake.none:
          default:
            break;
        }
        switch (userInfo.teaIntake) {
          case BeverageIntake.oneToTwo:
            caffeineMg += 1.5 * 40;
            break;
          case BeverageIntake.threeToFour:
            caffeineMg += 3.5 * 40;
            break;
          case BeverageIntake.fivePlus:
            caffeineMg += 5.0 * 40;
            break;
          case BeverageIntake.none:
          default:
            break;
        }
      }
    }

    final double caffeineAdjMl = caffeineMg * 2.0;

    // ------------------------------------------------------------------
    // Step B4: Food water deduction (today's scans only)
    // ------------------------------------------------------------------
    final double foodWaterMl = await _fetchTodayFoodWater();

    // ------------------------------------------------------------------
    // Total  Gtotal = Gbase + Stepsadj + Tempadj + Cadj - Foodwater
    // ------------------------------------------------------------------
    final double totalGoalMl =
        baseGoalMl + stepsAdjMl + tempAdjMl + caffeineAdjMl - foodWaterMl;

    final result = AiHydrationResult(
      weightKg: weightKg,
      baseGoalMl: baseGoalMl,
      steps: steps,
      stepsAdjMl: stepsAdjMl,
      temperatureC: temperatureC,
      tempAdjMl: tempAdjMl,
      caffeineMg: caffeineMg,
      caffeineAdjMl: caffeineAdjMl,
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
            'Temp(+${tempAdjMl.toInt()}) | Caffeine(+${caffeineAdjMl.toInt()}) | '
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

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
