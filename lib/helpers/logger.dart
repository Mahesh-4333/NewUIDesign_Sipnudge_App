import 'dart:developer' as developer;

/// A utility class for structured and colored console logging.
class Console {
  /// Logs a message with a specific tag and optional color.
  /// 
  /// Usage: `Console.log(tag: "AUTH", value: "User logged in")`
  static void log({required String tag, required dynamic value, LogLevel level = LogLevel.info}) {
    final String timestamp = DateTime.now().toString().split(' ').last;
    final String message = "[$timestamp] [$tag] $value";
    
    developer.log(
      message,
      name: tag,
      level: level.weight,
    );

    // Also print with ANSI colors for terminal-based debuggers
    print(level.colorCode + message + '\x1B[0m');
  }

  /// Shortcut for error logging
  static void error(String tag, dynamic value) => log(tag: tag, value: value, level: LogLevel.error);

  /// Shortcut for success logging
  static void success(String tag, dynamic value) => log(tag: tag, value: value, level: LogLevel.success);

  /// Shortcut for warning logging
  static void warn(String tag, dynamic value) => log(tag: tag, value: value, level: LogLevel.warning);
}

enum LogLevel {
  info(0, '\x1B[34m'),    // Blue
  success(0, '\x1B[32m'), // Green
  warning(500, '\x1B[33m'), // Yellow
  error(1000, '\x1B[31m'); // Red

  final int weight;
  final String colorCode;
  const LogLevel(this.weight, this.colorCode);
}
