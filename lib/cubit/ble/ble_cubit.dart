
// // -----------------------------------------------------------------------------
import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ble_state.dart';

/// Helper class to manage BLE notification state
class BleNotificationManager {
  final Map<Guid, bool> _notificationState = {};
  final Map<Guid, StreamSubscription<List<int>>> _subscriptions = {};

  bool isNotificationEnabled(Guid uuid) => _notificationState[uuid] ?? false;

  void setNotificationState(Guid uuid, bool enabled) {
    _notificationState[uuid] = enabled;
  }

  void addSubscription(Guid uuid, StreamSubscription<List<int>> subscription) {
    _subscriptions[uuid] = subscription;
  }

  void cancelSubscription(Guid uuid) {
    _subscriptions[uuid]?.cancel();
    _subscriptions.remove(uuid);
  }

  void cancelAllSubscriptions() {
    _subscriptions.forEach((_, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();
    _notificationState.clear();
  }
}

class BleCubit extends Cubit<BleState> implements HydrationSync {
  BleCubit() : super(const BleState());

  final _hydrationController =
      StreamController<List<HydrationEntry>>.broadcast();
  final BleNotificationManager _notificationManager = BleNotificationManager();
  final Map<Guid, int> _notificationRetryCount = {};
  static const int MAX_NOTIFICATION_RETRIES = 3;

  // BLE UUIDs
  final Guid serviceUUID = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid dataUUID = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid hydrationDataUUID = Guid("6E400004-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid ackUUID = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid hydrationCharUUID = Guid("6E400005-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid water30DaysDataUUID = Guid("6E400006-B5A3-F393-E0A9-E50E24DCCA9E");

  // BLE Characteristics
  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _ackChar;
  BluetoothCharacteristic? _hydrationDataChar;
  BluetoothCharacteristic? _hydrationChar;
  BluetoothCharacteristic? _hydration30DaysChar;

  // Subscriptions
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  // State
  String? savedDeviceName;
  String? savedDeviceId;
  final bool _isReconnecting = false;
  final dbHelper = DatabaseHelper();
  final List<HydrationEntry> _pendingSlots = [];

  // RTC Sync
  DateTime? _lastRtcSentAt;
  static const int RTC_SYNC_INTERVAL_SECONDS = 45;

  // ---------------------------------------------------------------------------
  // BLE Initialization and Scanning
  // ---------------------------------------------------------------------------

  Future<void> start() async {
    print("Started 1");
    emit(state.copyWith(
      status: BleStatus.initializing,
      message: "Initializing Bluetooth...",
    ));

    await _waitForBluetoothOn(() async {
      print("Started 6");

      final prefs = await SharedPreferences.getInstance();
      savedDeviceName = prefs.getString('last_device_name');
      savedDeviceId = prefs.getString('last_device_id');

      final bool isFirst = (savedDeviceName == null || savedDeviceId == null);
      emit(state.copyWith(
        status: BleStatus.initializing,
        message: "Initializing Bluetooth",
        isFirstConnection: isFirst,
      ));

      if (!isFirst) {
        print("Started 7");

        _scanForLastDevice();
      } else {
        print("Started 8");

        _scanForAllDevices();
      }
    });
  }

  Future<void> checkAndResetForNewDay(List<HydrationEntry> entry) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDate = await dbHelper.getLastSyncDate();

    // First ever launch
    if (lastDate == null) {
      await dbHelper.saveLastSyncDate(today);
      await dbHelper.clearHydrationSlots();

      for (final updatedEntry in entry) {
        await dbHelper.insertOrUpdateSlot(updatedEntry);
      }
      return;
    }

    // Same day → do nothing
    if (lastDate.isAtSameMomentAs(today)) {
      return;
    }

    // New day detected
    log(
      '[BLE_Cubit] New day detected. Resetting hydration slots.\n'
      'Last=$lastDate | Today=$today',
      name: 'BLE_Cubit',
    );

    // 1. Clear hydration slots
    await dbHelper.clearHydrationSlots();
    for (final updatedEntry in entry) {
      await dbHelper.insertOrUpdateSlot(updatedEntry);
    }

    // 2. Clear in-memory streams
    _hydrationController.add([]);

    // 3. Update last hydration date if significant volume was consumed
    // if ((state.volume ?? 0) > 600) {
    await dbHelper.saveLastSyncDate(today);
    // }

    // 4. Update UI state
    emit(state.copyWith(
      message: "New day started. Hydration reset.",
    ));
  }

  Future<void> _waitForBluetoothOn(Future<void> Function() onReady) async {
    print("Started 2");

    if (await FlutterBluePlus.isSupported == false) {
      print("Started 3");

      emit(state.copyWith(
        status: BleStatus.error,
        message: "Bluetooth not supported on this device",
      ));
      return;
    }

    final currentState = await FlutterBluePlus.adapterState.first;
    print("Started 4");

    if (currentState == BluetoothAdapterState.on) {
      print("Started 5");

      await onReady();
      return;
    }

    emit(state.copyWith(
      status: BleStatus.error,
      message: "Please turn on Bluetooth",
    ));

    // Wait for Bluetooth to be turned on
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 30), onTimeout: () {
      throw TimeoutException("Bluetooth not turned on within 30 seconds");
    });

    await onReady();
  }

