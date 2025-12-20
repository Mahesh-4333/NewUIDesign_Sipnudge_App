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
      this.slotData});

  BleState copyWith(
      {BleStatus? status,
      String? message,
      final int? battery,
      final double? volume,
      final int? percent,
      List<ScanResult>? scannedDevices,
      bool? isFirstConnection,
      bool? isHydration30DaysDataSync,
      dynamic bottleData,
      dynamic historyData,
      dynamic slotData}) {
    return BleState(
        status: status ?? this.status,
        message: message ?? this.message,
        battery: battery ?? this.battery,
        volume: volume ?? this.volume,
        percent: percent ?? this.percent,
        scannedDevices: scannedDevices ?? this.scannedDevices,
        isFirstConnection: isFirstConnection ?? this.isFirstConnection,
        isHydration30DaysDataSync:
            isHydration30DaysDataSync ?? this.isHydration30DaysDataSync,
        bottleData: bottleData ?? this.bottleData,
        historyData: historyData ?? this.historyData,
        slotData: slotData ?? this.slotData);
  }
}
