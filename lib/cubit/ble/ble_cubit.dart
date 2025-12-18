import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ble_state.dart';

class BleCubit extends Cubit<BleState> implements HydrationSync {
  BleCubit() : super(const BleState());
  final _hydrationController =
      StreamController<List<HydrationEntry>>.broadcast();

  final Guid serviceUUID = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid dataUUID = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid hydrationDataUUID = Guid("6E400004-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid ackUUID = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  final Guid hydrationCharUUID = Guid("6E400005-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid water30DaysDataUUID = Guid("6E400006-B5A3-F393-E0A9-E50E24DCCA9E");

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _ackChar;
  BluetoothCharacteristic? _hydrationDataChar;
  BluetoothCharacteristic? _hydrationChar; // 🔹 NEW for 7-slot hydration data
  BluetoothCharacteristic? _hydration30DaysChar;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  String? savedDeviceName;
  String? savedDeviceId;

  final bool _isReconnecting = false;
  final dbHelper = DatabaseHelper();
  final List<HydrationEntry> _pendingSlots = [];

  // ---------------------------------------------------------------------------
  // BLE initialization and scanning
  // ---------------------------------------------------------------------------

  Future<void> start() async {
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
      return;
    }

    emit(state.copyWith(
      status: BleStatus.error,
      message: "Please turn on Bluetooth",
    ));

    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    await onReady();
  }

