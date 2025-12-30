import 'package:vibration/vibration.dart';

class VibrationHelper {
  static Future<void> vibrate({int duration = 250, int amplitude = -1}) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration, amplitude: amplitude);
    }
  }

  static Future<void> pattern({
    required List<int> timings,
    List<int> intensities = const [],
  }) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: timings, intensities: intensities);
    }
  }

  static Future<void> warning() async {
    if (await Vibration.hasCustomVibrationsSupport() ?? false) {
      Vibration.vibrate(
          pattern: [0, 150, 100, 150], intensities: [0, 200, 0, 200]);
    } else {
      Vibration.vibrate(duration: 400);
    }
  }

  static Future<void> lightTap() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30, amplitude: 100);
    }
  }

  static void stop() {
    Vibration.cancel();
  }
}
