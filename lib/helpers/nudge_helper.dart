import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';

class NudgeHelper {
  static const int oneHourMs = 60 * 60 * 1000;

  /// Returns remaining minutes if on cooldown, or 0 if free to nudge.
  static Future<int> getRemainingCooldownMinutes(String targetUserId) async {
    final lastTime = await SharedPrefsHelper.getLastNudgeTimestamp(targetUserId);
    if (lastTime == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastTime;
    if (elapsed < oneHourMs) {
      final remainingMs = oneHourMs - elapsed;
      return (remainingMs / (60 * 1000)).ceil();
    }
    return 0;
  }

  /// Sends a nudge with client-side & server-side 1-hour cooldown enforcement.
  /// Shows appropriate SnackBar and prevents spam clicking.
  static Future<void> triggerNudge({
    required BuildContext context,
    required String? currentUserId,
    required String targetUserId,
    required String targetUserName,
    VoidCallback? onStateChanged,
  }) async {
    if (currentUserId == null || currentUserId.isEmpty) {
      if (context.mounted) {
        _showSnackBar(
          context,
          "Please log in to send nudges.",
          isError: true,
        );
      }
      return;
    }

    // 1. Check local 1-hour cooldown
    final remainingMinutes = await getRemainingCooldownMinutes(targetUserId);
    if (remainingMinutes > 0) {
      if (context.mounted) {
        _showSnackBar(
          context,
          "⏳ You can nudge $targetUserName once every hour. Please wait $remainingMinutes min${remainingMinutes > 1 ? 's' : ''}.",
          isWarning: true,
        );
      }
      return;
    }

    try {
      final res = await ApiService().sendNudge(
        senderId: currentUserId,
        targetUserId: targetUserId,
      );

      final now = DateTime.now().millisecondsSinceEpoch;

      if (res['success'] == true) {
        // Save cooldown timestamp
        await SharedPrefsHelper.setLastNudgeTimestamp(targetUserId, now);
        onStateChanged?.call();
        if (context.mounted) {
          _showSnackBar(
            context,
            "💧 Nudge sent to $targetUserName!",
            isSuccess: true,
          );
        }
      } else if (res['cooldown'] == true) {
        final rem = (res['remainingMinutes'] as num?)?.toInt() ?? 60;
        final remainingMs = rem * 60 * 1000;
        await SharedPrefsHelper.setLastNudgeTimestamp(
          targetUserId,
          now - (oneHourMs - remainingMs),
        );
        onStateChanged?.call();
        if (context.mounted) {
          _showSnackBar(
            context,
            "⏳ You can nudge once per hour. Please wait $rem min${rem > 1 ? 's' : ''}.",
            isWarning: true,
          );
        }
      } else {
        if (context.mounted) {
          _showSnackBar(
            context,
            res['message'] ?? "Could not send nudge. Please try again.",
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint("Error in triggerNudge: $e");
      if (context.mounted) {
        _showSnackBar(
          context,
          "Could not send nudge. Please try again.",
          isError: true,
        );
      }
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isWarning = false,
    bool isError = false,
  }) {
    Color bg = const Color(0xFF007AFF);
    if (isWarning) bg = const Color(0xFFEA580C);
    if (isError) bg = const Color(0xFFDC2626);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
