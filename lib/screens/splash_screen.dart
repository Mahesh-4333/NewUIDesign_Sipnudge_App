import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/local_auth_screen.dart';
import 'package:hydrify/screens/language_selection_screen.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashInitResult {
  final bool isShutdown;
  final bool isFirstTime;

  _SplashInitResult({required this.isShutdown, required this.isFirstTime});
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  late Future<_SplashInitResult> _initFuture;
  bool _hasNavigated = false;
  bool _hasStartedPlaying = false;

  @override
  void initState() {
    super.initState();

    // Start background sync & checks immediately
    _initFuture = _performBackgroundInit();

    _controller = VideoPlayerController.asset(AssetsPath.onboardingLogoAnim);
    _controller.addListener(_videoListener);
    _controller.initialize().then((_) async {
      if (mounted) {
        await _controller.setLooping(false);
        await _controller.play();
        setState(() {});
      }
    }).catchError((e) {
      Console.log(tag: "SPLASH", value: "Video init error: $e");
      _handleNavigation();
    });

    // Safety fallback: if video stalls or takes too long, navigate after 5s
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) {
        _handleNavigation();
      }
    });
  }

  void _videoListener() {
    if (!mounted || _hasNavigated) return;

    final value = _controller.value;
    if (value.hasError) {
      Console.log(tag: "SPLASH", value: "Video error: ${value.errorDescription}");
      _handleNavigation();
      return;
    }

    if (value.isInitialized && value.duration > Duration.zero) {
      if (value.isPlaying) {
        _hasStartedPlaying = true;
      }

      // Check if video has reached the end
      if (_hasStartedPlaying && value.position >= value.duration) {
        _handleNavigation();
      }
    }
  }

  Future<void> _handleNavigation() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Ensure background sync/trial status check is completed
    final result = await _initFuture;

    if (!mounted) return;

    if (result.isShutdown) {
      UiUtilsService.showTrialRestrictionDialog(context);
      return;
    }

    Widget targetScreen = result.isFirstTime
        ? const LanguageSelectionScreen(isFirstTime: true)
        : const LocalAuthScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650), // smoother
        pageBuilder: (_, animation, __) => targetScreen,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut, // smoother fade
          );

          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  Future<_SplashInitResult> _performBackgroundInit() async {
    DatabaseSyncService().syncAll();

    bool isShutdown = false;
    final email = await SharedPrefsHelper.getUserEmail();
    if (email != null && email.isNotEmpty) {
      try {
        final trialResponse = await ApiService().checkTrialStatus(email);
        if (trialResponse != null) {
          isShutdown = trialResponse["shutdown_app"] ?? false;
          await SharedPrefsHelper.setAppShutdownStatus(isShutdown);
        }
      } catch (e) {
        Console.log(tag: "AUTH", value: "Trial check failed: $e");
        isShutdown = await SharedPrefsHelper.isAppShutdown();
      }
    }

    final isFirstTime = await SharedPrefsHelper.isFirstTimeLaunch();
    return _SplashInitResult(isShutdown: isShutdown, isFirstTime: isFirstTime);
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
