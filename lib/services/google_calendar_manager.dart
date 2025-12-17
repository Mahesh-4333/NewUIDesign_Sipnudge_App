import 'dart:convert';
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
      _currentUser ??= await _googleSignIn.signInSilently();
      _currentUser ??= await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Checks if any calendar event overlaps the given time range
  Future<bool> hasEventDuring(
    DateTime start,
    DateTime end,
  ) async {
    final signedIn = await ensureSignedIn();
    if (!signedIn) return false;

    final authHeaders = await _currentUser!.authHeaders;

    final uri = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events'
      '?timeMin=${start.toUtc().toIso8601String()}'
      '&timeMax=${end.toUtc().toIso8601String()}'
      '&singleEvents=true'
      '&orderBy=startTime',
    );

    final response = await http.get(uri, headers: authHeaders);

    if (response.statusCode != 200) {
      return false;
    }

    final data = json.decode(response.body);
    final List events = data['items'] ?? [];

    return events.isNotEmpty;
  }

  /// Optional: Explicit sign out
  Future<void> signOut() async {
    _currentUser = null;
    await _googleSignIn.signOut();
  }
}
