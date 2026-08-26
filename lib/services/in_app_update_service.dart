import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update_flutter/in_app_update_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  // The iOS App Store ID
  static const String appStoreId = '6754545762';

  /// Checks if an update is available and prompts the user to install it.
  Future<void> checkAndTriggerUpdate() async {
    // Skip during local debug builds.
    if (kDebugMode) {
      debugPrint(
          '[InAppUpdateService] Skipping in-app update check in debug mode.');
      return;
    }

    try {
      if (Platform.isAndroid) {
        final InAppUpdateFlutter updater = InAppUpdateFlutter();
        final info = await updater.checkUpdateAndroid();

        if (info.updateAvailability ==
            UpdateAvailabilityAndroid.updateAvailable) {
          if (info.isImmediateUpdateAllowed) {
            await updater.startImmediateUpdateAndroid();
          } else if (info.isFlexibleUpdateAllowed) {
            await updater.startFlexibleUpdateAndroid();
            updater.installStateStreamAndroid.listen((state) {
              if (state.status == InstallStatusAndroid.downloaded) {
                updater.completeUpdateAndroid();
              }
            });
          }
        }
      } else if (Platform.isIOS) {
        await _checkIosUpdate();
      }
    } catch (e) {
      debugPrint('[InAppUpdateService] Error during in-app update check: $e');
    }
  }

  /// Fetches the latest version from the iTunes lookup API and opens the
  /// App Store only if a newer version is actually available.
  Future<void> _checkIosUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version; // e.g. "1.1.0"

      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?id=$appStoreId&country=in',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return;

      final storeVersion = results.first['version'] as String?;
      if (storeVersion == null) return;

      debugPrint(
        '[InAppUpdateService] Installed: $installedVersion | Store: $storeVersion',
      );

      if (_isNewerVersion(storeVersion, installedVersion)) {
        debugPrint(
            '[InAppUpdateService] Update available — opening App Store.');
        final storeUrl = Uri.parse(
          'https://apps.apple.com/app/id$appStoreId',
        );
        if (await canLaunchUrl(storeUrl)) {
          await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        debugPrint('[InAppUpdateService] App is up to date.');
      }
    } catch (e) {
      debugPrint('[InAppUpdateService] iOS update check error: $e');
    }
  }

  /// Returns true if [storeVersion] is strictly newer than [installedVersion].
  /// Compares each numeric segment (major.minor.patch).
  bool _isNewerVersion(String storeVersion, String installedVersion) {
    final storeParts = storeVersion.split('.').map(_parseSegment).toList();
    final installedParts =
        installedVersion.split('.').map(_parseSegment).toList();

    final length = storeParts.length > installedParts.length
        ? storeParts.length
        : installedParts.length;

    for (int i = 0; i < length; i++) {
      final s = i < storeParts.length ? storeParts[i] : 0;
      final ins = i < installedParts.length ? installedParts[i] : 0;
      if (s > ins) return true;
      if (s < ins) return false;
    }
    return false; // versions are equal
  }

  int _parseSegment(String s) {
    // Strip any pre-release suffix (e.g. "1" from "1-config4")
    return int.tryParse(s.split('-').first) ?? 0;
  }
}
