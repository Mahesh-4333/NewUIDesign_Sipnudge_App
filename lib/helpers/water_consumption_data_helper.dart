import 'package:flutter/material.dart';
import 'package:hydrify/helpers/logger.dart';

import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/water_consumption_data.dart';
import 'package:intl/intl.dart';

class WaterConsumptionCalculator {
  /// Calculate cumulative expected slot target percentage at current time.
  /// Each slot progresses one by one:
  /// - Before a slot's startTime: 0% contribution for that slot.
  /// - Between startTime and endTime: Smoothly progresses from 0% to 100% of that slot's target.
  /// - After endTime: 100% contribution of that slot's target is retained.
  /// - Between slots (gap time): Stays static at the completed slots' cumulative target until the next slot starts.
  static double calculateExpectedPercentage(
    List<HydrationEntry> slots,
    double dailyGoalMl, {
    TimeOfDay? nowTime,
  }) {
    if (dailyGoalMl <= 0 || slots.isEmpty) return 0.0;

    final now = nowTime ?? TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final sortedSlots = List<HydrationEntry>.from(slots)..sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });

    double expectedCumulative = 0.0;

    for (int i = 0; i < sortedSlots.length; i++) {
      final slot = sortedSlots[i];
      final startMin = slot.startTime.hour * 60 + slot.startTime.minute;
      final endMin = slot.endTime.hour * 60 + slot.endTime.minute;

      if (nowMinutes >= endMin) {
        // Slot has passed -> add full slot target
        expectedCumulative += slot.amount;
      } else if (nowMinutes >= startMin && nowMinutes < endMin) {
        // Currently active slot -> progress smoothly from startMin to endMin
        final duration = endMin - startMin;
        if (duration > 0) {
          final elapsed = nowMinutes - startMin;
          expectedCumulative += slot.amount * (elapsed / duration);
        }
        break; // Subsequent slots haven't started yet
      } else {
        // Next slots haven't started yet
        break;
      }
    }

    return ((expectedCumulative / dailyGoalMl) * 100.0).clamp(0.0, 100.0);
  }

  // Calculate consumption for a single day from bottle readings
  static double calculateDailyConsumption(List<BottleData> dayReadings) {
    if (dayReadings.isEmpty) return 0;

    // Sort readings by timestamp
    dayReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalConsumption = 0;

    for (int i = 1; i < dayReadings.length; i++) {
      double previousVolume = dayReadings[i - 1].liquidVolume;
      double currentVolume = dayReadings[i].liquidVolume;

      // Only count decreases in volume as consumption
      if (currentVolume < previousVolume) {
        totalConsumption += (previousVolume - currentVolume);
      }
    }

    return totalConsumption;
  }

  // Calculate completion percentage
  static Future<double> calculateCompletionPercentage(
    double consumedVolume,
  ) async {
    var goal = await SharedPrefsHelper.getUserGoal() ?? 0;
    if (goal <= 0) return 0.0;
    final percentage = (consumedVolume / goal) * 100;
    return double.parse(percentage.toStringAsFixed(1));
  }

  static Future<double> calculateRemainingPercentage(
    double consumedVolume,
  ) async {
    var goal = await SharedPrefsHelper.getUserGoal() ?? 0;
    if (goal <= 0) return 0.0;
    final remaining = (goal - consumedVolume);
    return remaining < 0 ? 0.0 : double.parse(remaining.toStringAsFixed(1));
  }

  static List<ChartData> formatChartData(
    List<WaterConsumptionData> consumptionData,
    FilterInterval interval,
  ) {
    return consumptionData.map((data) {
      String xValue;

      if (interval == FilterInterval.weekly) {
        // Show weekday abbreviation: Mon, Tue, etc.
        xValue = DateFormat.E().format(data.date);
      } else if (interval == FilterInterval.monthly) {
        // Show day of month: 1, 2, 3...
        xValue = data.date.day.toString();
      } else if (interval == FilterInterval.yearly) {
        // Show month abbreviation: Jan, Feb, ...
        xValue = DateFormat.MMM().format(data.date);
      } else {
        xValue = '';
      }

      return ChartData(
        xValue,
        data.completionPercentage,
        data.consumedVolume,
        data.date,
      );
    }).toList();
  }

  static double calculateWaterIntakeGoal(UserInfoState state,
      {double? currentTemperature}) {
    // Return 0 if essential data is missing
    if (state.weight == null || state.weightUnit == null) {
      return 0.0;
    }

    // Convert weight to kg if needed
    double weightInKg = state.weight!;
    Console.log(
        tag: "APP",
        value: "Weight is $weightInKg || unit is ${state.weightUnit}");
    if (state.weightUnit == 'lbs') {
      weightInKg = state.weight! * 0.453592; // Convert lbs to kg
    }

    // Base calculation: 30-35ml per kg (using 32ml as middle ground)
    double baseIntake = weightInKg * 32.5;

    Console.log(tag: "APP", value: "baseIntake is $baseIntake");
    // Activity level adjustment (based on step ranges from guide)
    double activityAdjustment = 0.0;
    // switch (state.activityLevel) {
    //   case ActivityLevel.sedentary:
    //     activityAdjustment = 0.0;
    //     break;
    //   case ActivityLevel.lightActivity:
    //     activityAdjustment = 200.0;
    //     break;
    //   case ActivityLevel.midActive:
    //     activityAdjustment = 400.0;
    //     break;
    //   case ActivityLevel.veryActive:
    //     activityAdjustment = 700.0;
    //     break;
    //   case null:
    //     activityAdjustment = 200.0; // Default to light activity
    //     break;
    // }

    double dietAdjustment = 0.0;
    // switch (state.dietType) {
    //   case DietType.balanced:
    //     dietAdjustment = 0.0; // Baseline
    //     break;
    //   case DietType.vegetarian:
    //     dietAdjustment = -300.0; // Water-rich plant foods
    //     break;
    //   case DietType.highProtein:
    //     dietAdjustment = 500.0; // Increased kidney workload
    //     break;
    //   case DietType.processed:
    //     dietAdjustment = 200.0; // High sodium needs more water
    //     break;
    //   case null:
    //     dietAdjustment = 0.0; // Default to balanced
    //     break;
    // }

    double ageAdjustment = 0.0;
    if (state.age != null) {
      if (state.age! < 30) {
        ageAdjustment = 200.0;
      } else if (state.age! > 55) {
        ageAdjustment = -200.0;
      }
    }

    double coffeeAdjustment = 0.0;
    switch (state.coffeeIntake) {
      case BeverageIntake.none:
        coffeeAdjustment = 0.0;
        break;
      case BeverageIntake.oneToTwo:
        coffeeAdjustment = 250.0;
        break;
      case BeverageIntake.threeToFour:
        coffeeAdjustment = 500.0;
        break;
      case BeverageIntake.fivePlus:
        coffeeAdjustment = 750.0;
        break;
      case null:
        coffeeAdjustment = 0.0;
        break;
    }

    double teaAdjustment = 0.0;
    switch (state.teaIntake) {
      case BeverageIntake.none:
        teaAdjustment = 0.0;
        break;
      case BeverageIntake.oneToTwo:
        teaAdjustment = 150.0;
        break;
      case BeverageIntake.threeToFour:
        teaAdjustment = 300.0;
        break;
      case BeverageIntake.fivePlus:
        teaAdjustment = 450.0;
        break;
      case null:
        teaAdjustment = 0.0;
        break;
    }

    double totalIntake = baseIntake;

    // Optional: Adjust based on typical intake if it's significantly higher
    // if (state.typicalWaterIntake != null) {
    //   double typicalMl = state.typicalWaterIntake! * 1000;
    //   if (typicalMl > totalIntake) {
    //     // If user already drinks more, don't recommend less than what they are used to
    //     // unless it's excessive (>4L)
    //     totalIntake = (totalIntake + typicalMl) / 2;
    //   }
    // }

    // Ensure minimum reasonable intake (1500ml) and maximum safe intake (4000ml)
    return totalIntake;
  }

  /// Returns a breakdown of the calculation for transparency
  static Map<String, double> getCalculationBreakdown(UserInfoState state,
      {double? currentTemperature}) {
    if (state.weight == null || state.weightUnit == null) {
      return {};
    }

    double weightInKg = state.weight!;
    if (state.weightUnit == 'lbs') {
      weightInKg = state.weight! * 0.453592;
    }

    double baseIntake = weightInKg * 30;

    double activityAdjustment = 0.0;
    switch (state.activityLevel) {
      case ActivityLevel.sedentary:
        activityAdjustment = 0.0;
        break;
      case ActivityLevel.lightActivity:
        activityAdjustment = 200.0;
        break;
      case ActivityLevel.midActive:
        activityAdjustment = 400.0;
        break;
      case ActivityLevel.veryActive:
        activityAdjustment = 700.0;
        break;
      case null:
        activityAdjustment = 200.0; // Default to light activity
        break;
    }

    double dietAdjustment = 0.0;
    switch (state.dietType) {
      case DietType.balanced:
        dietAdjustment = 0.0; // Baseline
        break;
      case DietType.vegetarian:
        dietAdjustment = -300.0; // Water-rich plant foods
        break;
      case DietType.highProtein:
        dietAdjustment = 500.0; // Increased kidney workload
        break;
      case DietType.processed:
        dietAdjustment = 200.0; // High sodium needs more water
        break;
      case null:
        dietAdjustment = 0.0; // Default to balanced
        break;
    }

    double ageAdjustment = 0.0;
    if (state.age != null) {
      if (state.age! < 30) {
        ageAdjustment = 200.0;
      } else if (state.age! > 55) {
        ageAdjustment = -200.0;
      }
    }

    double coffeeAdjustment = 0.0;
    switch (state.coffeeIntake) {
      case BeverageIntake.none:
        coffeeAdjustment = 0.0;
        break;
      case BeverageIntake.oneToTwo:
        coffeeAdjustment = 250.0;
        break;
      case BeverageIntake.threeToFour:
        coffeeAdjustment = 500.0;
        break;
      case BeverageIntake.fivePlus:
        coffeeAdjustment = 750.0;
        break;
      case null:
        coffeeAdjustment = 0.0;
        break;
    }

    double teaAdjustment = 0.0;
    switch (state.teaIntake) {
      case BeverageIntake.none:
        teaAdjustment = 0.0;
        break;
      case BeverageIntake.oneToTwo:
        teaAdjustment = 150.0;
        break;
      case BeverageIntake.threeToFour:
        teaAdjustment = 300.0;
        break;
      case BeverageIntake.fivePlus:
        teaAdjustment = 450.0;
        break;
      case null:
        teaAdjustment = 0.0;
        break;
    }

    return {
      'baseIntake': baseIntake,
      'genderAdjustment': 0,
      'activityAdjustment': activityAdjustment,
      'dietAdjustment': dietAdjustment,
      'caffeineAdjustment': coffeeAdjustment + teaAdjustment,
      'typicalIntakeAdjustment': state.typicalWaterIntake != null
          ? (state.typicalWaterIntake! * 1000)
          : 0.0,
      'ageAdjustment': ageAdjustment,
      'temperatureAdjustment': 0,
      'total': calculateWaterIntakeGoal(state,
          currentTemperature: currentTemperature),
    };
  }
}
