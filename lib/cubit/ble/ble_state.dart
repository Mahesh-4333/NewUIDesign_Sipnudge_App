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
  final double? refill;
  final int? percent;
  final double? temp;
  final double? bqTemp;
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
  final bool manualRetryRequired;
  final int refreshTrigger;
  /// True when iOS Low Power Mode is active — background BLE uploads are deferred.
  final bool isLowPowerModeActive;
  final bool showWifiConnectedDialog;
  final String? wifiConnectedSsid;
  final String? wifiConnectedIp;
  final bool isWifiProvisioning;
  final bool showWifiFailedDialog;
  final String? wifiFailedReason;

  const BleState({
    this.status = BleStatus.idle,
    this.message = '',
    this.battery,
    this.volume,
    this.refill,
    this.percent,
    this.temp,
    this.bqTemp,
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
    this.manualRetryRequired = false,
    this.refreshTrigger = 0,
    this.isLowPowerModeActive = false,
    this.showWifiConnectedDialog = false,
    this.wifiConnectedSsid,
    this.wifiConnectedIp,
    this.isWifiProvisioning = false,
    this.showWifiFailedDialog = false,
    this.wifiFailedReason,
  });

  BleState copyWith({
    BleStatus? status,
    String? message,
    int? battery,
    double? volume,
    double? refill,
    int? percent,
    double? temp,
    double? bqTemp,
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
    bool? manualRetryRequired,
    int? refreshTrigger,
    bool? isLowPowerModeActive,
    bool? showWifiConnectedDialog,
    String? wifiConnectedSsid,
    String? wifiConnectedIp,
    bool? isWifiProvisioning,
    bool? showWifiFailedDialog,
    String? wifiFailedReason,
  }) {
    return BleState(
      status: status ?? this.status,
      message: message ?? this.message,
      battery: battery ?? this.battery,
      volume: volume ?? this.volume,
      refill: refill ?? this.refill,
      percent: percent ?? this.percent,
      temp: temp,
      bqTemp: bqTemp,
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
          isServiceDiscoveryDone ?? this.isServiceDiscoveryDone,
      manualRetryRequired: manualRetryRequired ?? this.manualRetryRequired,
      refreshTrigger: refreshTrigger ?? this.refreshTrigger,
      isLowPowerModeActive: isLowPowerModeActive ?? this.isLowPowerModeActive,
      showWifiConnectedDialog: showWifiConnectedDialog ?? this.showWifiConnectedDialog,
      wifiConnectedSsid: wifiConnectedSsid ?? this.wifiConnectedSsid,
      wifiConnectedIp: wifiConnectedIp ?? this.wifiConnectedIp,
      isWifiProvisioning: isWifiProvisioning ?? this.isWifiProvisioning,
      showWifiFailedDialog: showWifiFailedDialog ?? this.showWifiFailedDialog,
      wifiFailedReason: wifiFailedReason ?? this.wifiFailedReason,
    );
  }
}
