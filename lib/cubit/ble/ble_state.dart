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

  const BleState(
      {this.status = BleStatus.idle,
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
      this.ts});

  BleState copyWith(
      {BleStatus? status,
      String? message,
      final int? battery,
      final double? volume,
      final int? percent,
      final DateTime? ts,
      List<ScanResult>? scannedDevices,
      bool? isFirstConnection,
      bool? isHydration30DaysDataSync,
      dynamic bottleData,
      dynamic historyData,
      dynamic slotData,
      double? currentHydrationValue}) {
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
            currentHydrationValue ?? this.currentHydrationValue);
  }
}
