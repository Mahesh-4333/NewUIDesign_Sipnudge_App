import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarManager {
  /// 🔒 Private static instance
  static final GoogleCalendarManager _instance =
      GoogleCalendarManager._internal();

  /// 🏭 Factory constructor
  factory GoogleCalendarManager() => _instance;

  /// 🧠 Private constructor
  GoogleCalendarManager._internal();

  static const _logTag = '[GoogleCalendarManager]';

  /// Google Sign-In with Calendar scope
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
  );

  GoogleSignInAccount? _currentUser;

  /// Ensures the user is signed in
  Future<bool> ensureSignedIn() async {
    try {
      debugPrint('$_logTag ensureSignedIn() called');

      _currentUser ??= await _googleSignIn.signInSilently();
      debugPrint(
        '$_logTag Silent sign-in result: ${_currentUser?.email}',
      );

      _currentUser ??= await _googleSignIn.signIn();
      debugPrint(
        '$_logTag Interactive sign-in result: ${_currentUser?.email}',
      );

      final isSignedIn = _currentUser != null;
      debugPrint('$_logTag Signed in: $isSignedIn');

      return isSignedIn;
    } catch (e, s) {
      debugPrint('$_logTag Sign-in failed: $e');
      debugPrint('$_logTag StackTrace: $s');
      return false;
    }
  }

  /// Checks if any calendar event overlaps the given time range
  Future<bool> hasEventDuring(
    DateTime start,
    DateTime end,
  ) async {
    debugPrint(
      '$_logTag Checking events between '
      '${start.toLocal()} → ${end.toLocal()}',
    );

    final signedIn = await ensureSignedIn();
    if (!signedIn) {
      debugPrint('$_logTag Not signed in, skipping calendar check');
      return false;
    }

    final authHeaders = await _currentUser!.authHeaders;

    final uri = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events'
      '?timeMin=${start.toUtc().toIso8601String()}'
      '&timeMax=${end.toUtc().toIso8601String()}'
      '&singleEvents=true'
      '&orderBy=startTime',
    );

    debugPrint('$_logTag Fetching events from: $uri');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      '$_logTag Calendar API status: ${response.statusCode}',
    );
    log("=-=-=-=-=-=-=-=-=-=-=- response is ${response.body} =-=-=-=-=-=-=-=-=-=-=-");

    if (response.statusCode != 200) {
      debugPrint(
        '$_logTag Calendar API error body: ${response.body}',
      );
      return false;
    }

    final data = json.decode(response.body);
    final List events = data['items'] ?? [];

    debugPrint('$_logTag Events found: ${events.length}');

    if (events.isNotEmpty) {
      debugPrint('$_logTag Event details ↓↓↓');

      for (final event in events) {
        final title = event['summary'] ?? '(No title)';
        final startTime =
            event['start']?['dateTime'] ??
            event['start']?['date'];
        final endTime =
            event['end']?['dateTime'] ??
            event['end']?['date'];

        debugPrint(
          '$_logTag • $title | $startTime → $endTime',
        );
      }

      debugPrint('$_logTag Event details ↑↑↑');
    }

    return events.isNotEmpty;
  }

  Future<bool> hasOverlappingEvent(
    DateTime slotStart,
    DateTime slotEnd,
  ) async {
    log("🟦 Checking slot:");
    log("🟦 Slot start: $slotStart");
    log("🟦 Slot end  : $slotEnd");

    final signedIn = await ensureSignedIn();
    if (!signedIn) {
      log("❌ User not signed in");
      return false;
    }

    final authHeaders = await _currentUser!.authHeaders;

    final uri = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events'
      '?timeMin=${slotStart.toUtc().toIso8601String()}'
      '&timeMax=${slotEnd.toUtc().toIso8601String()}'
      '&singleEvents=true'
      '&orderBy=startTime',
    );

    log("🌐 Request URL:");
    log(uri.toString());

    final response = await http.get(uri, headers: authHeaders);

    log("📡 Response status: ${response.statusCode}");
    log("📡 Raw response body:");
    log(response.body);

    if (response.statusCode != 200) {
      log("❌ Google Calendar API error");
      return false;
    }

    final data = json.decode(response.body);
    final List events = data['items'] ?? [];

    log("📅 Total events fetched: ${events.length}");

    for (int i = 0; i < events.length; i++) {
      final event = events[i];

      final startRaw = event['start'];
      final endRaw = event['end'];

      DateTime eventStart;
      DateTime eventEnd;

      // ⏰ Timed event
      if (startRaw['dateTime'] != null) {
        eventStart = DateTime.parse(startRaw['dateTime']).toLocal();
        eventEnd = DateTime.parse(endRaw['dateTime']).toLocal();
      }
      // 📆 All-day event
      else {
        eventStart = DateTime.parse(startRaw['date']).toLocal();
        eventEnd = DateTime.parse(endRaw['date']).toLocal();
      }

      log("────────────────────────────");
      log("📌 Event #$i");
      log("📌 Title : ${event['summary']}");
      log("📌 Start : $eventStart");
      log("📌 End   : $eventEnd");

      final overlaps =
          eventStart.isBefore(slotEnd) && eventEnd.isAfter(slotStart);

      log("🔍 Overlap check:");
      log("    eventStart < slotEnd  → ${eventStart.isBefore(slotEnd)}");
      log("    eventEnd   > slotStart→ ${eventEnd.isAfter(slotStart)}");
      log("    👉 OVERLAPS = $overlaps");

      if (overlaps) {
        log("⚠️ CONFLICT FOUND with event: ${event['summary']}");
        return true;
      }
    }

    log("✅ No overlapping events found");
    return false;
  }

  /// Optional: Explicit sign out
  Future<void> signOut() async {
    debugPrint('$_logTag Signing out');
    _currentUser = null;
    await _googleSignIn.signOut();
  }
}
