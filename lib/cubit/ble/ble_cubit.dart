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
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/health_service.dart';
import 'package:http/http.dart' as http;
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

  final dbHelper = DatabaseHelper();
  final List<HydrationEntry> _pendingSlots = [];

  int _investorDayIncrement = 0;

  /// Implements [HydrationSync.currentHydrationValue].
  /// Returns the latest total hydration consumed today (ml) from BLE state.
  @override
  double get currentHydrationValue => state.currentHydrationValue;

  // ---------------------------------------------------------------------------
  // BLE initialization and scanning
  // ---------------------------------------------------------------------------

  // investor bottle 3 day before
  // new bottle 1 day before
  // tap bottle 0 day before

  Future<void> start() async {
    // await _checkAndResetForNewDay();

    // await _fetchInvestorDayIncrement();

    emit(state.copyWith(
      status: BleStatus.initializing,
      message: "Initializing...",
    ));

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
          log('[BLE_Cubit] _investorDayIncrement set to $_investorDayIncrement from API',
              name: 'BLE_Cubit');
          return;
        }
      }
    } catch (e) {
      log('[BLE_Cubit] _fetchInvestorDayIncrement failed: $e — using default 4',
          name: 'BLE_Cubit');
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
    log(
      '[BLE_Cubit] New day detected. Resetting hydration slots.\n'
      'Last=$lastDate | Today=$today',
      name: 'BLE_Cubit',
    );

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
        log('[BLE_Cubit] Bluetooth re-enabled — restarting scan',
            name: 'BLE_Cubit');
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
    FlutterBluePlus.startScan(
      withServices: [serviceUUID],
      timeout: const Duration(seconds: 30),
    );

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
      log('[BLE_Cubit] Scan error: $e', name: 'BLE_Cubit');
      emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
      _rescan(lastDeviceOnly: true);
    });

    // ✅ Restart scan after timeout ONLY if we haven't already connected
    Future.delayed(const Duration(seconds: 30), () {
      if (!_scanCancelled && state.status == BleStatus.scanning) {
        log('[BLE_Cubit] Scan timeout — restarting scan for last device',
            name: 'BLE_Cubit');
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
    FlutterBluePlus.startScan(
      withServices: [serviceUUID],
      timeout: const Duration(seconds: 30),
    );

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
      log('[BLE_Cubit] Scan error (all): $e', name: 'BLE_Cubit');
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
    log('[BLE_Cubit] _rescan attempt $_scanRetryCount, delay ${delayMs}ms',
        name: 'BLE_Cubit');
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
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _connectToDevice(device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // ✅ Guard: prevent concurrent connection attempts
    if (_isConnecting) {
      log('[BLE_Cubit] _connectToDevice called while already connecting — ignored',
          name: 'BLE_Cubit');
      return;
    }
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
      await prefs.setString('last_device_id', device.remoteId.str);
      await prefs.setString('last_device_name', device.platformName);

      savedDeviceId = device.remoteId.str;
      savedDeviceName = device.platformName;

      Console.log(
          tag: "device.remoteId.str_123",
          value: "${device.remoteId.str} ${device.platformName}");
      if (wasFirst) emit(state.copyWith(isFirstConnection: false));

      await _discoverServices(device);
      await prefs.setBool('ble_connected_once', true);
    } catch (e) {
      log('[BLE_Cubit] Connection failed: $e', name: 'BLE_Cubit');
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
        if (s.uuid == serviceUUID) {
          for (var c in s.characteristics) {
            if (c.uuid == dataUUID) _dataChar = c;
            if (c.uuid == ackUUID) _ackChar = c;
            if (c.uuid == hydrationGoalDataUUID) _hydrationGoalDataChar = c;
            if (c.uuid == hydrationSlotsUUID) _hydrationSlotsChar = c; // ✅ new
            if (c.uuid == water30DaysDataUUID) {
              _hydration30DaysChar = c; // ✅ new
            }
            if (c.uuid == configUUID) _configChar = c;
            if (c.uuid == resetUUID) _resetChar = c;
            if (c.uuid == rtcSyncUUID) _rtcSyncChar = c;
          }
        }
      }

      // ✅ Clear any old characteristic-specific subscriptions before adding new ones
      _clearCharacteristicSubscriptions();

      if (_dataChar == null || _ackChar == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_device_id');
        await prefs.remove('last_device_name');

        savedDeviceId = null;
        savedDeviceName = null;

        emit(state.copyWith(
          status: BleStatus.error,
          message: "Required characteristics not found",
          isFirstConnection: true,
        ));

        await device.disconnect();
        _rescan(lastDeviceOnly: false);
        return;
      }

      if (_hydration30DaysChar != null) {
        await _hydration30DaysChar!.setNotifyValue(true);
        _hydration30DaysSub =
            _hydration30DaysChar!.onValueReceived.listen((value) async {
          try {
            await dbHelper.clearHydrationDaySummaries();
            final data = String.fromCharCodes(value);
            // if (data == state.historyData) {
            //   log("30-day summary data unchanged, skipping processing",
            //       name: "BLE_Cubit");
            //   _sendAck(device);
            //   return;
            // }

            Console.log(tag: "Hydration 30 days Raw: ", value: "$data");

            final parsed = await _parse30DaysHydration(data);
            if (parsed.isNotEmpty) {
              final List<HydrationDaySummary> list = parsed.map((m) {
                // m['date'] is a DateTime from the parser — normalize to local midnight
                final DateTime rawDate = m['date'] as DateTime;
                final date = DateTime(rawDate.year, rawDate.month,
                    rawDate.day + _investorDayIncrement);
                // midnight
                final targetVal = (m['target'] as num).toDouble();
                final consumedVal = (m['consumed'] as num).toDouble();
                // Determine if this day met its hydration goal
                final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;

                return HydrationDaySummary(
                  date: date,
                  dayIndex: m['dayIndex'] as int,
                  target: targetVal,
                  consumed: consumedVal,
                  deviceId: savedDeviceId,
                  isPerfect: isPerfectDay, // ✅ Set isPerfect directly!
                );
              }).toList();

              // Save to DB in bulk (fast)
              // if ((state.volume ?? 0) > 600) {
              await dbHelper.bulkUpsert30Days(list);
              await Future.delayed(Duration(seconds: 1));

              final history = await getCurrentDayHistory();
              emit(state.copyWith(currentHydrationValue: history));

              Console.log(
                  tag: "BleCubit_stopWhenFull",
                  value: "completionPercent: $history");
              // Cancel all today's notifications if target already met
              final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();
              if (stopWhenFull) {
                final completionPercent = await WaterConsumptionCalculator
                    .calculateCompletionPercentage(history);
                Console.log(
                    tag: "BleCubit_stopWhenFull",
                    value: "completionPercent: $history");
                if (completionPercent >= 100) {
                  final notificationService = NotificationService();
                  for (final slot in HydrationSlot.values) {
                    await notificationService.cancelSlotReminders(slot, 0);
                  }
                }
              }

              emit(state.copyWith(
                  isHydration30DaysDataSync: true, historyData: data));

              // Trigger HydrationCubit to call refreshAchievementStats()
              _hydrationController.add([]);

              log("[BLE_Cubit] Saved ${list.length} day summaries to DB",
                  name: "BLE_Cubit");

              // Sync today's total with Health
              _syncWithHealth(history);

              // Optionally emit to UI stream:
              // _hydrationController.add(list.map((e) => convertToHydrationEntryIfNeeded(e)).toList());

              // for (final day in list) {
              //   // Example debug print (you already log inside parser)
              //   print("30d -> ${day.dayIndex} : ${day.date} "
              //       "target=${day.target} consumed=${day.consumed}  percentage ${(day.consumed / day.target) * 100}");
              // }
            }

            _sendAck(device);
          } catch (e) {
            print("========> erroe ${e.toString()}");
          }
        });
      }
      // 🔹 NEW: Real-time hydration slot data (slotId/Target/Consumed)
      if (_hydrationSlotsChar != null) {
        await _hydrationSlotsChar!.setNotifyValue(true);
        // Inside _discoverServices where you listen to _hydrationChar:
        _hydrationSlotsSub =
            _hydrationSlotsChar!.onValueReceived.listen((value) async {
          final data = String.fromCharCodes(value);
          emit(state.copyWith(slotData: data));
          log("Hydration Slot Data: $data", name: "BLE_Cubit");

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
      await _hydrationGoalDataChar?.setNotifyValue(true);

      // 💧 Hydration history data
      _hydrationGoalDataSub =
          _hydrationGoalDataChar?.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("HydrationDataReceived: $data", name: "BLE_Cubit");
        var slots = _parseHydrationData(data);
        if (slots.isNotEmpty) _hydrationController.add(slots);
        _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
      });

      await _dataChar!.setNotifyValue(true);

      _dataSub = _dataChar!.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("Received data: $data", name: "BLE_Cubit");
        _parseData(data);
        _sendAck(device);
      });

      emit(state.copyWith(
        status: BleStatus.connected,
        message: "Connected to ${device.platformName}",
      ));

      await _flushPendingSlots();
    } catch (e) {
      try {
        await device.disconnect();
      } catch (_) {}

      emit(state.copyWith(
        status: BleStatus.error,
        message: "Service discovery failed: $e",
      ));
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
        log("Raw TS from bottle: $tsStr", name: "BLE_Cubit");

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
          log("Parsed UTC TS: ${ts.toIso8601String()}", name: "BLE_Cubit");

          final nowUtc = DateTime.now().toUtc();

          final difference = nowUtc.difference(ts).inMinutes.abs();

          if (difference >= 1) {
            log("Time drift detected ($difference min). Syncing RTC...",
                name: "BLE_Cubit");
            sendRtcSyncCommand();
          }
        } catch (e) {
          log("Failed to parse TS: $tsStr", name: "BLE_Cubit", error: e);
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

      log("Start time ${_epochToTimeOfDay(startEpoch)}  \nEnd Time ${_epochToTimeOfDay(endEpoch)}");

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
      log("Unexpected error parsing hydration slot data: $e",
          name: "BLE_Cubit");
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

      log("30-days startDate parsed as: $startDate  $epochMillis $epochNum ",
          name: "BLE_Cubit");

      var totalTarget = await SharedPrefsHelper.getWaterGoal();
      // Iterate remaining segments
      final segments = parts.sublist(1); // drop epoch
      for (var seg in segments) {
        if (seg.isEmpty || seg.toLowerCase() == 'na') continue;

        final segParts = seg.split('/');
        // Expected: index/target/consumed  (some firmwares might omit index; handle both)
        if (segParts.length < 2) {
          log("Skipping malformed 30-days segment: '$seg'", name: "BLE_Cubit");
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

        // LOG: similar style to your 7-slot logs
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
      log("Config characterstic not found", name: "BLE_Cubit");
      emit(state.copyWith(message: "Config characteristic not found"));
      return;
    }
    try {
      log("Sending config data: $payload", name: "BLE_Cubit");
      await _configChar!.write(payload.codeUnits, withoutResponse: true);
      emit(state.copyWith(
        message: "Config data sent successfully",
        commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
        lastCommandSent: 'config',
      ));
    } catch (e) {
      log("Failed to send config data: $e", name: "BLE_Cubit");
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
            message: "Device disconnected",
          ));
          log('[BLE_Cubit] Device disconnected — triggering reconnect scan',
              name: 'BLE_Cubit');
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
      // 1. Sync Hydration Slots
      if (_ackChar != null && _pendingSlots.isNotEmpty) {
        final payload = _pendingSlots.map((slot) {
          final start = _timeOfDayToEpoch(slot.startTime);
          final end = _timeOfDayToEpoch(slot.endTime);
          return "${slot.slot.label}/${slot.slot.index}/$start/$end/${slot.amount.toInt()}";
        }).join("|");

        log("Flushing hydration slots: ${"$payload|End/7/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 55))}/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 56))}/0"}");
        await _ackChar!.write(
            "$payload|End/7/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 55))}/${_timeOfDayToEpoch(TimeOfDay(hour: 23, minute: 56))}/0"
                .codeUnits,
            withoutResponse: true);
        _pendingSlots.clear();
        print(
            '============> success  $payload   =====> unit ${payload.codeUnits}');

        emit(state.copyWith(
          status: BleStatus.connected,
          message: "Hydration slots synced",
          commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
          lastCommandSent: 'hydrationSlots',
        ));
      }

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
          emit(state.copyWith(
            status: BleStatus.connected,
            message: "Config data sent successfully $pendingConfig",
            commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
            lastCommandSent: 'pendingConfig',
          ));
          await SharedPrefsHelper.clearPendingConfigData();
        } catch (e) {
          log("Failed to send pending config data: $e", name: "BLE_Cubit");
        }
      }

      // 3. Sync Pending Reset Command
      final pendingResetCommand =
          await SharedPrefsHelper.getPendingResetCommand();
      if (pendingResetCommand != null &&
          pendingResetCommand.isNotEmpty &&
          _resetChar != null) {
        try {
          log("Sending pending reset command: $pendingResetCommand",
              name: "BLE_Cubit");
          await _resetChar!
              .write(pendingResetCommand.codeUnits, withoutResponse: true);
          emit(state.copyWith(
            status: BleStatus.connected,
            message: "Reset command sent successfully $pendingResetCommand",
            commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
            lastCommandSent: 'pendingResetCommand',
          ));
          await SharedPrefsHelper.clearPendingResetCommand();
        } catch (e) {
          log("Failed to send pending reset command: $e", name: "BLE_Cubit");
        }
      }
    } catch (e) {
      print('============> error ${e.toString()}');

      emit(
          state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
    }
  }

  Future<bool> _waitForConnectedState() async {
    log("[WAIT] Listening to Cubit stream for CONNECTED (10s)",
        name: "BLE_CUBIT");

    // ✅ Fast path (already connected)
    if (state.status == BleStatus.connected) {
      log("[FAST-PATH] Already connected", name: "BLE_CUBIT");
      return true;
    }

    try {
      final result = await stream.map((s) {
        log("[STREAM] Cubit state update: ${s.status}", name: "BLE_CUBIT");
        return s.status;
      }).firstWhere(
        (status) {
          final isConnected = status == BleStatus.connected;

          if (isConnected) {
            log("[MATCH] Found CONNECTED state", name: "BLE_CUBIT");
          }

          return isConnected;
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        log("[TIMEOUT] Did not reach CONNECTED in 10 seconds",
            name: "BLE_CUBIT");
        throw TimeoutException("Cubit state timeout");
      });

      log("[SUCCESS] State reached: $result", name: "BLE_CUBIT");

      return result == BleStatus.connected;
    } catch (e) {
      log("[ERROR] Waiting for state failed: ${e.toString()}",
          name: "BLE_CUBIT");
      return false;
    }
  }

  Future sendResetCommandWithStateCheck() async {
    final payload = "0/reset/true";

    try {
      if (_resetChar != null) {
        await _resetChar?.write(payload.codeUnits, withoutResponse: true);
        log("[WRITE] Reset command sent successfully", name: "BLE_CUBIT");

        return true;
      } else {
        await SharedPrefsHelper.setPendingResetCommand(payload);
        log("[FALLBACK] Saved command to prefs", name: "BLE_CUBIT");
      }

      emit(state.copyWith(
        message: "Reset command sent successfully",
        commandSentTimestamp: DateTime.now().millisecondsSinceEpoch,
        lastCommandSent: 'reset',
      ));
    } catch (e) {
      log("[ERROR] Write failed: ${e.toString()}", name: "BLE_CUBIT");
      return false;
    }
  }

  Future<bool> sendRtcSyncCommand() async {
    try {
      final now = DateTime.now();

      // Format: YYYY-MM-DD HH:MM:SS
      final timestamp = "${now.year}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";

      log("Syncing RTC with: $timestamp", name: "BLE_CUBIT");

      await _rtcSyncChar?.write(
        timestamp.codeUnits,
        withoutResponse: true,
      );

      return true;
    } catch (e) {
      log("Exception occurred in RTC Sync: ${e.toString()}", name: "BLE_CUBIT");
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

      log("[HealthSync] Sync log: Bottle=$currentTotalL L, Health=$healthTotal L, Diff=$diff L",
          name: "BLE_Cubit");
      // Sync if more than 0.001L (approx 1ml)
      if (diff >= 0.001) {
        log("[HealthSync] Syncing $diff L to Health", name: "BLE_Cubit");
        await _healthService.addWaterIntake(diff, now);
      }
    } catch (e) {
      log("[HealthSync] Error syncing with Health: $e", name: "BLE_Cubit");
    }
  }
}
