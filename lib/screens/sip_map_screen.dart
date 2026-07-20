import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_api_constants.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';

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

  // Selected region for bottom Community Card overlay
  Map<String, dynamic>? _selectedRegion;

  // Locations / Communities data
  late final List<Map<String, dynamic>> _regions;

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

  // Base coordinates for regions
  static const LatLng _sfCoords = LatLng(37.7749, -122.4194);
  static const LatLng _mumbaiCoords = LatLng(19.0760, 72.8777);
  static const LatLng _londonCoords = LatLng(51.5074, -0.1278);
  static const LatLng _tokyoCoords = LatLng(35.6762, 139.6503);
  static const LatLng _nyCoords = LatLng(40.7128, -74.0060);
  static const LatLng _sydneyCoords = LatLng(-33.8688, 151.2093);
  static const LatLng _parisCoords = LatLng(48.8566, 2.3522);
  static const LatLng _delhiCoords = LatLng(28.6139, 77.2090);
  static const LatLng _berlinCoords = LatLng(52.5200, 13.4050);
  static const LatLng _userBaseCoords =
      LatLng(19.0500, 72.8500); // Shifted slightly from Mumbai

  List<LatLng> _serverUserLocations = [];

  @override
  void initState() {
    super.initState();
    _initRegions();
    _initMap();
    _fetchServerUserLocations();
  }

  Future<void> _fetchServerUserLocations() async {
    try {
      final apiService = ApiService();
      final locations = await apiService.getUsersLocations();
      if (mounted) {
        setState(() {
          _serverUserLocations = locations.map((loc) {
            return LatLng(loc['latitude']!, loc['longitude']!);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching server user locations: $e");
    }
  }

  Future<void> _initMap() async {
    // On iOS, dynamic API Key registration is required via MethodChannel
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

  void _initRegions() {
    // Initialize regions with real LatLng coordinate properties
    _regions = [
      {
        'id': 'sf',
        'name': 'San Francisco',
        'coords': _sfCoords,
        'bottlesSaved': 320,
        'carbonReduced': 31.3,
        'activeUsers': 142,
        'hue': BitmapDescriptor.hueRose,
        'story':
            'The Bay Area community has saved 320 bottles today! Direct action is lowering municipal waste near Silicon Valley.',
        'friends': [
          {'name': 'Sarah J.', 'level': 42},
          {'name': 'Mike T.', 'level': 35},
        ]
      },
      {
        'id': 'mumbai',
        'name': 'Mumbai',
        'coords': _mumbaiCoords,
        'bottlesSaved': 450,
        'carbonReduced': 44.1,
        'activeUsers': 289,
        'hue': BitmapDescriptor.hueGreen,
        'story':
            'The Mumbai community has saved 450 bottles today! Local tech campuses are driving dynamic hydration choices.',
        'friends': [
          {'name': 'Raj P.', 'level': 28},
          {'name': 'Ananya K.', 'level': 39},
        ]
      },
      {
        'id': 'london',
        'name': 'London',
        'coords': _londonCoords,
        'bottlesSaved': 210,
        'carbonReduced': 20.5,
        'activeUsers': 98,
        'hue': BitmapDescriptor.hueViolet,
        'story':
            'The London community has saved 210 bottles today! Commuters are replacing standard single-use PET bottles on the Tube.',
        'friends': [
          {'name': 'Emily R.', 'level': 30},
          {'name': 'John D.', 'level': 15},
        ]
      },
      {
        'id': 'tokyo',
        'name': 'Tokyo',
        'coords': _tokyoCoords,
        'bottlesSaved': 580,
        'carbonReduced': 56.8,
        'activeUsers': 312,
        'hue': BitmapDescriptor.hueOrange,
        'story':
            'The Tokyo community has saved 580 bottles today! Reusable smart bottles are trending in Shibuya and Shinjuku districts.',
        'friends': [
          {'name': 'Yuki S.', 'level': 48},
          {'name': 'Kenji M.', 'level': 22},
        ]
      },
      {
        'id': 'ny',
        'name': 'New York',
        'coords': _nyCoords,
        'bottlesSaved': 640,
        'carbonReduced': 62.5,
        'activeUsers': 295,
        'hue': BitmapDescriptor.hueCyan,
        'story':
            'New York City has saved 640 bottles today! Community actions near Central Park and Manhattan are minimizing waste.',
        'friends': [
          {'name': 'James L.', 'level': 50},
          {'name': 'Chloe W.', 'level': 38},
        ]
      },
      {
        'id': 'sydney',
        'name': 'Sydney',
        'coords': _sydneyCoords,
        'bottlesSaved': 190,
        'carbonReduced': 18.6,
        'activeUsers': 88,
        'hue': BitmapDescriptor.hueAzure,
        'story':
            'The Sydney community has saved 190 bottles today! Reusable habits along Bondi Beach are showing great progress.',
        'friends': [
          {'name': 'Liam N.', 'level': 24},
          {'name': 'Mia O.', 'level': 41},
        ]
      },
      {
        'id': 'paris',
        'name': 'Paris',
        'coords': _parisCoords,
        'bottlesSaved': 280,
        'carbonReduced': 27.4,
        'activeUsers': 156,
        'hue': BitmapDescriptor.hueRose,
        'story':
            'Paris has saved 280 bottles today! Tourists and locals are adopting reusable bottle stations throughout the city.',
        'friends': [
          {'name': 'Pierre B.', 'level': 37},
          {'name': 'Sophie M.', 'level': 29},
        ]
      },
      {
        'id': 'delhi',
        'name': 'New Delhi',
        'coords': _delhiCoords,
        'bottlesSaved': 390,
        'carbonReduced': 38.2,
        'activeUsers': 210,
        'hue': BitmapDescriptor.hueYellow,
        'story':
            'The New Delhi community has saved 390 bottles today! Reusable bottle campaigns are scaling across campuses.',
        'friends': [
          {'name': 'Amit S.', 'level': 34},
          {'name': 'Priya R.', 'level': 27},
        ]
      },
      {
        'id': 'berlin',
        'name': 'Berlin',
        'coords': _berlinCoords,
        'bottlesSaved': 330,
        'carbonReduced': 32.3,
        'activeUsers': 175,
        'hue': BitmapDescriptor.hueRed,
        'story':
            'Berlin has saved 330 bottles today! Eco-conscious cafe integrations are boosting sustainable hydration choices.',
        'friends': [
          {'name': 'Lukas K.', 'level': 45},
          {'name': 'Hannah G.', 'level': 32},
        ]
      }
    ];

    // Default to Mumbai as the first selection
    _selectedRegion = _regions[1];
  }

  // Returns user's location with fuzzy offset if enabled
  LatLng _getUserCoords() {
    if (!_fuzzyLocation) return _userBaseCoords;
    // Add fuzzy offset (approx 1km north-east)
    return LatLng(
        _userBaseCoords.latitude + 0.008, _userBaseCoords.longitude + 0.008);
  }

  // Identifies the closest community region to the current map camera position and updates state
  void _updateClosestRegion(LatLng cameraTarget) {
    if (_regions.isEmpty) return;

    Map<String, dynamic>? closestRegion;
    double minDistance = double.infinity;

    for (final region in _regions) {
      final coords = region['coords'] as LatLng;
      final distance = Geolocator.distanceBetween(
        cameraTarget.latitude,
        cameraTarget.longitude,
        coords.latitude,
        coords.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestRegion = region;
      }
    }

    if (closestRegion != null && closestRegion != _selectedRegion) {
      setState(() {
        _selectedRegion = closestRegion;
      });
    }
  }

  // Animates the camera to a target location
  void _animateToLocation(LatLng target, {double zoom = 12.0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  // Sets up the markers based on the selected mode & privacy toggles
  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    // Don't show friend pins in heatmap mode
    if (!_isHeatmapMode) {
      for (final region in _regions) {
        markers.add(
          Marker(
            markerId: MarkerId(region['id'] as String),
            position: region['coords'] as LatLng,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(region['hue'] as double),
            infoWindow: InfoWindow(
              title: "${region['name']} Community",
              snippet: "${region['activeUsers']} active users",
            ),
            onTap: () {
              setState(() => _selectedRegion = region);
              _animateToLocation(region['coords'] as LatLng);
            },
          ),
        );
      }
    }

    // Render user marker if Ghost Mode is disabled
    if (!_ghostMode) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_pin'),
          position: _getUserCoords(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(
            title: "You",
            snippet: "Approximate location",
          ),
        ),
      );
    }

    return markers;
  }

  // Sets up the circles for global heatmap hotspots or fuzzy location ranges
  Set<Circle> _buildCircles() {
    final Set<Circle> circles = {};

    // Draw Heatmap circles if Heatmap Mode is enabled
    if (_isHeatmapMode) {
      for (final region in _regions) {
        circles.add(
          Circle(
            circleId: CircleId("heatmap_${region['id']}"),
            center: region['coords'] as LatLng,
            radius: 80000, // 80km radius for community zone visibility
            fillColor: const Color(0xFFFF9100).withOpacity(0.25),
            strokeColor: const Color(0xFFFF9100).withOpacity(0.55),
            strokeWidth: 2,
          ),
        );
      }

      // Add circles for server users (seeded random users)
      int index = 0;
      for (final latLng in _serverUserLocations) {
        circles.add(
          Circle(
            circleId: CircleId("server_heatmap_$index"),
            center: latLng,
            radius: 40000, // 40km radius for individual users' heat spots
            fillColor: const Color(0xFFFF3D00).withOpacity(0.20),
            strokeColor: const Color(0xFFFF3D00).withOpacity(0.40),
            strokeWidth: 1,
          ),
        );
        index++;
      }
    }

    // Draw fuzzy location radius circle if Fuzzy Location is active & Ghost Mode is off
    if (!_ghostMode && _fuzzyLocation) {
      circles.add(
        Circle(
          circleId: const CircleId('user_fuzzy_radius'),
          center: _getUserCoords(),
          radius: 1200, // 1.2km fuzzy radius overlay
          fillColor: const Color(0xFF00A2FF).withOpacity(0.08),
          strokeColor: const Color(0xFF00A2FF).withOpacity(0.25),
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  // Opens the Location Privacy Settings Panel
  void _showPrivacyPanel() {
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
                    "Manage how your smart bottle and location interact with the community.",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Ghost Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ghost Mode",
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
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black12, height: 32),

                  // Fuzzy Location Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Fuzzy Location",
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Google Maps SDK Widget
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _mumbaiCoords,
                zoom: 4.0, // World/regional overview zoom
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _mapController?.setMapStyle(_mapStyleJson);
              },
              onCameraMove: (CameraPosition position) {
                _updateClosestRegion(position.target);
              },
              markers: _buildMarkers(),
              circles: _buildCircles(),
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          // 2. App Header (Overlaid)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
              ),
              padding: EdgeInsets.only(
                  top: 60.h, bottom: 20.h, left: 20.w, right: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    "Sip Map",
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

          // 3. Toggle Control (Friends vs Heatmap)
          Positioned(
            top: 130.h,
            left: 50.w,
            right: 50.w,
            child: Container(
              height: 48.h,
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
                          "Friends Map",
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
                          "Global Heatmap",
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

          // 4. Dynamic Overlay Community Story Card (Bottom)
          if (_selectedRegion != null)
            Positioned(
              bottom: 30.h,
              left: 20.w,
              right: 20.w,
              child: Container(
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
                          "${_selectedRegion!['name']} Community",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: const Color(0xFF0F172A),
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _animateToLocation(
                                _selectedRegion!['coords'] as LatLng);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A2FF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(100.r),
                            ),
                            child: Text(
                              "${_selectedRegion!['activeUsers']} Active",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF00A2FF),
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _selectedRegion!['story'],
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
                          child: _buildMiniStat(
                            title: "BOTTLES SAVED",
                            value: "${_selectedRegion!['bottlesSaved']}",
                            icon: Icons.local_drink,
                            color: const Color(0xFF00C853),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildMiniStat(
                            title: "CO2 REDUCED",
                            value: "${_selectedRegion!['carbonReduced']} kg",
                            icon: Icons.co2,
                            color: const Color(0xFF00A2FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 8.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
