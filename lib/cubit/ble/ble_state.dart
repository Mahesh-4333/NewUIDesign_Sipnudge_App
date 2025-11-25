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

  const BleState({
    this.status = BleStatus.idle,
    this.message = '',
    this.battery,
    this.volume,
    this.percent,
    this.scannedDevices = const [],
    this.isFirstConnection = true,
  });

  BleState copyWith({
    BleStatus? status,
    String? message,
    final int? battery,
    final double? volume,
    final int? percent,
    List<ScanResult>? scannedDevices,
    bool? isFirstConnection,
  }) {
    return BleState(
      status: status ?? this.status,
      message: message ?? this.message,
      battery: battery ?? this.battery,
      volume: volume ?? this.volume,
      percent: percent ?? this.percent,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      isFirstConnection: isFirstConnection ?? this.isFirstConnection,
    );
  }
}
