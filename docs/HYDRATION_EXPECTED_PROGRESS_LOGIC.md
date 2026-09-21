# 🌊 Hydration Expected Progress (Yellow Arc) Logic & Implementation Guide

> **Document Version:** 1.0  
> **Target Audience:** Frontend/Mobile Engineers (Flutter / iOS / Android / Web)  
> **Purpose:** Step-by-step technical and architectural specification to implement the **Expected Hydration Progress (Yellow Arc)** indicator alongside actual consumption.

---

## 1. Overview & Visual Architecture

The circular hydration widget uses a multi-layered arc progress system:

```
+-------------------------------------------------------------------+
|                        Circular Progress Indicator                |
|                                                                   |
|   Layer 1 (Bottom):   [=============================] White Base  |
|                       (100% full background track)                |
|                                                                   |
|   Layer 2 (Middle):   [==================]            Yellow Arc  |
|                       (Expected Cumulative Target %               |
|                        at Current Time, #FACC15)                  |
|                                                                   |
|   Layer 3 (Top):      [============]                  Blue Arc    |
|                       (Actual Consumed Intake %, #1C8DBB)         |
+-------------------------------------------------------------------+
```

### Visual Semantics for the User:
- **Blue < Yellow (Lagging behind):** The user is behind their scheduled hydration target. The yellow arc is visible ahead of the blue arc, prompting the user to drink.
- **Blue >= Yellow (On track / Ahead):** The blue actual intake arc covers/overlaps the yellow arc. The user is on track with or ahead of their schedule.

---

## 2. Core Hydration Slots Configuration

A user's daily hydration goal (e.g., $2500\text{ ml}$) is split across scheduled time windows throughout the day.

### Default Slot Distribution Table:

| Slot Enum | Slot Name | Start Time | End Time | Goal Weight (%) |
| :--- | :--- | :--- | :--- | :--- |
| `wakeup` | Wake Up | `07:00` | `08:00` | **25.0%** |
| `breakfast` | Breakfast | `08:30` | `09:30` | **12.5%** |
| `midMorning` | Mid-Morning | `11:00` | `11:30` | **12.5%** |
| `lunch` | Lunch | `13:00` | `14:00` | **12.5%** |
| `midAfternoon`| Mid-Afternoon | `16:00` | `16:30` | **12.5%** |
| `evening` | Evening | `18:00` | `19:00` | **12.5%** |
| `afterDinner` | After Dinner | `20:30` | `21:30` | **12.5%** |
| **Total** | | | | **100.0%** |

---

## 3. Mathematical Logic & Algorithm

### Inputs:
1. `slots`: List of `HydrationEntry` objects containing `startTime`, `endTime`, and `amount` (in ml).
2. `dailyGoalMl`: Total daily water goal in ml.
3. `now`: Current time (`TimeOfDay` or `DateTime`).

### Calculation Steps:

1. **Convert Current Time to Total Minutes:**
   $$\text{nowMinutes} = \text{now.hour} \times 60 + \text{now.minute}$$

2. **Sort Slots Chronologically by Start Time:**
   $$\text{slot.startMin} = \text{slot.startTime.hour} \times 60 + \text{slot.startTime.minute}$$
   $$\text{slot.endMin} = \text{slot.endTime.hour} \times 60 + \text{slot.endTime.minute}$$

3. **Compute Cumulative Target (`expectedCumulative`):**
   Iterate sequentially through each sorted slot:

   - **Case A — Slot is in the past (`nowMinutes >= slot.endMin`):**
     Add 100% of this slot's target:
     $$\text{expectedCumulative} = \text{expectedCumulative} + \text{slot.amount}$$

   - **Case B — Slot is currently active (`nowMinutes >= slot.startMin` AND `nowMinutes < slot.endMin`):**
     Progress smoothly and linearly from `startMin` to `endMin`:
     $$\text{duration} = \text{slot.endMin} - \text{slot.startMin}$$
     $$\text{elapsed} = \text{nowMinutes} - \text{slot.startMin}$$
     $$\text{progressRatio} = \frac{\text{elapsed}}{\text{duration}}$$
     $$\text{expectedCumulative} = \text{expectedCumulative} + (\text{slot.amount} \times \text{progressRatio})$$
     *Break loop immediately* (future slots have not started).

   - **Case C — Slot is in the future / Gap time (`nowMinutes < slot.startMin`):**
     *Break loop immediately*.
     *(Note: During gap periods between two slots, `expectedCumulative` remains static at the sum of all previously completed slots).*

