import 'package:hydrify/models/hydration_entry.dart';

abstract class HydrationSync {
  void queueHydrationSlots(List<HydrationEntry> entries);
  Stream<List<HydrationEntry>> get hydrationUpdates;

  /// The current total hydration consumed today (ml), as reported by the BLE device.
  double get currentHydrationValue;
}
