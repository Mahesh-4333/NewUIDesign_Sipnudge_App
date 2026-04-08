import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ble_state.dart';

class BleCubit extends Cubit<BleState> implements HydrationSync {
  BleCubit() : super(const BleState());
  final _healthService = HealthService();
  final _hydrationController =
      StreamController<List<HydrationEntry>>.broadcast();

  final Guid serviceUUID = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid dataUUID = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid hydrationGoalDataUUID =
      Guid("6E400004-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid ackUUID = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  final Guid hydrationSlotsUUID = Guid("6E400005-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid water30DaysDataUUID = Guid("6E400006-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid configUUID = Guid("6E400007-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid resetUUID = Guid("6E400008-B5A3-F393-E0A9-E50E24DCCA9E");

  final Guid rtcSyncUUID = Guid("6E400004-B5A3-F393-E0A9-E50E24DCCA9E");

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _ackChar;
  BluetoothCharacteristic? _hydrationGoalDataChar;
  BluetoothCharacteristic? _hydrationSlotsChar;
  BluetoothCharacteristic? _hydration30DaysChar;
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _resetChar;
  BluetoothCharacteristic? _rtcSyncChar;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

  // Track characteristic value notifications to avoid duplicate listeners
  StreamSubscription? _dataSub;
  StreamSubscription? _hydrationGoalDataSub;
  StreamSubscription? _hydrationSlotsSub;
  StreamSubscription? _hydration30DaysSub;

  String? savedDeviceName;
  String? savedDeviceId;

  /// Guards against concurrent connection attempts.
  bool _isConnecting = false;

  /// Set to true when a scan is intentionally stopped (device found / connected)
  /// so that the delayed-restart lambda is a no-op.
  bool _scanCancelled = false;

  /// Current retry count for exponential back-off in [_rescan].
  int _scanRetryCount = 0;

  /// Guards against multiple initialization calls to start()
  bool _isInitialized = false;

  final dbHelper = DatabaseHelper();
  final List<HydrationEntry> _pendingSlots = [];

  int _investorDayIncrement = 0;

  /// Implements [HydrationSync.currentHydrationValue].
  /// Returns the latest total hydration consumed today (ml) from BLE state.
  @override
  double get currentHydrationValue => state.currentHydrationValue;

  /// Requests all permissions sequentially for better UX.
  /// Bluetooth → Location → Notification
  Future<void> requestAllPermissionsSequentially() async {
    try {
      Console.log(
          tag: '[BLE_Cubit] Starting sequential permission flow',
          value: 'BLE_Cubit');

      // 1. BLUETOOTH PERMISSIONS
      Console.log(
          tag: '[BLE_Cubit] Requesting Bluetooth permissions...',
          value: 'BLE_Cubit');

      if (!await Permission.bluetooth.isGranted) {
        emit(state.copyWith(
          status: BleStatus.initializing,
          message: "Bluetooth permission required...",
        ));
        await Permission.bluetooth.request();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      if (!await Permission.bluetoothScan.isGranted) {
        emit(state.copyWith(
          status: BleStatus.initializing,
          message: "Bluetooth scan permission required...",
        ));
        await Permission.bluetoothScan.request();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      if (!await Permission.bluetoothConnect.isGranted) {
        emit(state.copyWith(
          status: BleStatus.initializing,
          message: "Bluetooth connect permission required...",
        ));
        await Permission.bluetoothConnect.request();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      if (!await Permission.bluetoothAdvertise.isGranted) {
        emit(state.copyWith(
          status: BleStatus.initializing,
          message: "Bluetooth advertise permission required...",
        ));
        await Permission.bluetoothAdvertise.request();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      Console.log(
          tag: '[BLE_Cubit] Bluetooth permissions granted', value: 'BLE_Cubit');

      // 2. LOCATION PERMISSION
      Console.log(
          tag: '[BLE_Cubit] Requesting Location permission...',
          value: 'BLE_Cubit');

      emit(state.copyWith(
        status: BleStatus.initializing,
        message: "Location permission required for weather...",
      ));

      final locationPermission = await Permission.locationWhenInUse.status;
      if (!locationPermission.isGranted) {
        await Permission.locationWhenInUse.request();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      Console.log(
          tag: '[BLE_Cubit] Location permission granted', value: 'BLE_Cubit');

      // 3. NOTIFICATION PERMISSION
      Console.log(
          tag: '[BLE_Cubit] Requesting Notification permission...',
          value: 'BLE_Cubit');

      emit(state.copyWith(
        status: BleStatus.initializing,
        message: "Notification permission required for reminders...",
      ));

      final notificationPermission = await Permission.notification.status;
      if (!notificationPermission.isGranted) {
        await Permission.notification.request();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      Console.log(
          tag: '[BLE_Cubit] Notification permission granted',
          value: 'BLE_Cubit');
      Console.log(
          tag: '[BLE_Cubit] All permissions completed successfully',
          value: 'BLE_Cubit');
    } catch (e) {
      Console.log(
          tag: '[BLE_Cubit] Permission request error: $e', value: 'BLE_Cubit');
    }
  }

  // ---------------------------------------------------------------------------
  // BLE initialization and scanning
  // ---------------------------------------------------------------------------
  // BLE initialization and scanning
  // ---------------------------------------------------------------------------

  // investor bottle 3 day before
  // new bottle 1 day before
  // tap bottle 0 day before

  Future<void> start() async {
    if (_isInitialized) {
      Console.log(
          tag: '[BLE_Cubit] start() already called, ignoring duplicate call',
          value: 'BLE_Cubit');
      return;
    }

    // await _checkAndResetForNewDay();

    // await _fetchInvestorDayIncrement();

    emit(state.copyWith(
      status: BleStatus.initializing,
      message: "Initializing...",
    ));

    // Request ALL permissions sequentially: Bluetooth → Location → Notification
    await requestAllPermissionsSequentially();

    _isInitialized = true;

    await _waitForBluetoothOn(() async {
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
        _scanForLastDevice();
      } else {
        _scanForAllDevices();
      }
    });
  }

  /// Fetches the investor day increment from the remote API.
  /// Falls back to the default value of 4 if the request fails.
  Future<void> _fetchInvestorDayIncrement() async {
    try {
      final uri = Uri.parse('https://api.pinktreehealth.com/api/dayIncrement');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['status'] == true && json['data'] != null) {
          _investorDayIncrement = (json['data'] as num).toInt();
          Console.log(
              tag:
                  '[BLE_Cubit] _investorDayIncrement set to $_investorDayIncrement from API',
              value: 'BLE_Cubit');
          return;
        }
      }
    } catch (e) {
      Console.log(
          tag:
              '[BLE_Cubit] _fetchInvestorDayIncrement failed: $e — using default 4',
          value: 'BLE_Cubit');
    }
    _investorDayIncrement = 4;
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

    // 🔥 NEW DAY DETECTED
    Console.log(
        tag: '[BLE_Cubit] New day detected. Resetting hydration slots.\n'
            'Last=$lastDate | Today=$today',
        value: 'BLE_Cubit');

    // 1️⃣ Clear hydration slots
    await dbHelper.clearHydrationSlots();
    for (final updatedEntry in entry) {
      await dbHelper.insertOrUpdateSlot(updatedEntry);
    } // 2️⃣ Clear in-memory streams
    _hydrationController.add([]);
    // if ((state.volume ?? 0) > 600) {
    // 3️⃣ Update last hydration date
    await dbHelper.saveLastSyncDate(today);
    // }

    // 4️⃣ Update UI state (optional but recommended)
    emit(state.copyWith(
      message: "New day started. Hydration reset.",
    ));
  }

  Future<void> _waitForBluetoothOn(Future<void> Function() onReady) async {
    if (await FlutterBluePlus.isSupported == false) {
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Bluetooth not supported",
      ));
      return;
    }

    final currentState = await FlutterBluePlus.adapterState.first;
    if (currentState == BluetoothAdapterState.on) {
      await onReady();
    } else {
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Please turn on Bluetooth",
      ));

      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;

      await onReady();
    }

    // ✅ Keep listening so that if BT is toggled off→on again we recover
    //    automatically without requiring an app restart.
    _adapterStateSub?.cancel();
    _adapterStateSub =
        FlutterBluePlus.adapterState.listen((adapterState) async {
      if (adapterState == BluetoothAdapterState.off) {
        // BT was switched off — stop any in-progress scan and surface the error
        _scanCancelled = true;
        _isConnecting = false;
        _scanSub?.cancel();
        if (FlutterBluePlus.isScanningNow) {
          try {
            await FlutterBluePlus.stopScan();
          } catch (_) {}
        }
        emit(state.copyWith(
          status: BleStatus.error,
          message: "Bluetooth turned off",
        ));
      } else if (adapterState == BluetoothAdapterState.on) {
        // BT came back on — restart the full flow
        Console.log(
            tag: '[BLE_Cubit] Bluetooth re-enabled — restarting scan',
            value: 'BLE_Cubit');
        _scanRetryCount = 0;
        await onReady();
      }
    });
  }

  void _scanForLastDevice() {
    if (savedDeviceId == null && savedDeviceName == null) return;

    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge device...",
    ));

