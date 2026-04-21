import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Represents the completion status of a hydration slot.
enum HydrationStatus { pending, completed, ongoing }

/// Represents the different hydration slots during the day.
enum HydrationSlot {
  wakeup,
  breakfast,
  midMorning,
  lunch,
  midAfternoon,
  evening,
  afterDinner,
}

/// Extension methods for `HydrationSlot` to get labels and percentages.
extension HydrationSlotX on HydrationSlot {
  /// Human-readable label for each hydration slot.
  String get label {
    switch (this) {
      case HydrationSlot.wakeup:
        return 'Wakeup Time';
      case HydrationSlot.breakfast:
        return 'Breakfast Time';
      case HydrationSlot.midMorning:
        return 'Mid-Morning';
      case HydrationSlot.lunch:
        return 'Lunch Time';
      case HydrationSlot.midAfternoon:
        return 'Mid-Afternoon';
      case HydrationSlot.evening:
        return 'Evening';
      case HydrationSlot.afterDinner:
        return 'After Dinner';
    }
  }

  /// Percentage of daily hydration goal this slot represents.
  double get percentage {
    switch (this) {
      case HydrationSlot.wakeup:
        return 0.25; // 25%
      default:
        return 0.125; // 12.5%
    }
  }
}

/// Represents a single hydration entry for a time slot.
class HydrationEntry {
  final HydrationSlot slot;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double amount; // Target amount (mL)
  final double waterDrank; // Actual water consumed (mL)
  final double offslot; // Off-slot water consumed (mL)
  final HydrationStatus status;

  const HydrationEntry({
    required this.slot,
    required this.startTime,
    required this.endTime,
    required this.amount,
    this.waterDrank = 0.0,
    this.offslot = 0.0,
    this.status = HydrationStatus.pending,
  });

  HydrationEntry copyWith({
    HydrationSlot? slot,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    double? amount,
    double? waterDrank,
    double? offslot,
    HydrationStatus? status,
  }) {
    return HydrationEntry(
      slot: slot ?? this.slot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      amount: amount ?? this.amount,
      waterDrank: waterDrank ?? this.waterDrank,
      offslot: offslot ?? this.offslot,
      status: status ?? this.status,
    );
  }

  String get formattedRange =>
      "${_formatTime(startTime)} - ${_formatTime(endTime)}";

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  @override
  List<Object?> get props => [
        slot,
        startTime.hour,
        startTime.minute,
        endTime.hour,
        endTime.minute,
        amount,
        waterDrank,
        offslot,
        status,
      ];

  // @override
  // List<Object> get props =>
  //     [slot, startTime, endTime, amount, waterDrank, status];
}

/// Represents a time range in the day.
class TimeOfDayRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeOfDayRange({required this.start, required this.end});
}
