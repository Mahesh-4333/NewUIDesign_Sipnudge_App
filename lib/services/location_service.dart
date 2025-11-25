// lib/services/location_service.dart
import 'dart:developer';

import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
}

class LocationService {
  LocationService();

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      try {
        await Geolocator.requestPermission();
      } catch (e) {
        throw LocationException('Location services are disabled.');
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw LocationException(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return true;
  }

  Future<Position> getCurrentLocation() async {
    try {
      log('Getting current location');

      await handlePermission();

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      log('Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      log('Error getting location: $e');
      throw LocationException('Failed to get location: $e');
    }
  }
}