  void _scanForLastDevice() {
    if (savedDeviceId == null && savedDeviceName == null) {
      _scanForAllDevices();
      return;
    }

    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge device...",
    ));

    _scanSub?.cancel();
    _notificationManager.cancelAllSubscriptions();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        // Filter for only Sipnudge devices
        final deviceName = r.device.name.toLowerCase();
        if (!deviceName.contains('sipnudge')) continue;

        if (r.device.id.id == savedDeviceId ||
            r.device.name == savedDeviceName) {
          _stopScanning();
          _connectToDevice(r.device);
          return;
        }
      }
    }, onError: (e) {
      log("Scan error: $e", name: "BLE_Cubit");
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Scan error: ${e.toString()}",
      ));
      _rescan(lastDeviceOnly: true);
    });

    // Timeout handler
    Future.delayed(const Duration(seconds: 20), () {
      if (state.status == BleStatus.scanning) {
        _stopScanning();
        _scanForLastDevice();
      }
    });
  }

  void _scanForAllDevices() {
    print("Started 9");

    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge devices...",
      scannedDevices: [],
    ));

    _scanSub?.cancel();
    _notificationManager.cancelAllSubscriptions();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
    print("Started 10");

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      print("Started 11");

      final filtered = results.where((it) {
        final name = it.device.name.toLowerCase();
        return name.contains('sipnudge');
      }).toList();

      if (filtered.isNotEmpty) {
        emit(state.copyWith(scannedDevices: filtered));
      }
    }, onError: (e) {
      log("Scan error: $e", name: "BLE_Cubit");
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Scan error: ${e.toString()}",
      ));
      _rescan();
    });

    // Timeout handler
    Future.delayed(const Duration(seconds: 20), () {
      if (state.status == BleStatus.scanning) {
        _stopScanning();
        _scanForAllDevices();
      }
    });
  }

  Future<void> _stopScanning() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      _scanSub?.cancel();
      _scanSub = null;
    } catch (e) {
      log("Error stopping scan: $e", name: "BLE_Cubit");
    }
  }

  Future<void> _rescan({
    bool lastDeviceOnly = false,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await _stopScanning();
    await Future.delayed(delay);

    if (lastDeviceOnly) {
      _scanForLastDevice();
    } else {
      _scanForAllDevices();
    }
  }

  // ---------------------------------------------------------------------------
  // BLE Connection
  // ---------------------------------------------------------------------------

  Future<void> connectToSelectedDevice(BluetoothDevice device) async {
    await _stopScanning();
    _connectToDevice(device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    emit(state.copyWith(
      status: BleStatus.connecting,
      message: "Connecting to ${device.name}...",
    ));

    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 6),
      );

      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));

      _setupConnectionMonitoring(device);

      final prefs = await SharedPreferences.getInstance();
      final wasFirst = (savedDeviceId == null || savedDeviceName == null);
      await prefs.setString('last_device_id', device.id.id);
      await prefs.setString('last_device_name', device.name);

      savedDeviceId = device.id.id;
      savedDeviceName = device.name;

      if (wasFirst) {
        emit(state.copyWith(isFirstConnection: false));
      }

      await _discoverServices(device);
      await prefs.setBool('ble_connected_once', true);
    } on TimeoutException {
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Connection timeout. Please try again.",
      ));
      await device.disconnect();
      _rescan(
          lastDeviceOnly: (savedDeviceId != null || savedDeviceName != null));
    } catch (e) {
      log("Connection failed: $e", name: "BLE_Cubit");
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Connection failed: ${e.toString()}",
      ));

      try {
        await device.disconnect();
      } catch (_) {}

      _rescan(
          lastDeviceOnly: (savedDeviceId != null || savedDeviceName != null));
    }
  }

  void _setupConnectionMonitoring(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((stateChange) {
      switch (stateChange) {
        case BluetoothConnectionState.connected:
          log("Device connected: ${device.name}", name: "BLE_Cubit");
          emit(state.copyWith(
            status: BleStatus.connected,
            message: "Connected to ${device.name}",
          ));
          break;

        case BluetoothConnectionState.disconnected:
          log("Device disconnected: ${device.name}", name: "BLE_Cubit");
          _notificationManager.cancelAllSubscriptions();
          _notificationRetryCount.clear();
          _lastRtcSentAt = null;

          emit(state.copyWith(
            status: BleStatus.disconnected,
            message: "Device disconnected",
          ));

          if (savedDeviceId != null || savedDeviceName != null) {
            Future.delayed(const Duration(seconds: 2), () {
              _rescan(lastDeviceOnly: true);
            });
          }
          break;

        case BluetoothConnectionState.connecting:
          emit(state.copyWith(
            status: BleStatus.connecting,
            message: "Reconnecting to ${device.name}...",
          ));
          break;

        default:
          break;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Service Discovery + Notification Setup
  // ---------------------------------------------------------------------------

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      log("Discovering services...", name: "BLE_Cubit");
      final services =
          await device.discoverServices().timeout(const Duration(seconds: 10));

      final service = services.firstWhere(
        (s) => s.uuid == serviceUUID,
        orElse: () => throw Exception('Required service not found'),
      );

      // Discover characteristics
      _discoverCharacteristics(service);

      // Validate required characteristics
      if (_dataChar == null || _ackChar == null) {
        await _handleMissingCharacteristics(device);
        return;
      }

      // Setup notifications in proper sequence
      await _setupAllNotifications(device);

      emit(state.copyWith(
        status: BleStatus.connected,
        message: "Connected to ${device.name}",
      ));

      await _flushPendingSlots();
    } on TimeoutException {
      log("Service discovery timeout", name: "BLE_Cubit");
      await _handleDiscoveryError(device, "Service discovery timeout");
    } catch (e) {
      log("Service discovery error: $e", name: "BLE_Cubit");
      await _handleDiscoveryError(device, e.toString());
    }
  }

  void _discoverCharacteristics(BluetoothService service) {
    for (var c in service.characteristics) {
      log("Found characteristic: ${c.uuid}", name: "BLE_Cubit");

      if (c.uuid == dataUUID) _dataChar = c;
      if (c.uuid == ackUUID) _ackChar = c;
      if (c.uuid == hydrationDataUUID) _hydrationDataChar = c;
      if (c.uuid == hydrationCharUUID) _hydrationChar = c;
      if (c.uuid == water30DaysDataUUID) _hydration30DaysChar = c;
    }
  }

  Future<void> _setupAllNotifications(BluetoothDevice device) async {
    try {
      log("Setting up notifications...", name: "BLE_Cubit");

      // Setup in priority order
      final notificationQueue = [
        if (_hydration30DaysChar != null) _setup30DaysNotifications(device),
        if (_hydrationChar != null) _setupHydrationSlotNotifications(device),
        if (_hydrationDataChar != null)
          _setupHydrationDataNotifications(device),
        if (_dataChar != null) _setupDataNotifications(device),
      ];

      await Future.wait(notificationQueue, eagerError: true);

      log("All notifications setup complete", name: "BLE_Cubit");
    } catch (e) {
      log("Notification setup failed: $e", name: "BLE_Cubit");
      rethrow;
    }
  }

  Future<void> _setupDataNotifications(BluetoothDevice device) async {
    await _enableCharacteristicNotification(
      device: device,
      characteristic: _dataChar!,
      onDataReceived: (value) => _handleMainData(value, device),
      retryCount: 0,
    );
  }

  Future<void> _setup30DaysNotifications(BluetoothDevice device) async {
    await _enableCharacteristicNotification(
      device: device,
      characteristic: _hydration30DaysChar!,
      onDataReceived: (value) => _handle30DaysData(value, device),
      retryCount: 0,
    );
  }

  Future<void> _setupHydrationSlotNotifications(BluetoothDevice device) async {
    await _enableCharacteristicNotification(
      device: device,
      characteristic: _hydrationChar!,
      onDataReceived: (value) => _handleHydrationSlotData(value, device),
      retryCount: 0,
    );
  }

  Future<void> _setupHydrationDataNotifications(BluetoothDevice device) async {
    await _enableCharacteristicNotification(
      device: device,
      characteristic: _hydrationDataChar!,
      onDataReceived: (value) => _handleHydrationData(value, device),
      retryCount: 0,
    );
  }

  Future<void> _enableCharacteristicNotification({
    required BluetoothDevice device,
    required BluetoothCharacteristic characteristic,
    required void Function(List<int> value) onDataReceived,
    int retryCount = 0,
  }) async {
    final uuid = characteristic.uuid;

    // Skip if already enabled
    if (_notificationManager.isNotificationEnabled(uuid)) {
      log("Notification already enabled for $uuid", name: "BLE_Cubit");
      return;
    }

    try {
      // Check if characteristic supports notifications
      if (!characteristic.properties.notify &&
          !characteristic.properties.indicate) {
        log("Characteristic $uuid doesn't support notifications/indications",
            name: "BLE_Cubit");
        return;
      }

      // Cancel any existing subscription
      _notificationManager.cancelSubscription(uuid);

      // Setup listener first
      final subscription = characteristic.onValueReceived.listen(
        onDataReceived,
        onError: (error) {
          log("Notification error for $uuid: $error", name: "BLE_Cubit");
          _notificationManager.setNotificationState(uuid, false);
        },
      );

      _notificationManager.addSubscription(uuid, subscription);

      // Enable notification with timeout
      log("Enabling notification for $uuid (attempt ${retryCount + 1})",
          name: "BLE_Cubit");

      await characteristic
          .setNotifyValue(true)
          .timeout(const Duration(seconds: 5));

      _notificationManager.setNotificationState(uuid, true);
      _notificationRetryCount.remove(uuid);

      log("Notification enabled successfully for $uuid", name: "BLE_Cubit");
    } on TimeoutException {
      log("Notification enable timeout for $uuid", name: "BLE_Cubit");
      _handleNotificationRetry(
        device: device,
        characteristic: characteristic,
        onDataReceived: onDataReceived,
        retryCount: retryCount,
      );
    } catch (e) {
      log("Failed to enable notification for $uuid: $e", name: "BLE_Cubit");
      _handleNotificationRetry(
        device: device,
        characteristic: characteristic,
        onDataReceived: onDataReceived,
        retryCount: retryCount,
      );
    }
  }

  void _handleNotificationRetry({
    required BluetoothDevice device,
    required BluetoothCharacteristic characteristic,
    required void Function(List<int> value) onDataReceived,
    required int retryCount,
  }) {
    final uuid = characteristic.uuid;
    final currentRetry = retryCount + 1;
    _notificationRetryCount[uuid] = currentRetry;

    if (currentRetry < MAX_NOTIFICATION_RETRIES) {
      log("Retrying notification for $uuid in 500ms (attempt $currentRetry)",
          name: "BLE_Cubit");

      Future.delayed(const Duration(milliseconds: 500), () {
        _enableCharacteristicNotification(
          device: device,
          characteristic: characteristic,
          onDataReceived: onDataReceived,
          retryCount: currentRetry,
        );
      });
    } else {
      log("Max retries reached for $uuid notification", name: "BLE_Cubit");
      emit(state.copyWith(
        message: "Warning: Some device features may not work properly",
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Data Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handle30DaysData(
      List<int> value, BluetoothDevice device) async {
    try {
      final data = String.fromCharCodes(value);
      log("Hydration 30 days Raw: $data", name: "BLE_Cubit");

      final parsed = _parse30DaysHydration(data);
      if (parsed.isNotEmpty) {
        final List<HydrationDaySummary> list = parsed.map((m) {
          final DateTime rawDate = m['date'] as DateTime;
          final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
          return HydrationDaySummary(
            date: date,
            dayIndex: m['dayIndex'] as int,
            target: (m['target'] as num).toDouble(),
            consumed: (m['consumed'] as num).toDouble(),
            deviceId: savedDeviceId,
          );
        }).toList();

        // Save to DB in bulk
        // if ((state.volume ?? 0) > 600) {
        await dbHelper.bulkUpsert30Days(list);
        // }

        emit(state.copyWith(
          isHydration30DaysDataSync: true,
          historyData: data,
        ));

        log("[BLE_Cubit] Saved ${list.length} day summaries to DB",
            name: "BLE_Cubit");

        // Debug output
        for (final day in list) {
          print("30d -> ${day.dayIndex} : ${day.date} "
              "target=${day.target} consumed=${day.consumed}  "
              "percentage ${(day.consumed / day.target) * 100}");
        }
      }

      await _sendAck(device);
    } catch (e) {
      log("Error handling 30-days data: $e", name: "BLE_Cubit");
    }
  }

  Future<void> _handleHydrationSlotData(
      List<int> value, BluetoothDevice device) async {
    try {
      final data = String.fromCharCodes(value);
      emit(state.copyWith(slotData: data));
      log("Hydration Slot Data: $data", name: "BLE_Cubit");

      final updatedEntries = _parseHydrationSlotData(data);
      // if (updatedEntries.isNotEmpty && ((state.volume ?? 0) > 600)) {
      await dbHelper.saveLastSyncDate(DateTime.now());
      _hydrationController.add(updatedEntries);

      for (final updatedEntry in updatedEntries) {
        await dbHelper.insertOrUpdateSlot(updatedEntry);
      }
      // }

      await _sendAck(device);
    } catch (e) {
      log("Error handling hydration slot data: $e", name: "BLE_Cubit");
    }
  }

  void _handleHydrationData(List<int> value, BluetoothDevice device) {
    try {
      final data = String.fromCharCodes(value);
      log("HydrationDataReceived: $data", name: "BLE_Cubit");
      var slots = _parseHydrationData(data);
      if (slots.isNotEmpty) _hydrationController.add(slots);
      _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
    } catch (e) {
      log("Error handling hydration data: $e", name: "BLE_Cubit");
    }
  }

  void _handleMainData(List<int> value, BluetoothDevice device) async {
    try {
      final data = String.fromCharCodes(value);
      log("Received main data: $data", name: "BLE_Cubit");

      _parseData(data);

      // Handle RTC sync if needed
      // await _handleRtcSync(data, device);
    } catch (e) {
      log("Error handling main data: $e", name: "BLE_Cubit");
    }
  }

  Future<void> _handleRtcSync(String data, BluetoothDevice device) async {
    try {
      if (_hydrationDataChar == null) return;

      DateTime? deviceDate;
      final parts = data.split(';');

      for (final p in parts) {
        if (p.startsWith('ts=')) {
          deviceDate = DateTime.tryParse(p.split('=')[1]);
          break;
        }
      }

      if (deviceDate == null) return;

      final now = DateTime.now();
      final diffInSeconds = now.difference(deviceDate).inSeconds.abs();

      // Check if we should send RTC update
      final canSendRtc = _lastRtcSentAt == null ||
          now.difference(_lastRtcSentAt!).inSeconds >=
              RTC_SYNC_INTERVAL_SECONDS;

      if (diffInSeconds >= 15 && canSendRtc) {
        _lastRtcSentAt = now;
        log("RTC sync needed: drift=$diffInSeconds seconds", name: "BLE_Cubit");

        final formattedNow = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        final rtcCommand = 'rtc/$formattedNow'.codeUnits;

        try {
          await _hydrationDataChar!.write(
            rtcCommand,
            withoutResponse: false,
          );
          log("RTC sync sent: $formattedNow", name: "BLE_Cubit");
        } catch (e) {
          log("RTC sync failed: $e", name: "BLE_Cubit");
        }
      }
    } catch (e) {
      log("RTC sync error: $e", name: "BLE_Cubit");
    }
  }

  // ---------------------------------------------------------------------------
  // Data Parsing
  // ---------------------------------------------------------------------------

  void _parseData(String data) {
    final parts = data.split(';');
    int? battery;
    double? volume;
    int? percent;

    for (var p in parts) {
      if (p.contains('battery=')) battery = int.tryParse(p.split('=')[1]);
      if (p.contains('volume=')) volume = double.tryParse(p.split('=')[1]);
      if (p.contains('percent=')) percent = int.tryParse(p.split('=')[1]);
    }

    emit(state.copyWith(
      battery: battery,
      volume: volume,
      percent: percent,
      bottleData: data,
    ));
  }

  List<HydrationEntry> _parseHydrationData(String payload) {
    if (payload.isEmpty || payload.toLowerCase() == "na") return [];
    return payload.split("|").map((entry) {
      final parts = entry.split("/");
      if (parts.length < 5) throw FormatException("Invalid payload: $entry");

      final index = int.parse(parts[1]);
      final startEpoch = int.parse(parts[2]);
      final endEpoch = int.parse(parts[3]);
      final amount = int.parse(parts[4]);

      final slot = HydrationSlot.values[index];
      return HydrationEntry(
        slot: slot,
        startTime: _epochToTimeOfDay(startEpoch),
        endTime: _epochToTimeOfDay(endEpoch),
        waterDrank: amount.toDouble(),
        amount: 0,
      );
    }).toList();
  }

  List<HydrationEntry> _parseHydrationSlotData(String payload) {
    final List<HydrationEntry> results = [];

    try {
      if (payload.isEmpty) return results;
      payload = payload.trim();

      final segments = payload.split('|');

      for (final seg in segments) {
        final s = seg.trim();
        if (s.isEmpty || s.toLowerCase() == 'na') continue;

        final parts = s.split('/');
        if (parts.length < 3) {
          log("Skipping malformed hydration segment: '$s'", name: "BLE_Cubit");
          continue;
        }

        final slotId = int.tryParse(parts[0].trim());
        final target = double.tryParse(parts[1].trim());
        final consumed = double.tryParse(parts[2].trim());

        if (slotId == null || target == null || consumed == null) {
          log("Failed to parse numbers in segment: '$s'", name: "BLE_Cubit");
          continue;
        }

        if (slotId < 0 || slotId >= HydrationSlot.values.length) {
          log("Invalid slot index $slotId in segment: '$s'", name: "BLE_Cubit");
          continue;
        }

        final slot = HydrationSlot.values[slotId];
        final now = DateTime.now();

        results.add(HydrationEntry(
          slot: slot,
          startTime: TimeOfDay(hour: now.hour, minute: now.minute),
          endTime: TimeOfDay(hour: now.hour, minute: (now.minute + 1) % 60),
          waterDrank: consumed,
          amount: target,
        ));
      }
    } catch (e) {
      log("Unexpected error parsing hydration slot data: $e",
          name: "BLE_Cubit");
    }

    return results;
  }

  List<Map<String, dynamic>> _parse30DaysHydration(String payload) {
    final List<Map<String, dynamic>> results = [];

    try {
      if (payload.isEmpty) return results;
      payload = payload.trim();

      final parts = payload.split('|').map((s) => s.trim()).toList();
      if (parts.isEmpty) return results;

      final epochToken = parts.first;
      final epochNum = int.tryParse(epochToken);

      if (epochNum == null) {
        log("Invalid epoch in 30-days payload: '$epochToken'",
            name: "BLE_Cubit");
        return results;
      }

      final epochMillis =
          (epochNum.toString().length == 13) ? epochNum : epochNum * 1000;

      DateTime startDate =
          DateTime.fromMillisecondsSinceEpoch(epochMillis).toLocal();

      log("30-days startDate parsed as: $startDate ($epochMillis ms)",
          name: "BLE_Cubit");

      final segments = parts.sublist(1);
      for (var seg in segments) {
        if (seg.isEmpty || seg.toLowerCase() == 'na') continue;

        final segParts = seg.split('/');
        if (segParts.length < 2) {
          log("Skipping malformed 30-days segment: '$seg'", name: "BLE_Cubit");
          continue;
        }

        int dayIndex;
        double target;
        double consumed;

        if (segParts.length >= 3) {
          dayIndex = int.tryParse(segParts[0].trim()) ?? -1;
          target = double.tryParse(segParts[1].trim()) ?? 0.0;
          consumed = double.tryParse(segParts[2].trim()) ?? 0.0;
        } else {
          final orderIndex = segments.indexOf(seg);
          dayIndex = orderIndex;
          target = double.tryParse(segParts[0].trim()) ?? 0.0;
          consumed = double.tryParse(segParts[1].trim()) ?? 0.0;
        }

        if (dayIndex < 0) {
          log("Invalid day index for segment '$seg' — skipping",
              name: "BLE_Cubit");
          continue;
        }

        final dayDate = startDate.add(Duration(days: dayIndex));
        final entry = {
          "dayIndex": dayIndex,
          "date": dayDate,
          "target": target,
          "consumed": consumed,
          "raw": seg,
        };

        log(
          "[30Days] Day ${dayIndex.toString().padLeft(2, '0')} | "
          "Date=${dayDate.toIso8601String().split('T').first} | "
          "Target=${target.toStringAsFixed(0)}ml | "
          "Consumed=${consumed.toStringAsFixed(0)}ml",
          name: "BLE_Cubit",
        );

        results.add(entry);
      }
    } catch (e) {
      log("Error parsing 30-days hydration payload: $e", name: "BLE_Cubit");
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // ACK Handling
  // ---------------------------------------------------------------------------

  Future<void> _sendAck(BluetoothDevice device,
      {bool sendAckToHydrationSlotsCharacteristic = false}) async {
    const maxRetries = 2;
    var ackBytes = "ACK".codeUnits;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (sendAckToHydrationSlotsCharacteristic &&
            _hydrationDataChar != null) {
          await _hydrationDataChar!.write(ackBytes, withoutResponse: true);
        } else if (_ackChar != null) {
          await _ackChar!.write(ackBytes, withoutResponse: true);
        }

        log("ACK sent successfully (attempt ${attempt + 1})",
            name: "BLE_Cubit");
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          log("ACK failed after $maxRetries attempts: $e", name: "BLE_Cubit");
        } else {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Error Handling
  // ---------------------------------------------------------------------------

  Future<void> _handleMissingCharacteristics(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_device_id');
    await prefs.remove('last_device_name');

    savedDeviceId = null;
    savedDeviceName = null;

    emit(state.copyWith(
      status: BleStatus.error,
      message: "Device incompatible. Required features not found.",
      isFirstConnection: true,
    ));

    try {
      await device.disconnect();
    } catch (_) {}

    _rescan(lastDeviceOnly: false);
  }

  Future<void> _handleDiscoveryError(
      BluetoothDevice device, String error) async {
    try {
      await device.disconnect();
    } catch (_) {}

    emit(state.copyWith(
      status: BleStatus.error,
      message: "Connection failed: $error",
    ));

    _rescan(lastDeviceOnly: savedDeviceId != null || savedDeviceName != null);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  int _timeOfDayToEpoch(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  TimeOfDay _epochToTimeOfDay(int epoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  Future<void> _flushPendingSlots() async {
    if (_ackChar == null || _pendingSlots.isEmpty) return;

    try {
      final payload = _pendingSlots.map((slot) {
        final start = _timeOfDayToEpoch(slot.startTime);
        final end = _timeOfDayToEpoch(slot.endTime);
        return "${slot.slot.label}/${slot.slot.index}/$start/$end/${slot.amount.toInt()}";
      }).join("|");

      log("Flushing hydration slots: $payload", name: "BLE_Cubit");

      final endTime = TimeOfDay(hour: 23, minute: 55);
      final flushPayload =
          "$payload|End/7/${_timeOfDayToEpoch(endTime)}/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 59))}/0";

      await _ackChar!.write(
        flushPayload.codeUnits,
        withoutResponse: true,
      );

      _pendingSlots.clear();

      emit(state.copyWith(
        message: "Hydration slots synced to device",
      ));
    } catch (e) {
      log("Flush failed: $e", name: "BLE_Cubit");
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Failed to sync slots: ${e.toString()}",
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<void> queueHydrationSlots(List<HydrationEntry> entries) async {
    _pendingSlots.clear();
    _pendingSlots.addAll(entries);

    if (state.status == BleStatus.connected) {
      await _flushPendingSlots();
    } else {
      emit(state.copyWith(
        message: "Device not connected. Slots will sync when connected.",
      ));
    }
  }

  Future<void> forgetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_device_id');
    await prefs.remove('last_device_name');

    savedDeviceId = null;
    savedDeviceName = null;

    await _stopScanning();
    _notificationManager.cancelAllSubscriptions();
    _notificationRetryCount.clear();
    _lastRtcSentAt = null;
    _pendingSlots.clear();

    emit(state.copyWith(
      status: BleStatus.scanning,
      isFirstConnection: true,
      scannedDevices: [],
      message: "Device forgotten. Ready to scan for new devices.",
    ));

    _scanForAllDevices();
  }

  Future<void> disconnect() async {
    try {
      final device = BluetoothDevice.fromId(savedDeviceId ?? '');
      await device.disconnect();
    } catch (_) {
      // Device already disconnected or not found
    }

    _notificationManager.cancelAllSubscriptions();
    _notificationRetryCount.clear();
    _lastRtcSentAt = null;

    emit(state.copyWith(
      status: BleStatus.disconnected,
      message: "Disconnected from device",
    ));
  }

  @override
  Stream<List<HydrationEntry>> get hydrationUpdates =>
      _hydrationController.stream;

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    log("Closing BleCubit...", name: "BLE_Cubit");

    _scanSub?.cancel();
    _connectionSub?.cancel();
    _notificationManager.cancelAllSubscriptions();
    _hydrationController.close();

    _notificationRetryCount.clear();
    _pendingSlots.clear();

    return super.close();
  }
}
