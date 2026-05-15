import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hydrify/helpers/logger.dart';

class InternetConnectionHelper {
  static final InternetConnectionHelper _instance =
      InternetConnectionHelper._internal();
  factory InternetConnectionHelper() => _instance;
  InternetConnectionHelper._internal();

  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get onInternetStatusChanged => _statusController.stream;

  /// Returns true if there is an active network connection (Wi-Fi, Mobile, etc.)
  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  /// Initialize the listener for connectivity changes
  void initialize() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = !results.contains(ConnectivityResult.none);
        Console.log(
            tag: "INTERNET",
            value: "Connectivity changed: $results (Has Internet: $hasConnection)");
        _statusController.add(hasConnection);
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
