import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CountryInfo {
  final String name;
  final String code;
  final LatLng center;
  final double zoom;
  final List<List<LatLng>> polygons;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.center,
    this.zoom = 4.8,
    required this.polygons,
  });
}

class CountryBordersHelper {
  static Map<String, CountryInfo>? _cachedCountries;
  static bool _isLoading = false;

  /// Popular country shortcuts for top selector bar
  static const List<Map<String, String>> popularCountries = [
    {'name': 'India', 'flag': '🇮🇳'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'United Arab Emirates', 'flag': '🇦🇪'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Singapore', 'flag': '🇸🇬'},
  ];

  /// Initialize and load official world boundaries dataset
  static Future<void> loadDataset() async {
    if (_cachedCountries != null || _isLoading) return;
    _isLoading = true;
    try {
      final jsonStr = await rootBundle.loadString('assets/world_countries.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final Map<String, CountryInfo> result = {};

      data.forEach((key, val) {
        final name = (val['name'] ?? key).toString();
        final iso2 = (val['iso2'] ?? '').toString();
        final centerList = val['center'] as List<dynamic>?;
        final center = centerList != null && centerList.length >= 2
            ? LatLng(
                (centerList[0] as num).toDouble(),
                (centerList[1] as num).toDouble(),
              )
            : const LatLng(20.0, 0.0);

        final rawPolys = val['polygons'] as List<dynamic>? ?? [];
        final List<List<LatLng>> parsedPolygons = [];

        for (final rawRing in rawPolys) {
          if (rawRing is List) {
            final List<LatLng> ring = [];
            for (final pt in rawRing) {
              if (pt is List && pt.length >= 2) {
                ring.add(LatLng(
                  (pt[0] as num).toDouble(),
                  (pt[1] as num).toDouble(),
                ));
              }
            }
            if (ring.length >= 3) {
              parsedPolygons.add(ring);
            }
          }
        }

        final info = CountryInfo(
          name: name,
          code: iso2,
          center: center,
          zoom: _getDefaultZoom(name),
          polygons: parsedPolygons,
        );

        result[key.toLowerCase()] = info;
        if (iso2.isNotEmpty) {
          result[iso2.toLowerCase()] = info;
        }
      });

      _cachedCountries = result;
    } catch (e) {
      debugPrint("Error loading world_countries.json: $e");
    } finally {
      _isLoading = false;
    }
  }

  static double _getDefaultZoom(String country) {
    final lower = country.toLowerCase();
    if (lower.contains('united states') || lower.contains('russia') || lower.contains('canada') || lower.contains('china')) {
      return 3.5;
    }
    if (lower.contains('india') || lower.contains('australia') || lower.contains('brazil')) {
      return 4.5;
    }
    if (lower.contains('singapore') || lower.contains('united arab emirates') || lower.contains('hong kong')) {
      return 5.8;
    }
    return 4.8;
  }

  /// Get official country information
  static CountryInfo getCountryInfo(String countryName, {LatLng? fallbackCenter}) {
    final key = countryName.trim().toLowerCase();

    if (_cachedCountries != null) {
      if (_cachedCountries!.containsKey(key)) {
        return _cachedCountries![key]!;
      }

      // Alias handling
      if (key == 'in' || key == 'bharat' || key.contains('india')) {
        if (_cachedCountries!.containsKey('india')) return _cachedCountries!['india']!;
      }
      if (key == 'usa' || key == 'us' || key.contains('united states') || key == 'america') {
        if (_cachedCountries!.containsKey('united states of america')) return _cachedCountries!['united states of america']!;
        if (_cachedCountries!.containsKey('united states')) return _cachedCountries!['united states']!;
      }
      if (key == 'uk' || key == 'great britain' || key.contains('united kingdom') || key == 'england') {
        if (_cachedCountries!.containsKey('united kingdom')) return _cachedCountries!['united kingdom']!;
      }
      if (key == 'uae' || key.contains('emirates') || key == 'dubai') {
        if (_cachedCountries!.containsKey('united arab emirates')) return _cachedCountries!['united arab emirates']!;
      }
      if (key == 'russia' || key.contains('russian federation')) {
        if (_cachedCountries!.containsKey('russia')) return _cachedCountries!['russia']!;
      }

      // Partial fuzzy search
      for (final entry in _cachedCountries!.entries) {
        if (entry.key.contains(key) || key.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    final center = fallbackCenter ?? const LatLng(20.0, 78.0);
    return CountryInfo(
      name: countryName,
      code: countryName.length >= 2 ? countryName.substring(0, 2).toUpperCase() : 'XX',
      center: center,
      zoom: 4.8,
      polygons: const [],
    );
  }

  /// Build exact official Polygons for a given country
  static Set<Polygon> buildCountryPolygons(
    String countryName, {
    Color fillColor = const Color(0x3300A2FF),
    Color strokeColor = const Color(0xFF00A2FF),
    int strokeWidth = 2,
  }) {
    final Set<Polygon> set = {};
    final info = getCountryInfo(countryName);

    int ringIndex = 0;
    for (final ring in info.polygons) {
      if (ring.isNotEmpty) {
        set.add(
          Polygon(
            polygonId: PolygonId('highlight_${info.name}_$ringIndex'),
            points: ring,
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            geodesic: true,
          ),
        );
        ringIndex++;
      }
    }
    return set;
  }
}
