import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_api_constants.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/helpers/country_borders_helper.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UserMapLocation {
  final String userId;
  final LatLng position;
  final int bottlesSaved;
  final double carbonReduced;
  final int totalConsumed;

  UserMapLocation({
    required this.userId,
    required this.position,
    required this.bottlesSaved,
    required this.carbonReduced,
    required this.totalConsumed,
  });
}

class SipMapScreen extends StatefulWidget {
  const SipMapScreen({super.key});

  @override
  State<SipMapScreen> createState() => _SipMapScreenState();
}

class _SipMapScreenState extends State<SipMapScreen> {
  GoogleMapController? _mapController;
  bool _isHeatmapMode = false;
  bool _isMapInitialized = false;

  // Privacy Protocol states (Ghost Mode by default is ON)
  bool _ghostMode = true;
  bool _fuzzyLocation = true;

  // User's own impact story data from Leaderboard
  int _myBottlesSaved = 0;
  double _myCarbonReduced = 0.0;

  // Country-wise zoom tracking
  double _currentZoom = 4.8;

  // Country selection & highlight state
  String _selectedCountry = 'India';
  String _currentCountry = 'India';
  LatLng _lastCameraTarget = _defaultCoords;
  Timer? _geocodeDebounceTimer;

  // Real user locations fetched from backend
  List<UserMapLocation> _serverUserLocations = [];
  LatLng? _currentUserLocation;

  // Default coordinate if no GPS or server location yet
  static const LatLng _defaultCoords = LatLng(19.0760, 72.8777);

