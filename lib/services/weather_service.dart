// lib/services/weather_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

/// Custom exception
class WeatherApiException implements Exception {
  final String message;
  WeatherApiException(this.message);
}

/// WeatherData model with sunrise/sunset
// class WeatherData {
//   final double temperature;
//   final int humidity;
//   final String condition; // e.g. "Clear", "Clouds", "Rain"
//   final String iconCode; // e.g. "01d"
//   final int? sunrise; // unix seconds (UTC)
//   final int? sunset; // unix seconds (UTC)

//   WeatherData({
//     required this.temperature,
//     required this.humidity,
//     required this.condition,
//     required this.iconCode,
//     this.sunrise,
//     this.sunset,
//   });

//   factory WeatherData.fromJson(Map<String, dynamic> json) {
//     // 'main' and 'weather' are expected in OpenWeatherMap current weather response
//     final main = json['main'] ?? {};
//     final weatherList = json['weather'] as List<dynamic>? ?? [];
//     final weather =
//         weatherList.isNotEmpty ? weatherList[0] as Map<String, dynamic> : {};
//     final sys = json['sys'] ?? {};

//     return WeatherData(
//       temperature: (main['temp'] ?? 0).toDouble(),
//       humidity: (main['humidity'] ?? 0).toInt(),
//       condition: (weather['main'] ?? '').toString(),
//       iconCode: (weather['icon'] ?? '').toString(),
//       sunrise: sys['sunrise'] is int
//           ? sys['sunrise'] as int
//           : (sys['sunrise'] is double
//               ? (sys['sunrise'] as double).toInt()
//               : null),
//       sunset: sys['sunset'] is int
//           ? sys['sunset'] as int
//           : (sys['sunset'] is double
//               ? (sys['sunset'] as double).toInt()
//               : null),
//     );
//   }
// }

class WeatherData {
  final double temperature;
  final int humidity;
  final String condition; // e.g. "Clouds"
  final String description; // e.g. "overcast clouds"
  final String iconCode; // e.g. "01d"
  final int? sunrise; // unix seconds (UTC)
  final int? sunset; // unix seconds (UTC)

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.iconCode,
    this.sunrise,
    this.sunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final weather =
        weatherList.isNotEmpty ? weatherList[0] as Map<String, dynamic> : {};
    final sys = json['sys'] ?? {};

    return WeatherData(
      temperature: (main['temp'] ?? 0).toDouble(),
      humidity: (main['humidity'] ?? 0).toInt(),
      condition: (weather['main'] ?? '').toString(),
      description: (weather['description'] ?? '').toString(),
      iconCode: (weather['icon'] ?? '').toString(),
      sunrise: sys['sunrise'] is int
          ? sys['sunrise'] as int
          : (sys['sunrise'] is double
              ? (sys['sunrise'] as double).toInt()
              : null),
      sunset: sys['sunset'] is int
          ? sys['sunset'] as int
          : (sys['sunset'] is double
              ? (sys['sunset'] as double).toInt()
              : null),
    );
  }
}

class WeatherService {
  final http.Client client;
  final String apiKey;
  static const baseUrl = 'https://api.openweathermap.org/data/2.5';

  WeatherService({
    required this.client,
    required this.apiKey,
  });

  /// Fetch current weather using lat/lon (units: metric)
  Future<WeatherData> getCurrentWeatherByCoordinates(
      double lat, double lon) async {
    try {
      log('Fetching weather data for coordinates: $lat, $lon');

      final url = Uri.parse(
          '$baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey');

      final response = await client.get(url);

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return WeatherData.fromJson(decoded);
      } else {
        // Try to parse message from API if present
        String message = 'Status code: ${response.statusCode}';
        try {
          final body = json.decode(response.body);
          if (body is Map && body['message'] != null) message = body['message'];
        } catch (_) {}
        throw WeatherApiException('Failed to fetch weather data: $message');
      }
    } catch (e) {
      log('Error fetching weather data: $e');
      throw WeatherApiException('Failed to fetch weather data: $e');
    }
  }
}

//==========================================================================

// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;

// class WeatherApiException implements Exception {
//   final String message;
//   WeatherApiException(this.message);
// }

// class WeatherData {
//   final double temperature;
//   final int humidity; // ✅ Added
//   final String condition;
//   final String iconCode;

//   WeatherData({
//     required this.temperature,
//     required this.humidity, // ✅ Added
//     required this.condition,
//     required this.iconCode,
//   });

//   factory WeatherData.fromJson(Map<String, dynamic> json) {
//     return WeatherData(
//       temperature: json['main']['temp'].toDouble(),
//       humidity: json['main']['humidity'], // ✅ Extract humidity
//       condition: json['weather'][0]['main'],
//       iconCode: json['weather'][0]['icon'],
//     );
//   }
// }

// class WeatherService {
//   final http.Client client;
//   final String apiKey;
//   static const baseUrl = 'https://api.openweathermap.org/data/2.5';

//   WeatherService({
//     required this.client,
//     required this.apiKey,
//   });

//   Future<WeatherData> getCurrentWeatherByCoordinates(
//       double lat, double lon) async {
//     try {
//       log('Fetching weather data for coordinates: $lat, $lon');

//       final url = Uri.parse(
//           '$baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey');

//       final response = await client.get(url);

//       log('Response status: ${response.statusCode}');
//       log('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final decodedData = json.decode(response.body);
//         return WeatherData.fromJson(decodedData);
//       } else {
//         throw WeatherApiException(
//             'Failed to fetch weather data. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       log('Error fetching weather data: $e');
//       throw WeatherApiException('Failed to fetch weather data: $e');
//     }
//   }
// }

//==========================================================================

// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;

// class WeatherApiException implements Exception {
//   final String message;
//   WeatherApiException(this.message);
// }

// class WeatherData {
//   final double temperature;
//   final String condition;
//   final String iconCode;

//   WeatherData({
//     required this.temperature,
//     required this.condition,
//     required this.iconCode,
//   });

//   factory WeatherData.fromJson(Map<String, dynamic> json) {
//     return WeatherData(
//       temperature: json['main']['temp'].toDouble(),
//       condition: json['weather'][0]['main'],
//       iconCode: json['weather'][0]['icon'],
//     );
//   }
// }

// class WeatherService {
//   final http.Client client;
//   final String apiKey;
//   static const baseUrl = 'https://api.openweathermap.org/data/2.5';

//   WeatherService({
//     required this.client,
//     required this.apiKey,
//   });

//   Future<WeatherData> getCurrentWeatherByCoordinates(
//       double lat, double lon) async {
//     try {
//       log('Fetching weather data for coordinates: $lat, $lon');

//       final url = Uri.parse(
//           '$baseUrl/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey');

//       final response = await client.get(url);

//       log('Response status: ${response.statusCode}');
//       log('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final decodedData = json.decode(response.body);
//         return WeatherData.fromJson(decodedData);
//       } else {
//         throw WeatherApiException(
//             'Failed to fetch weather data. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       log('Error fetching weather data: $e');
//       throw WeatherApiException('Failed to fetch weather data: $e');
//     }
//   }
// }

//==========================================================================
