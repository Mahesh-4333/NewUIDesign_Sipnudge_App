import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:hydrify/constants/assets_path.dart';

class FeedbackHelper {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  /// Call once (e.g. in initState) for zero delay playback
  static Future<void> init() async {
    if (_initialized) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
    _initialized = true;
  }

  static Future<void> click() async {
    // light system haptic
    HapticFeedback.selectionClick();

    // prevent overlapping sound
    await _player.stop();

    // play click
    await _player.play(
      AssetSource(AssetsPath.clickSound),
    );
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}
