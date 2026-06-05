import 'package:flutter/foundation.dart';

/// Lightweight event bus that fires whenever a full sync completes.
///
/// Any widget that needs to react to a sync (e.g. charts) should:
///   1. Add a listener in [initState].
///   2. Remove the listener in [dispose].
///
/// Example:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   SyncBus.instance.addListener(_onSync);
/// }
///
/// @override
/// void dispose() {
///   SyncBus.instance.removeListener(_onSync);
///   super.dispose();
/// }
///
/// void _onSync() => setState(() { /* invalidate cache */ });
/// ```
class SyncBus extends ChangeNotifier {
  SyncBus._();
  static final SyncBus instance = SyncBus._();

  /// Call this after every successful sync to notify all listeners.
  void notifySyncComplete() {
    notifyListeners();
  }
}
