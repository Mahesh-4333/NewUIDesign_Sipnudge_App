import 'dart:developer';

import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/chart_data.dart';
import 'package:hydrify/models/water_consumption_data.dart';
import 'package:intl/intl.dart';

class WaterConsumptionCalculator {
  static const double DAILY_GOAL_ML = 2500.0;
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
  static double calculateCompletionPercentage(double consumedVolume) {
    return (consumedVolume / DAILY_GOAL_ML * 100).clamp(0, 100);
  }

  // Get weekly consumption data
  static List<WaterConsumptionData> getWeeklyData(
    List<BottleData> allReadings,
    DateTime weekStart,
  ) {
    List<WaterConsumptionData> weeklyData = [];

    for (int i = 0; i < 7; i++) {
      DateTime currentDate = weekStart.add(Duration(days: i));
      DateTime nextDate = currentDate.add(const Duration(days: 1));

      // Include readings at exactly currentDate
      List<BottleData> dayReadings = allReadings
          .where((reading) =>
              reading.timestamp.isAtSameMomentAs(currentDate) ||
              (reading.timestamp.isAfter(currentDate) &&
                  reading.timestamp.isBefore(nextDate)))
          .toList();

      double consumption = calculateDailyConsumption(dayReadings);
      double percentage = calculateCompletionPercentage(consumption);

      weeklyData.add(WaterConsumptionData(
        date: currentDate,
        consumedVolume: consumption,
        completionPercentage: percentage,
      ));
    }

    return weeklyData;
  }

  static List<WaterConsumptionData> getMonthlyData(
    List<BottleData> allReadings,
    DateTime month,
  ) {
    List<WaterConsumptionData> monthlyData = [];

    int daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      DateTime currentDate = DateTime(month.year, month.month, i);
      DateTime nextDate = DateTime(month.year, month.month, i + 1);

      List<BottleData> dayReadings = allReadings
          .where((reading) =>
              reading.timestamp.isAfter(currentDate) &&
              reading.timestamp.isBefore(nextDate))
          .toList();

      double consumption = calculateDailyConsumption(dayReadings);
      double percentage = calculateCompletionPercentage(consumption);

      monthlyData.add(WaterConsumptionData(
        date: currentDate,
        consumedVolume: consumption,
        completionPercentage: percentage,
      ));
    }

    return monthlyData;
  }

  static List<WaterConsumptionData> getYearlyData(
    List<BottleData> allReadings,
    DateTime year,
  ) {
    List<WaterConsumptionData> yearlyData = [];

    for (int month = 1; month <= 12; month++) {
      DateTime monthDate = DateTime(year.year, month);

      // Get daily data for this month
      List<WaterConsumptionData> monthlyData =
          getMonthlyData(allReadings, monthDate);

      if (monthlyData.isNotEmpty) {
        double avgConsumption =
            monthlyData.map((d) => d.consumedVolume).reduce((a, b) => a + b) /
                monthlyData.length;

        double avgPercentage = monthlyData
                .map((d) => d.completionPercentage)
                .reduce((a, b) => a + b) /
            monthlyData.length;

        yearlyData.add(WaterConsumptionData(
          date: monthDate, // represent the month
          consumedVolume: avgConsumption,
          completionPercentage: avgPercentage,
        ));
      } else {
        // No data for this month → add empty entry
        yearlyData.add(WaterConsumptionData(
          date: monthDate,
          consumedVolume: 0,
          completionPercentage: 0,
        ));
      }
    }

    return yearlyData;
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
    log("Weight is $weightInKg || unit is ${state.weightUnit}");
    if (state.weightUnit == 'lbs') {
      weightInKg = state.weight! * 0.453592; // Convert lbs to kg
    }

    // Base calculation: 30-35ml per kg (using 32ml as middle ground)
    double baseIntake = weightInKg * 30.0;

    log("baseIntake is $baseIntake");
    // Activity level adjustment (based on step ranges from guide)
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

    double totalIntake = baseIntake + activityAdjustment + dietAdjustment;

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

    return {
      'baseIntake': baseIntake,
      'genderAdjustment': 0,
      'activityAdjustment': activityAdjustment,
      'dietAdjustment': dietAdjustment,
      'ageAdjustment': 0,
      'temperatureAdjustment': 0,
      'total': calculateWaterIntakeGoal(state,
          currentTemperature: currentTemperature),
    };
  }
}




// 
// Shaking of password when password is wrong 
// Instead of 35 = use 30 
// Goal calculation 
// Checks 
// home weather || icon change || blur || dabna chahea
// home fade in / fade out 
// analysis pill size 
// yearly dummy data , 
// reduce height of water completion 
// Drink reminder || Static 



//===========================================================================
// import 'dart:developer';

// import 'package:hydrify/cubit/filter/filter_cubit.dart';
// import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
// import 'package:hydrify/models/bottle_data.dart';
// import 'package:hydrify/models/chart_data.dart';
// import 'package:hydrify/models/water_consumption_data.dart';
// import 'package:intl/intl.dart';