4. **Compute Final Percentage:**
   $$\text{baseDenominator} = \sum \text{slot.amount} \quad (\text{or } \text{dailyGoalMl})$$
   $$\text{expectedPercentage} = \left( \frac{\text{expectedCumulative}}{\text{baseDenominator}} \times 100 \right)$$
   $$\text{finalExpectedPercentage} = \text{clamp}(\text{expectedPercentage}, 0.0, 100.0)$$

---

## 4. Concrete Example Walkthrough

Assume **Daily Goal = 2000 ml**:
- `Wakeup` target (07:00 - 08:00) = $2000 \times 0.25 = 500\text{ ml}$
- `Breakfast` target (08:30 - 09:30) = $2000 \times 0.125 = 250\text{ ml}$

| Time | `nowMinutes` | Active State | Expected Cumulative (ml) | Expected % (`yellowArc`) |
| :--- | :--- | :--- | :--- | :--- |
| **06:45 AM** | 405 | Before 1st slot | $0\text{ ml}$ | **0.0%** |
| **07:30 AM** | 450 | Mid Wakeup (30m/60m) | $500 \times \frac{30}{60} = 250\text{ ml}$ | $\frac{250}{2000} \times 100 = \mathbf{12.5\%}$ |
| **08:00 AM** | 480 | Wakeup finished | $500\text{ ml}$ | $\frac{500}{2000} \times 100 = \mathbf{25.0\%}$ |
| **08:15 AM** | 495 | Gap Time (No active slot) | Static at $500\text{ ml}$ | $\mathbf{25.0\%}$ |
| **09:00 AM** | 540 | Mid Breakfast (30m/60m) | $500 + (250 \times \frac{30}{60}) = 625\text{ ml}$ | $\frac{625}{2000} \times 100 = \mathbf{31.25\%}$ |
| **09:30 AM** | 570 | Breakfast finished | $500 + 250 = 750\text{ ml}$ | $\frac{750}{2000} \times 100 = \mathbf{37.5\%}$ |
| **10:00 PM** | 1320 | All slots completed | $2000\text{ ml}$ | **100.0%** |

---

## 5. Reference Code Implementation

### A. Data Calculator (`water_consumption_data_helper.dart`)

```dart
import 'package:flutter/material.dart';

class WaterConsumptionCalculator {
  /// Calculate cumulative expected slot target percentage at current time.
  static double calculateExpectedPercentage(
    List<HydrationEntry> slots,
    double dailyGoalMl, {
    TimeOfDay? nowTime,
  }) {
    if (dailyGoalMl <= 0 || slots.isEmpty) return 0.0;

    final now = nowTime ?? TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // Sort slots by start time
    final sortedSlots = List<HydrationEntry>.from(slots)..sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });

    final totalSlotsTarget = sortedSlots.fold<double>(0.0, (sum, s) => sum + s.amount);
    double expectedCumulative = 0.0;

    for (int i = 0; i < sortedSlots.length; i++) {
      final slot = sortedSlots[i];
      final startMin = slot.startTime.hour * 60 + slot.startTime.minute;
      final endMin = slot.endTime.hour * 60 + slot.endTime.minute;

      if (nowMinutes >= endMin) {
        // Slot has passed -> add full slot target
        expectedCumulative += slot.amount;
      } else if (nowMinutes >= startMin && nowMinutes < endMin) {
        // Currently active slot -> progress smoothly
        final duration = endMin - startMin;
        if (duration > 0) {
          final elapsed = nowMinutes - startMin;
          expectedCumulative += slot.amount * (elapsed / duration);
        }
        break; // Next slots haven't started
      } else {
        // In gap or before next slot
        break;
      }
    }

    final baseDenominator = totalSlotsTarget > 0 ? totalSlotsTarget : dailyGoalMl;
    return ((expectedCumulative / baseDenominator) * 100.0).clamp(0.0, 100.0);
  }
}
```

