# iOS Live Activities & Dynamic Island Specification for Sipnudge

## 1. Overview
This document outlines the architecture, user flows, and technical implementation strategy for integrating **iOS Live Activities** and **Dynamic Island** support into the **Sipnudge** Flutter application.

---

## 2. Core Concepts
* **Live Activities (Lock Screen):** Persistent, glanceable real-time widgets on the iPhone Lock Screen (iOS 16.1+).
* **Dynamic Island:** Real-time pill / bubble on iPhone 14 Pro, iPhone 15/16 series at the top of the display while navigating other apps.
* **Interactive Widgets (iOS 17+):** Buttons directly on the widget to trigger quick actions (e.g. `+250ml`) without opening the full application.

---

## 3. Sipnudge Use Cases

### A. Live Daily Hydration Tracker
* Displays real-time daily progress: `💧 1,400 / 3,190 ml (44%)`.
* Visual progress bar filling up as user logs intake.
* Status message / Smart Nudge countdown: *"Next sip in 25 mins"*.

### B. Dynamic Island Views
1. **Compact State (Default):**
   * Leading: 💧 Droplet icon
   * Trailing: `60%` or `1.8L`
2. **Minimal State (Multi-tasking):**
   * Small isolated circular badge with hydration progress.
3. **Expanded State (Long Press):**
   * Complete progress bar with target.
   * Quick-add logging buttons (`+150ml`, `+250ml`, `+500ml`).
   * Tap opens the full Sipnudge app.

### C. 1-Tap Quick Logging (Zero-Friction UX)
* User logs water intake directly from the Lock Screen widget or Dynamic Island via App Intents (iOS 17+).

### D. Smart Bottle (BLE) Sync Integration
* When the user sips from their smart bottle:
  1. Smart bottle detects sip quantity via sensor.
  2. Sends BLE payload to iPhone (CoreBluetooth background execution).
  3. Sipnudge background handler receives BLE data, saves to local DB.
  4. ActivityKit updates the Lock Screen & Dynamic Island widget instantly (`+220ml from Bottle ✨`).
  5. Displays bottle connection status (`🟢 Bottle Connected`, `🪫 Low Battery`).

### E. Inactivity Nudges & Gamification
* If no water is logged for >2 hours, the widget switches to an alert state / thirsty mascot.
* When 100% daily target is achieved, displays a celebration state (`Goal Complete 🎉`).

---

## 4. End-to-End User Flow

1. **Permission / Opt-in:**
   * iOS prompt: *"Allow Live Activities from Sipnudge?"* (Triggered during onboarding or reminder setup).
2. **Morning Activation:**
   * Live Activity starts at wake-up time or when the first drink is recorded.
3. **Intraday Tracking & Logging:**
   * Real-time progress updates via manual 1-tap lock screen buttons, in-app logs, or automatic Smart Bottle BLE sync.
4. **Bedtime / Goal End (Auto-Dismiss):**
   * Automatically dismisses at bedtime or end of active hydration window to keep the lock screen clean.

---

## 5. Technical Implementation Architecture

```
┌────────────────────────────────────────────────────────┐
│                   Flutter App (Dart)                   │
│   - Hydration State Management (Bloc / Provider)       │
│   - BLE Background Sync Service                        │
│   - Live Activity Controller (live_activities package) │
└───────────────────────────┬────────────────────────────┘
                            │ MethodChannel / ActivityKit Bridge
┌───────────────────────────▼────────────────────────────┐
│              iOS Native Widget Extension               │
│   - ActivityAttributes (Static data: Goal, UserID)     │
│   - ContentState (Dynamic data: CurrentML, NextSipTime)│
│   - SwiftUI Widget View (Lock Screen layout)           │
│   - DynamicIsland View (Compact, Minimal, Expanded)    │
│   - AppIntents (for interactive 1-tap quick log buttons│
└────────────────────────────────────────────────────────┘
```

### Dependencies to Evaluate:
* [`live_activities`](https://pub.dev/packages/live_activities) Flutter plugin for ActivityKit lifecycle management.
* Custom Swift Widget Extension using `WidgetKit`, `ActivityKit`, and `AppIntents`.
* App Groups (`group.com.sipnudge.app`) for shared storage between Flutter app and Widget extension.

---

## 6. Status
* **Status:** 📋 Backlog / Planned for future release.
* **Target Version:** Post-MVP iOS Enhancement.