// class WaterConsumptionCalculator {
//   static const double DAILY_GOAL_ML = 2500.0;
//   // Calculate consumption for a single day from bottle readings
//   static double calculateDailyConsumption(List<BottleData> dayReadings) {
//     if (dayReadings.isEmpty) return 0;

//     // Sort readings by timestamp
//     dayReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

//     double totalConsumption = 0;

//     for (int i = 1; i < dayReadings.length; i++) {
//       double previousVolume = dayReadings[i - 1].liquidVolume;
//       double currentVolume = dayReadings[i].liquidVolume;

//       // Only count decreases in volume as consumption
//       if (currentVolume < previousVolume) {
//         totalConsumption += (previousVolume - currentVolume);
//       }
//     }

//     return totalConsumption;
//   }

//   // Calculate completion percentage
//   static double calculateCompletionPercentage(double consumedVolume) {
//     return (consumedVolume / DAILY_GOAL_ML * 100).clamp(0, 100);
//   }

//   // Get weekly consumption data
//   static List<WaterConsumptionData> getWeeklyData(
//     List<BottleData> allReadings,
//     DateTime weekStart,
//   ) {
//     List<WaterConsumptionData> weeklyData = [];

//     for (int i = 0; i < 7; i++) {
//       DateTime currentDate = weekStart.add(Duration(days: i));
//       DateTime nextDate = currentDate.add(const Duration(days: 1));

//       // Include readings at exactly currentDate
//       List<BottleData> dayReadings = allReadings
//           .where((reading) =>
//               reading.timestamp.isAtSameMomentAs(currentDate) ||
//               (reading.timestamp.isAfter(currentDate) &&
//                   reading.timestamp.isBefore(nextDate)))
//           .toList();

//       double consumption = calculateDailyConsumption(dayReadings);
//       double percentage = calculateCompletionPercentage(consumption);

//       weeklyData.add(WaterConsumptionData(
//         date: currentDate,
//         consumedVolume: consumption,
//         completionPercentage: percentage,
//       ));
//     }

//     return weeklyData;
//   }

//   static List<WaterConsumptionData> getMonthlyData(
//     List<BottleData> allReadings,
//     DateTime month,
//   ) {
//     List<WaterConsumptionData> monthlyData = [];

//     int daysInMonth = DateTime(month.year, month.month + 1, 0).day;

//     for (int i = 1; i <= daysInMonth; i++) {
//       DateTime currentDate = DateTime(month.year, month.month, i);
//       DateTime nextDate = DateTime(month.year, month.month, i + 1);

//       List<BottleData> dayReadings = allReadings
//           .where((reading) =>
//               reading.timestamp.isAfter(currentDate) &&
//               reading.timestamp.isBefore(nextDate))
//           .toList();

//       double consumption = calculateDailyConsumption(dayReadings);
//       double percentage = calculateCompletionPercentage(consumption);

//       monthlyData.add(WaterConsumptionData(
//         date: currentDate,
//         consumedVolume: consumption,
//         completionPercentage: percentage,
//       ));
//     }

//     return monthlyData;
//   }

//   static List<WaterConsumptionData> getYearlyData(
//     List<BottleData> allReadings,
//     DateTime year,
//   ) {
//     List<WaterConsumptionData> yearlyData = [];

//     for (int month = 1; month <= 12; month++) {
//       DateTime monthDate = DateTime(year.year, month);

//       // Get daily data for this month
//       List<WaterConsumptionData> monthlyData =
//           getMonthlyData(allReadings, monthDate);

//       if (monthlyData.isNotEmpty) {
//         double avgConsumption =
//             monthlyData.map((d) => d.consumedVolume).reduce((a, b) => a + b) /
//                 monthlyData.length;

//         double avgPercentage = monthlyData
//                 .map((d) => d.completionPercentage)
//                 .reduce((a, b) => a + b) /
//             monthlyData.length;

//         yearlyData.add(WaterConsumptionData(
//           date: monthDate, // represent the month
//           consumedVolume: avgConsumption,
//           completionPercentage: avgPercentage,
//         ));
//       } else {
//         // No data for this month → add empty entry
//         yearlyData.add(WaterConsumptionData(
//           date: monthDate,
//           consumedVolume: 0,
//           completionPercentage: 0,
//         ));
//       }
//     }

//     return yearlyData;
//   }

//   static List<ChartData> formatChartData(
//     List<WaterConsumptionData> consumptionData,
//     FilterInterval interval,
//   ) {
//     return consumptionData.map((data) {
//       String xValue;

