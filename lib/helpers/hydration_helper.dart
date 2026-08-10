import 'package:flutter/material.dart';
import 'package:hydrify/models/hydration_entry.dart';

class HydrationHelper {
  static List<HydrationEntry> generateHydrationSlots(double dailyGoal) {
    final slotPercentages = {
      HydrationSlot.wakeup: 0.25,
      HydrationSlot.breakfast: 0.125,
      HydrationSlot.midMorning: 0.125,
      HydrationSlot.lunch: 0.125,
      HydrationSlot.midAfternoon: 0.125,
      HydrationSlot.evening: 0.125,
      HydrationSlot.afterDinner: 0.125,
    };

    final slotTimes = {
      HydrationSlot.wakeup: TimeOfDayRange(
          start: const TimeOfDay(hour: 7, minute: 0),
          end: const TimeOfDay(hour: 8, minute: 0)),
      HydrationSlot.breakfast: TimeOfDayRange(
          start: const TimeOfDay(hour: 8, minute: 30),
          end: const TimeOfDay(hour: 9, minute: 30)),
      HydrationSlot.midMorning: TimeOfDayRange(
          start: const TimeOfDay(hour: 11, minute: 0),
          end: const TimeOfDay(hour: 11, minute: 30)),
      HydrationSlot.lunch: TimeOfDayRange(
          start: const TimeOfDay(hour: 13, minute: 0),
          end: const TimeOfDay(hour: 14, minute: 0)),
      HydrationSlot.midAfternoon: TimeOfDayRange(
          start: const TimeOfDay(hour: 16, minute: 0),
          end: const TimeOfDay(hour: 16, minute: 30)),
      HydrationSlot.evening: TimeOfDayRange(
          start: const TimeOfDay(hour: 18, minute: 0),
          end: const TimeOfDay(hour: 19, minute: 0)),
      HydrationSlot.afterDinner: TimeOfDayRange(
          start: const TimeOfDay(hour: 20, minute: 30),
          end: const TimeOfDay(hour: 21, minute: 30)),
    };

    List<HydrationEntry> slots = [];

    slotPercentages.forEach((slot, percent) {
      final amount = (dailyGoal * percent).round();
      final times = slotTimes[slot]!;
      slots.add(HydrationEntry(
        slot: slot,
        startTime: times.start,
        endTime: times.end,
        amount: amount.toDouble(),
        waterDrank: 0,
        status: HydrationStatus.pending,
      ));
    });

    return slots;
  }

  static String formatVolume(double ml, String unit, {bool showUnit = false}) {
    if (unit == "L") {
      final value = ml / 1000.0;
      final formatted =
          value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return showUnit ? "$formatted L" : formatted;
    } else if (unit == "US Oz") {
      final value = ml / 29.5735;
      final formatted = value.round().toString();
      return showUnit ? "$formatted US Oz" : formatted;
    } else if (unit == "UK Oz") {
      final value = ml / 28.4131;
      final formatted = value.round().toString();
      return showUnit ? "$formatted UK Oz" : formatted;
    } else {
      // mL
      final formatted = ml.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => "${m[1]},",
          );
      return showUnit ? "$formatted mL" : formatted;
    }
  }
}
