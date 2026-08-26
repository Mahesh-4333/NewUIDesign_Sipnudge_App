import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/models/bottle_data.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:hydrify/services/home_widget_service.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrify/helpers/internet_connection_helper.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/sync_bus.dart';

part 'ble_state.dart';

class BleCubit extends Cubit<BleState>
    with WidgetsBindingObserver
    implements HydrationSync {
  BleCubit() : super(const BleState()) {
    SyncBus.instance.addListener(_onSyncComplete);
    WidgetsBinding.instance.addObserver(this);
    // Listen for native → Dart events (e.g. when native CBCentralManager
    // connects after a BT toggle or after the 30-second FBP scan times out).
    if (Platform.isIOS) {
      _setupNativeBleChannel();
    }
  }

  /// Registers a handler for incoming MethodChannel calls FROM the native side.
  /// Handles:
  ///   • "onNativeConnected"    — native CBCentralManager connected after BT toggle
  ///   • "onLowPowerModeChanged" — iOS Low Power Mode toggled; updates BleState so
  ///                               the UI can show "Sync paused — Low Power Mode"
  void _setupNativeBleChannel() {
    const MethodChannel('com.sipnudge.sipnudge/native_ble')
        .setMethodCallHandler((call) async {
      if (call.method == 'onNativeConnected') {
        final uuid = call.arguments as String?;
        if (uuid == null || uuid.isEmpty) return;
        Console.log(
            tag: '[BLE_Cubit] onNativeConnected from Swift uuid=$uuid',
            value: 'BLE_Cubit');
        // Only attempt if not already connecting/connected.
        if (_isConnecting) {
          Console.log(
              tag:
                  '[BLE_Cubit] onNativeConnected: ignored because _isConnecting is true',
              value: 'BLE_Cubit');
          return;
        }
        final alreadyConnected =
            FlutterBluePlus.connectedDevices.any((d) => d.remoteId.str == uuid);
        if (alreadyConnected) {
          Console.log(
              tag:
                  '[BLE_Cubit] onNativeConnected: device already connected in FBP. Hooking listener.',
              value: 'BLE_Cubit');
          final device = FlutterBluePlus.connectedDevices
              .firstWhere((d) => d.remoteId.str == uuid);
          _listenToConnection(device);
          return;
        }
        // Create a BluetoothDevice from the UUID and connect via FBP so the
        // Flutter UI reflects the connection established by the native manager.
        try {
          final device = BluetoothDevice.fromId(uuid);
          Console.log(
              tag: '[BLE_Cubit] Triggering FBP connect after native connect',
              value: 'BLE_Cubit');
          // Stop scan if active before triggering connect
          if (FlutterBluePlus.isScanningNow) {
            try {
              _scanCancelled = true;
              await FlutterBluePlus.stopScan();
              _scanSub?.cancel();
            } catch (_) {}
          }
          await _connectToDevice(device);
          Console.log(
              tag:
                  '[BLE_Cubit] FBP connected after native trigger successfully',
              value: 'BLE_Cubit');
        } catch (e) {
          Console.log(
              tag:
                  '[BLE_Cubit] FBP connect after native trigger failed (non-fatal): $e',
              value: 'BLE_Cubit');
        }
      } else if (call.method == 'onLowPowerModeChanged') {
        // Fired by SipnudgeBackgroundBLE whenever iOS Low Power Mode toggles.
        // isActive = true  → LPM on,  background uploads are deferred by nsurlsessiond.
        // isActive = false → LPM off, deferred uploads resume automatically.
        final isActive = call.arguments as bool? ?? false;
        Console.log(
            tag: '[BLE_Cubit] Low Power Mode changed: isActive=$isActive',
            value: 'BLE_Cubit');
        emit(state.copyWith(isLowPowerModeActive: isActive));
      }
    });
  }

  Future<void> _onSyncComplete() async {
    Console.log(
        tag: "BLE_Cubit",
        value: "Sync completed. Reloading hydration value from DB.");
    final history = await getCurrentDayHistory();
    emit(state.copyWith(currentHydrationValue: history));
    _hydrationController.add([]); // triggers UI stream update
  }

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
  final Guid wifiProvUUID = Guid("6E400009-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid wifiNotifUUID = Guid("6E40000B-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid consumedUpdate = Guid("6E40000A-B5A3-F393-E0A9-E50E24DCCA9E");

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _ackChar;
  BluetoothCharacteristic? _hydrationGoalDataChar;
  BluetoothCharacteristic? _hydrationSlotsChar;
  BluetoothCharacteristic? _hydration30DaysChar;
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _resetChar;
  BluetoothCharacteristic? _rtcSyncChar;
  BluetoothCharacteristic? _wifiProvChar;
  BluetoothCharacteristic? _wifiNotifChar;
  BluetoothCharacteristic? _consumedUpdateChar;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  Timer? _watchdogTimer;
  Timer? _scanRestartTimer;
  DateTime? _stuckScanningSince;

  // Track characteristic value notifications to avoid duplicate listeners
  StreamSubscription? _dataSub;
  StreamSubscription? _hydrationGoalDataSub;
  StreamSubscription? _hydrationSlotsSub;
  StreamSubscription? _hydration30DaysSub;
  StreamSubscription? _wifiNotifSub;

  Completer<WifiProvResponse>? _wifiProvCompleter;

  String? savedDeviceName;
  String? savedDeviceId;

  /// Guards against concurrent connection attempts.
  bool _isConnecting = false;

  /// Guards against concurrent flush attempts.
  bool _isFlushing = false;

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

  /// Requests all permissions in groups for better UX and reliability.
  /// Bluetooth (Scan, Connect, Advertise) → Location → Notification
  Future<void> requestAllPermissionsSequentially() async {
    try {
      Console.log(
          tag: '[BLE_Cubit] Starting grouped permission flow',
          value: 'BLE_Cubit');

      // 1. BLUETOOTH PERMISSIONS
      if (Platform.isAndroid) {
        // For Android 12+ (API 31+), we need specific BLE permissions.
        // permission_handler handles SDK version checks internally when requesting these.
        Console.log(
            tag: '[BLE_Cubit] Requesting Android Bluetooth permissions...',
            value: 'BLE_Cubit');

        emit(state.copyWith(
          status: BleStatus.initializing,
          message: "Bluetooth permissions required...",
        ));

        // Grouping these ensures fewer system dialog interruptions
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();
      } else if (Platform.isIOS) {
        if (!await Permission.bluetooth.isGranted) {
          await Permission.bluetooth.request();
        }
      }

      // 2. LOCATION PERMISSION (Required for scanning on older Android, and for weather)
      Console.log(
          tag: '[BLE_Cubit] Requesting Location permission...',
          value: 'BLE_Cubit');

      emit(state.copyWith(
        status: BleStatus.initializing,
        message: "Location permission required...",
      ));

      await Permission.locationWhenInUse.request();

      // 3. NOTIFICATION PERMISSION
      Console.log(
          tag: '[BLE_Cubit] Requesting Notification permission...',
          value: 'BLE_Cubit');

      emit(state.copyWith(
        status: BleStatus.initializing,
        message: "Notification permission required...",
      ));

      await Permission.notification.request();

      Console.log(
          tag: '[BLE_Cubit] All permission groups processed',
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

    await checkAndResetForNewDay();

    // await _fetchInvestorDayIncrement();

    emit(state.copyWith(
      status: BleStatus.initializing,
      message: "Initializing...",
    ));

    // Request ALL permissions sequentially: Bluetooth → Location → Notification
    await requestAllPermissionsSequentially();

    _isInitialized = true;

    await _waitForBluetoothOn(() async {
      _startWatchdog(); // ✅ Start the watchdog to ensure scanning recovery
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

  Future<void> checkAndResetForNewDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDate = await DatabaseHelper().getLastSyncDate();
    final dbHelper = DatabaseHelper();

    // Same day → do nothing
    if (lastDate != null && lastDate.isAtSameMomentAs(today)) {
      return;
    }

    Console.log(
        tag: '[BLE_Cubit] New day detected or initial setup. Resetting daily hydration progress.\n'
            'Last=$lastDate | Today=$today',
        value: 'BLE_Cubit');

    // 1️⃣ Save today's date first so we don't repeatedly reset on the same day
    await dbHelper.saveLastSyncDate(today);

    // 2️⃣ Check if slots already exist in DB
    var existingSlots = await dbHelper.getAllSlots();
    if (existingSlots.isEmpty) {
      // First ever launch with no slots in DB: generate default slots
      final convertedWaterGoal = await SharedPrefsHelper.getWaterGoal() ?? 2500;
      final defaultSlots =
          HydrationHelper.generateHydrationSlots(convertedWaterGoal.toDouble());
      for (var slot in defaultSlots) {
        await dbHelper.insertOrUpdateSlot(slot);
      }
      existingSlots = defaultSlots;
    } else {
      // Slots exist: only reset waterDrank to 0 and status to pending (preserve custom startTime and endTime!)
      await dbHelper.resetSlotProgressForNewDay();
    }

    // 3️⃣ Clear today's hydration history
    await dbHelper.clearTodayHydrationHistory();

    // 4️⃣ Clear in-memory streams
    _hydrationController.add([]);

    // 5️⃣ Reset refills (Hardware & State)
    emit(state.copyWith(
      refill: 0.0,
      currentHydrationValue: 0,
      message: "New day started. Hydration and refills reset.",
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

    BluetoothAdapterState currentState;
    try {
      currentState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
    } catch (e) {
      currentState = BluetoothAdapterState.unknown;
    }

    if (currentState == BluetoothAdapterState.on) {
      await onReady();
    } else {
      emit(state.copyWith(
        status: BleStatus.error,
        message: "Please turn on Bluetooth",
      ));
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

        // Guard: If we are already connected or in the middle of a connection attempt
        // (e.g. native MethodChannel connection already fired), skip starting a fresh scan.
        final isConnected = FlutterBluePlus.connectedDevices
            .any((d) => d.remoteId.str == savedDeviceId);
        if (_isConnecting ||
            isConnected ||
            state.status == BleStatus.connected) {
          Console.log(
              tag:
                  '[BLE_Cubit] Reconnection already in progress or connected. Skipping scan restart.',
              value: 'BLE_Cubit');
          return;
        }
        await onReady();
      }
    });
  }

  Future<void> _scanForLastDevice() async {
    if (savedDeviceId == null && savedDeviceName == null) return;

    // Guard: Do not start a scan if we are already connected/connecting
    final isConnected = FlutterBluePlus.connectedDevices
        .any((d) => d.remoteId.str == savedDeviceId);
    if (_isConnecting || isConnected || state.status == BleStatus.connected) {
      Console.log(
          tag:
              '[BLE_Cubit] _scanForLastDevice: Already connecting or connected. Ignoring scan request.',
          value: 'BLE_Cubit');
      return;
    }

    // ✅ Cancel any previously pending restart timer — prevents timer stack-up
    _scanRestartTimer?.cancel();
    _scanRestartTimer = null;

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
      await FlutterBluePlus.startScan(
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
          // ✅ Mark cancelled so the restart timer is a no-op
          _scanCancelled = true;
          _scanRestartTimer?.cancel();
          _scanRestartTimer = null;
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

    // ✅ Single cancellable restart timer — only one can ever be pending at a time
    _scanRestartTimer = Timer(const Duration(seconds: 32), () {
      _scanRestartTimer = null;
      if (!_scanCancelled && state.status == BleStatus.scanning) {
        Console.log(
            tag:
                '[BLE_Cubit] Scan timeout (32s) — restarting scan for last device',
            value: 'BLE_Cubit');
        _scanForLastDevice();
      }
    });
  }

  Future<void> _scanForAllDevices() async {
    // Guard: Do not start a scan if we are already connected/connecting
    if (_isConnecting || state.status == BleStatus.connected) {
      Console.log(
          tag:
              '[BLE_Cubit] _scanForAllDevices: Already connecting or connected. Ignoring scan request.',
          value: 'BLE_Cubit');
      return;
    }

    // ✅ Cancel any previously pending restart timer
    _scanRestartTimer?.cancel();
    _scanRestartTimer = null;

    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge devices...",
    ));

    _scanCancelled = false;
    _scanSub?.cancel();

    // ✅ Use withServices filter; 30 s gives more ad cycles
    try {
      await FlutterBluePlus.startScan(
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

    // ✅ Single cancellable restart timer
    _scanRestartTimer = Timer(const Duration(seconds: 32), () {
      _scanRestartTimer = null;
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

  /// ✅ Watchdog: Periodically monitors BLE state and ensures scanning is active
  /// when the app expects to be connected but isn't.
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // 1. Skip if Bluetooth is not supported or not ON
      if (await FlutterBluePlus.isSupported == false) return;
      BluetoothAdapterState adapterState;
      try {
        adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
      } catch (_) {
        adapterState = BluetoothAdapterState.unknown;
      }
      if (adapterState != BluetoothAdapterState.on) return;

      // 2. Skip if already connected or currently connecting
      if (state.status == BleStatus.connected || _isConnecting) {
        _stuckScanningSince = null;
        if (state.manualRetryRequired) {
          emit(state.copyWith(manualRetryRequired: false));
        }
        return;
      }

      // 3. Skip if already scanning or a restart is already scheduled
      if (FlutterBluePlus.isScanningNow || _scanRestartTimer != null) {
        _stuckScanningSince = null;
        if (state.manualRetryRequired) {
          emit(state.copyWith(manualRetryRequired: false));
        }
        return;
      }

      // 4. Track stuck state
      _stuckScanningSince ??= DateTime.now();
      final stuckDuration = DateTime.now().difference(_stuckScanningSince!);

      if (stuckDuration.inSeconds >= 10) {
        Console.log(
            tag:
                '[BLE_Watchdog] Scanning stuck for > 10s. Automatically recovering BLE service.',
            value: 'BLE_Cubit');
        _stuckScanningSince = null;
        await reinitialize();
        return;
      }

      // 5. Trigger recovery scan
      final hasSavedDevice = (savedDeviceId != null || savedDeviceName != null);

      if (hasSavedDevice) {
        Console.log(
            tag:
                '[BLE_Watchdog] Device disconnected and not scanning. Restarting scan for last device.',
            value: 'BLE_Cubit');
        _scanForLastDevice();
      } else if (state.status == BleStatus.scanning) {
        Console.log(
            tag:
                '[BLE_Watchdog] Scanning status active but no scan running. Restarting all-device scan.',
            value: 'BLE_Cubit');
        _scanForAllDevices();
      }
    });
  }

  @override
  Future<void> close() {
    SyncBus.instance.removeListener(_onSyncComplete);
    WidgetsBinding.instance.removeObserver(this);
    _watchdogTimer?.cancel();
    _scanRestartTimer?.cancel();
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _adapterStateSub?.cancel();
    _clearCharacteristicSubscriptions();
    _clearCharacteristicReferences();
    _hydrationController.close();
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      Console.log(
          tag: "BLE_Cubit",
          value: "App resumed. Verifying BLE connection status...");
      _verifyConnectionStatus();
    }
  }

  Future<void> _verifyConnectionStatus() async {
    final connectedDevices = FlutterBluePlus.connectedDevices;

    // Find if our saved/last device is currently connected
    BluetoothDevice? connectedDevice;
    for (var device in connectedDevices) {
      bool match = false;
      if (savedDeviceId != null && savedDeviceId!.isNotEmpty) {
        match = (device.remoteId.str == savedDeviceId);
      } else if (savedDeviceName != null && savedDeviceName!.isNotEmpty) {
        match = (device.platformName == savedDeviceName);
      }
      if (match) {
        connectedDevice = device;
        break;
      }
    }

    if (connectedDevice != null) {
      // The device is physically/OS-level connected.
      if (state.status != BleStatus.connected ||
          state.isServiceDiscoveryDone != true) {
        Console.log(
            tag: "BLE_Cubit",
            value:
                "Device is connected at OS level, but Cubit state is ${state.status}. Syncing state and discovering services.");
        // Make sure we listen to its connection changes
        _listenToConnection(connectedDevice);

        // Discover services and update status
        emit(state.copyWith(
          status: BleStatus.connecting,
          message: "Restoring connection to ${connectedDevice.platformName}...",
        ));
        await _discoverServices(connectedDevice);
      } else {
        Console.log(
            tag: "BLE_Cubit",
            value: "Device is connected and Cubit state matches.");
      }
    } else {
      // The device is NOT connected.
      if (state.status == BleStatus.connected) {
        Console.log(
            tag: "BLE_Cubit",
            value:
                "Cubit state is connected, but device is not in connectedDevices. Updating state to disconnected.");

        _isConnecting = false;
        _clearCharacteristicSubscriptions();
        _clearCharacteristicReferences();
        emit(state.copyWith(
          status: BleStatus.disconnected,
          isServiceDiscoveryDone: false,
          message: "Device disconnected",
          scannedDevices: [],
        ));

        // Trigger scan to reconnect
        if (savedDeviceId != null || savedDeviceName != null) {
          _scanForLastDevice();
        }
      }
    }
  }

  /// ✅ Completely resets the BLE service and restarts it.
  Future<void> reinitialize() async {
    Console.log(
        tag: '[BLE_Cubit] Reinitializing BLE service...', value: 'BLE_Cubit');

    // 1. Reset state and stop everything
    _watchdogTimer?.cancel();
    _scanRestartTimer?.cancel();
    _scanRestartTimer = null;
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _adapterStateSub?.cancel();
    _clearCharacteristicSubscriptions();
    _clearCharacteristicReferences();

    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}

    _isInitialized = false;
    _isConnecting = false;
    _stuckScanningSince = null;
    _scanCancelled = false;
    _scanRetryCount = 0;

    final wasFirstConnection =
        (savedDeviceId == null && savedDeviceName == null);
    emit(BleState(
      status: BleStatus.initializing,
      message: "Reinitializing...",
      isFirstConnection: wasFirstConnection,
    ));

    // 2. Start fresh
    await start();
  }

  /// ✅ Unlinks the currently paired device and restarts BLE service
  Future<void> unlinkDevice() async {
    Console.log(tag: "BLE_Cubit", value: "Unlinking device...");

    // Disconnect currently connected device if any
    try {
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        await device.disconnect();
      }
    } catch (e) {
      Console.log(tag: "BLE_Cubit", value: "Error disconnecting: $e");
    }

    // Clear saved device from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_device_id');
    await prefs.remove('last_device_name');

    savedDeviceId = null;
    savedDeviceName = null;

    // Restart BLE Cubit to scan for new devices
    await reinitialize();
  }

  /// ✅ Manually dismisses the retry dialog
  void dismissRetryDialog() {
    _stuckScanningSince =
        null; // Reset the timer so it doesn't pop up immediately
    emit(state.copyWith(manualRetryRequired: false));
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
      scannedDevices: [],
    ));

    try {
      // ✅ Use autoConnect: false on both iOS and Android.
      //    On iOS, since our native Swift manager handles background reconnection,
      //    we do NOT want FBP's autoConnect: true (which waits for advertisements
      //    and blocks indefinitely if the native manager has already connected the peripheral).
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

      // ✅ Notify native iOS CBCentralManager that flutter_blue_plus has connected.
      //    The native manager calls retrieveConnectedPeripherals() to get the
      //    peripheral reference and immediately registers a pending connection.
      //    Without this call, the native manager may never get the peripheral
      //    reference and iOS will never wake the app for background BLE events.
      if (Platform.isIOS) {
        try {
          await const MethodChannel('com.sipnudge.sipnudge/native_ble')
              .invokeMethod('triggerNativeConnect');
          Console.log(
              tag: '[BLE_Cubit] Native BLE connect triggered successfully',
              value: 'BLE_Cubit');
        } catch (e) {
          Console.log(
              tag:
                  '[BLE_Cubit] Native BLE connect trigger failed (non-fatal): $e',
              value: 'BLE_Cubit');
        }
      }

      Console.log(
          tag: "device.remoteId.str_123",
          value: "${device.remoteId.str} ${device.advName}");
      if (wasFirst) emit(state.copyWith(isFirstConnection: false));

      Console.log(tag: '[BLE_Cubit] Connection SUCCESS', value: 'BLE_Cubit');

      // ✅ Request MTU (223 bytes) for better data throughput
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
          Console.log(
              tag: '[BLE_Cubit] MTU requested (max 223)', value: 'BLE_Cubit');
        } catch (e) {
          Console.log(
              tag: '[BLE_Cubit] MTU request failed: $e', value: 'BLE_Cubit');
        }
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
            if (c.uuid == wifiProvUUID) {
              _wifiProvChar = c;
              Console.log(
                  tag: 'BLE_Cubit', value: "Wifi prov cha: ${_wifiProvChar}");
            }
            if (c.uuid == wifiNotifUUID) {
              _wifiNotifChar = c;
              Console.log(
                  tag: 'BLE_Cubit', value: "Wifi notif cha: ${_wifiNotifChar}");
            }
            if (c.uuid == consumedUpdate) {
              _consumedUpdateChar = c;
              Console.log(
                  tag: 'BLE_Cubit',
                  value: "Consumed update cha: ${_consumedUpdateChar}");
            }
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
              else if (c.uuid == resetUUID)
                charName = " [Reset]";
              else if (c.uuid == wifiProvUUID)
                charName = " [WifiProv]";
              else if (c.uuid == wifiNotifUUID) charName = " [WifiNotif]";
            }

            final logTag = supported.contains("Notify") ? "✅" : "✍️";
            Console.log(
                tag: "Found Characteristic",
                value: "${charName}: ${c.uuid} | ${supported.join(' | ')}");
          } else {
            Console.log(
                tag: "Characteristic",
                value: "${c.uuid} | No common properties");
          }
        }
      }

      // ✅ Clear any old characteristic-specific subscriptions before adding new ones
      _clearCharacteristicSubscriptions();

      // Final availability check for critical characteristics (Temporarily bypassed for Wi-Fi testing)
      /*
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
      */

      Console.log(
          tag: "✅ All critical characteristics confirmed.", value: 'BLE_Cubit');
      emit(state.copyWith(isServiceDiscoveryDone: true));

      // ✅ 1. Register all listeners BEFORE enabling notifications
      if (_hydration30DaysChar != null) {
        _hydration30DaysSub =
            _hydration30DaysChar!.onValueReceived.listen((value) async {
          try {
            final data = String.fromCharCodes(value);
            Console.log(
                tag: "⬇️ [30_DAYS] Raw Data: $data", value: 'BLE_Cubit');
            final parsed = await _parse30DaysHydration(data);
            List<HydrationDaySummary> list = [];
            if (parsed.isNotEmpty) {
              list = parsed.map((m) {
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
            }

            emit(state.copyWith(
                isHydration30DaysDataSync: true,
                historyData: data,
                parsed30DaysList: list));
            _sendAck(device);
          } catch (e) {
            Console.log(
                tag: "BLE_Cubit",
                value: "Error in 30-day BLE notification handler: $e");
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

      if (_wifiNotifChar != null) {
        Console.log(
            tag: 'BLE_Cubit', value: "Wifi notif cha: ${_wifiNotifChar}");
        _wifiNotifSub = _wifiNotifChar!.onValueReceived.listen((value) {
          Console.log(tag: "⬇️ [WIFI_NOTIF] Raw Data", value: 'BLE_Cubit');
          final data = String.fromCharCodes(value);
          Console.log(
              tag: "⬇️ [WIFI_NOTIF] Raw Data: $data", value: 'BLE_Cubit');
          _handleWifiProvNotification(data);
        });
      }

      Console.log(tag: 'BLE_Cubit', value: "Data cha: ${_dataChar}");
      if (_dataChar != null) {
        _dataSub = _dataChar!.onValueReceived.listen((value) {
          final data = String.fromCharCodes(value);
          Console.log(
              tag: "⬇️ [DATA_CHAR] Raw Data: $data", value: 'BLE_Cubit');
          _parseData(data);
          _sendAck(device);
        });
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

      await _flushPendingSlots();
      final flushDelay = await SharedPrefsHelper.getFlushDelay();
      await Future.delayed(Duration(milliseconds: flushDelay));

      // ✅ 2. Now enable notifications for ALL characteristics across all services
      for (var service in services) {
        for (var c in service.characteristics) {
          if ((c.properties.notify || c.properties.indicate) &&
              c.device.isConnected) {
            try {
              await c.setNotifyValue(true);
              Console.log(
                  tag:
                      "[BLE_Cubit]  enable notify for ${c.uuid} ${c.properties.notify} ${c.properties.indicate}",
                  value: 'BLE_Cubit');
            } catch (e) {
              final errorStr = e.toString();
              String diagnostic = "";
              if (errorStr.contains('apple-code: 10') ||
                  errorStr.contains('Attribute could not be found')) {
                diagnostic =
                    " | DIAGNOSTIC: iOS CoreBluetooth cannot find the CCCD (0x2902) descriptor for this characteristic. "
                    "This usually happens due to iOS caching stale GATT services (restart Bluetooth/device to clear cache), "
                    "or because the peripheral firmware declared the Notify/Indicate property but did not add the CCCD descriptor to the database.";
              }
              Console.log(
                  tag:
                      "[BLE_Cubit] Failed to enable notify for ${c.uuid}: $e$diagnostic",
                  value: 'BLE_Cubit');
            }
          }
        }
      }

      emit(state.copyWith(
        status: BleStatus.connected,
        message: "Connected to ${device.platformName}",
      ));
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

  // Debounce guard: update widget from DATA_CHAR at most once per 60 seconds.
  DateTime? _lastWidgetUpdateFromDataChar;

  void _parseData(String data) {
    final parts = data.split(';');
    int? battery;
    double? volume;
    int? percent;
    double? refill;
    double? temp;
    double? bqTemp;
    DateTime? ts;
    int? dailyTotalMl; // parsed from daily_total_ml key
    Console.log(tag: "Raw TS from bottle parts: $parts", value: 'BLE_Cubit');
    for (var p in parts) {
      final kv = p.split('=');
      if (kv.length < 2) continue;

      final key = kv[0].trim();
      String value = kv[1].trim();

      // Clean value from trailing garbage (like the ']' in "34.55] BLE_Cubit")
      if (value.contains(']')) {
        value = value.split(']').first.trim();
      }

      if (key == 'battery') {
        battery = int.tryParse(value);
      } else if (key == 'volume') {
        volume = double.tryParse(value);
      } else if (key == 'percent') {
        percent = int.tryParse(value);
      } else if (key == 'refills') {
        final parsedInt = int.tryParse(value);
        refill =
            parsedInt != null ? parsedInt.toDouble() : double.tryParse(value);
      } else if (key == 'temp') {
        temp = double.tryParse(value);
        Console.log(
            tag: "Raw TS from bottle_temp:  $temp ", value: 'BLE_Cubit');
      } else if (key == 'bq_temp') {
        bqTemp = double.tryParse(value);
      } else if (key == 'daily_total_ml') {
        // The bottle reports today's total in every DATA_CHAR packet.
        // We use this to keep the home widget current without waiting
        // for a full 30-day sync (6E400006).
        dailyTotalMl = int.tryParse(value);
      } else if (key == 'ts') {
        String tsStr = value;
        Console.log(
            tag: "Raw TS from bottle: $tsStr $temp $refill $kv",
            value: 'BLE_Cubit');

        // Format: "2026-03-13 13:06:08" -> "2026-03-13T13:06:08"
        tsStr = tsStr.replaceFirst(' ', 'T');

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
        refill: refill,
        percent: percent,
        temp: temp,
        bqTemp: bqTemp,
        ts: ts,
        bottleData: data));

    // When DATA_CHAR reports daily_total_ml, sync today's intake directly
    if (dailyTotalMl != null && dailyTotalMl >= 0) {
      _syncDailyTotalFromDataChar(dailyTotalMl, battery: battery);
    }
  }

  /// Saves today's intake to local SQLite and updates server with force: true
  /// whenever DATA_CHAR sends daily_total_ml.
  Future<void> _syncDailyTotalFromDataChar(int dailyTotalMl, {int? battery}) async {
    try {
      final now = DateTime.now();
      final target = await SharedPrefsHelper.getWaterGoal() ?? 2500;
      final consumed = dailyTotalMl.toDouble();
      final isPerfect = target > 0 && consumed >= target;

      // 1. Save today's record to SQLite
      final todaySummary = HydrationDaySummary(
        date: DateTime(now.year, now.month, now.day),
        dayIndex: 0,
        target: target.toDouble(),
        consumed: consumed,
        isPerfect: isPerfect,
      );
      await dbHelper.bulkUpsert30Days([todaySummary]);

      // 2. Push today's record to server with force: true
      final userId = await SharedPrefsHelper.getUserId();
      if (userId != null && userId.isNotEmpty) {
        final dateUtc =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00.000Z';

        await ApiService().updateTodayConsumed(
          userId,
          dateUtc,
          consumed,
          isPerfect,
          target: target.toDouble(),
          battery: battery ?? state.battery,
          force: true,
        );
      }

      // 3. Update BleCubit state so Home Screen UI refreshes instantly
      emit(state.copyWith(currentHydrationValue: consumed));

      // 4. Notify SyncBus for UI listeners (BottleDataCubit, charts, timeline)
      SyncBus.instance.notifySyncComplete();

      // 5. Debounced home widget update (at most once per 30 seconds)
      final lastUpdate = _lastWidgetUpdateFromDataChar;
      if (lastUpdate == null || now.difference(lastUpdate).inSeconds >= 30) {
        _lastWidgetUpdateFromDataChar = now;
        await HomeWidgetService.updateWidgetData();
      }
    } catch (e) {
      Console.log(
          tag: "[BLE_Cubit]",
          value: "Error syncing daily_total_ml from DATA_CHAR: $e");
    }
  }

  /// Updates the home widget from DATA_CHAR's daily_total_ml field.
  /// Called at most once per 60 seconds (see _lastWidgetUpdateFromDataChar).
  Future<void> _updateWidgetFromDailyTotal(int dailyTotalMl) async {
    try {
      await HomeWidgetService.updateWidgetData();
      Console.log(
          tag: "[HomeWidget] Widget updated from DATA_CHAR",
          value: 'BLE_Cubit');
    } catch (e) {
      Console.log(
          tag: "[HomeWidget] Error updating widget from DATA_CHAR: $e",
          value: 'BLE_Cubit');
    }
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

        // Fetch manual logs for this slot's time range
        final manualWaterDrank = await dbHelper.getManualWaterDrankForRange(
          currentSlotIdData.startTime,
          currentSlotIdData.endTime,
        );

        results.add(HydrationEntry(
          slot: slot,
          startTime: TimeOfDay(
              hour: currentSlotIdData.startTime.hour,
              minute: currentSlotIdData.startTime.minute),
          endTime: TimeOfDay(
              hour: currentSlotIdData.endTime.hour,
              minute: currentSlotIdData.endTime.minute),
          waterDrank: consumed + manualWaterDrank,
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

      // The device tracks days in UTC (manual delta writes go to the UTC-day
      // slot on the device). Parse the epoch as UTC so dayIndex arithmetic
      // matches the device's internal calendar. Previously isUtc:false caused
      // a +1 day shift on IST: dayIndex 2 (Aug 11 UTC) displayed as Aug 12 IST.
      DateTime startDate =
          DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true);

      // Normalize to UTC midnight so adding Duration(days: N) always hits the
      // correct UTC calendar day regardless of the epoch's time-of-day.
      startDate = DateTime.utc(startDate.year, startDate.month, startDate.day);

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

  void _listenToConnection(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((stateChange) async {
      switch (stateChange) {
        case BluetoothConnectionState.connected:
          // ✅ Always re-discover services on every connect event.
          //    On iOS with autoConnect=true, CoreBluetooth can silently reconnect
          //    the device while the app is in background. When the app resumes,
          //    this fires and we must re-subscribe to all characteristics
          //    because iOS drops all notification subscriptions after disconnect.
          Console.log(
              tag:
                  '[BLE_Cubit] Connected (or reconnected) — re-discovering services',
              value: 'BLE_Cubit');
          emit(state.copyWith(
            status: BleStatus.connected,
            message: "Connected to ${device.platformName}",
          ));
          _clearCharacteristicSubscriptions();
          await _discoverServices(device);
          break;
        case BluetoothConnectionState.disconnected:
          // ✅ Clear the connecting guard so the next connection attempt is allowed
          _isConnecting = false;
          _clearCharacteristicSubscriptions();
          _clearCharacteristicReferences();
          emit(state.copyWith(
            status: BleStatus.disconnected,
            isServiceDiscoveryDone: false,
            message: "Device disconnected",
            scannedDevices: [],
          ));
          Console.log(
              tag: '[BLE_Cubit] Device disconnected', value: 'BLE_Cubit');
          // ✅ On iOS with autoConnect=true, CoreBluetooth will reconnect automatically
          //    in the background — no need to trigger a Dart-level scan.
          //    On Android, fall back to _scanForLastDevice() as before.
          if (Platform.isAndroid &&
              (savedDeviceId != null || savedDeviceName != null)) {
            _scanForLastDevice();
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> _flushPendingSlots() async {
    if (_isFlushing) {
      Console.log(
          tag: "BLE_Cubit",
          value:
              "[_flushPendingSlots] Already flushing, ignoring duplicate call.");
      return;
    }
    _isFlushing = true;
    final startMs = DateTime.now().millisecondsSinceEpoch;
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
      await sendRtcSyncCommand();

      // 2. Sync Pending Config Data
      final pendingConfig = await SharedPrefsHelper.getPendingConfigData();
      Console.log(
          tag: "BLE_Cubit",
          value: "Sending pending config data (UUID: ${_configChar?.uuid})");
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

      // 3.5 Sync Manual Liquid Delta (000A)
      final freshConsumedChar = await _getFreshCharacteristic(consumedUpdate);
      if (freshConsumedChar != null) {
        final pendingDelta = await SharedPrefsHelper.getPendingManualDelta();
        String payload = pendingDelta.toString();
        if (pendingDelta > 0) {
          payload = "+$pendingDelta";
        }
        try {
          Console.log(
              tag: "BLE_Cubit",
              value: "Sending pending manual liquid delta (000A): $payload");
          await freshConsumedChar.write(payload.codeUnits,
              withoutResponse: true);
          if (pendingDelta != 0) {
            await SharedPrefsHelper.clearPendingManualDelta();
          }
        } catch (e) {
          Console.log(
              tag: "BLE_Cubit",
              value: "Failed to send pending manual liquid delta: $e");
        }
      }

      // 4. Sync Pending Wi-Fi Provisioning
      if (_wifiProvCompleter == null || _wifiProvCompleter!.isCompleted) {
        final pendingWifi = await SharedPrefsHelper.getPendingWifiProvData();
        Console.log(
            tag: "BLE_Cubit",
            value: "Sending pending Wi-Fi provisioning data: $pendingWifi");
        final freshWifiProvChar = await _getFreshCharacteristic(wifiProvUUID);
        if (pendingWifi != null &&
            pendingWifi.isNotEmpty &&
            freshWifiProvChar != null) {
          final completer = Completer<WifiProvResponse>();
          _wifiProvCompleter = completer;

          emit(state.copyWith(isWifiProvisioning: true));

          bool isSuccess = false;
          String? ssid;
          String? ip;
          String? errorReason;

          try {
            Console.log(
                tag: "BLE_Cubit",
                value: "Sending pending Wi-Fi provisioning data: $pendingWifi");

            final bool writeWithoutResp = !freshWifiProvChar.properties.write &&
                freshWifiProvChar.properties.writeWithoutResponse;
            await freshWifiProvChar.write(utf8.encode(pendingWifi),
                withoutResponse: writeWithoutResp);
            await SharedPrefsHelper.clearPendingWifiProvData();

            // Wait for response with a 30-second timeout
            final response = await completer.future.timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                if (_wifiProvCompleter == completer) {
                  _wifiProvCompleter = null;
                }
                return WifiProvResponse(
                  result: 'fail',
                  reason: 'timeout',
                  saved: false,
                  savedUserId: false,
                );
              },
            );

            if (response.result == 'ok') {
              isSuccess = true;
              ip = response.ip;
              try {
                final Map<String, dynamic> wifiMap = jsonDecode(pendingWifi);
                ssid = wifiMap['ssid'];
                if (ssid != null) {
                  await SharedPrefsHelper.setActiveWifiSsid(ssid);
                }
                if (wifiMap['password'] != null) {
                  await SharedPrefsHelper.setActiveWifiPassword(
                      wifiMap['password']);
                }
                if (response.ip != null) {
                  await SharedPrefsHelper.setActiveWifiIp(response.ip!);
                }
                if (response.priority != null) {
                  await SharedPrefsHelper.setActiveWifiPriority(
                      response.priority!);
                }
              } catch (e) {
                Console.log(
                    tag: "BLE_Cubit", value: "Error saving active Wi-Fi: $e");
              }
            } else {
              errorReason = response.reason;
            }

            Console.log(
                tag: "BLE_Cubit",
                value:
                    "Pending Wi-Fi provisioning response: ${response.result}, IP: ${response.ip}");
          } catch (e) {
            if (_wifiProvCompleter == completer) {
              _wifiProvCompleter = null;
            }
            errorReason = e.toString();
            Console.log(
                tag: "Failed to send pending Wi-Fi provisioning data: $e",
                value: 'BLE_Cubit');
          } finally {
            emit(state.copyWith(
              isWifiProvisioning: false,
              showWifiConnectedDialog: isSuccess,
              wifiConnectedSsid: ssid,
              wifiConnectedIp: ip,
              showWifiFailedDialog: !isSuccess && errorReason != null,
              wifiFailedReason: errorReason,
            ));
          }
        }
      }
    } catch (e) {
      print('============> error ${e.toString()}');

      emit(
          state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
    } finally {
      _isFlushing = false;
      final endMs = DateTime.now().millisecondsSinceEpoch;
      print(
          "============> Total time taken for _flushPendingSlots: ${endMs - startMs}ms");
    }
  }

  /// Sends any accumulated manual liquid delta to characteristic 000A immediately
  Future<void> syncPendingManualDelta() async {
    if (state.status != BleStatus.connected) return;
    try {
      final freshConsumedChar = await _getFreshCharacteristic(consumedUpdate);
      if (freshConsumedChar != null) {
        final pendingDelta = await SharedPrefsHelper.getPendingManualDelta();
        if (pendingDelta != 0) {
          String payload = pendingDelta.toString();
          if (pendingDelta > 0) {
            payload = "+$pendingDelta";
          }
          Console.log(
              tag: "BLE_Cubit",
              value: "Writing manual liquid delta (000A): $payload");
          await freshConsumedChar.write(payload.codeUnits,
              withoutResponse: true);
          await SharedPrefsHelper.clearPendingManualDelta();
        }
      }
    } catch (e) {
      Console.log(
          tag: "BLE_Cubit", value: "Failed to write manual delta (000A): $e");
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

  Future<void> sendRtcSyncCommand() async {
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
    } catch (e) {
      Console.log(
          tag: "Exception occurred in RTC Sync: ${e.toString()}",
          value: "BLE_CUBIT");
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
    _clearCharacteristicReferences();

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
  /// Also clears characteristic references so stale handles from the old
  /// connection are never used after a disconnect.
  void _clearCharacteristicSubscriptions() {
    _dataSub?.cancel();
    _hydrationGoalDataSub?.cancel();
    _hydrationSlotsSub?.cancel();
    _hydration30DaysSub?.cancel();
    _wifiNotifSub?.cancel();

    _dataSub = null;
    _hydrationGoalDataSub = null;
    _hydrationSlotsSub = null;
    _hydration30DaysSub = null;
    _wifiNotifSub = null;
  }

  void _clearCharacteristicReferences() {
    _dataChar = null;
    _ackChar = null;
    _hydrationGoalDataChar = null;
    _rtcSyncChar = null;
    _hydrationSlotsChar = null;
    _hydration30DaysChar = null;
    _configChar = null;
    _resetChar = null;
    _wifiProvChar = null;
    _wifiNotifChar = null;
    _consumedUpdateChar = null;
  }

  @override
  Stream<List<HydrationEntry>> get hydrationUpdates =>
      _hydrationController.stream;

  Future<double> getCurrentDayHistory() async {
    final now = DateTime.now();
    final localSummary = await dbHelper.getSummaryForDate(now);
    if (localSummary != null) {
      Console.log(
          tag: "BleCubit_getCurrentDayHistory",
          value: "Loaded from local DB: ${localSummary.consumed} ml");
      return localSummary.consumed;
    }

    try {
      final hasInternet =
          await InternetConnectionHelper().hasInternetConnection();
      if (hasInternet) {
        final userId = await SharedPrefsHelper.getUserId();
        if (userId != null && userId.isNotEmpty) {
          // Server stores logs in UTC — query with UTC day boundaries.
          final startDate = DateTime.utc(now.year, now.month, now.day);
          final endDate =
              DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
          final summaries =
              await ApiService().getDailySummaries(userId, startDate, endDate);
          if (summaries != null && summaries.isNotEmpty) {
            final summaryMap = summaries.first;
            final serverConsumed = (summaryMap['consumed'] as num).toDouble();
            final targetVal =
                (summaryMap['target'] as num?)?.toDouble() ?? 2500;

            // Always use today's local date — server date string may be UTC
            // and would shift to the next local day for IST users.
            final DateTime targetDate = DateTime(now.year, now.month, now.day);

            await dbHelper.bulkUpsert30Days([
              HydrationDaySummary(
                date: targetDate,
                dayIndex: summaryMap['dayIndex'] as int? ?? 0,
                target: targetVal,
                consumed: serverConsumed,
                isPerfect: targetVal > 0 && serverConsumed >= targetVal,
              )
            ]);

            Console.log(
                tag: "BleCubit_getCurrentDayHistory",
                value: "Fetched from server: $serverConsumed ml");
            return serverConsumed;
          }
        }
      }
    } catch (e) {
      Console.log(
          tag: "BleCubit_getCurrentDayHistory",
          value: "Failed fetching from server, falling back to local DB: $e");
    }

    final db = await dbHelper.database;

    final normalizedStart = DateTime(now.year, now.month, now.day);
    final normalizedEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.hydrationSummaryTableName,
    );

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

  // Future<void> _syncWithHealth(double currentTotalMl) async {
  //   try {
  //     final now = DateTime.now();
  //     final startOfDay = DateTime(now.year, now.month, now.day);
  //
  //     // 1. Convert current data from bottle (ml) to Liters
  //     final currentTotalL = currentTotalMl / 1000.0;
  //
  //     // 2. Get what's currently in Health (Liters)
  //     final healthTotal = await _healthService.getWaterIntakeLiters(
  //       start: startOfDay,
  //       end: now,
  //     );
  //
  //     // 3. We only sync the difference if current bottle data is greater
  //     final diff = currentTotalL - healthTotal;
  //
  //     Console.log(
  //         tag:
  //             "[HealthSync] Sync log: Bottle=$currentTotalL L, Health=$healthTotal L, Diff=$diff L",
  //         value: "BLE_Cubit");
  //     // Sync if more than 0.001L (approx 1ml)
  //     if (diff >= 0.001) {
  //       Console.log(
  //           tag: "[HealthSync] Syncing $diff L to Health", value: "BLE_Cubit");
  //       await _healthService.addWaterIntake(diff, now);
  //     }
  //   } catch (e) {
  //     Console.log(
  //         tag: "[HealthSync] Error syncing with Health: $e",
  //         value: "BLE_Cubit");
  //   }
  // }

  Future<void> _syncWithLocalConsumption(
      double currentTotalMl, double previousTotal) async {
    try {
      final now = DateTime.now();

      // 1. Current data from bottle (ml)
      final currentTotal = currentTotalMl;

      // 3. Difference (ml)
      final diff = currentTotal - previousTotal;
      final diffL = diff / 1000.0;

      Console.log(
          tag:
              "[LocalSync] Sync log: Bottle=$currentTotal ml, AppState=$previousTotal ml, Diff=$diff ml",
          value: "BLE_Cubit");

      // Sync if more than 40ml
      if (diff >= 40.0) {
        Console.log(
            tag: "[LocalSync] Syncing $diffL L to Health and Database",
            value: "BLE_Cubit");

        await dbHelper.insertTodayHydration(diff, now,
            percentage: state.battery?.toDouble(),
            remaining: state.volume,
            totalAtTime: currentTotal);

        // Only sync to HealthKit/Health Connect if the user has already been
        // asked for health permission. If onboarding is still in progress,
        // skip silently to avoid triggering the iOS HealthKit dialog.
        final healthPermissionRequested =
            await SharedPrefsHelper.getHasRequestedHealthPermission();
        if (healthPermissionRequested) {
          await _healthService.addWaterIntake(diff / 1000, now);
        } else {
          Console.log(
              tag:
                  "[LocalSync] Skipping Health sync — permission not yet requested",
              value: "BLE_Cubit");
        }
      }
    } catch (e) {
      Console.log(
          tag: "[LocalSync] Error syncing locally: $e", value: "BLE_Cubit");
    }
  }

  void triggerRefresh() {
    emit(state.copyWith(refreshTrigger: state.refreshTrigger + 1));
  }

  void dismissWifiConnectedDialog() {
    emit(state.copyWith(
      showWifiConnectedDialog: false,
      wifiConnectedSsid: null,
      wifiConnectedIp: null,
    ));
  }

  void dismissWifiFailedDialog() {
    emit(state.copyWith(
      showWifiFailedDialog: false,
      wifiFailedReason: null,
    ));
  }

  void _handleWifiProvNotification(String data) {
    String cleanedData = data.trim();
    final firstBrace = cleanedData.indexOf('{');
    final lastBrace = cleanedData.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleanedData = cleanedData.substring(firstBrace, lastBrace + 1);
    }

    if (_wifiProvCompleter != null && !_wifiProvCompleter!.isCompleted) {
      try {
        final Map<String, dynamic> json = jsonDecode(cleanedData);
        final response = WifiProvResponse.fromJson(json);
        _wifiProvCompleter!.complete(response);
        _wifiProvCompleter = null;
      } catch (e) {
        Console.log(
            tag:
                "[WIFI_PROV] Error parsing notification JSON (original: '$data', cleaned: '$cleanedData'): $e",
            value: "BLE_Cubit");
        _wifiProvCompleter!.complete(WifiProvResponse(
          result: 'error',
          reason: 'bad_json',
        ));
        _wifiProvCompleter = null;
      }
    } else {
      Console.log(
          tag:
              "[WIFI_PROV] Notification received but no pending completer: $data",
          value: "BLE_Cubit");
    }
  }

  Future<WifiProvResponse> provisionWifi({
    required int priority,
    String? ssid,
    String? pass,
    String? userId,
  }) async {
    // Build request payload
    final Map<String, dynamic> request = {};
    if (userId != null && userId.isNotEmpty) {
      request['userId'] = userId;
    }
    if (ssid != null && ssid.isNotEmpty) {
      request['ssid'] = ssid;
      request['priority'] = priority;
      request['pass'] = pass ?? '';
    }

    final jsonPayload = jsonEncode(request);

    // Save to shared preferences as pending wifi provisioning data
    try {
      await SharedPrefsHelper.setPendingWifiProvData(jsonPayload);
      Console.log(
          tag:
              "[WIFI_PROV] Saved pending Wi-Fi config to SharedPreferences: $jsonPayload",
          value: "BLE_Cubit");
    } catch (e) {
      Console.log(
          tag: "[WIFI_PROV] Failed to save config to SharedPreferences: $e",
          value: "BLE_Cubit");
    }

    final freshWifiProvChar = await _getFreshCharacteristic(wifiProvUUID);
    if (freshWifiProvChar == null || !freshWifiProvChar.device.isConnected) {
      return WifiProvResponse(
        result: 'saved_pending',
        reason:
            'Device not connected. Configuration saved and will be sent when the bottle connects.',
      );
    }

    // Cancel any previous pending completer
    if (_wifiProvCompleter != null && !_wifiProvCompleter!.isCompleted) {
      _wifiProvCompleter!.complete(WifiProvResponse(
        result: 'error',
        reason: 'Operation superseded by new request',
      ));
    }
    final completer = Completer<WifiProvResponse>();
    _wifiProvCompleter = completer;

    emit(state.copyWith(isWifiProvisioning: true));

    try {
      Console.log(
          tag: "BLE_Cubit",
          value: "Sending Wi-Fi provisioning data directly: $jsonPayload");

      final freshWifiNotifChar = await _getFreshCharacteristic(wifiNotifUUID);
      if (freshWifiNotifChar != null &&
          freshWifiNotifChar.device.isConnected &&
          (freshWifiNotifChar.properties.notify ||
              freshWifiNotifChar.properties.indicate)) {
        try {
          // await freshWifiNotifChar.setNotifyValue(true);
          Console.log(
              tag: "BLE_Cubit",
              value: "Enabled notify for wifiNotifChar in provisionWifi");
        } catch (e) {
          final errorStr = e.toString();
          String diagnostic = "";
          if (errorStr.contains('apple-code: 10') ||
              errorStr.contains('Attribute could not be found')) {
            diagnostic =
                " | DIAGNOSTIC: iOS CoreBluetooth cannot find the CCCD (0x2902) descriptor for wifiNotifChar. "
                "Check for stale iOS BLE cache or ensure peripheral firmware includes the CCCD descriptor.";
          }
          Console.log(
              tag:
                  "Failed to enable notify for wifiNotifChar in provisionWifi: $e$diagnostic",
              value: 'BLE_Cubit');
        }
      }

      final bool writeWithoutResp = !freshWifiProvChar.properties.write &&
          freshWifiProvChar.properties.writeWithoutResponse;

      await freshWifiProvChar.write(
        utf8.encode(jsonPayload),
        withoutResponse: writeWithoutResp,
      ); // Successfully written, clear the pending config
      await SharedPrefsHelper.clearPendingWifiProvData();

      // Return the future with a 30-second timeout
      final response = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (_wifiProvCompleter == completer) {
            _wifiProvCompleter = null;
          }
          return WifiProvResponse(
            result: 'fail',
            reason: 'timeout',
            saved: false,
            savedUserId: false,
          );
        },
      );

      if (response.result == 'ok') {
        if (ssid != null) {
          await SharedPrefsHelper.setActiveWifiSsid(ssid);
        }
        if (pass != null) {
          await SharedPrefsHelper.setActiveWifiPassword(pass);
        }
        if (response.ip != null) {
          await SharedPrefsHelper.setActiveWifiIp(response.ip!);
        }
        if (response.priority != null) {
          await SharedPrefsHelper.setActiveWifiPriority(response.priority!);
        }
      }

      return response;
    } catch (e) {
      if (_wifiProvCompleter == completer) {
        _wifiProvCompleter = null;
      }
      Console.log(
          tag: "[WIFI_PROV] Error sending Wi-Fi provisioning: $e",
          value: "BLE_Cubit");
      return WifiProvResponse(
        result: 'error',
        reason: e.toString(),
      );
    } finally {
      emit(state.copyWith(isWifiProvisioning: false));
    }
  }

  Future<BluetoothCharacteristic?> _getFreshCharacteristic(
      Guid charUuid) async {
    // Return the cached reference if it is already available and the device is connected
    if (charUuid == wifiProvUUID &&
        _wifiProvChar != null &&
        _wifiProvChar!.device.isConnected) {
      Console.log(
          tag: "[WIFI_PROV] Using cached characteristic for $charUuid",
          value: "BLE_Cubit");
      return _wifiProvChar;
    }
    if (charUuid == wifiNotifUUID &&
        _wifiNotifChar != null &&
        _wifiNotifChar!.device.isConnected) {
      Console.log(
          tag: "[WIFI_NOTIF] Using cached characteristic for $charUuid",
          value: "BLE_Cubit");
      return _wifiNotifChar;
    }
    BluetoothDevice? device;
    if (_wifiProvChar != null && _wifiProvChar!.device.isConnected) {
      device = _wifiProvChar!.device;
    } else if (_wifiNotifChar != null && _wifiNotifChar!.device.isConnected) {
      device = _wifiNotifChar!.device;
    } else {
      final connected = FlutterBluePlus.connectedDevices;
      if (connected.isNotEmpty) {
        device = connected.first;
      }
    }

    if (device == null || !device.isConnected) return null;

    try {
      final services = await device.discoverServices();
      for (var s in services) {
        final bool isMainService = (s.uuid == serviceUUID);
        for (var c in s.characteristics) {
          // Update the stored reference in cubit so subsequent calls or listeners use the fresh instance
          if (isMainService) {
            if (c.uuid == dataUUID) _dataChar = c;
            if (c.uuid == ackUUID) _ackChar = c;
            if (c.uuid == hydrationGoalDataUUID) _hydrationGoalDataChar = c;
            if (c.uuid == rtcSyncUUID) _rtcSyncChar = c;
            if (c.uuid == hydrationSlotsUUID) _hydrationSlotsChar = c;
            if (c.uuid == water30DaysDataUUID) _hydration30DaysChar = c;
            if (c.uuid == configUUID) _configChar = c;
            if (c.uuid == resetUUID) _resetChar = c;
            if (c.uuid == wifiProvUUID) {
              Console.log(
                  tag: "[WIFI_PROV] Wifi reference found and stored",
                  value: "BLE_Cubit");
              _wifiProvChar = c;
            }
            if (c.uuid == wifiNotifUUID) {
              Console.log(
                  tag: "[WIFI_NOTIF] Wifi notif reference found and stored",
                  value: "BLE_Cubit");
              _wifiNotifChar = c;
            }
            if (c.uuid == consumedUpdate) {
              _consumedUpdateChar = c;
            }
          }
          if (c.uuid == charUuid) {
            return c;
          }
        }
      }
    } catch (e) {
      Console.log(
          tag: "Error getting fresh characteristic: $e", value: "BLE_Cubit");
    }

    // Fallback to the currently cached reference if discovery failed
    return _getTargetCharByUuid(charUuid);
  }

  BluetoothCharacteristic? _getTargetCharByUuid(Guid uuid) {
    if (uuid == dataUUID) return _dataChar;
    if (uuid == ackUUID) return _ackChar;
    if (uuid == hydrationGoalDataUUID) return _hydrationGoalDataChar;
    if (uuid == rtcSyncUUID) return _rtcSyncChar;
    if (uuid == hydrationSlotsUUID) return _hydrationSlotsChar;
    if (uuid == water30DaysDataUUID) return _hydration30DaysChar;
    if (uuid == configUUID) return _configChar;
    if (uuid == resetUUID) return _resetChar;
    if (uuid == wifiProvUUID) return _wifiProvChar;
    if (uuid == wifiNotifUUID) return _wifiNotifChar;
    if (uuid == consumedUpdate) return _consumedUpdateChar;
    return null;
  }
}

class WifiProvResponse {
  final String result;
  final int? priority;
  final String? ip;
  final bool? savedUserId;
  final bool? saved;
  final String? reason;

  WifiProvResponse({
    required this.result,
    this.priority,
    this.ip,
    this.savedUserId,
    this.saved,
    this.reason,
  });

  factory WifiProvResponse.fromJson(Map<String, dynamic> json) {
    return WifiProvResponse(
      result: json['result'] ?? 'error',
      priority: json['priority'],
      ip: json['ip'],
      savedUserId: json['savedUserId'],
      saved: json['saved'],
      reason: json['reason'],
    );
  }
}
