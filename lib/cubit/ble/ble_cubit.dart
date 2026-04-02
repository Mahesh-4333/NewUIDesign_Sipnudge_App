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
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'ble_state.dart';

class BleCubit extends Cubit<BleState> implements HydrationSync {
  BleCubit() : super(const BleState());
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

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _ackChar;
  BluetoothCharacteristic? _hydrationGoalDataChar;
  BluetoothCharacteristic? _hydrationSlotsChar;
  BluetoothCharacteristic? _hydration30DaysChar;
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _resetChar;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

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
          }
        }
      }

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
        _hydration30DaysChar!.onValueReceived.listen((value) async {
          try {
            await dbHelper.clearHydrationDaySummaries();
            final data = String.fromCharCodes(value);
            //final data = "1771467000|0/1800/1165|1/1800/2082|2/1800/7|3/1800/0|4/1800/0|5/1800/125|6/1800/0|7/1800/738|8/1800/4|9/1800/0|10/1800/7|11/1800/3|12/1800/0|13/1800/10|14/1800/3|15/1800/0|16/1800/623|17/1800/0|18/1800/0|19/1800/0|20/1800/0|21/1800/0|22/1800/0|23/1800/0|24/1800/0|25/1800/0|26/1800/0|27/1800/0|28/1800/0|29/1800/0";

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

              // Cancel all today's notifications if target already met
              final stopWhenFull = await SharedPrefsHelper.getStopWhenFull();
              if (stopWhenFull) {
                final completionPercent = await WaterConsumptionCalculator
                    .calculateCompletionPercentage(history);
                Console.log(
                    tag: "BleCubit_stopWhenFull",
                    value: "completionPercent: $completionPercent");
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
      _hydrationGoalDataChar?.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("HydrationDataReceived: $data", name: "BLE_Cubit");
        var slots = _parseHydrationData(data);
        if (slots.isNotEmpty) _hydrationController.add(slots);
        _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
      });

      await _dataChar!.setNotifyValue(true);

      _dataChar!.onValueReceived.listen((value) {
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
          tsStr = '$tsStr+05:30';
        }

        try {
          ts = DateTime.parse(tsStr).toUtc();
          log("Parsed UTC TS: ${ts.toIso8601String()}", name: "BLE_Cubit");
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
      emit(state.copyWith(message: "Config data sent successfully"));
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

    if (_ackChar == null || _pendingSlots.isEmpty) return;

    try {
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
      ));

      // config data command
      final pendingConfig = await SharedPrefsHelper.getPendingConfigData();
      if (pendingConfig != null &&
          pendingConfig.isNotEmpty &&
          _configChar != null) {
        try {
          log("Sending pending config data: $pendingConfig", name: "BLE_Cubit");
          await _configChar!
              .write(pendingConfig.codeUnits, withoutResponse: true);
          await SharedPrefsHelper.clearPendingConfigData();
        } catch (e) {
          log("Failed to send pending config data: $e", name: "BLE_Cubit");
        }
      }

      // reset command
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

  Future<void> sendResetCommand() async {
    final payload = "0/reset/true";
    await SharedPrefsHelper.setPendingResetCommand(payload);
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

  @override
  Stream<List<HydrationEntry>> get hydrationUpdates =>
      _hydrationController.stream;

  // ---------------------------------------------------------------------------
  // MOCKING & TESTING METHODS
  // ---------------------------------------------------------------------------

  /// Simulates a Bluetooth device scan.
  /// Sets the status to [BleStatus.scanning].
  void mockBluetoothScan() {
    log("🧪 [MOCK] Simulating Bluetooth Scan...", name: "BLE_Cubit");
    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "[MOCK] Scanning for Sipnudge devices...",
    ));
  }

  /// Simulates the asynchronous initialization and connection flow of [start].
  ///
  /// If [isFirstConnection] is true, it stops at the [scanning] state,
  /// mimicking the discovery of new devices.
  /// If false, it proceeds to the [connected] state, mimicking a reconnection.
  Future<void> mockStart({bool isFirstConnection = false}) async {
    log("🧪 [MOCK] Starting asynchronous connection flow (isFirstConnection: $isFirstConnection)...",
        name: "BLE_Cubit");

    emit(state.copyWith(
      status: BleStatus.initializing,
      message: "[MOCK] Initializing...",
    ));
    await Future.delayed(const Duration(milliseconds: 500));

    emit(state.copyWith(
      status: BleStatus.initializing,
      message: "[MOCK] Initializing Bluetooth",
      isFirstConnection: isFirstConnection,
    ));
    await Future.delayed(const Duration(milliseconds: 500));

    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "[MOCK] Scanning for Sipnudge devices...",
    ));

    if (isFirstConnection) {
      log("🧪 [MOCK] Stopping at scanning state for discovery...",
          name: "BLE_Cubit");
      // Note: We don't populate scannedDevices here because ScanResult
      // requires real BluetoothDevice objects which are hard to instantiate.
      // We rely on the UI to show a "Mock Device" if it's in mock mode or similar.
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    emit(state.copyWith(
      status: BleStatus.connecting,
      message: "[MOCK] Connecting to Sipnudge MOCK...",
    ));
    await Future.delayed(const Duration(milliseconds: 1000));

    savedDeviceId = "MOCK_DEVICE_01";
    savedDeviceName = "Sipnudge MOCK";

    emit(state.copyWith(
      status: BleStatus.connected,
      message: "[MOCK] Connected to Sipnudge MOCK",
    ));
  }

  /// Simulates connecting to a selected device from the scan list.
  /// Mimics the behavior of [connectToSelectedDevice].
  Future<void> mockConnectToSelectedDevice() async {
    log("🧪 [MOCK] Simulating selection and connection to device...",
        name: "BLE_Cubit");

    emit(state.copyWith(
      status: BleStatus.connecting,
      message: "[MOCK] Connecting to selected Sipnudge device...",
    ));

    await Future.delayed(const Duration(milliseconds: 1000));

    savedDeviceId = "MOCK_DEVICE_01";
    savedDeviceName = "Sipnudge MOCK";

    emit(state.copyWith(
      status: BleStatus.connected,
      message: "[MOCK] Connected to Sipnudge MOCK",
    ));
  }

  /// Simulates a successful Bluetooth connection to a Sipnudge device.
  /// Sets the status to [BleStatus.connected].
  @Deprecated(
      "Use mockStart() for full flow or mockBluetoothConnect for instant")
  void mockBluetoothConnect() {
    log("🧪 [MOCK] Simulating Bluetooth Connection...", name: "BLE_Cubit");
    savedDeviceId = "MOCK_DEVICE_01";
    savedDeviceName = "Sipnudge MOCK";
    emit(state.copyWith(
      status: BleStatus.connected,
      message: "[MOCK] Connected to Sipnudge MOCK",
    ));
  }

  /// Simulates receiving real-time bottle data.
  /// [volume]: current water volume in ml.
  /// [battery]: battery percentage (0-100).
  /// [percent]: hydration percentage of the current goal.
  void mockBottleData(
      {double volume = 450.0, int battery = 85, int percent = 45}) {
    final mockPayload = "battery=$battery;volume=$volume;percent=$percent";
    log("🧪 [MOCK] Simulating Bottle Data: $mockPayload", name: "BLE_Cubit");
    _parseData(mockPayload);
  }

  /// Simulates receiving hydration slot data (e.g., from the current day).
  /// [mockPayload]: formatted string "slotId/target/consumed|..."
  /// Example: "0/250/200|1/250/0"
  Future<void> mockHydrationSlots(String mockPayload) async {
    log("🧪 [MOCK] Injecting Hydration Slot Data: $mockPayload",
        name: "BLE_Cubit");

    final updatedEntries = await _parseHydrationSlotData(mockPayload);

    if (updatedEntries.isNotEmpty) {
      // 1. Update last sync date
      await dbHelper.saveLastSyncDate(DateTime.now());

      // 2. Persist to local database
      for (final updatedEntry in updatedEntries) {
        await dbHelper.insertOrUpdateSlot(updatedEntry);
      }

      // 3. Check for "perfect day" achievement
      final bool isPerfectNow = await dbHelper.isDayPerfect();

      // 4. Create summary for today
      final double totalConsumed =
          updatedEntries.fold(0.0, (sum, e) => sum + e.waterDrank);
      final double totalTarget =
          updatedEntries.fold(0.0, (sum, e) => sum + e.amount);

      final todaySummary = HydrationDaySummary(
        date: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        dayIndex: 0,
        target: totalTarget,
        consumed: totalConsumed,
        isPerfect: isPerfectNow,
        deviceId: savedDeviceId,
      );

      Console.log(
          tag: "mockHydrationSlots_todaySummary",
          value: todaySummary.toMap().toString());

      // 5. Update 30-day history with today's summary
      await dbHelper.bulkUpsert30Days([todaySummary]);

      // 6. Notify observers (like HydrationCubit)
      _hydrationController.add(updatedEntries);
    }
  }

  /// Simulates receiving a 30-day historical hydration payload.
  /// [mockPayload]: "epoch|index/target/consumed|..."
  Future<void> mock30DayHistory(String mockPayload) async {
    log("🧪 [MOCK] Injecting 30-Day History: $mockPayload", name: "BLE_Cubit");

    final parsed = await _parse30DaysHydration(mockPayload);
    if (parsed.isNotEmpty) {
      final List<HydrationDaySummary> list = parsed.map((m) {
        final targetVal = (m['target'] as num).toDouble();
        final consumedVal = (m['consumed'] as num).toDouble();
        final isPerfectDay = targetVal > 0 && consumedVal >= targetVal;

        return HydrationDaySummary(
          date: m['date'] as DateTime,
          dayIndex: m['dayIndex'] as int,
          target: targetVal,
          consumed: consumedVal,
          deviceId: savedDeviceId,
          isPerfect: isPerfectDay, // ✅ Set isPerfect
        );
      }).toList();

      // Save to database
      await dbHelper.bulkUpsert30Days(list);

      // Update state for UI feedback
      emit(state.copyWith(
        isHydration30DaysDataSync: true,
        historyData: mockPayload,
      ));

      log("🧪 [MOCK] Saved ${list.length} day summaries to DB",
          name: "BLE_Cubit");

      // Notify to refresh charts
      _hydrationController.add([]);
    }
  }

  /// Helper to quickly simulate a full 7-day perfect hydration streak.
  Future<void> mockFull7DayStreak() async {
    log("🚀 [MOCK] Starting Full 7-Day Streak Injection...", name: "BLE_Cubit");

    // 1. Clear existing summaries
    await dbHelper.clearHydrationDaySummaries();

    // 2. Inject 7 consecutive perfect days
    for (int i = 6; i >= 0; i--) {
      final testDate = DateTime.now().subtract(Duration(days: i));
      final normalizedDate =
          DateTime(testDate.year, testDate.month, testDate.day);

      final summary = HydrationDaySummary(
        date: normalizedDate,
        dayIndex: 0,
        target: 2000,
        consumed: 2000,
        isPerfect: true,
      );

      await dbHelper.bulkUpsert30Days([summary]);
      log("✅ [MOCK] Injected Perfect Day for: ${normalizedDate.toIso8601String()}",
          name: "BLE_Cubit");
    }

    // 3. Trigger recalculation in other Cubits
    _hydrationController.add([]);

    log("🏁 [MOCK] Injection Complete. Achievement stats should refresh.",
        name: "BLE_Cubit");
  }

  /// Manually adds water consumption to a specific slot for a given date.
  /// [slotIndex]: The index of the HydrationSlot (0 to 6).
  /// [amount]: The amount of water to add in mL.
  /// [date]: The date for which to add consumption (defaults to today).
  Future<void> mockManualConsumption(int slotIndex, double amount,
      {DateTime? date}) async {
    final effectiveDate = date ?? DateTime.now();
    final slots = await dbHelper.getAllSlots();
    if (slotIndex < 0 || slotIndex >= slots.length) {
      Console.error("MOCK", "Invalid slot index: $slotIndex");
      return;
    }

    final entry = slots[slotIndex];
    final updatedEntry = entry.copyWith(
      waterDrank: entry.waterDrank + amount,
    );

    // Save to DB (today's slots)
    await dbHelper.insertOrUpdateSlot(updatedEntry);

    // Record reading in history for WaterConsumptionCalculator
    double currentVol = state.volume ?? 750.0;
    // If we would go below 0, simulate a refill first
    // if (currentVol < amount) {
    //   await dbHelper.insertBottleData(BottleData(
    //     liquidVolume: 1000.0,
    //     liquidPercent: 100,
    //     battery: state.battery ?? 100,
    //     timestamp: effectiveDate.subtract(const Duration(seconds: 1)),
    //   ));
    //   currentVol = 1000.0;
    // }

    final newVol = currentVol - amount;
    final newPercent = ((newVol / 1000.0) * 100).toInt();

    await dbHelper.insertBottleData(BottleData(
      liquidVolume: newVol,
      liquidPercent: newPercent,
      battery: state.battery ?? 100,
      timestamp: effectiveDate,
    ));

    // Update state to reflect the new bottle volume and trigger listeners
    emit(state.copyWith(
      status: BleStatus.connected,
      volume: newVol,
      percent: newPercent,
    ));

    // Notify observers (only for today)
    final updatedSlots = await dbHelper.getAllSlots();
    _hydrationController.add(updatedSlots);

    double totalTarget = updatedSlots.fold(0.0, (sum, e) => sum + e.amount);
    double currentConsumed =
        updatedSlots.fold(0.0, (sum, e) => sum + e.waterDrank);

    // Simple heuristic for isPerfect: if consumed >= target
    final bool isPerfect = currentConsumed >= totalTarget;

    final updatedSummary = HydrationDaySummary(
      date:
          DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day),
      dayIndex: slotIndex,
      target: totalTarget,
      consumed: currentConsumed,
      isPerfect: isPerfect,
      deviceId: savedDeviceId,
    );

    Console.log(tag: "updatedSummary", value: updatedSummary.toMap());

    await dbHelper.bulkUpsert30Days([updatedSummary]);

    _hydrationController.add([]);
  }

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
}