//       if (interval == FilterInterval.weekly) {
//         // Show weekday abbreviation: Mon, Tue, etc.
//         xValue = DateFormat.E().format(data.date);
//       } else if (interval == FilterInterval.monthly) {
//         // Show day of month: 1, 2, 3...
//         xValue = data.date.day.toString();
//       } else if (interval == FilterInterval.yearly) {
//         // Show month abbreviation: Jan, Feb, ...
//         xValue = DateFormat.MMM().format(data.date);
//       } else {
//         xValue = '';
//       }

//       return ChartData(
//         xValue,
//         data.completionPercentage,
//         data.consumedVolume,
//         data.date,
//       );
//     }).toList();
//   }

//   static double calculateWaterIntakeGoal(UserInfoState state,
//       {double? currentTemperature}) {
//     // Return 0 if essential data is missing
//     if (state.weight == null || state.weightUnit == null) {
//       return 0.0;
//     }

//     // Convert weight to kg if needed
//     double weightInKg = state.weight!;
//     log("Weight is $weightInKg || unit is ${state.weightUnit}");
//     if (state.weightUnit == 'lbs') {
//       weightInKg = state.weight! * 0.453592; // Convert lbs to kg
//     }

//     // Base calculation: 30-35ml per kg (using 32ml as middle ground)
//     double baseIntake = weightInKg * 30.0;

//     log("baseIntake is $baseIntake");
//     // Activity level adjustment (based on step ranges from guide)
//     double activityAdjustment = 0.0;
//     switch (state.activityLevel) {
//       case ActivityLevel.sedentary:
//         activityAdjustment = 0.0;
//         break;
//       case ActivityLevel.lightActivity:
//         activityAdjustment = 200.0;
//         break;
//       case ActivityLevel.midActive:
//         activityAdjustment = 400.0;
//         break;
//       case ActivityLevel.veryActive:
//         activityAdjustment = 700.0;
//         break;
//       case null:
//         activityAdjustment = 200.0; // Default to light activity
//         break;
//     }

//     double dietAdjustment = 0.0;
//     switch (state.dietType) {
//       case DietType.balanced:
//         dietAdjustment = 0.0; // Baseline
//         break;
//       case DietType.vegetarian:
//         dietAdjustment = -300.0; // Water-rich plant foods
//         break;
//       case DietType.highProtein:
//         dietAdjustment = 500.0; // Increased kidney workload
//         break;
//       case DietType.processed:
//         dietAdjustment = 200.0; // High sodium needs more water
//         break;
//       case null:
//         dietAdjustment = 0.0; // Default to balanced
//         break;
//     }

//     double totalIntake = baseIntake + activityAdjustment + dietAdjustment;

//     // Ensure minimum reasonable intake (1500ml) and maximum safe intake (4000ml)
//     return totalIntake;
//   }

//   /// Returns a breakdown of the calculation for transparency
//   static Map<String, double> getCalculationBreakdown(UserInfoState state,
//       {double? currentTemperature}) {
//     if (state.weight == null || state.weightUnit == null) {
//       return {};
//     }

//     double weightInKg = state.weight!;
//     if (state.weightUnit == 'lbs') {
//       weightInKg = state.weight! * 0.453592;
//     }

//     double baseIntake = weightInKg * 30;

//     double activityAdjustment = 0.0;
//     switch (state.activityLevel) {
//       case ActivityLevel.sedentary:
//         activityAdjustment = 0.0;
//         break;
//       case ActivityLevel.lightActivity:
//         activityAdjustment = 200.0;
//         break;
//       case ActivityLevel.midActive:
//         activityAdjustment = 400.0;
//         break;
//       case ActivityLevel.veryActive:
//         activityAdjustment = 700.0;
//         break;
//       case null:
//         activityAdjustment = 200.0; // Default to light activity
//         break;
//     }

//     double dietAdjustment = 0.0;
//     switch (state.dietType) {
//       case DietType.balanced:
//         dietAdjustment = 0.0; // Baseline
//         break;
//       case DietType.vegetarian:
//         dietAdjustment = -300.0; // Water-rich plant foods
//         break;
//       case DietType.highProtein:
//         dietAdjustment = 500.0; // Increased kidney workload
//         break;
//       case DietType.processed:
//         dietAdjustment = 200.0; // High sodium needs more water
//         break;
//       case null:
//         dietAdjustment = 0.0; // Default to balanced
//         break;
//     }

//     return {
//       'baseIntake': baseIntake,
//       'genderAdjustment': 0,
//       'activityAdjustment': activityAdjustment,
//       'dietAdjustment': dietAdjustment,
//       'ageAdjustment': 0,
//       'temperatureAdjustment': 0,
//       'total': calculateWaterIntakeGoal(state,
//           currentTemperature: currentTemperature),
//     };
//   }
// }

// //
// // Shaking of password when password is wrong
// // Instead of 35 = use 30
// // Goal calculation
// // Checks
// // home weather || icon change || blur || dabna chahea
// // home fade in / fade out
// // analysis pill size
// // yearly dummy data ,
// // reduce height of water completion
// // Drink reminder || Static

//===========================================================================

