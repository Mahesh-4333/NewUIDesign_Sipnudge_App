import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/cubit/hydration/hydration_sync.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
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

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _ackChar;
  BluetoothCharacteristic? _hydrationDataChar;
  BluetoothCharacteristic? _hydrationChar; // 🔹 NEW for 7-slot hydration data

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

      // 🩵 Main data (battery, volume, percent)
      _dataChar!.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("Received data: $data", name: "BLE_Cubit");
        _parseData(data);
        _sendAck(device);
      });
      await _dataChar!.setNotifyValue(true);

      // 💧 Hydration history data
      _hydrationDataChar?.onValueReceived.listen((value) {
        final data = String.fromCharCodes(value);
        log("HydrationDataReceived: $data", name: "BLE_Cubit");
        var slots = _parseHydrationData(data);
        if (slots.isNotEmpty) _hydrationController.add(slots);
        _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
      });
      await _hydrationDataChar?.setNotifyValue(true);

      // 🔹 NEW: Real-time hydration slot data (slotId/Target/Consumed)
      if (_hydrationChar != null) {
        await _hydrationChar!.setNotifyValue(true);
        _hydrationChar!.onValueReceived.listen((value) async {
          final data = String.fromCharCodes(value);
          log("Hydration Slot Data: $data", name: "BLE_Cubit");

          final updatedEntry = _parseHydrationSlotData(data);
          if (updatedEntry != null) {
            _hydrationController.add([updatedEntry]);
            await dbHelper.insertOrUpdateSlot(updatedEntry);
          }

          _sendAck(device);
        });
      }

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

    emit(state.copyWith(battery: battery, volume: volume, percent: percent));
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

  HydrationEntry? _parseHydrationSlotData(String payload) {
    try {
      if (payload.isEmpty || payload.toLowerCase() == 'na') return null;

      final parts = payload.split('/');
      if (parts.length < 3)
        throw FormatException("Invalid slot payload: $payload");

      final slotId = int.parse(parts[0]);
      final target = double.parse(parts[1]);
      final consumed = double.parse(parts[2]);

      if (slotId < 0 || slotId >= HydrationSlot.values.length) {
        throw RangeError("Invalid slot index: $slotId");
      }

      final slot = HydrationSlot.values[slotId];
      final now = DateTime.now();

      return HydrationEntry(
        slot: slot,
        startTime: TimeOfDay(hour: now.hour, minute: now.minute),
        endTime: TimeOfDay(hour: now.hour, minute: now.minute + 1),
        waterDrank: consumed,
        amount: target,
      );
    } catch (e) {
      log("Failed to parse hydration slot data: $e", name: "BLE_Cubit");
      return null;
    }
  }

  Future<void> _sendAck(BluetoothDevice device,
      {bool sendAckToHydrationSlotsCharacteristic = false}) async {
    try {
      if (sendAckToHydrationSlotsCharacteristic) {
        await _hydrationDataChar?.write("ACK".codeUnits, withoutResponse: true);
      } else {
        await _ackChar?.write("ACK".codeUnits, withoutResponse: true);
      }
    } catch (e) {
      log("ACK failed: $e", name: "BLE_Cubit");
    }
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
    if (_ackChar == null || _pendingSlots.isEmpty) return;

    try {
      final payload = _pendingSlots.map((slot) {
        final start = _timeOfDayToEpoch(slot.startTime);
        final end = _timeOfDayToEpoch(slot.endTime);
        return "${slot.slot.label}/${slot.slot.index}/$start/$end/${slot.amount}";
      }).join("|");

      log("Flushing hydration slots: $payload");
      await _ackChar!.write(payload.codeUnits, withoutResponse: true);
      _pendingSlots.clear();

      emit(state.copyWith(
        status: BleStatus.connected,
        message: "Hydration slots synced",
      ));
    } catch (e) {
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

// import 'dart:async';
// import 'dart:developer';
// import 'package:bloc/bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:hydrify/cubit/hydration/hydration_sync.dart';
// import 'package:hydrify/helpers/database_helper.dart';
// import 'package:hydrify/models/hydration_entry.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// part 'ble_state.dart';

// class BleCubit extends Cubit<BleState> implements HydrationSync {
//   BleCubit() : super(const BleState());
//   final _hydrationController =
//       StreamController<List<HydrationEntry>>.broadcast();

//   final Guid serviceUUID = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
//   final Guid dataUUID = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
//   final Guid hydrationDataUUID = Guid("6E400004-B5A3-F393-E0A9-E50E24DCCA9E");
//   final Guid ackUUID = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
//   final Guid hydrationCharUUID = Guid("6E400005-B5A3-F393-E0A9-E50E24DCCA9E");

//   BluetoothCharacteristic? _dataChar;
//   BluetoothCharacteristic? _ackChar;
//   BluetoothCharacteristic? _hydrationDataChar;

//   StreamSubscription<List<ScanResult>>? _scanSub;
//   StreamSubscription<BluetoothConnectionState>? _connectionSub;

//   String? savedDeviceName;
//   String? savedDeviceId;

//   final bool _isReconnecting = false;
//   final dbHelper = DatabaseHelper();
//   final List<HydrationEntry> _pendingSlots = [];

//   Future<void> start() async {
//     emit(
//       state.copyWith(
//         status: BleStatus.initializing,
//         message: "Initializing...",
//       ),
//     );

//     await _waitForBluetoothOn(() async {
//       final prefs = await SharedPreferences.getInstance();
//       savedDeviceName = prefs.getString('last_device_name');
//       savedDeviceId = prefs.getString('last_device_id');

//       final bool isFirst = (savedDeviceName == null || savedDeviceId == null);
//       emit(
//         state.copyWith(
//           status: BleStatus.initializing,
//           message: "Initializing Bluetooth",
//           isFirstConnection: isFirst,
//         ),
//       );

//       // Show one-time message if first time connecting
//       // if (isFirst && !(prefs.getBool('shownReconnectMessage') ?? false)) {
//       //   Fluttertoast.showToast(
//       //       msg: "Long press on bottle cap to reconnect",
//       //       toastLength: Toast.LENGTH_LONG,
//       //       gravity: ToastGravity.CENTER);
//       //   await prefs.setBool('shownReconnectMessage', true);
//       // }

//       if (!isFirst) {
//         _scanForLastDevice();
//       } else {
//         _scanForAllDevices();
//       }
//     });
//   }

//   Future<void> _waitForBluetoothOn(Future<void> Function() onReady) async {
//     if (await FlutterBluePlus.isSupported == false) {
//       emit(
//         state.copyWith(
//           status: BleStatus.error,
//           message: "Bluetooth not supported",
//         ),
//       );
//       return;
//     }

//     final currentState = await FlutterBluePlus.adapterState.first;
//     if (currentState == BluetoothAdapterState.on) {
//       await onReady();
//       return;
//     }

//     emit(
//       state.copyWith(
//         status: BleStatus.error,
//         message: "Please turn on Bluetooth",
//       ),
//     );

//     await FlutterBluePlus.adapterState
//         .where((s) => s == BluetoothAdapterState.on)
//         .first;

//     await onReady();
//   }

//   void _scanForLastDevice() {
//     if (savedDeviceId == null && savedDeviceName == null) {
//       return;
//     }

//     emit(
//       state.copyWith(
//         status: BleStatus.scanning,
//         message: "Scanning for last device...",
//       ),
//     );

//     _scanSub?.cancel();
//     FlutterBluePlus.startScan(
//       timeout: const Duration(seconds: 20),
//       withServices: [serviceUUID],
//     );

//     _scanSub = FlutterBluePlus.scanResults.listen(
//       (results) {
//         for (var r in results) {
//           if (r.device.id.id == savedDeviceId ||
//               r.device.name == savedDeviceName) {
//             _scanSub?.cancel();

//             FlutterBluePlus.stopScan();
//             _connectToDevice(r.device);
//             return;
//           }
//         }
//       },
//       onError: (e) {
//         emit(
//           state.copyWith(status: BleStatus.error, message: "Scan error: $e"),
//         );
//         _rescan(lastDeviceOnly: true);
//       },
//     );

//     Future.delayed(const Duration(seconds: 20), () {
//       if (state.status == BleStatus.scanning) {
//         FlutterBluePlus.stopScan().then((_) {
//           _scanForLastDevice();
//         });
//       }
//     });
//   }

//   void _scanForAllDevices() {
//     emit(
//       state.copyWith(
//         status: BleStatus.scanning,
//         message: "Scanning for BLE devices...",
//       ),
//     );

//     _scanSub?.cancel();

//     FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));

//     _scanSub = FlutterBluePlus.scanResults.listen(
//       (results) {
//         if (results.isNotEmpty) {
//           var filteredDevices = results.where((it) {
//             return it.advertisementData.serviceUuids.contains(serviceUUID);
//           }).toList();
//           emit(state.copyWith(scannedDevices: filteredDevices));
//         }
//       },
//       onError: (e) {
//         emit(
//           state.copyWith(status: BleStatus.error, message: "Scan error: $e"),
//         );
//         _rescan();
//       },
//     );

//     Future.delayed(const Duration(seconds: 20), () async {
//       if (state.status == BleStatus.scanning) {
//         FlutterBluePlus.stopScan().then((_) {
//           _scanForAllDevices();
//         });
//       }
//     });
//   }

//   Future<void> _rescan({
//     bool lastDeviceOnly = false,
//     Duration delay = const Duration(milliseconds: 200),
//   }) async {
//     if (FlutterBluePlus.isScanningNow) {
//       return;
//     }

//     await Future.delayed(delay);

//     if (lastDeviceOnly) {
//       _scanForLastDevice();
//     } else {
//       _scanForAllDevices();
//     }
//   }

//   Future<void> connectToSelectedDevice(BluetoothDevice device) async {
//     FlutterBluePlus.stopScan();
//     _scanSub?.cancel();
//     _connectToDevice(device);
//   }

//   Future<void> _connectToDevice(BluetoothDevice device) async {
//     emit(
//       state.copyWith(
//         status: BleStatus.connecting,
//         message: "Connecting to ${device.name}...",
//       ),
//     );

//     try {
//       await device.connect(autoConnect: false, timeout: Duration(seconds: 6));
//       await device.connectionState
//           .where((s) => s == BluetoothConnectionState.connected)
//           .first;

//       _listenToConnection(device);

//       final prefs = await SharedPreferences.getInstance();
//       final bool wasFirst = (savedDeviceId == null || savedDeviceName == null);
//       await prefs.setString('last_device_id', device.id.id);
//       await prefs.setString('last_device_name', device.name);

//       savedDeviceId = device.id.id;
//       savedDeviceName = device.name;
//       if (wasFirst) {
//         emit(state.copyWith(isFirstConnection: false));
//       }

//       await _discoverServices(device);
//       // ✅ Save flag that BLE connected at least once
//       await prefs.setBool('ble_connected_once', true);
//     } catch (e) {
//       emit(
//         state.copyWith(
//           status: BleStatus.error,
//           message: "Connection failed: $e",
//         ),
//       );
//       _rescan(
//         lastDeviceOnly: (savedDeviceId != null || savedDeviceName != null),
//       );
//     }
//   }

//   Future<void> _discoverServices(BluetoothDevice device) async {
//     try {
//       final services = await device.discoverServices();
//       for (var s in services) {
//         if (s.uuid == serviceUUID) {
//           for (var c in s.characteristics) {
//             if (c.uuid == dataUUID) _dataChar = c;
//             if (c.uuid == ackUUID) _ackChar = c;
//             if (c.uuid == hydrationDataUUID) {
//               _hydrationDataChar = c;
//             }
//           }
//         }
//       }

//       if (_dataChar == null || _ackChar == null) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.remove('last_device_id');
//         await prefs.remove('last_device_name');

//         savedDeviceId = null;
//         savedDeviceName = null;

//         emit(
//           state.copyWith(
//             status: BleStatus.error,
//             message: "Required characteristics not found",
//             isFirstConnection: true,
//           ),
//         );

//         await device.disconnect();
//         _rescan(lastDeviceOnly: false);
//         return;
//       }

//       _dataChar!.onValueReceived.listen((value) {
//         // Fluttertoast.showToast(
//         //     msg: "BottleDataReceived : $value");
//         final data = String.fromCharCodes(value);
//         log("Received data is $data", name: "BLE_Cubit");
//         _parseData(data);
//         _sendAck(device);
//       });

//       _hydrationDataChar!.onValueReceived.listen((value) {
//         Fluttertoast.showToast(msg: "HydrationDataReceived : $value");
//         final data = String.fromCharCodes(value);
//         log("Received data is $data", name: "BLE_Cubit");
//         var hydrationUpdatedSlots = _parseHydrationData(data);
//         if (hydrationUpdatedSlots.isNotEmpty) {
//           _hydrationController.add(hydrationUpdatedSlots);
//         }
//         _sendAck(device, sendAckToHydrationSlotsCharacteristic: true);
//       });

//       await _dataChar!.setNotifyValue(true);

//       await _hydrationDataChar!.setNotifyValue(true);

//       emit(
//         state.copyWith(
//           status: BleStatus.connected,
//           message: "Connected to ${device.name}",
//         ),
//       );

//       await _flushPendingSlots();
//     } catch (e) {
//       try {
//         await device.disconnect();
//       } catch (_) {}

//       emit(
//         state.copyWith(
//           status: BleStatus.error,
//           message: "Service discovery failed: $e",
//         ),
//       );

//       _rescan(lastDeviceOnly: savedDeviceId != null || savedDeviceName != null);
//     }
//   }

//   void _parseData(String data) {
//     final parts = data.split(';');
//     int? battery;
//     double? volume;
//     int? percent;

//     for (var p in parts) {
//       if (p.contains('battery=')) {
//         battery = int.tryParse(p.split('=')[1]);
//       }
//       if (p.contains('volume=')) {
//         volume = double.tryParse(p.split('=')[1]);
//       }
//       if (p.contains('percent=')) {
//         percent = int.tryParse(p.split('=')[1]);
//       }
//     }

//     emit(state.copyWith(
//       battery: battery,
//       volume: volume,
//       percent: percent,
//     ));
//   }

//   List<HydrationEntry> _parseHydrationData(String payload) {
//     if (payload.isEmpty) return [];
//     if (payload.toLowerCase() == "na") return [];
//     return payload.split("|").map((entry) {
//       final parts = entry.split("/");
//       if (parts.length < 5) {
//         throw FormatException("Invalid payload format: $entry");
//       }

//       final index = int.parse(parts[1]);
//       final startEpoch = int.parse(parts[2]);
//       final endEpoch = int.parse(parts[3]);
//       final amount = int.parse(parts[4]);

//       final slot = HydrationSlot.values[index];

//       return HydrationEntry(
//         slot: slot,
//         startTime: _epochToTimeOfDay(startEpoch),
//         endTime: _epochToTimeOfDay(endEpoch),
//         waterDrank: amount.round().toDouble(),
//         amount: 0,
//       );
//     }).toList();
//   }

//   Future<void> _sendAck(BluetoothDevice device,
//       {bool sendAckToHydrationSlotsCharacteristic = false}) async {
//     // try {
//     //   emit(
//     //     state.copyWith(status: BleStatus.sendingAck, message: "Sending ACK..."),
//     //   );
//     //   if (sendAckToHydrationSlotsCharacteristic == true) {
//     //     await _hydrationDataChar?.write("ACK".codeUnits, withoutResponse: true);
//     //     await device.disconnect();
//     //   } else {
//     //     await _ackChar?.write("ACK".codeUnits, withoutResponse: true);
//     //     await device.disconnect();
//     //   }

//     //   emit(
//     //     state.copyWith(
//     //       status: BleStatus.disconnected,
//     //       message: "Device sleeping, will reconnect...",
//     //     ),
//     //   );
//     // } catch (e) {
//     //   emit(state.copyWith(status: BleStatus.error, message: "ACK failed: $e"));
//     // }
//   }

  // Future<void> forgetDevice() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('last_device_id');
  //   await prefs.remove('last_device_name');

  //   savedDeviceId = null;
  //   savedDeviceName = null;

  //   emit(
  //     state.copyWith(
  //       status: BleStatus.scanning,
  //       isFirstConnection: true,
  //       message: "Device forgotten. \nReady to scan for new devices.",
  //     ),
  //   );

  //   if (FlutterBluePlus.isScanningNow) {
  //     await FlutterBluePlus.stopScan();
  //   }
  //   emit(
  //     state.copyWith(
  //       status: BleStatus.scanning,
  //       isFirstConnection: true,
  //       scannedDevices: [],
  //       message: "Device forgotten. \nReady to scan for new devices.",
  //     ),
  //   );

  //   _scanForAllDevices();
  // }

//   void _listenToConnection(BluetoothDevice device) {
//     _connectionSub?.cancel();

//     _connectionSub = device.connectionState.listen((stateChange) {
//       switch (stateChange) {
//         case BluetoothConnectionState.connected:
//           emit(state.copyWith(
//             status: BleStatus.connected,
//             message: "Connected to ${device.name}",
//           ));
//           break;

//         case BluetoothConnectionState.disconnected:
//           emit(state.copyWith(
//             status: BleStatus.disconnected,
//             message: "Device disconnected",
//           ));

//           if (savedDeviceId != null || savedDeviceName != null) {
//             _rescan(lastDeviceOnly: true);
//           }
//           break;

//         case BluetoothConnectionState.connecting:
//           emit(state.copyWith(
//             status: BleStatus.connecting,
//             message: "Connecting to ${device.name}...",
//           ));
//           break;

//         default:
//           {}
//       }
//     });
//   }

//   Future<void> _flushPendingSlots() async {
//     if (_ackChar == null || _pendingSlots.isEmpty) return;

//     try {
//       final payload = _pendingSlots.map((slot) {
//         final startEpoch = _timeOfDayToEpoch(slot.startTime);
//         final endEpoch = _timeOfDayToEpoch(slot.endTime);

//         return "${slot.slot.label}/${slot.slot.index}/$startEpoch/$endEpoch/${slot.amount}";
//       }).join("|");

//       log("Flushing hydration slots: $payload");

//       await _ackChar!.write(payload.codeUnits, withoutResponse: true);

//       _pendingSlots.clear();

//       emit(state.copyWith(
//         status: BleStatus.connected,
//         message: "Hydration slots synced",
//       ));
//     } catch (e) {
//       emit(
//           state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
//     }
//   }

//   Future<void> _fetchUpdatedSlots() async {
//     if (_ackChar == null || _pendingSlots.isEmpty) return;

//     try {
//       final payload = _pendingSlots.map((slot) {
//         final startEpoch = _timeOfDayToEpoch(slot.startTime);
//         final endEpoch = _timeOfDayToEpoch(slot.endTime);

//         return "${slot.slot.label}/${slot.slot.index}/$startEpoch/$endEpoch/${slot.amount}";
//       }).join("|");

//       log("Flushing hydration slots: $payload");

//       await _ackChar!.write(payload.codeUnits, withoutResponse: true);

//       _pendingSlots.clear();

//       emit(state.copyWith(
//         status: BleStatus.connected,
//         message: "Hydration slots synced",
//       ));
//     } catch (e) {
//       emit(
//           state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
//     }
//   }
//   /* For testing */

//   Future<void> forceFlushSlots() async {
//     try {
//       var slots = await dbHelper.getAllSlots();

//       final payload = slots.map((slot) {
//         final startEpoch = _timeOfDayToEpoch(slot.startTime);
//         final endEpoch = _timeOfDayToEpoch(slot.endTime);

//         return "${slot.slot.label}/${slot.slot.index}/$startEpoch/$endEpoch/${slot.amount}";
//       }).join("|");

//       log("Flushing hydration slots: $payload");

//       await _ackChar!.write(payload.codeUnits, withoutResponse: true);

//       slots.clear();

//       emit(state.copyWith(
//         status: BleStatus.connected,
//         message: "Hydration slots synced",
//       ));
//     } catch (e) {
//       emit(
//           state.copyWith(status: BleStatus.error, message: "Flush failed: $e"));
//     }
//   }

//   int _timeOfDayToEpoch(TimeOfDay tod) {
//     final now = DateTime.now();
//     final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
//     return dt.millisecondsSinceEpoch ~/ 1000; // seconds since epoch
//   }

//   TimeOfDay _epochToTimeOfDay(int epoch) {
//     final hour = epoch ~/ 3600;
//     final minute = (epoch % 3600) ~/ 60;
//     return TimeOfDay(hour: hour, minute: minute);
//   }

//   // @override
//   // Future<void> queueHydrationSlots(List<HydrationEntry> slots) async {
//   //   // Add to pending queue
//   //   _pendingSlots.clear();
//   //   _pendingSlots.addAll(slots);

//   //   if (state.status == BleStatus.connected) {
//   //     await _flushPendingSlots();
//   //   } else {
//   //     emit(state.copyWith(message: "Device not connected, will sync later"));
//   //   }
//   // }

//   @override
//   Future<void> queueHydrationSlots(List<HydrationEntry> entries) async {
//     _pendingSlots.clear();
//     _pendingSlots.addAll(entries);
//     if (state.status == BleStatus.connected) {
//       await _flushPendingSlots();
//     } else {
//       emit(state.copyWith(message: "Device not connected, will sync later"));
//     }
//   }

//   @override
//   Stream<List<HydrationEntry>> get hydrationUpdates =>
//       _hydrationController.stream;
// }