  // Light Mode Style JSON for Google Maps
  static const String _mapStyleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f7fa"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#4f5e71"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#d6e1e5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#ae9e90"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#edf2f7"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#edf2f7"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#5b6e84"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e2e8f0"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#cbd5e1"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#cce3f5"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3b82f6"
      }
    ]
  }
]
  ''';

  @override
  void initState() {
    super.initState();
    CountryBordersHelper.loadDataset().then((_) {
      if (mounted) setState(() {});
    });
    _loadPrivacySettings();
    _initMap();
    _fetchRealLocations();
    context.read<BottomNavCubit>().hideBar();
  }

  Future<void> _loadPrivacySettings() async {
    final ghost = await SharedPrefsHelper.getGhostMode();
    final fuzzy = await SharedPrefsHelper.getFuzzyLocation();
    if (mounted) {
      setState(() {
        _ghostMode = ghost;
        _fuzzyLocation = fuzzy;
      });
    }
  }

  Future<void> _fetchRealLocations() async {
    try {
      final apiService = ApiService();
      final uid = await SharedPrefsHelper.getUserId();
      if (uid != null && uid.isNotEmpty) {
        try {
          final leaderboard = await apiService.getLeaderboard(uid);
          if (leaderboard != null && leaderboard['impactStory'] != null) {
            final story = leaderboard['impactStory'];
            if (mounted) {
              setState(() {
                _myBottlesSaved = (story['bottlesSaved'] as num? ?? 0).toInt();
                _myCarbonReduced =
                    (story['carbonReduced'] as num? ?? 0.0).toDouble();
              });
            }
          }
        } catch (e) {
          debugPrint("Error fetching user leaderboard for map: $e");
        }
      }

      final locations = await apiService.getUsersLocations();
      if (mounted) {
        setState(() {
          _serverUserLocations = locations.map((loc) {
            return UserMapLocation(
              userId: loc['userId']?.toString() ?? '',
              position: LatLng(
                (loc['latitude'] as num).toDouble(),
                (loc['longitude'] as num).toDouble(),
              ),
              bottlesSaved: (loc['bottlesSaved'] as num? ?? 0).toInt(),
              carbonReduced: (loc['carbonReduced'] as num? ?? 0.0).toDouble(),
              totalConsumed: (loc['totalConsumed'] as num? ?? 0).toInt(),
            );
          }).toList();
        });
      }

      // Obtain user's real GPS position if permission is granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        final currentLatLng = LatLng(pos.latitude, pos.longitude);
        await SharedPrefsHelper.setUserLatitude(pos.latitude);
        await SharedPrefsHelper.setUserLongitude(pos.longitude);
        if (mounted) {
          setState(() {
            _currentUserLocation = currentLatLng;
          });
          try {
            final placemarks =
                await placemarkFromCoordinates(pos.latitude, pos.longitude);
            if (placemarks.isNotEmpty &&
                placemarks.first.country != null &&
                placemarks.first.country!.isNotEmpty) {
              _selectCountry(placemarks.first.country!,
                  center: currentLatLng, zoom: 4.8);
            } else {
              _animateToLocation(currentLatLng, zoom: 4.8);
            }
          } catch (_) {
            _animateToLocation(currentLatLng, zoom: 4.8);
          }
        }
        final uid = await SharedPrefsHelper.getUserId();
        if (uid != null && uid.isNotEmpty) {
          _syncLocationToServer();
        }
      }
    } catch (e) {
      debugPrint("Error fetching real locations: $e");
    }
  }

  Future<void> _syncLocationToServer() async {
    final uid = await SharedPrefsHelper.getUserId();
    if (uid == null || uid.isEmpty || _currentUserLocation == null) return;
    await ApiService().syncUserLocation(
        uid, _currentUserLocation!.latitude, _currentUserLocation!.longitude);
  }

  @override
  void dispose() {
    _geocodeDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    if (Platform.isIOS) {
      try {
        const MethodChannel mapsChannel =
            MethodChannel('com.sipnudge.sipnudge/google_maps');
        await mapsChannel.invokeMethod(
            'setApiKey', {'key': AppApiConstants.googleMapsApiKey});
      } catch (e) {
        debugPrint("Error registering iOS Google Maps API Key: $e");
      }
    }
    if (mounted) {
      setState(() {
        _isMapInitialized = true;
      });
      _checkAndShowPrivacyPanel();
    }
  }

  Future<void> _checkAndShowPrivacyPanel() async {
    final hasShown = await SharedPrefsHelper.hasShownLocationPrivacy();
    if (!hasShown) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _showPrivacyPanel();
          await SharedPrefsHelper.setHasShownLocationPrivacy(true);
        });
      }
    }
  }

  void _selectCountry(String countryName, {LatLng? center, double? zoom}) {
    final info = CountryBordersHelper.getCountryInfo(countryName,
        fallbackCenter: center);
    setState(() {
      _selectedCountry = info.name;
      _currentCountry = info.name;
    });

    final targetCenter = center ?? info.center;
    final targetZoom = (zoom ?? info.zoom).clamp(2.0, 6.2);
    _animateToLocation(targetCenter, zoom: targetZoom);
  }

  Future<void> _updateLocationNames(LatLng target) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(target.latitude, target.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final country = (place.country != null && place.country!.isNotEmpty)
            ? place.country!
            : '';

        if (country.isNotEmpty && country != _currentCountry) {
          setState(() {
            _currentCountry = country;
            _selectedCountry = country;
          });
        }
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
  }

  Map<String, dynamic> _getScopeDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countryName = _selectedCountry;
    final isGlobal = countryName == 'Global' || _currentZoom < 3.0;

    if (isGlobal) {
      // Global View: Sum of all users globally
      final Map<String, int> userBottles = {};
      final Map<String, double> userCarbon = {};

      int index = 0;
      for (final loc in _serverUserLocations) {
        final key = loc.userId.isNotEmpty ? loc.userId : 'user_$index';
        userBottles[key] = loc.bottlesSaved;
        userCarbon[key] = loc.carbonReduced;
        index++;
      }

      int totalBottles = userBottles.values.fold(0, (sum, b) => sum + b);
      double totalCarbon = userCarbon.values.fold(0.0, (sum, c) => sum + c);

      if (totalBottles < _myBottlesSaved) {
        totalBottles = _myBottlesSaved;
        totalCarbon = _myCarbonReduced;
      }

      final carbonStr = totalCarbon.toStringAsFixed(1);
      return {
        'title': l10n?.globalCommunity ?? 'Global Community',
        'tag': l10n?.globalView ?? 'Global View',
        'story': _serverUserLocations.isNotEmpty
            ? (l10n?.globalStoryActive ??
                'Worldwide hydration impact across all active Sipnudge hydrators.')
            : (l10n?.globalStoryEmpty ??
                'No active global hydrators currently visible on the map.'),
        'bottlesSaved': totalBottles,
        'carbonReduced': carbonStr,
        'hydratorCount':
            _serverUserLocations.isNotEmpty ? _serverUserLocations.length : 1,
      };
    } else {
      // Country View
      final info = CountryBordersHelper.getCountryInfo(countryName);
      final center = info.center;
      int countryBottles = 0;
      double countryCarbon = 0.0;
      int hydratorCount = 0;

      for (final loc in _serverUserLocations) {
        final dist = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          loc.position.latitude,
          loc.position.longitude,
        );
        if (dist <= 1200000) {
          hydratorCount++;
          countryBottles += loc.bottlesSaved;
          countryCarbon += loc.carbonReduced;
        }
      }

      if (countryBottles < _myBottlesSaved && _myBottlesSaved > 0) {
        countryBottles = _myBottlesSaved;
        countryCarbon = _myCarbonReduced;
      }

      final carbonStr = countryCarbon > 0
          ? countryCarbon.toStringAsFixed(1)
          : _myCarbonReduced.toStringAsFixed(1);
      final finalBottles =
          countryBottles > 0 ? countryBottles : _myBottlesSaved;

      final communitySuffix = l10n?.communityText ?? 'Community';
      final viewSuffix = l10n?.viewText ?? 'View';

      return {
        'title': '${info.name} $communitySuffix',
        'tag': '${info.name} $viewSuffix',
        'story': hydratorCount > 0
            ? 'Highlighting ${info.name} with $hydratorCount active hydrator(s) and community hydration impact.'
            : 'Active regional hydration impact and community statistics in ${info.name}.',
        'bottlesSaved': finalBottles,
        'carbonReduced': carbonStr,
        'hydratorCount': hydratorCount > 0 ? hydratorCount : 1,
      };
    }
  }

  LatLng _getUserCoords() {
    final base = _currentUserLocation ?? _defaultCoords;
    if (!_fuzzyLocation) return base;
    return LatLng(base.latitude + 0.008, base.longitude + 0.008);
  }

  void _animateToLocation(LatLng target, {double zoom = 4.8}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom.clamp(2.0, 6.2)),
      ),
    );
  }

  Set<Polygon> _buildPolygons() {
    if (_selectedCountry == 'Global') return {};
    return CountryBordersHelper.buildCountryPolygons(
      _selectedCountry,
      fillColor: const Color(0xFF00A2FF).withOpacity(0.18),
      strokeColor: const Color(0xFF00A2FF),
      strokeWidth: 2,
    );
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    int index = 1;
    for (final loc in _serverUserLocations) {
      markers.add(
        Marker(
          markerId: MarkerId('server_user_$index'),
          position: loc.position,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: "Hydrator #$index",
            snippet: "${loc.bottlesSaved} bottles saved",
          ),
          onTap: () async {
            try {
              final placemarks = await placemarkFromCoordinates(
                loc.position.latitude,
                loc.position.longitude,
              );
              if (placemarks.isNotEmpty &&
                  placemarks.first.country != null &&
                  placemarks.first.country!.isNotEmpty) {
                _selectCountry(placemarks.first.country!, center: loc.position);
              }
            } catch (_) {}
          },
        ),
      );
      index++;
    }

    if (!_ghostMode && _currentUserLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_pin'),
          position: _getUserCoords(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(
            title: "You",
            snippet: "Your location",
          ),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final Set<Circle> circles = {};

    if (_selectedCountry != 'Global') {
      final info = CountryBordersHelper.getCountryInfo(_selectedCountry);
      circles.add(
        Circle(
          circleId: CircleId('country_glow_${info.name}'),
          center: info.center,
          radius: 350000,
          fillColor: const Color(0xFF00A2FF).withOpacity(0.06),
          strokeColor: const Color(0xFF00A2FF).withOpacity(0.25),
          strokeWidth: 1,
        ),
      );
    }

    if (_isHeatmapMode) {
      int index = 0;
      for (final loc in _serverUserLocations) {
        circles.add(
          Circle(
            circleId: CircleId("server_heatmap_$index"),
            center: loc.position,
            radius: 80000,
            fillColor: const Color(0xFFFF3D00).withOpacity(0.25),
            strokeColor: const Color(0xFFFF3D00).withOpacity(0.50),
            strokeWidth: 1,
          ),
        );
        index++;
      }
    }

    if (!_ghostMode && _fuzzyLocation && _currentUserLocation != null) {
      circles.add(
        Circle(
          circleId: const CircleId('user_fuzzy_radius'),
          center: _getUserCoords(),
          radius: 20000,
          fillColor: const Color(0xFF00A2FF).withOpacity(0.08),
          strokeColor: const Color(0xFF00A2FF).withOpacity(0.25),
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  void _showPrivacyPanel() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
                border: Border.all(
                  color: Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    l10n?.locationPrivacySettings ??
                        "Location Privacy Settings",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF0F172A),
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n?.locationPrivacyDescription ??
                        "Manage how your smart bottle and location interact with the community.",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.ghostMode ?? "Ghost Mode",
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  color: const Color(0xFF0F172A),
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation
                                  ]),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              l10n?.ghostModeDescription ??
                                  "When enabled, your avatar is completely hidden. Your logs still anonymously support the global community heatmap.",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Switch(
                        value: _ghostMode,
                        activeThumbColor: const Color(0xFF00A2FF),
                        onChanged: (val) {
                          setModalState(() => _ghostMode = val);
                          setState(() => _ghostMode = val);
                          SharedPrefsHelper.setGhostMode(val);
                          _syncLocationToServer();
                          if (!val && _currentUserLocation != null) {
                            _animateToLocation(_getUserCoords());
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black12, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.fuzzyLocation ?? "Fuzzy Location",
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  color: const Color(0xFF0F172A),
                                  fontVariations: [
                                    AppFontStyles.boldFontVariation
                                  ]),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              l10n?.fuzzyLocationDescription ??
                                  "Off-sets your marker by 500m–1km on the map so others see your general neighborhood, not your exact address.",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Switch(
                        value: _fuzzyLocation,
                        activeThumbColor: const Color(0xFF00A2FF),
                        onChanged: (val) {
                          setModalState(() => _fuzzyLocation = val);
                          setState(() => _fuzzyLocation = val);
                          SharedPrefsHelper.setFuzzyLocation(val);
                          _syncLocationToServer();
                          if (!_ghostMode && _currentUserLocation != null) {
                            _animateToLocation(_getUserCoords());
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_isMapInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A2FF)),
          ),
        ),
      );
    }

    final initialTarget = _currentUserLocation ??
        (_serverUserLocations.isNotEmpty
            ? _serverUserLocations.first.position
            : _defaultCoords);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        context.read<BottomNavCubit>().showBar();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 4.8,
                ),
                minMaxZoomPreference: const MinMaxZoomPreference(2.0, 6.2),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _mapController?.setMapStyle(_mapStyleJson);
                  if (_currentUserLocation != null) {
                    _animateToLocation(_getUserCoords(), zoom: 4.8);
                  }
                },
                onCameraMove: (CameraPosition position) {
                  _lastCameraTarget = position.target;
                  if ((position.zoom - _currentZoom).abs() > 0.1) {
                    setState(() {
                      _currentZoom = position.zoom;
                    });
                  }
                  _geocodeDebounceTimer?.cancel();
                  _geocodeDebounceTimer =
                      Timer(const Duration(milliseconds: 300), () {
                    _updateLocationNames(position.target);
                  });
                },
                onCameraIdle: () {
                  _geocodeDebounceTimer?.cancel();
                  _updateLocationNames(_lastCameraTarget);
                },
                onTap: (LatLng tappedCoords) async {
                  try {
                    List<Placemark> placemarks = await placemarkFromCoordinates(
                        tappedCoords.latitude, tappedCoords.longitude);
                    if (placemarks.isNotEmpty) {
                      final country = placemarks.first.country;
                      if (country != null && country.isNotEmpty) {
                        _selectCountry(country, center: tappedCoords);
                      }
                    }
                  } catch (e) {
                    debugPrint("Map onTap geocode error: $e");
                  }
                },
                polygons: _buildPolygons(),
                markers: _buildMarkers(),
                circles: _buildCircles(),
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                ),
                padding: EdgeInsets.only(
                    top: 60.h, bottom: 14.h, left: 20.w, right: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<BottomNavCubit>().showBar();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Color(0xFF0F172A), size: 20),
                      ),
                    ),
                    Text(
                      l10n?.sipMap ?? "Sip Map",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: const Color(0xFF0F172A),
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPrivacyPanel,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _ghostMode ? Icons.security : Icons.visibility_off,
                          color: _ghostMode
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF00A2FF),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Horizontal Country Selector Chips Bar
            Positioned(
              top: 116.h,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 38.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ...CountryBordersHelper.popularCountries.map((c) {
                      final isSelected = _selectedCountry == c['name'];
                      return _buildCountryChip(
                        label: "${c['flag']} ${c['name']}",
                        isSelected: isSelected,
                        onTap: () {
                          _selectCountry(c['name']!);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 166.h,
              left: 50.w,
              right: 50.w,
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isHeatmapMode = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isHeatmapMode
                                ? const Color(0xFF00A2FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n?.friendsMap ?? "Friends Map",
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: !_isHeatmapMode
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontVariations: [
                                !_isHeatmapMode
                                    ? AppFontStyles.boldFontVariation
                                    : AppFontStyles.semiBoldFontVariation
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isHeatmapMode = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isHeatmapMode
                                ? const Color(0xFF00A2FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n?.globalHeatmap ?? "Global Heatmap",
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: _isHeatmapMode
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontVariations: [
                                _isHeatmapMode
                                    ? AppFontStyles.boldFontVariation
                                    : AppFontStyles.semiBoldFontVariation
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30.h,
              left: 20.w,
              right: 20.w,
              child: Builder(
                builder: (context) {
                  final scopeInfo = _getScopeDetails(context);
                  final l10n = AppLocalizations.of(context);
                  return Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              scopeInfo['title']!,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: const Color(0xFF0F172A),
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF00A2FF).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Text(
                                scopeInfo['tag']!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF00A2FF),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          scopeInfo['story']!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF475569),
                            height: 1.4,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildImpactStatCard(
                                iconAsset: AssetsPath.leaderWaterIntake,
                                value: "${scopeInfo['bottlesSaved']}",
                                label:
                                    l10n?.bottlesSavedUpper ?? "BOTTLES SAVED",
                                valueColor: const Color(0xFF003057),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildImpactStatCard(
                                iconAsset: AssetsPath.leaderCo2,
                                value: "${scopeInfo['carbonReduced']} kg",
                                label: l10n?.carbonReducedUpper ??
                                    "CARBON REDUCED",
                                valueColor: const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A2FF) : Colors.white,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00A2FF)
                : Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF00A2FF).withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              isSelected
                  ? AppFontStyles.boldFontVariation
                  : AppFontStyles.semiBoldFontVariation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactStatCard({
    required String iconAsset,
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color.fromARGB(255, 235, 235, 235),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            iconAsset,
            width: 36.w,
            height: 36.h,
          ),
          SizedBox(height: 8.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: valueColor,
                  fontVariations: [AppFontStyles.extraBoldFontVariation],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
