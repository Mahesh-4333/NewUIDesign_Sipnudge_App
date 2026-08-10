import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/screens/onboarding/hydration_ring_onboarding_screen.dart';
import 'package:hydrify/services/location_service.dart';
import 'package:hydrify/l10n/app_localizations.dart';

class EnvironmentalHarmonyLocationScreen extends StatefulWidget {
  const EnvironmentalHarmonyLocationScreen({super.key});

  @override
  State<EnvironmentalHarmonyLocationScreen> createState() =>
      _EnvironmentalHarmonyLocationScreenState();
}

class _EnvironmentalHarmonyLocationScreenState
    extends State<EnvironmentalHarmonyLocationScreen> {
  String _displayName = 'Newton Singh';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userManager = UserManager();
    if (userManager.userName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _displayName = userManager.userName;
        });
      }
    } else {
      final storedName = await SharedPrefsHelper.getUserName();
      if (storedName != null && storedName.isNotEmpty && mounted) {
        setState(() {
          _displayName = storedName;
        });
      } else if (mounted) {
        final userInfoState = context.read<UserInfoCubit>().state;
        if (userInfoState.name != null && userInfoState.name!.isNotEmpty) {
          setState(() {
            _displayName = userInfoState.name!;
          });
        }
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppLocalizations.of(context)?.goodMorning ?? 'Good Morning';
    } else if (hour < 17) {
      return AppLocalizations.of(context)?.goodAfternoon ?? 'Good Afternoon';
    } else {
      return AppLocalizations.of(context)?.goodEvening ?? 'Good Evening';
    }
  }

  Future<void> _requestLocationAndProceed() async {
    try {
      await LocationService().handlePermission();
    } catch (_) {
      // Also request via permission_handler as fallback
      await Permission.location.request();
    }
    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const HydrationRingOnboardingScreen(isFromOnboarding: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Top Gradient Card Header
            _buildTopHeaderCard(context),

            // Scrollable Middle Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 28.h),

                    // Main Title
                    Text(
                      AppLocalizations.of(context)?.environmentalHarmony ?? 'Environmental\nHarmony',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF35586B),
                        fontSize: 26.sp,
                        height: 1.25,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Description Subtitle
                    Text(
                      AppLocalizations.of(context)?.environmentalHarmonyDescription ?? 'Connect seamlessly with your \nsurroundings. Sipnudge harmonizes \nwith local climate conditions to \ndynamically balance your hydration \nneeds, maintaining optimal wellness \nwherever you are.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF4A6B7C),
                        fontSize: 18.sp,
                        height: 1.5,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                      ),
                    ),
                    SizedBox(height: 36.h),

                    // Horizontal Weather Icons Row
                    _buildWeatherIconsRow(),
                    SizedBox(height: 44.h),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Padding(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                bottom: 24.h,
                top: 8.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Disclaimer / Footnote Text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      AppLocalizations.of(context)?.temperatureCalibrationDisclaimer ?? "Temperature data is primary sourced from your Sipnudge bottle to estimate surrounding conditions. If the bottle is unavailable, the model automatically switches to your city's local temperature for calibration.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: const Color(0xFF788A96),
                          fontSize: 11.sp,
                          height: 1.45,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation]),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Enable Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _requestLocationAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A2FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.enableLocation ?? 'Enable Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // I'll do it later Button
                  InkWell(
                    onTap: _navigateToNext,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.illDoItLater ?? "I'll do it later",
                        style: TextStyle(
                          color: const Color(0xFF1E293B),
                          fontSize: 15.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            AppFontStyles.boldFontVariation,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xB2C4E8FF),
            Color(0xB283B7D7),
            Color(0xB2418BB0),
            Color(0xB2005586),
          ],
          stops: [0.0, 0.33, 0.66, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 8.h,
            bottom: 24.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Row
              InkWell(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color.fromARGB(255, 29, 29, 29),
                    size: 24,
                  ),
                ),
              ),
              SizedBox(height: 6.h),

              // e.g. label
              Text(
                AppLocalizations.of(context)?.eg ?? 'e.g.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation]),
              ),

              // Greeting
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 17.sp,
                  fontFamily: AppFontStyles.museoModernoFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
              ),

              // Name
              Text(
                _displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 14.h),

              // Weather Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Weather Icon & Temp
                  Column(
                    children: [
                      Image.asset(
                        AssetsPath.onboardingSunnyWeather,
                        width: 44.w,
                        height: 44.w,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '26°C/68%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 14.w),

                  // Weather Text Message
                  Expanded(
                    child: Text(
                      "${AppLocalizations.of(context)?.itsA ?? "It's a "}${AppLocalizations.of(context)?.sunnyDay ?? "Sunny"}${AppLocalizations.of(context)?.today ?? " today!"}\n${AppLocalizations.of(context)?.waterBottleReminder ?? "Remember to stay hydrated throughout the day"}",
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 16.sp,
                          height: 1.35,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherIconsRow() {
    return const _WeatherIconsMarquee();
  }
}

class _WeatherIconsMarquee extends StatefulWidget {
  const _WeatherIconsMarquee();

  @override
  State<_WeatherIconsMarquee> createState() => _WeatherIconsMarqueeState();
}

class _WeatherIconsMarqueeState extends State<_WeatherIconsMarquee>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;

  static const List<String> _weatherAssets = [
    'assets/weather/01_sunny_color.png',
    'assets/weather/02_moon_stars_color.png',
    'assets/weather/03_cloud_color.png',
    'assets/weather/04_sun_cloudy_color.png',
    'assets/weather/05_moon_cloudy_color.png',
    'assets/weather/06_cloudy_color.png',
    'assets/weather/07_lightning_color.png',
    'assets/weather/08_wet_color.png',
    'assets/weather/09_light_rain_color.png',
    'assets/weather/10_moderate_rain_color.png',
    'assets/weather/11_heavy_rain_color.png',
    'assets/weather/12_rainstorm_color.png',
    'assets/weather/13_heavy_rainstorm_color.png',
    'assets/weather/14_thunderstorm_color.png',
    'assets/weather/15_fog_color.png',
    'assets/weather/16_hail_color.png',
    'assets/weather/17_light_sonw_color.png',
    'assets/weather/18_moderate_snow_color.png',
    'assets/weather/19_heavy_snow_color.png',
    'assets/weather/20_snowstorm_color.png',
    'assets/weather/21_heavy_snowstorm_color.png',
    'assets/weather/22_snow_color.png',
    'assets/weather/23_windy_color.png',
    'assets/weather/24_blizzard_color.png',
    'assets/weather/25_mist_color.png',
    'assets/weather/26_haze_color.png',
    'assets/weather/27_typhoon_color.png',
    'assets/weather/28_NA_color.png',
    'assets/weather/29_sunrise_color.png',
    'assets/weather/30_sunset_color.png',
    'assets/weather/31_low_temperature_color.png',
    'assets/weather/32_high_temperature_color.png',
    'assets/weather/33_sparkles_color.png',
    'assets/weather/34_full_moon_color.png',
    'assets/weather/35_partly_cloudy_daytime_color.png',
    'assets/weather/36_partly_cloudy_night_color.png',
    'assets/weather/37_dry_color.png',
    'assets/weather/38_blowing_sand_color.png',
    'assets/weather/39_sandstorm_color.png',
    'assets/weather/40_rainbow_color.png',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animController.repeat();
      }
    });
  }

  double get _itemExtent => 42.w + 32.w;

  void _onTick() {
    if (!_scrollController.hasClients) return;
    final itemExtent = _itemExtent;
    final singleLoopWidth = _weatherAssets.length * itemExtent;
    double newOffset = _scrollController.offset + 0.65;
    if (newOffset >= singleLoopWidth) {
      newOffset -= singleLoopWidth;
    }
    _scrollController.jumpTo(newOffset);
  }

  @override
  void dispose() {
    _animController.removeListener(_onTick);
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = 42.w;
    final itemExtent = _itemExtent;

    return SizedBox(
      height: 90.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final viewportCenter = containerWidth / 2;
          final maxDistance = 90.w;

          return AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final scrollOffset =
                  _scrollController.hasClients ? _scrollController.offset : 0.0;

              return ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final assetIndex = index % _weatherAssets.length;
                  final assetPath = _weatherAssets[assetIndex];

                  final itemCenter =
                      (index * itemExtent) + (itemExtent / 2) - scrollOffset;
                  final distanceFromCenter =
                      (itemCenter - viewportCenter).abs();

                  final normDistance =
                      (distanceFromCenter / maxDistance).clamp(0.0, 1.0);
                  final bellFactor =
                      (1.0 - normDistance) * (1.0 - normDistance);
                  final scale = 0.85 + (0.90 * bellFactor);
                  final opacity = 0.55 + (0.45 * bellFactor);

                  return Container(
                    width: itemExtent,
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Image.asset(
                          assetPath,
                          width: itemWidth,
                          height: itemWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
