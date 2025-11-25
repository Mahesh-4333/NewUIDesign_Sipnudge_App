import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  static const String _userNameKey = 'user_display_name';

  String _cachedUserName = '';

  // Listeners for name changes
  final List<Function(String)> _listeners = [];

  // Get current username
  String get userName => _cachedUserName;

  // Initialize and load username
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserName = prefs.getString(_userNameKey) ?? '';
  }

  // Update username
  Future<void> setUserName(String name) async {
    _cachedUserName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);

    // Notify all listeners
    for (var listener in _listeners) {
      listener(name);
    }
  }

  // Add listener for name changes
  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  // Remove listener
  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  // Clear all data
  Future<void> clear() async {
    _cachedUserName = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);

    // Notify listeners
    for (var listener in _listeners) {
      listener('');
    }
  }
}
