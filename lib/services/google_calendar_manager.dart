import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hydrify/helpers/logger.dart';
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

  /// Google Sign-In with Calendar scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/calendar.events.readonly',
    ],
  );

  bool _isSignedIn = false;
  GoogleSignInAccount? _currentUser;

  /// Ensures the user is signed in
  Future<bool> ensureSignedIn() async {
    try {
    // If already signed in, no need to sign in again
    if (_isSignedIn && _currentUser != null) {
      debugPrint('$_logTag Already signed in, skipping sign-in');
      return true;
    }

    // Try silent sign‑in first; if that fails, fall back to interactive sign‑in which will request the required scopes
    _currentUser ??= await _googleSignIn.signInSilently();
    if (_currentUser == null) {
      _currentUser = await _googleSignIn.signIn();
    }

    final isSignedIn = _currentUser != null;
    if (isSignedIn) {
      _isSignedIn = true;
    }
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
    Console.log(
        tag: "APP",
        value:
            "=-=-=-=-=-=-=-=-=-=-=- response is ${response.body} =-=-=-=-=-=-=-=-=-=-=-");

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
            event['start']?['dateTime'] ?? event['start']?['date'];
        final endTime = event['end']?['dateTime'] ?? event['end']?['date'];

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
    Console.log(tag: "APP", value: "🟦 Checking slot:");
    Console.log(tag: "APP", value: "🟦 Slot start: $slotStart");
    Console.log(tag: "APP", value: "🟦 Slot end  : $slotEnd");

    final signedIn = await ensureSignedIn();
    if (!signedIn) {
      Console.log(tag: "APP", value: "❌ User not signed in");
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

    Console.log(tag: "APP", value: "🌐 Request URL:");
    Console.log(tag: "APP", value: uri.toString());

    final response = await http.get(uri, headers: authHeaders);

    Console.log(
        tag: "APP", value: "📡 Response status: ${response.statusCode}");
    Console.log(tag: "APP", value: "📡 Raw response body:");
    Console.log(tag: "APP", value: response.body);

    if (response.statusCode != 200) {
      Console.log(tag: "APP", value: "❌ Google Calendar API error");
      return false;
    }

    final data = json.decode(response.body);
    final List events = data['items'] ?? [];

    Console.log(tag: "APP", value: "📅 Total events fetched: ${events.length}");

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

      Console.log(tag: "APP", value: "────────────────────────────");
      Console.log(tag: "APP", value: "📌 Event #$i");
      Console.log(tag: "APP", value: "📌 Title : ${event['summary']}");
      Console.log(tag: "APP", value: "📌 Start : $eventStart");
      Console.log(tag: "APP", value: "📌 End   : $eventEnd");

      final overlaps =
          eventStart.isBefore(slotEnd) && eventEnd.isAfter(slotStart);

      Console.log(tag: "APP", value: "🔍 Overlap check:");
      Console.log(
          tag: "APP",
          value: "    eventStart < slotEnd  → ${eventStart.isBefore(slotEnd)}");
      Console.log(
          tag: "APP",
          value: "    eventEnd   > slotStart→ ${eventEnd.isAfter(slotStart)}");
      Console.log(tag: "APP", value: "    👉 OVERLAPS = $overlaps");

      if (overlaps) {
        Console.log(
            tag: "APP",
            value: "⚠️ CONFLICT FOUND with event: ${event['summary']}");
        return true;
      }
    }

    Console.log(tag: "APP", value: "✅ No overlapping events found");
    return false;
  }

  // Inside GoogleCalendarManager class

  Future<List<Map<String, dynamic>>> fetchEventsForRange(
      DateTime start, DateTime end) async {
    try {
      final signedIn = await ensureSignedIn();
      if (!signedIn) return [];

      final authHeaders = await _currentUser!.authHeaders;
      final uri = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?timeMin=${start.toUtc().toIso8601String()}'
        '\u0026timeMax=${end.toUtc().toIso8601String()}'
        '\u0026singleEvents=true'
        '\u0026orderBy=startTime',
      );

      final response = await http.get(uri, headers: authHeaders);

      // Log the raw response for debugging
      debugPrint('[$_logTag] fetchEventsForRange response status: ${response.statusCode}');
      debugPrint('[$_logTag] fetchEventsForRange body: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('[$_logTag] Calendar API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final List events = data['items'] ?? [];
      if (events.isEmpty) {
        debugPrint('[$_logTag] No calendar events found for the requested range.');
      } else {
        debugPrint('[$_logTag] Retrieved ${events.length} events.');
      }
      return List<Map<String, dynamic>>.from(events);
    } catch (e) {
      debugPrint('[$_logTag] Exception in fetchEventsForRange: $e');
      return [];
    }
  }

  bool checkOverlapLocally(
      DateTime slotStart, DateTime slotEnd, List<Map<String, dynamic>> events) {
    for (final event in events) {
      final startRaw = event['start'];
      final endRaw = event['end'];

      DateTime eventStart;
      DateTime eventEnd;

      if (startRaw['dateTime'] != null) {
        eventStart = DateTime.parse(startRaw['dateTime']).toLocal();
        eventEnd = DateTime.parse(endRaw['dateTime']).toLocal();
      } else if (startRaw['date'] != null) {
        eventStart = DateTime.parse(startRaw['date']).toLocal();

        eventEnd = DateTime.parse(endRaw['date']).toLocal();
      } else {
        continue;
      }

      final overlaps =
          eventStart.isBefore(slotEnd) && eventEnd.isAfter(slotStart);

      if (overlaps) {
        Console.log(
            tag: "APP",
            value:
                "⚠️ Local Conflict: '${event['summary']}' overlaps with slot.");
        return true;
      }
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      debugPrint('$_logTag Signing out');
    _currentUser = null;
    _isSignedIn = false;
    await _googleSignIn.signOut();
    } catch (e) {
      Console.log(
          tag: "APP", value: "Exception occurred in signOut ${e.toString()}");
    }
  }
}
