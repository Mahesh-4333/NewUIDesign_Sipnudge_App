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

  HydrationState({
    required this.entries,
    required this.totalDrank,
    required this.goal,
    required this.selectedDate,
    this.errorMessage,
    this.successMessage,
    this.currentSlotEntry,
    this.currentSlotConsumption = 0.0,
    this.currentSlotPercentage = 0.0,
  });

  HydrationState copyWith({
    List<HydrationEntry>? entries,
    int? totalDrank,
    int? goal,
    DateTime? selectedDate,
    String? errorMessage,
    String? successMessage,
    HydrationEntry? currentSlotEntry,
    double? currentSlotConsumption,
    double? currentSlotPercentage,
  }) {
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
    );
  }

  factory HydrationState.initial() {
    return HydrationState(
      entries: [],
      totalDrank: 0,
      goal: 2000, // Default goal in mL
      selectedDate: DateTime.now(),
      currentSlotConsumption: 0.0,
      currentSlotPercentage: 0.0,
    );
  }
}

// -----------------------------------------------------------------------------

// part of 'hydration_cubit.dart';

// class HydrationState {
//   final List<HydrationEntry> entries;
//   final int totalDrank;
//   final int goal;
//   final DateTime selectedDate;
//   final String? errorMessage;
//   final String? successMessage;
//   final HydrationEntry? currentSlotEntry;
//   final double currentSlotConsumption; // Water Drank in this slot (in mL)
//   final double currentSlotPercentage;

//   HydrationState({
//     required this.entries,
//     required this.totalDrank,
//     required this.goal,
//     required this.selectedDate,
//     this.errorMessage,
//     this.successMessage,
//     this.currentSlotEntry,
//     this.currentSlotConsumption = 0.0,
//     this.currentSlotPercentage = 0.0,
//   });

//   HydrationState copyWith({
//     List<HydrationEntry>? entries,
//     int? totalDrank,
//     int? goal,
//     DateTime? selectedDate,
//     String? errorMessage,
//     String? successMessage,
//     HydrationEntry? currentSlotEntry,
//     double? currentSlotConsumption,
//     double? currentSlotPercentage,
//   }) {
//     return HydrationState(
//       entries: entries ?? this.entries,
//       totalDrank: totalDrank ?? this.totalDrank,
//       goal: goal ?? this.goal,
//       selectedDate: selectedDate ?? this.selectedDate,
//       errorMessage: errorMessage,
//       successMessage: successMessage,
//       currentSlotEntry: currentSlotEntry ?? this.currentSlotEntry,
//       currentSlotConsumption:
//           currentSlotConsumption ?? this.currentSlotConsumption,
//       currentSlotPercentage:
//           currentSlotPercentage ?? this.currentSlotPercentage,
//     );
//   }
// }
