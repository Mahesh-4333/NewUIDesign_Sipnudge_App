import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class VibrationHelper {
  static final AudioPlayer _player = AudioPlayer();

  // Guard flag to prevent stacking vibrations from rapid-fire events (e.g. picker scroll)
  static bool _isVibrating = false;

  static Future<void> vibrate({
    int duration = 250,
    int amplitude = -1,
    bool playSound = false,
  }) async {
    if (_isVibrating) {
      // Cancel any ongoing vibration before starting a new one
      Vibration.cancel();
    }
    if (await Vibration.hasVibrator() ?? false) {
      _isVibrating = true;
      await Vibration.vibrate(
        duration: duration,
        amplitude: amplitude,
      );
      _isVibrating = false;
      SystemSound.play(Platform.isIOS ? SystemSoundType.tick : SystemSoundType.click);
    }
  }

  static Future<void> pattern({
    required List<int> timings,
    List<int> intensities = const [],
  }) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.cancel();
      Vibration.vibrate(pattern: timings, intensities: intensities);
    }
  }

  static Future<void> warning() async {
    Vibration.cancel();
    if (await Vibration.hasCustomVibrationsSupport() ?? false) {
      Vibration.vibrate(
          pattern: [0, 150, 100, 150], intensities: [0, 200, 0, 200]);
    } else {
      Vibration.vibrate(duration: 400);
    }
  }

  static Future<void> lightTap() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.cancel();
      Vibration.vibrate(duration: 30, amplitude: 100);
    }
  }

  static void stop() {
    _isVibrating = false;
    Vibration.cancel();
    _player.stop();
  }
}
