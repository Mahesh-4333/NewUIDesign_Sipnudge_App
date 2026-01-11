import 'dart:developer';
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
      log("Exception occurred in fetchingWeatherForCurrentLocation ${e.toString()}");
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
