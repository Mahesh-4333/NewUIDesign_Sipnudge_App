// lib/services/location_service.dart
import 'package:hydrify/helpers/logger.dart';

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
      Console.log(tag: "APP", value: '=== GET CURRENT LOCATION CALLED ===');

      final permission = await Geolocator.checkPermission();
      Console.log(tag: "APP", value: 'Current permission status: $permission');

      await handlePermission();

      Console.log(tag: "APP", value: 'Permission granted, getting position...');

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      Console.log(
          tag: "APP",
          value:
              'Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      Console.log(tag: "APP", value: 'Error getting location: $e');
      throw LocationException('Failed to get location: $e');
    }
  }
}