    _scanCancelled = false;
    _scanSub?.cancel();

    // ✅ Use withServices filter so the OS pre-filters ads for our UART service
    //    (reduces packet drops on Android; iOS still scans all but ranks better).
    // ✅ Longer timeout (30 s) gives more advertising cycles to be caught.
    try {
      FlutterBluePlus.startScan(
        withServices: [serviceUUID],
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      Console.log(
          tag: '[BLE_Cubit] Failed to start scan: $e', value: 'BLE_Cubit');
      _rescan(lastDeviceOnly: true);
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      // ✅ Guard: skip if already connecting to avoid concurrent attempts
      if (_isConnecting) return;

      for (var r in results) {
        final deviceName = r.device.platformName.toLowerCase();
        if (!deviceName.contains('sipnudge')) continue;

        bool match = false;
        // Prefer ID match; fall back to name only when ID is absent
        if (savedDeviceId != null && savedDeviceId!.isNotEmpty) {
          match = (r.device.remoteId.str == savedDeviceId);
        } else if (savedDeviceName != null && savedDeviceName!.isNotEmpty) {
          match = (r.device.platformName == savedDeviceName);
        }

        if (match) {
          // ✅ Mark cancelled so the delayed-rescan lambda is a no-op
          _scanCancelled = true;
          _scanSub?.cancel();
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          return;
        }
      }
    }, onError: (e) {
      Console.log(tag: '[BLE_Cubit] Scan error: $e', value: 'BLE_Cubit');
      emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
      _rescan(lastDeviceOnly: true);
    });

