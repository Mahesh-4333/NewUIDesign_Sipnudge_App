import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService;
  final LocationService _locationService;
  bool _isInternetAvailable = true;
  bool get isInternetAvailable => _isInternetAvailable;

  String get offlineMessage =>
      "Turn on data/Wi-Fi to update weather.\nRemember to stay hydrated throughout the day";

  String get displayTemperature =>
      !_isInternetAvailable ? "NA°C" : "${_weatherData?.temperature ?? '--'}°C";

  String get displayHumidity =>
      !_isInternetAvailable ? "NA%" : "${_weatherData?.humidity ?? '--'}%";

  String get offlineIcon => "assets/images/na_icon.svg";

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;
  Position? _currentLocation;

  WeatherProvider(this._weatherService, this._locationService);

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentLocation => _currentLocation;

  // --------------------------------------------------------------------------
  // 🌤️ Fetch weather data
  // --------------------------------------------------------------------------
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Future<void> fetchWeatherForCurrentLocation() async {
  //   try {
  //     _isLoading = false;
  //     _error = null;
  //     notifyListeners();

  //     _currentLocation = await _locationService.getCurrentLocation();
  //     _weatherData = await _weatherService.getCurrentWeatherByCoordinates(
  //       _currentLocation!.latitude,
  //       _currentLocation!.longitude,
  //     );
  //   } catch (e) {
  //     _error = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchWeatherForCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check internet before calling API
    _isInternetAvailable = await _checkInternet();

    if (!_isInternetAvailable) {
      // STOP loading and show static UI
      _isLoading = false;
      _weatherData = null;
      _error = "No internet connection";
      notifyListeners();
      return;
    }

    try {
      _currentLocation = await _locationService.getCurrentLocation();

      _weatherData = await _weatherService.getCurrentWeatherByCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // 🌅 Accurate Weather Description with dynamic sunrise/sunset + special cases
  // --------------------------------------------------------------------------
  String getWeatherDescription() {
    if (_weatherData == null) return 'Loading...';

    final nowUtc = DateTime.now().toUtc();
    final sunriseUtc = _weatherData!.sunrise != null
        ? DateTime.fromMillisecondsSinceEpoch(
            _weatherData!.sunrise! * 1000,
            isUtc: true,
          )
        : null;
    final sunsetUtc = _weatherData!.sunset != null
        ? DateTime.fromMillisecondsSinceEpoch(
            _weatherData!.sunset! * 1000,
            isUtc: true,
          )
        : null;

    // 🌅 Detect sunrise/sunset time (±40 min window)
    if (sunriseUtc != null &&
        nowUtc.isAfter(sunriseUtc.subtract(const Duration(minutes: 20))) &&
        nowUtc.isBefore(sunriseUtc.add(const Duration(minutes: 40)))) {
      return 'Beautiful sunrise';
    }
    if (sunsetUtc != null &&
        nowUtc.isAfter(sunsetUtc.subtract(const Duration(minutes: 40))) &&
        nowUtc.isBefore(sunsetUtc.add(const Duration(minutes: 20)))) {
      return 'Beautiful sunset';
    }

    final desc = _weatherData!.description.toLowerCase();

    // 🌕 Full moon (days 14–16) — clear night
    final dayOfMonth = DateTime.now().day;
    if (desc.contains('clear') && isNight) {
      if (dayOfMonth >= 14 && dayOfMonth <= 16) return 'Full moon';
      return 'bright and sparkling day'; // ✨ stars visible
    }

    // 🌈 Rainbow (rain + clear/partly)
    if ((desc.contains('rain') || desc.contains('drizzle')) &&
        (desc.contains('clear') || desc.contains('few clouds'))) {
      return 'rainbow day after the rain';
    }

    // ☁️ Cloud-related cases
    if (desc.contains('overcast')) {
      return isNight ? 'overcast night' : 'overcast day';
    }
    if (desc.contains('scattered clouds') ||
        desc.contains('few clouds') ||
        desc.contains('broken clouds')) {
      return isNight ? 'partly cloudy night' : 'partly cloudy';
    }
    if (desc.contains('cloud')) {
      return isNight ? 'cloudy night' : 'cloudy day';
    }

    // ☀️ Clear, rain, thunderstorm, snow, etc.
    if (desc.contains('clear')) return isNight ? 'Clear night' : 'sunny day';
    if (desc.contains('drizzle')) return 'Drizzly day';
    if (desc.contains('light rain')) return ' light rainy day';
    if (desc.contains('rain')) return 'rainy day';
    if (desc.contains('heavy rain')) return 'heavy rain';
    if (desc.contains('rainstorm')) return 'rainstorm outside — stay safe';
    if (desc.contains('Heavy Rainstorm'))
      return 'strong rainstorm outside — stay safe';
    if (desc.contains('wet')) return 'wet day after the rain';
    if (desc.contains('thunderstorm'))
      return 'thunderstorm'; //thunderstorm outside — stay indoors
    if (desc.contains('light snow')) return 'light snowy day';
    if (desc.contains('snow')) return 'snowy day';
    if (desc.contains('mist')) return ' misty day';
    if (desc.contains('fog')) return 'foggy day';
    if (desc.contains('hail')) return 'hailing outside — stay safe';
    if (desc.contains('haze')) return 'hazy day';
    if (desc.contains('smoke')) return 'Smoggy day';
    if (desc.contains('dust') || desc.contains('sand')) return 'dusty day';

    return _weatherData!.condition;
  }

  // --------------------------------------------------------------------------
  // 🌗 Determine if it's currently night
  // --------------------------------------------------------------------------
  bool get isNight {
    if (_weatherData == null) return false;

    final iconCode = _weatherData!.iconCode;
    if (iconCode.isNotEmpty && iconCode.endsWith('n')) {
      return true;
    }

    final nowUtc = DateTime.now().toUtc();
    final sunriseUtc = _weatherData!.sunrise != null
        ? DateTime.fromMillisecondsSinceEpoch(
            _weatherData!.sunrise! * 1000,
            isUtc: true,
          )
        : null;
    final sunsetUtc = _weatherData!.sunset != null
        ? DateTime.fromMillisecondsSinceEpoch(
            _weatherData!.sunset! * 1000,
            isUtc: true,
          )
        : null;

    if (sunriseUtc != null && sunsetUtc != null) {
      return nowUtc.isBefore(sunriseUtc) || nowUtc.isAfter(sunsetUtc);
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // 🌦️ Weather Icon Mapper (day/night-aware + special icons)
  // --------------------------------------------------------------------------
  String getWeatherIcon() {
    if (_weatherData == null) {
      return 'assets/images/01_sunny_color.svg';
    }

    final description = getWeatherDescription().toLowerCase();

    switch (description) {
      case 'sunny day':
        return 'assets/images/01_sunny_color.svg';

      case 'clear night':
        return 'assets/images/02_moon_stars_color.svg';

      case 'sparkling night':
        return 'assets/images/33_sparkles_color.svg'; // 🌟 custom asset

      case 'full moon':
        return 'assets/images/02_moon_stars_color.svg';

      case 'rainbow':
        return 'assets/images/31_rainbow_color.svg'; // 🌈 custom asset

      case 'partly cloudy':
        return 'assets/images/04_sun_cloudy_color.svg';
      case 'partly cloudy night':
        return 'assets/images/05_moon_cloudy_color.svg';

      case 'overcast day':
      case 'cloudy day':
        return 'assets/images/06_cloudy_color.svg';
      case 'overcast night':
      case 'cloudy night':
        return 'assets/images/05_moon_cloudy_color.svg';

      case 'drizzly day':
      case 'rainy day':
      case 'heavy rain':
        return 'assets/images/11_heavy_rain.svg';

      case 'thunderstorm':
        return 'assets/images/14_thunderstorm_color.svg';

      case 'snowy day':
        return 'assets/images/22_snow_color.svg';

      case 'misty day':
      case 'foggy day':
        return 'assets/images/15_fog_color.svg';

      case 'hazy day':
        return 'assets/images/26_haze_color.svg';

      case 'smoggy day':
        return 'assets/images/25_mist_color.svg';

      case 'dusty day':
        return 'assets/images/06_cloudy_color.svg';

      case 'beautiful sunrise':
        return 'assets/images/29_sunrise_color.svg';

      case 'beautiful sunset':
        return 'assets/images/30_sunset_color.svg';

      default:
        return isNight
            ? 'assets/images/02_moon_stars_color.svg'
            : 'assets/images/01_sunny_color.svg';
    }
  }
}

//=============================================================================

// import 'package:flutter/material.dart';
// import '../services/weather_service.dart';
// import '../services/location_service.dart';
// import 'package:geolocator/geolocator.dart';

// class WeatherProvider extends ChangeNotifier {
//   final WeatherService _weatherService;
//   final LocationService _locationService;
//   WeatherData? _weatherData;
//   bool _isLoading = false;
//   String? _error;
//   Position? _currentLocation;

//   WeatherProvider(this._weatherService, this._locationService);

//   WeatherData? get weatherData => _weatherData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   Position? get currentLocation => _currentLocation;

//   Future<void> fetchWeatherForCurrentLocation() async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
//       _currentLocation = await _locationService.getCurrentLocation();
//       _weatherData = await _weatherService.getCurrentWeatherByCoordinates(
//         _currentLocation!.latitude,
//         _currentLocation!.longitude,
//       );
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   String getWeatherDescription() {
//     if (_weatherData == null) return 'Loading...';

//     final condition = _weatherData!.condition.toLowerCase();

//     // You can expand this as needed.
//     switch (condition) {
//       case 'Sunny':
//         return 'sunny day';
//       case 'Moon stars':
//       case 'clear night':
//         return 'clear night with the moon and stars';
//       case 'Cloud':
//         return 'Cloudy day';
//       case 'cloudy':
//         return 'Cloudy day';
//       case 'sun cloudy':
//       case 'sun & cloud':
//         return 'partly sunny day';
//       case 'partly cloudy':
//         return 'partly cloudy day';
//       case 'moon cloudy':
//         return 'cloudy night with the moon visible.';
//       case 'lightning':
//         return 'Lightning storm';
//       case 'wet':
//         return 'Moist air';
//       case 'light Rain':
//         return 'light rainy day';
//       case 'moderate Rain':
//         return 'rainy day';
//       case 'heavy rain':
//         return 'heavy rainy day';
//       case 'rainstorm':
//         return 'rainstorm outside';
//       case 'thunderstorm':
//         return 'thunderstorm outside';
//       case 'heavy rainstorm':
//         return 'Heavy rainstorm';
//       case 'Fog':
//         return 'foggy day';
//       case 'hail':
//         return 'Hail';
//       case 'light snow':
//         return 'Light snow';
//       case 'moderate snow':
//         return 'Moderate snow';
//       case 'heavy snow':
//         return 'Heavy snow';
//       case 'snowstorm':
//         return 'Snowstorm';
//       case 'snow':
//         return 'Snow';
//       case 'windy':
//         return 'Windy';
//       case 'blizzard':
//         return 'Blizzard';
//       case 'mist':
//         return 'Misty';
//       case 'haze':
//         return 'Hazy';
//       case 'typhoon':
//         return 'Typhoon';
//       case 'sunrise':
//         return 'Sunrise';
//       case 'sunset':
//         return 'Sunset';
//       case 'low temperature':
//         return 'Low temperature';
//       case 'high temperature':
//         return 'High temperature';
//       case 'sparkles':
//         return 'Shine bright';
//       case 'full moon':
//         return 'Full moon';
//       case 'dry':
//         return 'Dry';
//       case 'blowing sand':
//         return 'Blowing sand';
//       case 'sandstorm':
//         return 'Sandstorm';
//       case 'rainbow':
//         return 'Rainbow';
//       default:
//         // fallback
//         return _weatherData!.condition;
//     }
//   }

//   String getWeatherIcon() {
//     if (_weatherData == null) {
//       return 'assets/weather/01_sunny_color.png';
//     }

//     final iconCode = _weatherData!.iconCode;
//     final condition = _weatherData!.condition.toLowerCase();

//     switch (iconCode) {
//       case '01d':
//       case '01n':
//         return 'assets/weather/01_sunny_color.png';
//       case '02d':
//       case '02n':
//         return 'assets/weather/03_cloud_color.png';
//       case '03d':
//       case '03n':
//         return 'assets/weather/03_cloud_color.png';
//       case '04d':
//       case '04n':
//         return 'assets/weather/03_cloud_color.png';
//       case '09d':
//       case '09n':
//         return 'assets/weather/09_light_rain_color.png';
//       case '10d':
//       case '10n':
//         return 'assets/weather/10_moderate_rain_color.png';
//       case '11d':
//       case '11n':
//         return 'assets/weather/14_thunderstorm_color.png';
//       case '13d':
//       case '13n':
//         return 'assets/weather/22_snow_color.png';
//       case '50d':
//       case '50n':
//         return 'assets/weather/25_mist_color.png';
//       default:
//         // Try matching by condition if iconCode didn’t match
//         return _getIconByCondition(condition);
//     }
//   }

//   String _getIconByCondition(String condition) {
//     switch (condition) {
//       case 'sunny':
//         return 'assets/weather/01_sunny_color.png';
//       case 'moon stars':
//         return 'assets/weather/02_moon_stars_color.png';
//       case 'clear night':
//         return 'assets/weather/01_sunny_color.png';
//       case 'cloud':
//         return 'assets/weather/06_cloudy_color.png';
//       case 'cloudy':
//         return 'assets/weather/06_cloudy_color.png';
//       case 'sun cloudy':
//         return 'assets/weather/04_sun_cloudy_color.png';
//       case 'partly cloudy':
//       case 'sun & cloud':
//         return 'assets/weather/04_sun_cloudy_color.png';
//       case 'moon cloudy':
//         return 'assets/weather/03_cloud_color.png';
//       case 'light rain':
//         return 'assets/weather/09_light_rain_color.png';
//       case 'moderate rain':
//         return 'assets/weather/10_moderate_rain_color.png';
//       case 'heavy rain':
//         return 'assets/weather/11_heavy_rain_color.png';
//       case 'rainstorm':
//         return 'assets/weather/12_rainstorm_color.png';
//       case 'heavy rainstorm':
//         return 'assets/weather/13_heavy_rainstorm_color.png';
//       case 'thunderstorm':
//         return 'assets/weather/14_thunderstorm_color.png';
//       case 'fog':
//         return 'assets/weather/15_fog_color.png';
//       case 'hail':
//         return 'assets/weather/16_hail_color.png';
//       case 'light snow':
//         return 'assets/weather/16_light_snow_color.png';
//       case 'snow':
//         return 'assets/weather/22_snow_color.png';
//       case 'moderate snow':
//         return 'assets/weather/1_moderate_snow_color.png';
//       case 'heavy snow':
//         return 'assets/weather/19_heavy_snow_color.png';
//       case 'snowstorm':
//         return 'assets/weather/20_snowstorm_color.png';
//       case 'windy':
//         return 'assets/weather/23_windy_color.png';
//       case 'blizzard':
//         return 'assets/weather/24_blizzard_color.png';
//       case 'mist':
//         return 'assets/weather/25_mist_color.png';
//       case 'haze':
//         return 'assets/weather/26_haze_color.png';
//       case 'typhoon':
//         return 'assets/weather/27_typhoon_color.png';
//       case 'sunrise':
//         return 'assets/weather/29_sunrise_color.png';
//       case 'sunset':
//         return 'assets/weather/30_sunset_color.png';
//       case 'low temperature':
//         return 'assets/weather/31_low_temperature_color.png';
//       case 'high temperature':
//         return 'assets/weather/32_high_temperature_color.png';
//       case 'sparkles':
//         return 'assets/weather/33_sparkles_color.png';
//       case 'full moon':
//         return 'assets/weather/34_full_moon_color.png';
//       case 'partly cloud day':
//         return 'assets/weather/35_partly_cloudy_daytime_color.png';
//       case 'partly cloud night':
//         return 'assets/weather/36_partly_cloudy_night_color.png';
//       case 'dry':
//         return 'assets/weather/37_dry_color.png';
//       case 'blowing sand':
//         return 'assets/weather/38_blowing_sand_color.png';
//       case 'sandstorm':
//         return 'assets/weather/39_sandstorm_color.png';
//       case 'rainbow':
//         return 'assets/weather/40_rainbow_color.png';
//       default:
//         return 'assets/weather/01_sunny_color.png';
//     }
//   }
// }

//===================== lib/providers/weather_provider.dart ==================//
// import 'package:flutter/material.dart';
// import '../services/weather_service.dart';
// import '../services/location_service.dart';
// import 'package:geolocator/geolocator.dart';

// class WeatherProvider extends ChangeNotifier {
//   final WeatherService _weatherService;
//   final LocationService _locationService;
//   WeatherData? _weatherData;
//   bool _isLoading = false;
//   String? _error;
//   Position? _currentLocation;

//   WeatherProvider(this._weatherService, this._locationService);

//   WeatherData? get weatherData => _weatherData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   Position? get currentLocation => _currentLocation;

//   // --------------------------------------------------------------------------
//   // 📍 Fetch Weather for Current Location
//   // --------------------------------------------------------------------------
//   Future<void> fetchWeatherForCurrentLocation() async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       _currentLocation = await _locationService.getCurrentLocation();

//       _weatherData = await _weatherService.getCurrentWeatherByCoordinates(
//         _currentLocation!.latitude,
//         _currentLocation!.longitude,
//       );
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // --------------------------------------------------------------------------
//   // 🌤️ Accurate Weather Description
//   // --------------------------------------------------------------------------
//   String getWeatherDescription() {
//     if (_weatherData == null) return 'Loading...';

//     final condition = _weatherData!.condition.toLowerCase();

//     switch (condition) {
//       case 'clear':
//       case 'clear sky':
//         return 'Sunny day';
//       case 'moon stars':
//       case 'clear night':
//         return 'Moon and stars night';
//       case 'cloud':
//       case 'clouds':
//         return 'Cloudy day';
//       case 'few clouds':
//       case 'scattered clouds':
//       case 'broken clouds':
//         return 'Partly cloudy';
//       case 'overcast clouds':
//         return 'Overcast day';
//       case 'drizzle':
//       case 'light drizzle':
//         return 'Drizzly day';
//       case 'rain':
//       case 'light rain':
//         return 'Rainy day';
//       case 'moderate rain':
//       case 'heavy rain':
//         return 'Heavy rain';
//       case 'thunderstorm':
//       case 'thunderstorm with rain':
//       case 'thunderstorm with lightning':
//         return 'Thunderstorm';
//       case 'snow':
//       case 'light snow':
//       case 'heavy snow':
//       case 'sleet':
//         return 'Snowy day';
//       case 'mist':
//         return 'Misty day';
//       case 'fog':
//         return 'Foggy day';
//       case 'haze':
//         return 'Hazy day';
//       case 'smoke':
//         return 'Smoggy day';
//       case 'dust':
//       case 'sand':
//         return 'Dusty day';
//       case 'rainbow':
//         return 'Rainbow';
//       default:
//         return _weatherData!.condition;
//     }
//   }

//   // --------------------------------------------------------------------------
//   // 🌇 Detect Sunrise / Sunset Period
//   // --------------------------------------------------------------------------
//   String? getTimeOfDayCondition() {
//     if (_weatherData?.sunrise == null || _weatherData?.sunset == null)
//       return null;

//     final now = DateTime.now();
//     final sunrise =
//         DateTime.fromMillisecondsSinceEpoch(_weatherData!.sunrise! * 1000);
//     final sunset =
//         DateTime.fromMillisecondsSinceEpoch(_weatherData!.sunset! * 1000);

//     if (now.isAfter(sunrise) &&
//         now.isBefore(sunrise.add(const Duration(minutes: 30)))) {
//       return 'Sunrise';
//     } else if (now.isAfter(sunset.subtract(const Duration(minutes: 30))) &&
//         now.isBefore(sunset)) {
//       return 'Sunset';
//     }
//     return null;
//   }

//   // --------------------------------------------------------------------------
//   // 🌦️ Icon Based on Weather Description
//   // --------------------------------------------------------------------------
//   String getWeatherIcon() {
//     if (_weatherData == null) {
//       return 'assets/images/01_sunny_color.svg';
//     }

//     final timeOfDay = getTimeOfDayCondition();
//     if (timeOfDay == 'Sunrise') {
//       return 'assets/images/29_sunrise_color.svg';
//     } else if (timeOfDay == 'Sunset') {
//       return 'assets/images/30_sunset_color.svg';
//     }

//     final description = getWeatherDescription().toLowerCase();

//     switch (description) {
//       case 'sunny day':
//         return 'assets/images/01_sunny_color.svg';
//       case 'cloudy day':
//         return 'assets/images/06_cloudy_color.svg';
//       case 'partly cloudy':
//       case 'overcast day':
//         return 'assets/images/04_sun_cloudy_color.svg';
//       case 'drizzly day':
//         return 'assets/images/09_light_rain_color.svg';
//       case 'rainy day':
//       case 'heavy rain':
//         return 'assets/images/11_heavy_rain.svg';
//       case 'thunderstorm':
//         return 'assets/images/14_thunderstorm_color.svg';
//       case 'snowy day':
//         return 'assets/images/22_snow_color.svg';
//       case 'misty day':
//       case 'foggy day':
//         return 'assets/images/15_fog_color.svg';
//       case 'hazy day':
//         return 'assets/images/26_haze_color.svg';
//       case 'smoggy day':
//         return 'assets/images/25_mist_color.svg';
//       case 'dusty day':
//         return 'assets/images/06_cloudy_color.svg';
//       case 'rainbow':
//         return 'assets/images/40_rainbow_color.png';
//       default:
//         return 'assets/images/01_sunny_color.svg';
//     }
//   }
// }

// --------------------------------------------------------------------------
// 🌦️ Weather Icon Selection
// --------------------------------------------------------------------------
// String getWeatherIcon() {
//   print('=== getWeatherIcon() called ===');

//   if (_weatherData == null) {
//     print('Weather data is null, returning sunny_ic.svg');
//     return 'assets/images/01_sunny_color.svg';
//   }

//   final iconCode = _weatherData!.iconCode;
//   print('Icon Code from API: "$iconCode"');
//   print('Weather Condition: "${_weatherData!.condition}"');

//   // Handle both day and night versions
//   switch (iconCode) {
//     // Clear sky
//     case '01d':
//       print('Matched case: 01d (Clear sky - day)');
//       return 'assets/images/01_sunny_color.svg';
//     case '01n':
//       print('Matched case: 01n (Clear sky - night)');
//       return 'assets/images/01_sunny_color.svg';

//     // Few clouds
//     case '02d':
//       print('Matched case: 02d (Few clouds - day)');
//       return 'assets/images/04_sun_cloudy_color.svg';
//     case '02n':
//       print('Matched case: 02n (Few clouds - night)');
//       //return 'assets/images/05_moon_cloudy_color.svg';
//       return 'assets/images/04_sun_cloudy_color.svg';

//     // Scattered clouds
//     case '03d':
//       print('Matched case: 03d (Scattered clouds - day)');
//       return 'assets/images/04_sun_cloudy_color.svg';
//     case '03n':
//       print('Matched case: 03n (Scattered clouds - night)');
//       //return 'assets/images/05_moon_cloudy_color.svg';
//       return 'assets/images/04_sun_cloudy_color.svg';

//     // Broken clouds
//     case '04d':
//       print('Matched case: 04d (Broken clouds - day)');
//       return 'assets/images/04_sun_cloudy_color.svg';
//     case '04n':
//       print('Matched case: 04n (Broken clouds - night)');
//       // return 'assets/images/05_moon_cloudy_color.svg';
//       return 'assets/images/04_sun_cloudy_color.svg';

//     // Shower rain
//     case '09d':
//       print('Matched case: 09d (Shower rain - day)');
//       return 'assets/images/09_light_rain_color.svg';
//     case '09n':
//       print('Matched case: 09n (Shower rain - night)');
//       return 'assets/images/09_light_rain_color.svg';

//     // Rain
//     case '10d':
//       print('Matched case: 10d (Rain - day)');
//       return 'assets/images/11_heavy_rain.svg';
//     case '10n':
//       print('Matched case: 10n (Rain - night)');
//       return 'assets/images/11_heavy_rain.svg';

//     // Thunderstorm
//     case '11d':
//       print('Matched case: 11d (Thunderstorm - day)');
//       return 'assets/images/14_thunderstorm_color.svg';
//     case '11n':
//       print('Matched case: 11n (Thunderstorm - night)');
//       return 'assets/images/14_thunderstorm_color.svg';

//     // Snow
//     case '13d':
//       print('Matched case: 13d (Snow - day)');
//       return 'assets/images/22_snow_color.svg';
//     case '13n':
//       print('Matched case: 13n (Snow - night)');
//       return 'assets/images/22_snow_color.svg';

//     // Mist/Fog
//     case '50d':
//       print('Matched case: 50d (Mist/Fog - day)');
//       return 'assets/images/15_fog_color.svg';
//     case '50n':
//       print('Matched case: 50n (Mist/Fog - night)');
//       return 'assets/images/15_fog_color.svg';

//     // 🌅 Sunrise
//     case 'sunrise':
//     case 'sunrise_d':
//       print('Matched case: sunrise (Sunrise)');
//       return 'assets/images/29_sunrise_color.svg';

//     // 🌇 Sunset
//     case 'sunset':
//     case 'sunset_d':
//       print('Matched case: sunset (Sunset)');
//       return 'assets/images/30_sunset_color.svg';

//     default:
//       print(
//           'No icon code match found, falling back to condition-based logic');
//       print('Calling _getIconByCondition with: "${_weatherData!.condition}"');
//       return _getIconByCondition(_weatherData!.condition);
//   }
// }

// --------------------------------------------------------------------------
// ☁️ Fallback Icon Logic by Condition Text
// --------------------------------------------------------------------------
// String _getIconByCondition(String condition) {
//   print('=== _getIconByCondition() called ===');
//   print('Input condition: "$condition"');
//   print('Lowercase condition: "${condition.toLowerCase()}"');

//   switch (condition.toLowerCase()) {
//     case 'clear':
//       print('Matched condition: clear -> sunny_ic.svg');
//       return 'assets/images/01_sunny_color.svg';
//     case 'clouds':
//       print('Matched condition: clouds -> cloudy_ic.svg');
//       return 'assets/images/04_sun_cloudy_color.svg';
//     case 'broken clouds':
//       print('Matched condition: broken clouds -> cloudy_ic.svg');
//       return 'assets/images/04_sun_cloudy_color.svg';
//     case 'rain':
//       print('Matched condition: rain -> rainy_ic.svg');
//       return 'assets/images/11_heavy_rain.svg';
//     case 'drizzle':
//       print('Matched condition: drizzle -> rainy_ic.svg');
//       return 'assets/images/09_light_rain_color.svg';
//     case 'thunderstorm':
//       print('Matched condition: thunderstorm -> lightning_ic.svg');
//       return 'assets/images/14_thunderstorm_color.svg';
//     case 'snow':
//       print('Matched condition: snow -> snow icon');
//       return 'assets/images/22_snow_color.svg';
//     case 'mist':
//       print('Matched condition: mist -> mist icon');
//       return 'assets/images/25_mist_color.svg';
//     case 'smoke':
//       print('Matched condition: smoke -> cloudy icon');
//       return 'assets/images/06_cloudy_color.svg';
//     case 'haze':
//       print('Matched condition: haze -> haze icon');
//       return 'assets/images/26_haze_color.svg';
//     case 'dust':
//       print('Matched condition: dust -> dust icon');
//       return 'assets/images/06_cloudy_color.svg';
//     case 'fog':
//       print('Matched condition: fog -> fog icon');
//       return 'assets/images/15_fog_color.svg';
//     case 'sunrise':
//       print('Matched condition: sunrise -> sunrise icon');
//       return 'assets/images/29_sunrise_color.svg';
//     case 'sunset':
//       print('Matched condition: sunset -> sunset icon');
//       return 'assets/images/30_sunset_color.svg';
//     default:
//       print('No condition match found, returning default: sunny_ic.svg');
//       print(
//           'Available conditions were: clear, clouds, rain, drizzle, thunderstorm, snow, mist, smoke, haze, dust, fog, sunrise, sunset');
//       return 'assets/images/01_sunny_color.svg';
//   }
// }
// }

//===================== lib/helpers/database_helper.dart ==================//

// import 'package:flutter/material.dart';
// import '../services/weather_service.dart';
// import '../services/location_service.dart';
// import 'package:geolocator/geolocator.dart';

// class WeatherProvider extends ChangeNotifier {
//   final WeatherService _weatherService;
//   final LocationService _locationService;
//   WeatherData? _weatherData;
//   bool _isLoading = false;
//   String? _error;
//   Position? _currentLocation;

//   WeatherProvider(this._weatherService, this._locationService);

//   WeatherData? get weatherData => _weatherData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   Position? get currentLocation => _currentLocation;

//   Future<void> fetchWeatherForCurrentLocation() async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
//       _currentLocation = await _locationService.getCurrentLocation();
//       _weatherData = await _weatherService.getCurrentWeatherByCoordinates(
//         _currentLocation!.latitude,
//         _currentLocation!.longitude,
//       );
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   String getWeatherDescription() {
//     if (_weatherData == null) return 'Loading...';

//     switch (_weatherData!.condition.toLowerCase()) {
//       case 'clear':
//         return 'Sunny day';
//       case 'clouds':
//         return 'Cloudy day';
//       case 'rain':
//         return 'Rainy day';
//       case 'thunderstorm':
//         return 'Thunderstorm';
//       case 'smoke':
//         return 'Smoggy day';
//       default:
//         return _weatherData!.condition;
//     }
//   }

//   String getWeatherIcon() {
//     print('=== getWeatherIcon() called ===');

//     if (_weatherData == null) {
//       print('Weather data is null, returning sunny_ic.svg');
//       return 'assets/images/sunny_ic.svg';
//     }

//     final iconCode = _weatherData!.iconCode;
//     print('Icon Code from API: "$iconCode"');
//     print('Weather Condition: "${_weatherData!.condition}"');

//     // Handle both day and night versions
//     switch (iconCode) {
//       // Clear sky
//       case '01d':
//         print('Matched case: 01d (Clear sky - day)');
//         return 'assets/images/sunny_ic.svg';
//       case '01n':
//         print('Matched case: 01n (Clear sky - night)');
//         return 'assets/images/sunny_ic.svg';

//       // Few clouds
//       case '02d':
//         print('Matched case: 02d (Few clouds - day)');
//         return 'assets/images/cloudy_ic.svg';
//       case '02n':
//         print('Matched case: 02n (Few clouds - night)');
//         return 'assets/images/cloudy_ic.svg';

//       // Scattered clouds
//       case '03d':
//         print('Matched case: 03d (Scattered clouds - day)');
//         return 'assets/images/cloudy_ic.svg';
//       case '03n':
//         print('Matched case: 03n (Scattered clouds - night)');
//         return 'assets/images/cloudy_ic.svg';

//       // Broken clouds
//       case '04d':
//         print('Matched case: 04d (Broken clouds - day)');
//         return 'assets/images/cloudy_ic.svg';
//       case '04n':
//         print('Matched case: 04n (Broken clouds - night)');
//         return 'assets/images/cloudy_ic.svg';

//       // Shower rain
//       case '09d':
//         print('Matched case: 09d (Shower rain - day)');
//         return 'assets/images/rainy_ic.svg';
//       case '09n':
//         print('Matched case: 09n (Shower rain - night)');
//         return 'assets/images/rainy_ic.svg';

//       // Rain
//       case '10d':
//         print('Matched case: 10d (Rain - day)');
//         return 'assets/images/rainy_ic.svg';
//       case '10n':
//         print('Matched case: 10n (Rain - night)');
//         return 'assets/images/rainy_ic.svg';

//       // Thunderstorm
//       case '11d':
//         print('Matched case: 11d (Thunderstorm - day)');
//         return 'assets/images/lightning_ic.svg';
//       case '11n':
//         print('Matched case: 11n (Thunderstorm - night)');
//         return 'assets/images/lightning_ic.svg';

//       // Snow
//       case '13d':
//         print('Matched case: 13d (Snow - day)');
//         return 'assets/images/cloudy_ic.svg';
//       case '13n':
//         print('Matched case: 13n (Snow - night)');
//         return 'assets/images/cloudy_ic.svg';

//       // Mist/Fog
//       case '50d':
//         print('Matched case: 50d (Mist/Fog - day)');
//         return 'assets/images/cloudy_ic.svg';
//       case '50n':
//         print('Matched case: 50n (Mist/Fog - night)');
//         return 'assets/images/cloudy_ic.svg';

//       default:
//         print(
//             'No icon code match found, falling back to condition-based logic');
//         print('Calling _getIconByCondition with: "${_weatherData!.condition}"');
//         return _getIconByCondition(_weatherData!.condition);
//     }
//   }

//   String _getIconByCondition(String condition) {
//     print('=== _getIconByCondition() called ===');
//     print('Input condition: "$condition"');
//     print('Lowercase condition: "${condition.toLowerCase()}"');

//     switch (condition.toLowerCase()) {
//       case 'clear':
//         print('Matched condition: clear -> sunny_ic.svg');
//         return 'assets/images/sunny_ic.svg';
//       case 'clouds':
//         print('Matched condition: clouds -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       case 'rain':
//         print('Matched condition: rain -> rainy_ic.svg');
//         return 'assets/images/rainy_ic.svg';
//       case 'drizzle':
//         print('Matched condition: drizzle -> rainy_ic.svg');
//         return 'assets/images/rainy_ic.svg';
//       case 'thunderstorm':
//         print('Matched condition: thunderstorm -> lightning_ic.svg');
//         return 'assets/images/lightning_ic.svg';
//       case 'snow':
//         print('Matched condition: snow -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       case 'mist':
//         print('Matched condition: mist -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       case 'smoke':
//         print('Matched condition: smoke -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       case 'haze':
//         print('Matched condition: haze -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       case 'dust':
//         print('Matched condition: dust -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       case 'fog':
//         print('Matched condition: fog -> cloudy_ic.svg');
//         return 'assets/images/cloudy_ic.svg';
//       default:
//         print('No condition match found, returning default: sunny_ic.svg');
//         print(
//             'Available conditions were: clear, clouds, rain, drizzle, thunderstorm, snow, mist, smoke, haze, dust, fog');
//         return 'assets/images/sunny_ic.svg';
//     }
//   }
// }
