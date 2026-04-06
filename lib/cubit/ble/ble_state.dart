part of 'ble_cubit.dart';

enum BleStatus {
  idle,
  scanning,
  connecting,
  connected,
  readingData,
  sendingAck,
  disconnected,
  error,
  initializing,
}

class BleState {
  final BleStatus status;
  final String message;
  final int? battery;
  final double? volume;
  final int? percent;
  final List<ScanResult> scannedDevices;
  final bool isFirstConnection;
  final bool isHydration30DaysDataSync;
  final dynamic bottleData;
  final dynamic historyData;
  final dynamic slotData;
  final double currentHydrationValue;
  final DateTime? ts;
  final int commandSentTimestamp;
  final String? lastCommandSent;
  final bool? isServiceDiscoveryDone;

  const BleState({
    this.status = BleStatus.idle,
    this.message = '',
    this.battery,
    this.volume,
    this.percent,
    this.scannedDevices = const [],
    this.isFirstConnection = true,
    this.isHydration30DaysDataSync = false,
    this.bottleData,
    this.historyData,
    this.slotData,
    this.currentHydrationValue = 0,
    this.ts,
    this.commandSentTimestamp = 0,
    this.lastCommandSent,
    this.isServiceDiscoveryDone,
  });

  BleState copyWith({
    BleStatus? status,
    String? message,
    int? battery,
    double? volume,
    int? percent,
    DateTime? ts,
    List<ScanResult>? scannedDevices,
    bool? isFirstConnection,
    bool? isHydration30DaysDataSync,
    dynamic bottleData,
    dynamic historyData,
    dynamic slotData,
    double? currentHydrationValue,
    int? commandSentTimestamp,
    String? lastCommandSent,
    bool? isServiceDiscoveryDone,
  }) {
    return BleState(
      status: status ?? this.status,
      message: message ?? this.message,
      battery: battery ?? this.battery,
      volume: volume ?? this.volume,
      percent: percent ?? this.percent,
      ts: ts ?? this.ts,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      isFirstConnection: isFirstConnection ?? this.isFirstConnection,
      isHydration30DaysDataSync:
          isHydration30DaysDataSync ?? this.isHydration30DaysDataSync,
      bottleData: bottleData ?? this.bottleData,
      historyData: historyData ?? this.historyData,
      slotData: slotData ?? this.slotData,
      currentHydrationValue:
          currentHydrationValue ?? this.currentHydrationValue,
      commandSentTimestamp: commandSentTimestamp ?? this.commandSentTimestamp,
      lastCommandSent: lastCommandSent ?? this.lastCommandSent,
        isServiceDiscoveryDone:
        isServiceDiscoveryDone ?? this.isServiceDiscoveryDone
    );
  }
}