    // ✅ Restart scan after timeout ONLY if we haven't already connected
    Future.delayed(const Duration(seconds: 30), () {
      if (!_scanCancelled && state.status == BleStatus.scanning) {
        Console.log(
            tag: '[BLE_Cubit] Scan timeout — restarting scan for last device',
            value: 'BLE_Cubit');
        _scanForLastDevice();
      }
    });
  }

  void _scanForAllDevices() {
    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge devices...",
    ));

    _scanCancelled = false;
    _scanSub?.cancel();

    // ✅ Use withServices filter; 30 s gives more ad cycles
    try {
      FlutterBluePlus.startScan(
        withServices: [serviceUUID],
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      Console.log(
          tag: '[BLE_Cubit] Failed to start all-device scan: $e',
          value: 'BLE_Cubit');
      _rescan();
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        var filtered = results.where((it) {
          final name = it.device.platformName.toLowerCase();
          return name.contains('sipnudge');
        }).toList();

        if (filtered.isNotEmpty) {
          emit(state.copyWith(scannedDevices: filtered));
        }
      }
    }, onError: (e) {
      Console.log(tag: '[BLE_Cubit] Scan error (all): $e', value: 'BLE_Cubit');
      emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
      _rescan();
    });

    // ✅ Restart scan after timeout ONLY if we are still in scanning state
    Future.delayed(const Duration(seconds: 30), () async {
      if (!_scanCancelled && state.status == BleStatus.scanning) {
        log('[BLE_Cubit] Scan timeout — restarting all-device scan',
            name: 'BLE_Cubit');
        _scanForAllDevices();
      }
    });
  }

  Future<void> _rescan({
    bool lastDeviceOnly = false,
  }) async {
    if (FlutterBluePlus.isScanningNow) return;

    // ✅ Exponential back-off: 200 ms → 400 → 800 → ... → 8 000 ms
    final delayMs = (200 * (1 << _scanRetryCount)).clamp(200, 8000);
    _scanRetryCount++;
    Console.log(
        tag: '[BLE_Cubit] _rescan attempt $_scanRetryCount, delay ${delayMs}ms',
        value: 'BLE_Cubit');
    await Future.delayed(Duration(milliseconds: delayMs));

    if (lastDeviceOnly) {
      _scanForLastDevice();
    } else {
      _scanForAllDevices();
    }
  }

  // ---------------------------------------------------------------------------
  // BLE connection
  // ---------------------------------------------------------------------------

  Future<void> connectToSelectedDevice(BluetoothDevice device) async {
    _scanCancelled = true;
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _connectToDevice(device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // ✅ Guard: prevent concurrent connection attempts
    if (_isConnecting) {
      Console.log(
          tag:
              '[BLE_Cubit] _connectToDevice called while already connecting — ignored',
          value: 'BLE_Cubit');
      return;
    }
    _scanCancelled = true;
    _isConnecting = true;
    _scanRetryCount = 0; // reset back-off counter on a fresh connection attempt

    emit(state.copyWith(
      status: BleStatus.connecting,
      message: "Connecting to ${device.platformName}...",
    ));

    try {
      // ✅ Increased timeout: iOS sometimes needs 10-15 s on first connect
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );
      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first;

      _listenToConnection(device);

      final prefs = await SharedPreferences.getInstance();
      final wasFirst = (savedDeviceId == null || savedDeviceName == null);
      Console.log(
          tag:
              "=-=-=-=-=-=-=-=-=- Was first ${wasFirst} -=-=-=-=-=-=-=-=-=-=-=-=-=-=-",
          value: 'BLE_Cubit');
      await prefs.setString('last_device_id', device.remoteId.str);
      await prefs.setString('last_device_name', device.advName);

      savedDeviceId = device.remoteId.str;
      savedDeviceName = device.platformName;

      Console.log(
          tag: "device.remoteId.str_123",
          value: "${device.remoteId.str} ${device.advName}");
      if (wasFirst) emit(state.copyWith(isFirstConnection: false));

      Console.log(tag: '[BLE_Cubit] Connection SUCCESS', value: 'BLE_Cubit');

      // ✅ Request MTU (223 bytes) for better data throughput
      try {
        await device.requestMtu(223);
        Console.log(
            tag: '[BLE_Cubit] MTU requested (max 223)', value: 'BLE_Cubit');
      } catch (e) {
        Console.log(
            tag: '[BLE_Cubit] MTU request failed: $e', value: 'BLE_Cubit');
      }

      await _discoverServices(device);
      await prefs.setBool('ble_connected_once', true);
    } catch (e) {
      Console.log(tag: '[BLE_Cubit] Connection failed: $e', value: 'BLE_Cubit');
      emit(state.copyWith(
          status: BleStatus.error, message: "Connection failed: $e"));
      _rescan(
          lastDeviceOnly: (savedDeviceId != null || savedDeviceName != null));
    } finally {
      // ✅ Always clear the guard so future attempts are allowed
      _isConnecting = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Service Discovery + Notification setup
  // ---------------------------------------------------------------------------

  //E7FBFB7A-BFB5-26A1-ABD0-C8B2E380AFCD bottle 1
  //94B76983-3096-9E5D-B60C-E68A19CCD1B3 bottle 2

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (var s in services) {
        final bool isMainService = (s.uuid == serviceUUID);
        for (var c in s.characteristics) {
          // Dynamic assignment for Sipnudge main service
          if (isMainService) {
            if (c.uuid == dataUUID) _dataChar = c;
            if (c.uuid == ackUUID) _ackChar = c;
            if (c.uuid == hydrationGoalDataUUID) _hydrationGoalDataChar = c;
            if (c.uuid == rtcSyncUUID) _rtcSyncChar = c;
            if (c.uuid == hydrationSlotsUUID) _hydrationSlotsChar = c;
            if (c.uuid == water30DaysDataUUID) _hydration30DaysChar = c;
            if (c.uuid == configUUID) _configChar = c;
            if (c.uuid == resetUUID) _resetChar = c;
          }

          // Setup notifications and log characteristic status
          final props = c.properties;
          List<String> supported = [];

          if (props.notify || props.indicate) supported.add("Notify");
          if (props.read) supported.add("Read");
          if (props.write || props.writeWithoutResponse) supported.add("Write");

          if (supported.isNotEmpty) {
            String charName = "";
            if (isMainService) {
              if (c.uuid == dataUUID)
                charName = " [Data]";
              else if (c.uuid == ackUUID)
                charName = " [Ack]";
              else if (c.uuid == hydrationGoalDataUUID)
                charName = " [Goal]";
              else if (c.uuid == rtcSyncUUID)
                charName = " [RTC]";
              else if (c.uuid == hydrationSlotsUUID)
                charName = " [Slots]";
              else if (c.uuid == water30DaysDataUUID)
                charName = " [30Days]";
              else if (c.uuid == configUUID)
                charName = " [Config]";
              else if (c.uuid == resetUUID) charName = " [Reset]";
            }

            final logTag = supported.contains("Notify") ? "✅" : "✍️";
            print(
                "$logTag Found Characteristic${charName}: ${c.uuid} | ${supported.join(' | ')}");
          } else {
            print("⛔ Characteristic ${c.uuid}: No common properties");
          }
        }
      }

      // ✅ Clear any old characteristic-specific subscriptions before adding new ones
      _clearCharacteristicSubscriptions();

      // Final availability check for critical characteristics
      if (_dataChar == null || _ackChar == null) {
        String missing = "";
        if (_dataChar == null) missing += " [Data] ";
        if (_ackChar == null) missing += " [Ack] ";

        Console.log(
            tag: "❌ Missing Required Characteristics: $missing",
            value: 'BLE_Cubit');

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_device_id');
        await prefs.remove('last_device_name');

        savedDeviceId = null;
        savedDeviceName = null;

        emit(state.copyWith(
          status: BleStatus.error,
          message: "Required characteristics not found: $missing",
          isFirstConnection: true,
        ));

        await device.disconnect();
        _rescan(lastDeviceOnly: false);
        return;
      }

      Console.log(
          tag: "✅ All critical characteristics confirmed.", value: 'BLE_Cubit');
      emit(state.copyWith(isServiceDiscoveryDone: true));

      // ✅ 1. Register all listeners BEFORE enabling notifications
      if (_hydration30DaysChar != null) {
        _hydration30DaysSub =
            _hydration30DaysChar!.onValueReceived.listen((value) async {
          try {
            await dbHelper.clearHydrationDaySummaries();
            final data = String.fromCharCodes(value);
            Console.log(
                tag: "⬇️ [30_DAYS] Raw Data: $data", value: 'BLE_Cubit');
            final parsed = await _parse30DaysHydration(data);
            if (parsed.isNotEmpty) {
              final List<HydrationDaySummary> list = parsed.map((m) {
                final DateTime rawDate = m['date'] as DateTime;
                final date = DateTime(rawDate.year, rawDate.month,
                    rawDate.day + _investorDayIncrement);
                final targetVal = (m['target'] as num).toDouble();
                final consumedVal = (m['consumed'] as num).toDouble();
                final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;
                return HydrationDaySummary(
                  date: date,
                  dayIndex: m['dayIndex'] as int,
                  target: targetVal,
                  consumed: consumedVal,
                  deviceId: savedDeviceId,
                  isPerfect: isPerfectDay,
                );
              }).toList();
              await dbHelper.bulkUpsert30Days(list);
              await Future.delayed(Duration(seconds: 1));
              final history = await getCurrentDayHistory();
              emit(state.copyWith(currentHydrationValue: history));
              final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();
              if (stopWhenFull) {
                final completionPercent = await WaterConsumptionCalculator
                    .calculateCompletionPercentage(history);
                if (completionPercent >= 100) {
                  final notificationService = NotificationService();
                  for (final slot in HydrationSlot.values) {
                    await notificationService.cancelSlotReminders(slot, 0);
                  }
                }
              }
              emit(state.copyWith(
                  isHydration30DaysDataSync: true, historyData: data));
              _hydrationController.add([]);
              _syncWithHealth(history);
            }
            _sendAck(device);
          } catch (e) {
            print("========> error ${e.toString()}");
          }
        });
      }

      if (_hydrationSlotsChar != null) {
        _hydrationSlotsSub =
            _hydrationSlotsChar!.onValueReceived.listen((value) async {
          final data = String.fromCharCodes(value);
          emit(state.copyWith(slotData: data));
          Console.log(tag: "⬇️ [SLOTS] Raw Data: $data", value: 'BLE_Cubit');
          final updatedEntries = await _parseHydrationSlotData(data);
          if (updatedEntries.isNotEmpty) {
            await dbHelper.saveLastSyncDate(DateTime.now());
            _hydrationController.add(updatedEntries);
            for (final updatedEntry in updatedEntries) {
              await dbHelper.insertOrUpdateSlot(updatedEntry);
            }
          }
          _sendAck(device);
        });
      }

      if (_hydrationGoalDataChar != null) {
        _hydrationGoalDataSub =
            _hydrationGoalDataChar!.onValueReceived.listen((value) {
          final data = String.fromCharCodes(value);
          Console.log(tag: "⬇️ [GOAL] Raw Data: $data", value: 'BLE_Cubit');
          var slots = _parseHydrationData(data);
          if (slots.isNotEmpty) _hydrationController.add(slots);
          _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
        });
      }

      if (_dataChar != null) {
        _dataSub = _dataChar!.onValueReceived.listen((value) {
          final data = String.fromCharCodes(value);
          Console.log(
              tag: "⬇️ [DATA_CHAR] Raw Data: $data", value: 'BLE_Cubit');
          _parseData(data);
          _sendAck(device);
        });
      }

      // ✅ 2. Now enable notifications for ALL characteristics across all services
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            try {
              await c.setNotifyValue(true);
              Console.log(
                  tag: "[BLE_Cubit]  enable notify for ${c.uuid}",
                  value: 'BLE_Cubit');
            } catch (e) {
              Console.log(
                  tag: "[BLE_Cubit] Failed to enable notify for ${c.uuid}: $e",
                  value: 'BLE_Cubit');
            }
          }
        }
      }

      // ✅ 3. Perform an initial manual read of _dataChar to get status immediately
      if (_dataChar != null && _dataChar!.properties.read) {
        try {
          final val = await _dataChar!.read();
          if (val.isNotEmpty) {
            final data = String.fromCharCodes(val);
            Console.log(
                tag: "⬇️ [DATA_CHAR] Initial Read Result: $data",
                value: 'BLE_Cubit');
            _parseData(data);
          }
        } catch (e) {
          Console.log(
              tag: "[BLE_Cubit] Initial read failed: $e", value: 'BLE_Cubit');
        }
      }

      emit(state.copyWith(
        status: BleStatus.connected,
        message: "Connected to ${device.platformName}",
      ));

      await _flushPendingSlots();
    } catch (e, st) {
      Console.log(
          tag:
              "=-=-=-=-=-=- Exception occurred =-=-=-=-=-= ${e.toString()} \n$st",
          value: 'BLE_Cubit');
      try {
        await device.disconnect();
      } catch (_) {}

      emit(state.copyWith(
          status: BleStatus.error,
          message: "Service discovery failed: $e",
          isServiceDiscoveryDone: false));
      _rescan(lastDeviceOnly: savedDeviceId != null || savedDeviceName != null);
    }
  }

  // ---------------------------------------------------------------------------
  // Data parsing and ACK
  // ---------------------------------------------------------------------------

  void _parseData(String data) {
    final parts = data.split(';');
    int? battery;
    double? volume;
    int? percent;
    DateTime? ts;
    for (var p in parts) {
      if (p.contains('battery=')) battery = int.tryParse(p.split('=')[1]);
      if (p.contains('volume=')) volume = double.tryParse(p.split('=')[1]);
      if (p.contains('percent=')) percent = int.tryParse(p.split('=')[1]);
      if (p.contains('ts=')) {
        String tsStr = p.split('=')[1].trim();
        Console.log(tag: "Raw TS from bottle: $tsStr", value: 'BLE_Cubit');

        // Format: "2026-03-13 13:06:08" -> "2026-03-13T13:06:08"
        tsStr = tsStr.replaceFirst(' ', 'T');

        // If the string doesn't have a timezone offset, append IST (+05:30)
        if (!tsStr.contains('+') &&
            !tsStr.contains('-') &&
            !tsStr.endsWith('Z')) {
          // tsStr = '$tsStr+05:30';
        }

        try {
          ts = DateTime.parse(tsStr).toUtc();
          Console.log(
              tag: "Parsed UTC TS: ${ts.toIso8601String()}",
              value: 'BLE_Cubit');

          final nowUtc = DateTime.now().toUtc();

          final difference = nowUtc.difference(ts).inMinutes.abs();

          if (difference >= 1) {
            Console.log(
                tag: "Time drift detected ($difference min). Syncing RTC...",
                value: 'BLE_Cubit');
          }
        } catch (e) {
          Console.log(tag: "Failed to parse TS: $tsStr", value: 'BLE_Cubit');
        }
      }
    }

    emit(state.copyWith(
        battery: battery,
        volume: volume,
        percent: percent,
        ts: ts,
        bottleData: data));
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

      Console.log(
          tag:
              "Start time ${_epochToTimeOfDay(startEpoch)}  \nEnd Time ${_epochToTimeOfDay(endEpoch)}",
          value: 'BLE_Cubit');

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

// Replace the old _parseHydrationSlotData with this:
  Future<List<HydrationEntry>> _parseHydrationSlotData(String payload) async {
    final List<HydrationEntry> results = [];

    try {
      if (payload.isEmpty) return results;

      // Normalize line endings / stray whitespace
      payload = payload.trim();

      // The device might send multiple slot segments separated by '|'
      final segments = payload.split('|');
      final currentHyderationData = await dbHelper.getAllSlots();
      for (final seg in segments) {
        final s = seg.trim();
        if (s.isEmpty || s.toLowerCase() == 'na') continue;

        final parts = s.split('/');
        if (parts.length < 3) {
          // malformed segment — skip
          Console.log(
              tag: "Skipping malformed hydration segment: '$s'",
              value: 'BLE_Cubit');
          continue;
        }

        final slotId = int.tryParse(parts[0].trim());
        final target = double.tryParse(parts[1].trim());
        final consumed = double.tryParse(parts[2].trim());

        if (slotId == null || target == null || consumed == null) {
          Console.log(
              tag: "Failed to parse numbers in segment: '$s'",
              value: 'BLE_Cubit');
          continue;
        }

        if (slotId < 0 || slotId >= HydrationSlot.values.length) {
          Console.log(
              tag: "Invalid slot index $slotId in segment: '$s'",
              value: 'BLE_Cubit');
          continue;
        }

        final slot = HydrationSlot.values[slotId];

        var currentSlotIdData =
            currentHyderationData.where((e) => e.slot == slot).first;

        results.add(HydrationEntry(
          slot: slot,
          startTime: TimeOfDay(
              hour: currentSlotIdData.startTime.hour,
              minute: currentSlotIdData.startTime.minute),
          endTime: TimeOfDay(
              hour: currentSlotIdData.endTime.hour,
              minute: currentSlotIdData.endTime.minute),
          waterDrank: consumed,
          amount: target,
        ));
      }
    } catch (e) {
      Console.log(
          tag: "Unexpected error parsing hydration slot data: $e",
          value: 'BLE_Cubit');
    }

    return results;
  }

  /// Parses a 30-days hydration payload of the form:
  /// "1758076200|0/2000/1800|1/2000/1800|2/2000/1800|...|29/2000/1800"
  /// Returns a list of maps: { "dayIndex": int, "date": DateTime, "target": double, "consumed": double, "raw": String }
  Future<List<Map<String, dynamic>>> _parse30DaysHydration(
      String payload) async {
    final List<Map<String, dynamic>> results = [];

    try {
      if (payload.isEmpty) return results;

      payload = payload.trim();

      // Split into parts: first part is epoch, rest are day segments
      final parts = payload.split('|').map((s) => s.trim()).toList();
      if (parts.isEmpty) return results;

      // Parse epoch (first token). Detect secs vs millis.
      final epochToken = parts.first;

      final epochNum = int.tryParse(epochToken);
      if (epochNum == null) {
        log("Invalid epoch in 30-days payload: '$epochToken'",
            name: "BLE_Cubit");
        return results;
      }
      print("30d -> $epochNum");

      // Heuristic: if epoch looks like milliseconds (> 1e12) treat as ms, else seconds.
      final epochMillis =
          (epochNum.toString().length == 13) ? epochNum : epochNum * 1000;
      DateTime rawStartDate =
          DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true);
      // Normalize to UTC midnight for stable day-indexing
      DateTime startDate =
          DateTime.fromMillisecondsSinceEpoch(epochMillis).toLocal();

      Console.log(
          tag:
              "30-days startDate parsed as: $startDate  $epochMillis $epochNum ",
          value: 'BLE_Cubit');

      var totalTarget = await SharedPrefsHelper.getWaterGoal();
      // Iterate remaining segments
      final segments = parts.sublist(1); // drop epoch
      for (var seg in segments) {
        if (seg.isEmpty || seg.toLowerCase() == 'na') continue;

        final segParts = seg.split('/');
        // Expected: index/target/consumed  (some firmwares might omit index; handle both)
        if (segParts.length < 2) {
          Console.log(
              tag: "Skipping malformed 30-days segment: '$seg'",
              value: 'BLE_Cubit');
          continue;
        }

        // If firmware includes index in segment (0/target/consumed)
        int dayIndex;
        double target;
        double consumed;

        if (segParts.length >= 3) {
          dayIndex = int.tryParse(segParts[0].trim()) ?? -1;
          target = totalTarget!.toDouble();
          consumed = double.tryParse(segParts[2].trim()) ?? 0.0;
        } else {
          // If index is not provided, assume segments are in order and use current loop index
          final orderIndex = segments.indexOf(seg);
          dayIndex = orderIndex;
          target = totalTarget!.toDouble();
          consumed = double.tryParse(segParts[1].trim()) ?? 0.0;
        }

        if (dayIndex < 0) {
          Console.log(
              tag: "Invalid day index for segment '$seg' — skipping",
              value: 'BLE_Cubit');
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

        // LOG: similar style to your 7-slot logs
        Console.log(
            tag: "[30Days] Day ${dayIndex.toString().padLeft(2, '0')} | "
                "Date=${dayDate.toIso8601String().split('T').first} | "
                "Target=${target.toStringAsFixed(0)}ml | "
                "Consumed=${consumed.toStringAsFixed(0)}ml",
            value: 'BLE_Cubit');

        results.add(entry);
      }
    } catch (e) {
      Console.log(
          tag: "Error parsing 30-days hydration payload: $e",
          value: 'BLE_Cubit');
    }

    return results;
  }

  Future<void> _sendAck(BluetoothDevice device,
      {bool sendAckToHydrationSlotsCharacteristic = false}) async {
    // try {
    //   if (sendAckToHydrationSlotsCharacteristic) {
    //     await _hydrationDataChar?.write("ACK".codeUnits, withoutResponse: true);
    //   } else {
    //     await _ackChar?.write("ACK".codeUnits, withoutResponse: true);
    //   }
    // } catch (e) {
    //   log("ACK failed: $e", name: "BLE_Cubit");
    // }
  }

  // ---------------------------------------------------------------------------
  // Utilities + Hydration sync
  // ---------------------------------------------------------------------------

  Future<void> sendConfigData(String payload) async {
    if (_configChar == null) {
      Console.log(tag: "Config characterstic not found", value: 'BLE_Cubit');
      emit(state.copyWith(message: "Config characteristic not found"));
      return;
    }
    try {
      Console.log(tag: "Sending config data: $payload", value: 'BLE_Cubit');
      await _configChar!.write(payload.codeUnits, withoutResponse: true);
      emit(state.copyWith(
        message: "Config data sent successfully",
        commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
        lastCommandSent: 'config',
      ));
    } catch (e) {
      Console.log(tag: "Failed to send config data: $e", value: 'BLE_Cubit');
      emit(state.copyWith(message: "Failed to send config data"));
    }
  }

  void _listenToConnection(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((stateChange) {
      switch (stateChange) {
        case BluetoothConnectionState.connected:
          emit(state.copyWith(
            status: BleStatus.connected,
            message: "Connected to ${device.platformName}",
          ));
          break;
        case BluetoothConnectionState.disconnected:
          // ✅ Clear the connecting guard so the next scan can reconnect
          _isConnecting = false;
          _clearCharacteristicSubscriptions();
          emit(state.copyWith(
            status: BleStatus.disconnected,
            isServiceDiscoveryDone: false,
            message: "Device disconnected",
          ));
          Console.log(
              tag:
                  '[BLE_Cubit] Device disconnected — triggering reconnect scan',
              value: 'BLE_Cubit');
          if (savedDeviceId != null || savedDeviceName != null) {
            _rescan(lastDeviceOnly: true);
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> _flushPendingSlots() async {
    print("============> $_ackChar");
    print('============> ${_pendingSlots.isEmpty}');

    try {
      // 1. Sync Pending Reset Command
      final pendingResetCommand =
          await SharedPrefsHelper.getPendingResetCommand();
      if (pendingResetCommand != null &&
          pendingResetCommand.isNotEmpty &&
          _resetChar != null) {
        try {
          Console.log(
              tag: "Sending pending reset command: $pendingResetCommand",
              value: 'BLE_Cubit');
          await _resetChar!
              .write(pendingResetCommand.codeUnits, withoutResponse: true);
          // emit(state.copyWith(
          //   status: BleStatus.connected,
          //   message: "Reset command sent successfully $pendingResetCommand",
          //   commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
          //   lastCommandSent: 'pendingResetCommand',
          // ));
          await SharedPrefsHelper.clearPendingResetCommand();
        } catch (e) {
          Console.log(
              tag: "Failed to send pending reset command: $e",
              value: 'BLE_Cubit');
        }
      }

      //  sendRTCSyncCommand
      sendRtcSyncCommand();

      // 2. Sync Pending Config Data
      final pendingConfig = await SharedPrefsHelper.getPendingConfigData();
      Console.log(
          tag: "BLE_Cubit", value: "Sending pending config data: $_configChar");
      if (pendingConfig != null &&
          pendingConfig.isNotEmpty &&
          _configChar != null) {
        try {
          Console.log(
              tag: "BLE_Cubit",
              value: "Sending pending config data: $pendingConfig");
          await _configChar!
              .write(pendingConfig.codeUnits, withoutResponse: true);
          // emit(state.copyWith(
          //   status: BleStatus.connected,
          //   message: "Config data sent successfully $pendingConfig",
          //   commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
          //   lastCommandSent: 'pendingConfig',
          // ));
          await SharedPrefsHelper.clearPendingConfigData();
        } catch (e) {
          Console.log(
              tag: "Failed to send pending config data: $e",
              value: 'BLE_Cubit');
        }
      }

      // 3. Sync Hydration Slots
      if (_ackChar != null && _pendingSlots.isNotEmpty) {
        final payload = _pendingSlots.map((slot) {
          final start = _timeOfDayToEpoch(slot.startTime);
          final end = _timeOfDayToEpoch(slot.endTime);
          return "${slot.slot.label}/${slot.slot.index}/$start/$end/${slot.amount.toInt()}";
        }).join("|");

        Console.log(
            tag:
                "Flushing hydration slots: ${"$payload|End/7/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 55))}/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 56))}/0"}",
            value: 'BLE_Cubit');
        await _ackChar!.write(
            "$payload|End/7/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 55))}/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 56))}/0"
                .codeUnits,
            withoutResponse: true);
        _pendingSlots.clear();
        print(
            '============> success  $payload   =====> unit ${payload.codeUnits}');

        // emit(state.copyWith(
        //   status: BleStatus.connected,
        //   message: "Hydration slots synced",
        //   commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
        //   lastCommandSent: 'hydrationSlots',
        // ));
      }
    } catch (e) {
      print('============> error ${e.toString()}');

      emit(
          state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
    }
  }

  Future<bool> _waitForConnectedState() async {
    Console.log(
        tag: "[WAIT] Waiting for CONNECTED + SERVICE_DISCOVERED (20s)",
        value: 'BLE_CUBIT_CONNECTED_STATE');

    // ✅ Fast path
    if (state.status == BleStatus.connected &&
        state.isServiceDiscoveryDone == true) {
      Console.log(
          tag: "[FAST-PATH] Already ready", value: 'BLE_CUBIT_CONNECTED_STATE');
      return true;
    }

    try {
      final result = await stream.map((s) {
        Console.log(
            tag:
                "[STREAM] status=${s.status} | serviceDiscovered=${s.isServiceDiscoveryDone}",
            value: 'BLE_CUBIT_CONNECTED_STATE');
        return s;
      }).firstWhere((s) {
        final isReady =
            s.status == BleStatus.connected && s.isServiceDiscoveryDone == true;

        if (isReady) {
          Console.log(
              tag: "[MATCH] Device FULLY READY (connected + services)",
              value: 'BLE_CUBIT_CONNECTED_STATE');
        }

        return isReady;
      }).timeout(const Duration(seconds: 20), onTimeout: () {
        Console.log(
            tag: "[TIMEOUT] Device not ready within 20s",
            value: "BLE_CUBIT_CONNECTED_STATE");
        throw TimeoutException("Device not ready");
      });

      Console.log(
          tag: "[SUCCESS] Ready state achieved",
          value: "BLE_CUBIT_CONNECTED_STATE");

      return true;
    } catch (e) {
      Console.log(
          tag: "[ERROR] Wait failed: ${e.toString()}",
          value: "BLE_CUBIT_CONNECTED_STATE");
      return false;
    }
  }

  Future sendResetCommandWithStateCheck() async {
    final payload = "0/reset/true";

    try {
      // if (_resetChar != null) {
      //   await _resetChar?.write(payload.codeUnits, withoutResponse: true);
      //   Console.log(
      //       tag: "[WRITE] Reset command sent successfully", value: "BLE_CUBIT");
      //
      //   return true;
      // } else {
      await SharedPrefsHelper.setPendingResetCommand(payload);
      //   Console.log(
      //       tag: "[FALLBACK] Saved command to prefs", value: "BLE_CUBIT");
      // }

      emit(state.copyWith(
        message: "Reset command ready to sent",
        commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
        lastCommandSent: 'reset',
      ));
    } catch (e) {
      Console.log(
          tag: "[ERROR] Write failed: ${e.toString()}", value: "BLE_CUBIT");
      return false;
    }
  }

  Future<bool> sendRtcSyncCommand() async {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final sign = offset.isNegative ? '-' : '+';
      final formattedOffset = '$sign$hours:$minutes';

      // Format: YYYY-MM-DD HH:MM:SS±HH:MM
      final timestamp = "${now.year}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}/$formattedOffset";

      Console.log(tag: "Syncing RTC with: $timestamp", value: "BLE_CUBIT");

      await _rtcSyncChar?.write(
        timestamp.codeUnits,
        withoutResponse: true,
      );

      return true;
    } catch (e) {
      Console.log(
          tag: "Exception occurred in RTC Sync: ${e.toString()}",
          value: "BLE_CUBIT");
      return false;
    }
  }

  int _timeOfDayToEpoch(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  TimeOfDay _epochToTimeOfDay(int epoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  @override
  Future<void> queueHydrationSlots(List<HydrationEntry> entries) async {
    _pendingSlots.clear();
    _pendingSlots.addAll(entries);
    if (state.status == BleStatus.connected) {
      await _flushPendingSlots();
    } else {
      emit(state.copyWith(message: "Device not connected, will sync later"));
    }
  }

  Future<void> forgetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_device_id');
    await prefs.remove('last_device_name');

    savedDeviceId = null;
    savedDeviceName = null;
    _clearCharacteristicSubscriptions();

    emit(
      state.copyWith(
        status: BleStatus.scanning,
        isFirstConnection: true,
        message: "Device forgotten. \nReady to scan for new devices.",
        battery: 0,
        volume: 0,
        percent: 0,
        bottleData: null,
        slotData: null,
        currentHydrationValue: 0,
        scannedDevices: [],
      ),
    );

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    _scanForAllDevices();
  }

  Future<void> clearData() async {
    emit(state.copyWith(
      currentHydrationValue: 0,
      battery: 0,
      volume: 0,
      percent: 0,
      bottleData: null,
      slotData: null,
    ));
  }

  /// Cancels and nullifies all characteristic notification subscriptions.
  void _clearCharacteristicSubscriptions() {
    _dataSub?.cancel();
    _hydrationGoalDataSub?.cancel();
    _hydrationSlotsSub?.cancel();
    _hydration30DaysSub?.cancel();

    _dataSub = null;
    _hydrationGoalDataSub = null;
    _hydrationSlotsSub = null;
    _hydration30DaysSub = null;
  }

  @override
  Stream<List<HydrationEntry>> get hydrationUpdates =>
      _hydrationController.stream;

  Future<double> getCurrentDayHistory() async {
    final db = await dbHelper.database;

    final now = DateTime.now();
    // Normalize "Today" to UTC midnight for matching against stable database entries
    final normalizedStart = DateTime(now.year, now.month, now.day);
    final normalizedEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.hydrationSummaryTableName,
    );

    Console.log(tag: "getCurrentDayHistory", value: maps.toString());

    var hyderationData = List.generate(
      maps.length,
      (i) => HydrationDaySummary.fromMap(maps[i]),
    );

    var hydrationDataTemp = hyderationData.where((s) {
      if (s.date.isBefore(normalizedStart)) {
        return false;
      }
      if (s.date.isAfter(normalizedEnd)) {
        return false;
      }
      return true;
    }).toList();
    if (hydrationDataTemp.isEmpty) {
      return 0;
    }

    return hydrationDataTemp.first.consumed;
  }

  void updateCurrentHydrationValue(double value) {
    emit(state.copyWith(currentHydrationValue: value));
  }

  Future<void> _syncWithHealth(double currentTotalMl) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // 1. Convert current data from bottle (ml) to Liters
      final currentTotalL = currentTotalMl / 1000.0;

      // 2. Get what's currently in Health (Liters)
      final healthTotal = await _healthService.getWaterIntakeLiters(
        start: startOfDay,
        end: now,
      );

      // 3. We only sync the difference if current bottle data is greater
      final diff = currentTotalL - healthTotal;

      Console.log(
          tag:
              "[HealthSync] Sync log: Bottle=$currentTotalL L, Health=$healthTotal L, Diff=$diff L",
          value: "BLE_Cubit");
      // Sync if more than 0.001L (approx 1ml)
      if (diff >= 0.001) {
        Console.log(
            tag: "[HealthSync] Syncing $diff L to Health", value: "BLE_Cubit");
        await _healthService.addWaterIntake(diff, now);
      }
    } catch (e) {
      Console.log(
          tag: "[HealthSync] Error syncing with Health: $e",
          value: "BLE_Cubit");
    }
  }
}
