import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/screens/levelreached.dart';
import 'package:hydrify/services/api_service.dart';

/// Singleton that owns the achievement level-up check and dialog.
///
/// Works from any context (no BuildContext needed) — uses [navigatorKey].
///
/// Setup (do once in main.dart):
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
/// AchievementNotifier.instance.navigatorKey = navigatorKey;
/// // then pass navigatorKey to MaterialApp
/// ```
///
/// Trigger after a sync:
/// ```dart
/// await AchievementNotifier.instance.checkAndShow();
/// ```
class AchievementNotifier {
  AchievementNotifier._();
  static final AchievementNotifier instance = AchievementNotifier._();

  /// Set once from main.dart, also passed to MaterialApp.navigatorKey.
  GlobalKey<NavigatorState>? navigatorKey;

  final ApiService _apiService = ApiService();

  // Local fallback key (server is authoritative, this covers offline sessions).
  static const String _lastShownLevelKey = 'achievements_last_shown_level';

  bool _isShowing = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fetch achievement data from the server for [userId] (or reads userId from
  /// SharedPrefs if not provided), then shows the level-up dialog if a new
  /// level was unlocked since the last acknowledgement.
  Future<void> checkAndShow({String? userId}) async {
    final uid = userId ?? await SharedPrefsHelper.getUserId();
    if (uid == null || uid.isEmpty) return;

    try {
      final data = await _apiService.getAchievements(uid);
      if (data == null) return;

      final int currentLevel = (data['currentLevel'] as num?)?.toInt() ?? 0;
      final int serverLastShown =
          (data['lastShownLevel'] as num?)?.toInt() ?? 0;

      // Use the higher of server vs local to handle offline edge-cases.
      final prefs = await SharedPreferences.getInstance();
      final localLastShown = prefs.getInt(_lastShownLevelKey) ?? 0;
      final lastShownLevel = max(serverLastShown, localLastShown);

      if (currentLevel <= 0 || currentLevel <= lastShownLevel) return;

      final rawExactMap =
          (data['exactLevelToIntakeMap'] as Map?)?.map((k, v) =>
                  MapEntry(int.tryParse(k.toString()) ?? 0, v.toString())) ??
              <int, String>{};

      Console.log(
        tag: 'AchievementNotifier',
        value: 'New level $currentLevel unlocked (last shown: $lastShownLevel)',
      );

      await _showDialog(
        userId: uid,
        newLevel: currentLevel,
        exactMap: rawExactMap,
      );
    } catch (e) {
      Console.log(
          tag: 'AchievementNotifier', value: 'checkAndShow error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _showDialog({
    required String userId,
    required int newLevel,
    required Map<int, String> exactMap,
  }) async {
    if (_isShowing) return;

    // We need the overlay context from the navigator.
    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) {
      Console.log(
          tag: 'AchievementNotifier',
          value: 'Navigator not ready — dialog skipped');
      return;
    }

    _isShowing = true;

    final confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 2));
    final screenshotCtrl = ScreenshotController();
    final waterIntake = exactMap[newLevel] ?? '0';

    confettiCtrl.play();
    VibrationHelper.vibrate(duration: 300);

    await showLevelUpDialog(
      overlay.context,
      newLevel,
      waterIntake,
      screenshotController: screenshotCtrl,
      confettiController: confettiCtrl,
      createParticlePath: _drawRandomShape,
      onShare: (dialogContext) async {
        confettiCtrl.stop();
        try {
          final bytes = await screenshotCtrl.capture(pixelRatio: 2.0);
          if (bytes == null) return;
          final dir = await getTemporaryDirectory();
          final file =
              await File('${dir.path}/level_up_notifier.png').create();
          await file.writeAsBytes(bytes);
          Navigator.pop(dialogContext);
          await Share.shareXFiles(
            [XFile(file.path)],
            text: "I've reached Level $newLevel on Sipnudge! 💧",
            subject: 'My Hydration Achievement',
          );
        } catch (e) {
          debugPrint('AchievementNotifier share error: $e');
        }
      },
    );

    confettiCtrl.stop();
    confettiCtrl.dispose();
    _isShowing = false;

    // Persist acknowledgement on server (survives reinstalls).
    final ok = await _apiService.acknowledgeAchievementLevel(userId, newLevel);
    if (!ok) {
      // Offline: write locally so we don't re-show in the same session.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastShownLevelKey, newLevel);
    }
  }

  // ---------------------------------------------------------------------------
  // Confetti particle helpers (self-contained, no external dependency)
  // ---------------------------------------------------------------------------

  Path _drawRandomShape(Size size) {
    final choice = Random().nextInt(4);
    switch (choice) {
      case 0:
        return _star(size);
      case 1:
        return Path()
          ..addOval(Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2));
      case 2:
        return Path()
          ..addRect(Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: size.width,
              height: size.height));
      default:
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
    }
  }

  Path _star(Size size) {
    const pts = 5;
    final half = size.width / 2;
    final outer = half;
    final inner = half / 2.5;
    final step = 2 * pi / pts;
    final path = Path();
    const startAngle = -pi / 2;
    path.moveTo(
        half + outer * cos(startAngle), half + outer * sin(startAngle));
    for (var i = 0; i < pts; i++) {
      final a = startAngle + step * i;
      path.lineTo(half + outer * cos(a), half + outer * sin(a));
      path.lineTo(
          half + inner * cos(a + step / 2), half + inner * sin(a + step / 2));
    }
    path.close();
    return path;
  }
}
