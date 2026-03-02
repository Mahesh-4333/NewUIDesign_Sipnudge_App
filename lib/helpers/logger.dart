import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// A utility class for structured and colored console logging.
class Console {
  static File? _logFile;

  static Future<void> _writeToFile(String message) async {
    try {
      if (_logFile == null) {
        final directory = await getApplicationDocumentsDirectory();
        _logFile = File('${directory.path}/app_logs.txt');
      }

      // Use IOSink for more robust, stream-based appending of large strings
      final sink = _logFile!.openWrite(mode: FileMode.append);
      sink.writeln(message);
      await sink.flush();
      await sink.close();
    } catch (e) {
      // Ignore file write errors to avoid recursive loops
    }
  }

  /// Logs a message with a specific tag and optional color.
  ///
  /// Usage: `Console.log(tag: "AUTH", value: "User logged in")`
  static void log(
      {required String tag,
      required dynamic value,
      LogLevel level = LogLevel.info}) {
    final String timestamp = DateTime.now().toString().split(' ').last;
    final String message = "[$timestamp] [$tag] $value";

    developer.log(
      message,
      name: tag,
      level: level.weight,
    );

    // Also print with ANSI colors for terminal-based debuggers
    print(level.colorCode + message + '\x1B[0m');

    // Write to file asynchronously
    _writeToFile(message);
  }

  /// Shortcut for error logging
  static void error(String tag, dynamic value) =>
      log(tag: tag, value: value, level: LogLevel.error);

  /// Shortcut for success logging
  static void success(String tag, dynamic value) =>
      log(tag: tag, value: value, level: LogLevel.success);

  /// Shortcut for warning logging
  static void warn(String tag, dynamic value) =>
      log(tag: tag, value: value, level: LogLevel.warning);
}

enum LogLevel {
  info(0, '\x1B[34m'), // Blue
  success(0, '\x1B[32m'), // Green
  warning(500, '\x1B[33m'), // Yellow
  error(1000, '\x1B[31m'); // Red

  final int weight;
  final String colorCode;
  const LogLevel(this.weight, this.colorCode);
}