  void _scanForLastDevice() {
    if (savedDeviceId == null && savedDeviceName == null) return;

    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge device...",
    ));

    _scanSub?.cancel();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        // ✅ Filter for only Sipnudge devices
        final deviceName = r.device.name.toLowerCase();
        if (!deviceName.contains('sipnudge')) continue;

        if (r.device.id.id == savedDeviceId ||
            r.device.name == savedDeviceName) {
          _scanSub?.cancel();
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          return;
        }
      }
    }, onError: (e) {
      emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
      _rescan(lastDeviceOnly: true);
    });

    Future.delayed(const Duration(seconds: 20), () {
      if (state.status == BleStatus.scanning) {
        FlutterBluePlus.stopScan().then((_) => _scanForLastDevice());
      }
    });
  }

  // void _scanForLastDevice() {
  //   if (savedDeviceId == null && savedDeviceName == null) return;

  //   emit(state.copyWith(
  //     status: BleStatus.scanning,
  //     message: "Scanning for last device...",
  //   ));

  //   _scanSub?.cancel();
  //   FlutterBluePlus.startScan(
  //     timeout: const Duration(seconds: 20),
  //     withServices: [serviceUUID],
  //   );

  //   _scanSub = FlutterBluePlus.scanResults.listen((results) {
  //     for (var r in results) {
  //       if (r.device.id.id == savedDeviceId ||
  //           r.device.name == savedDeviceName) {
  //         _scanSub?.cancel();
  //         FlutterBluePlus.stopScan();
  //         _connectToDevice(r.device);
  //         return;
  //       }
  //     }
  //   }, onError: (e) {
  //     emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
  //     _rescan(lastDeviceOnly: true);
  //   });

  //   Future.delayed(const Duration(seconds: 20), () {
  //     if (state.status == BleStatus.scanning) {
  //       FlutterBluePlus.stopScan().then((_) => _scanForLastDevice());
  //     }
  //   });
  // }

  void _scanForAllDevices() {
    emit(state.copyWith(
      status: BleStatus.scanning,
      message: "Scanning for Sipnudge devices...",
    ));

    _scanSub?.cancel();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        // ✅ Only include devices with "Sipnudge" in their name
        var filtered = results.where((it) {
          final name = it.device.name.toLowerCase();
          return name.contains('sipnudge');
        }).toList();

        if (filtered.isNotEmpty) {
          emit(state.copyWith(scannedDevices: filtered));
        }
      }
    }, onError: (e) {
      emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
      _rescan();
    });

    Future.delayed(const Duration(seconds: 20), () async {
      if (state.status == BleStatus.scanning) {
        FlutterBluePlus.stopScan().then((_) => _scanForAllDevices());
      }
    });
  }

  // void _scanForAllDevices() {
  //   emit(state.copyWith(
  //     status: BleStatus.scanning,
  //     message: "Scanning for BLE devices...",
  //   ));

  //   _scanSub?.cancel();
  //   FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));

  //   _scanSub = FlutterBluePlus.scanResults.listen((results) {
  //     if (results.isNotEmpty) {
  //       var filtered = results
  //           .where(
  //               (it) => it.advertisementData.serviceUuids.contains(serviceUUID))
  //           .toList();
  //       emit(state.copyWith(scannedDevices: filtered));
  //     }
  //   }, onError: (e) {
  //     emit(state.copyWith(status: BleStatus.error, message: "Scan error: $e"));
  //     _rescan();
  //   });

  //   Future.delayed(const Duration(seconds: 20), () async {
  //     if (state.status == BleStatus.scanning) {
  //       FlutterBluePlus.stopScan().then((_) => _scanForAllDevices());
  //     }
  //   });
  // }

  Future<void> _rescan({
    bool lastDeviceOnly = false,
    Duration delay = const Duration(milliseconds: 200),
  }) async {
    if (FlutterBluePlus.isScanningNow) return;
    await Future.delayed(delay);
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
    emit(state.copyWith(
      status: BleStatus.connecting,
      message: "Connecting to ${device.name}...",
    ));

    try {
      await device.connect(autoConnect: false, timeout: Duration(seconds: 6));
      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first;

      _listenToConnection(device);

      final prefs = await SharedPreferences.getInstance();
      final wasFirst = (savedDeviceId == null || savedDeviceName == null);
      await prefs.setString('last_device_id', device.id.id);
      await prefs.setString('last_device_name', device.name);

      savedDeviceId = device.id.id;
      savedDeviceName = device.name;
      if (wasFirst) emit(state.copyWith(isFirstConnection: false));

      await _discoverServices(device);
      await prefs.setBool('ble_connected_once', true);
    } catch (e) {
      emit(state.copyWith(
          status: BleStatus.error, message: "Connection failed: $e"));
      _rescan(
          lastDeviceOnly: (savedDeviceId != null || savedDeviceName != null));
    }
  }

  // ---------------------------------------------------------------------------
  // Service Discovery + Notification setup
  // ---------------------------------------------------------------------------

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (var s in services) {
        if (s.uuid == serviceUUID) {
          for (var c in s.characteristics) {
            if (c.uuid == dataUUID) _dataChar = c;
            if (c.uuid == ackUUID) _ackChar = c;
            if (c.uuid == hydrationDataUUID) _hydrationDataChar = c;
            if (c.uuid == hydrationCharUUID) _hydrationChar = c; // ✅ new
            if (c.uuid == water30DaysDataUUID) {
              _hydration30DaysChar = c; // ✅ new
            }
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
            final data = String.fromCharCodes(value);
            log("Hydration 30 days Raw: $data", name: "BLE_Cubit");

            final parsed = _parse30DaysHydration(data);
            if (parsed.isNotEmpty) {
              final List<HydrationDaySummary> list = parsed.map((m) {
                // m['date'] is a DateTime from the parser — normalize to local midnight
                final DateTime rawDate = m['date'] as DateTime;
                final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
                // midnight
                return HydrationDaySummary(
                  date: date,
                  dayIndex: m['dayIndex'] as int,
                  target: (m['target'] as num).toDouble(),
                  consumed: (m['consumed'] as num).toDouble(),
                  deviceId: savedDeviceId,
                );
              }).toList();

              // Save to DB in bulk (fast)
              await dbHelper.bulkUpsert30Days(list);
              emit(state.copyWith(
                  isHydration30DaysDataSync: true, historyData: data));
              log("[BLE_Cubit] Saved ${list.length} day summaries to DB",
                  name: "BLE_Cubit");

              // Optionally emit to UI stream:
              // _hydrationController.add(list.map((e) => convertToHydrationEntryIfNeeded(e)).toList());

              for (final day in list) {
                // Example debug print (you already log inside parser)
                print("30d -> ${day.dayIndex} : ${day.date} "
                    "target=${day.target} consumed=${day.consumed}  percentage ${(day.consumed / day.target) * 100}");
              }
            }

            _sendAck(device);
          } catch (e) {
            print("========> erroe ${e.toString()}");
          }
        });
      }
      // 🔹 NEW: Real-time hydration slot data (slotId/Target/Consumed)
      if (_hydrationChar != null) {
        await _hydrationChar!.setNotifyValue(true);
        // Inside _discoverServices where you listen to _hydrationChar:
        _hydrationChar!.onValueReceived.listen((value) async {
          final data = String.fromCharCodes(value);
          emit(state.copyWith(slotData: data));
          log("Hydration Slot Data: $data", name: "BLE_Cubit");

          final updatedEntries = _parseHydrationSlotData(data);
          if (updatedEntries.isNotEmpty) {
            _hydrationController.add(updatedEntries);
            for (final updatedEntry in updatedEntries) {
              await dbHelper.insertOrUpdateSlot(updatedEntry);
            }
          }

          _sendAck(device);
        });
      }
      await _hydrationDataChar?.setNotifyValue(true);

      // 💧 Hydration history data
      _hydrationDataChar?.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("HydrationDataReceived: $data", name: "BLE_Cubit");
        var slots = _parseHydrationData(data);
        if (slots.isNotEmpty) _hydrationController.add(slots);
        _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
      });

      await _dataChar!.setNotifyValue(true);

      // 🩵 Main data (battery, volume, percent)
      _dataChar!.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("Received data: $data", name: "BLE_Cubit");
        _parseData(data);
        _sendAck(device);
      });

      emit(state.copyWith(
        status: BleStatus.connected,
        message: "Connected to ${device.name}",
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

    for (var p in parts) {
      if (p.contains('battery=')) battery = int.tryParse(p.split('=')[1]);
      if (p.contains('volume=')) volume = double.tryParse(p.split('=')[1]);
      if (p.contains('percent=')) percent = int.tryParse(p.split('=')[1]);
    }

    emit(state.copyWith(
        battery: battery, volume: volume, percent: percent, bottleData: data));
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

// Replace the old _parseHydrationSlotData with this:
  List<HydrationEntry> _parseHydrationSlotData(String payload) {
    final List<HydrationEntry> results = [];

    try {
      if (payload.isEmpty) return results;

      // Normalize line endings / stray whitespace
      payload = payload.trim();

      // The device might send multiple slot segments separated by '|'
      final segments = payload.split('|');

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

  /// Parses a 30-days hydration payload of the form:
  /// "1758076200|0/2000/1800|1/2000/1800|2/2000/1800|...|29/2000/1800"
  /// Returns a list of maps: { "dayIndex": int, "date": DateTime, "target": double, "consumed": double, "raw": String }
  List<Map<String, dynamic>> _parse30DaysHydration(String payload) {
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
      DateTime startDate =
          DateTime.fromMillisecondsSinceEpoch(epochMillis).toLocal();

      log("30-days startDate parsed as: $startDate  $epochMillis $epochNum ",
          name: "BLE_Cubit");

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
          target = double.tryParse(segParts[1].trim()) ?? 0.0;
          consumed = double.tryParse(segParts[2].trim()) ?? 0.0;
        } else {
          // If index is not provided, assume segments are in order and use current loop index
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

  void _listenToConnection(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((stateChange) {
      switch (stateChange) {
        case BluetoothConnectionState.connected:
          emit(state.copyWith(
            status: BleStatus.connected,
            message: "Connected to ${device.name}",
          ));
          break;
        case BluetoothConnectionState.disconnected:
          emit(state.copyWith(
            status: BleStatus.disconnected,
            message: "Device disconnected",
          ));
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
    } catch (e) {
      print('============> error ${e.toString()}');

      emit(
          state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
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

    emit(
      state.copyWith(
        status: BleStatus.scanning,
        isFirstConnection: true,
        message: "Device forgotten. \nReady to scan for new devices.",
      ),
    );

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    emit(
      state.copyWith(
        status: BleStatus.scanning,
        isFirstConnection: true,
        scannedDevices: [],
        message: "Device forgotten. \nReady to scan for new devices.",
      ),
    );

    _scanForAllDevices();
  }

  @override
  Stream<List<HydrationEntry>> get hydrationUpdates =>
      _hydrationController.stream;
}

// -----------------------------------------------------------------------------
