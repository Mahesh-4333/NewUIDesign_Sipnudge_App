import 'package:flutter/material.dart';
import 'package:hydrify/models/hydration_entry.dart';

class HydrationState {
  final List<HydrationEntry> entries;
  final int totalDrank;
  final int goal;
  final DateTime selectedDate;
  final String? errorMessage;
  final String? successMessage;
  final HydrationEntry? currentSlotEntry;
  final double currentSlotConsumption; // Water Drank in this slot (in mL)
  final double currentSlotPercentage;
  final int consistencyStreak;

  final int currentLevel;
  final int? newlyUnlockedLevel;
  final Map<int, String> levelToIntakeMap;
  final Map<int, String> exactLevelToIntakeMap;
  final List<Map<String, dynamic>> todayHydrationHistory;

  HydrationState(
      {required this.entries,
      required this.totalDrank,
      required this.goal,
      required this.selectedDate,
      this.errorMessage,
      this.successMessage,
      this.currentSlotEntry,
      this.currentSlotConsumption = 0.0,
      this.currentSlotPercentage = 0.0,
      this.currentLevel = 0,
      this.newlyUnlockedLevel = 0,
      this.consistencyStreak = 0,
      this.levelToIntakeMap = const {},
      this.exactLevelToIntakeMap = const {},
      this.todayHydrationHistory = const []});

  HydrationState copyWith(
      {List<HydrationEntry>? entries,
      int? totalDrank,
      int? goal,
      DateTime? selectedDate,
      String? errorMessage,
      String? successMessage,
      HydrationEntry? currentSlotEntry,
      double? currentSlotConsumption,
      double? currentSlotPercentage,
      int? currentLevel,
      int? newlyUnlockedLevel,
      int? consistencyStreak,
      bool clearNewlyUnlockedLevel = false,
      Map<int, String>? levelToIntakeMap,
      Map<int, String>? exactLevelToIntakeMap,
      List<Map<String, dynamic>>? todayHydrationHistory}) {
    return HydrationState(
      entries: entries ?? this.entries,
      totalDrank: totalDrank ?? this.totalDrank,
      goal: goal ?? this.goal,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentSlotEntry: currentSlotEntry ?? this.currentSlotEntry,
      currentSlotConsumption:
          currentSlotConsumption ?? this.currentSlotConsumption,
      currentSlotPercentage:
          currentSlotPercentage ?? this.currentSlotPercentage,
      currentLevel: currentLevel ?? this.currentLevel,
      // clearNewlyUnlockedLevel=true explicitly sets null;
      // otherwise fall back to the passed value or keep the existing one.
      newlyUnlockedLevel: clearNewlyUnlockedLevel
          ? null
          : (newlyUnlockedLevel ?? this.newlyUnlockedLevel),
      consistencyStreak: consistencyStreak ?? this.consistencyStreak,
      levelToIntakeMap: levelToIntakeMap ?? this.levelToIntakeMap,
      exactLevelToIntakeMap:
          exactLevelToIntakeMap ?? this.exactLevelToIntakeMap,
      todayHydrationHistory:
          todayHydrationHistory ?? this.todayHydrationHistory,
    );
  }

  factory HydrationState.initial() {
    return HydrationState(
      entries: [],
      totalDrank: 0,
      goal: 2000,
      // Default goal in mL
      selectedDate: DateTime.now(),
      currentSlotConsumption: 0.0,
      currentSlotPercentage: 0.0,
      consistencyStreak: 0,
      todayHydrationHistory: [],
    );
  }
}
