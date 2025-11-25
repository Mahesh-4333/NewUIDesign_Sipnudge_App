import 'package:permission_handler/permission_handler.dart';

class BLEPermissionHelper {
  static Future<bool> requestPermissions() async {
    if (await _hasPermissions()) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,

      // 🔹 Add notification permission
      Permission.notification,

      // 🔹 Add audio-related permissions
      Permission.audio,
      Permission.microphone,
    ].request();

    final bluetoothGranted =
        statuses[Permission.bluetooth]?.isGranted == true &&
            statuses[Permission.bluetoothScan]?.isGranted == true &&
            statuses[Permission.bluetoothConnect]?.isGranted == true;

    final notificationGranted =
        statuses[Permission.notification]?.isGranted == true;

    final audioGranted = statuses[Permission.audio]?.isGranted == true &&
        statuses[Permission.microphone]?.isGranted == true;

    return bluetoothGranted && notificationGranted && audioGranted;
  }

  static Future<bool> _hasPermissions() async {
    return await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.notification.isGranted &&
        await Permission.audio.isGranted &&
        await Permission.microphone.isGranted;
  }
}