---

### B. Custom Canvas Painter (`custom_circular_water_progress_indicator.dart`)

```dart
import 'dart:math';
import 'package:flutter/material.dart';

class WaterArcPainter extends CustomPainter {
  final double percentage;          // Actual intake % (Blue)
  final double expectedPercentage;  // Expected target % (Yellow)
  final double strokeWidth;
  final Color baseArcColor;
  final Color progressColor;

  WaterArcPainter({
    required this.percentage,
    required this.expectedPercentage,
    this.strokeWidth = 8.0,
    this.baseArcColor = Colors.white,
    this.progressColor = const Color(0xFF1C8DBB),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflatedRect = rect.deflate(strokeWidth / 1.5);

    // Circle arc parameters (-60° to 240° -> 300° total sweep)
    final startAngle = -pi / 3;
    final sweepAngle = 5 * pi / 3;

    // 1. BASE WHITE ARC (100% Track)
    final baseArc = Paint()
      ..color = baseArcColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(deflatedRect, startAngle, sweepAngle, false, baseArc);

    // 2. EXPECTED TARGET YELLOW ARC (#FACC15)
    if (expectedPercentage > 0) {
      final yellowArc = Paint()
        ..color = const Color(0xFFFACC15)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final expectedSweep = sweepAngle * (expectedPercentage.clamp(0, 100) / 100);
      canvas.drawArc(deflatedRect, startAngle, expectedSweep, false, yellowArc);
    }

    // 3. ACTUAL INTAKE BLUE ARC (Drawn on top)
    final progressArc = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressSweep = sweepAngle * (percentage.clamp(0, 100) / 100);
    canvas.drawArc(deflatedRect, startAngle, progressSweep, false, progressArc);
  }

  @override
  bool shouldRepaint(covariant WaterArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.expectedPercentage != expectedPercentage;
  }
}
```

---

### C. UI Integration Snippet (`home_screen.dart`)

```dart
FutureBuilder<(double, double, double)>(
  future: () async {
    // 1. Actual Volume Drank
    final waterVolumeConsumed = await bottleDataCubit.getCurrentDayHistory(localOnly: true);
    final completionPercent = await WaterConsumptionCalculator.calculateCompletionPercentage(waterVolumeConsumed);

    // 2. Expected Percentage at Current Time
    final goalMl = await dbHelper.getDailyWaterGoal(DateTime.now()) ?? 2500;
    var slots = await dbHelper.getAllSlots();
    if (slots.isEmpty) {
      slots = HydrationHelper.generateHydrationSlots(goalMl.toDouble());
    }

    final expectedPercent = WaterConsumptionCalculator.calculateExpectedPercentage(
      slots,
      goalMl.toDouble(),
    );

    return (completionPercent, waterVolumeConsumed, expectedPercent);
  }(),
  builder: (context, snapshot) {
    final (completionPercent, waterVolumeConsumed, expectedPercent) =
        snapshot.data ?? (0.0, 0.0, 0.0);

    return CustomCircularWaterProgressIndicator(
      percentageValue: completionPercent,
      expectedPercentage: expectedPercent,
      // ...
    );
  },
);
```

---

## 6. Implementation Checklist for Other Developers / Platforms

- [ ] **Data Model:** Create a `HydrationSlot` model with `startHour`, `startMinute`, `endHour`, `endMinute`, and `targetAmount`.
- [ ] **Goal Distribution:** Split the daily goal into slots matching user schedule or standard defaults.
- [ ] **Calculator:** Implement the minute-based piecewise linear interpolation logic (`calculateExpectedPercentage`).
- [ ] **Painter:** Draw the **Base Arc**, then **Yellow Arc** (`#FACC15`), then **Blue Arc** (`#1C8DBB`) in sequential layers.
- [ ] **Trigger / Auto-Refresh:** Recompute `expectedPercentage` on app resume, time change (e.g. periodic timer / minute tick), and whenever water intake state updates.
