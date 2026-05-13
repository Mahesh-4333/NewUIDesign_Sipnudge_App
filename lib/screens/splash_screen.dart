import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/local_auth_screen.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/location_service.dart';
import 'package:hydrify/services/database_sync_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;

        // Trigger database sync to backend
        DatabaseSyncService().syncAll();

        final email = await SharedPrefsHelper.getUserEmail();
        if (email != null && email.isNotEmpty) {
          try {
            final trialResponse = await ApiService().checkTrialStatus(email);
            if (trialResponse != null) {
              final bool isShutdown = trialResponse["shutdown_app"] ?? false;

              if (isShutdown) {
                await SharedPrefsHelper.setAppShutdownStatus(true);
                if (!mounted) return;
                UiUtilsService.showTrialRestrictionDialog(context);
                return;
              } else {
                // Ensure we clear shutdown status if server says it's okay now
                await SharedPrefsHelper.setAppShutdownStatus(false);
              }
            }
          } catch (e) {
            Console.log(tag: "AUTH", value: "Trial check failed: $e");
            // Fallback to local status if API fails
            final isShutdown = await SharedPrefsHelper.isAppShutdown();
            if (isShutdown) {
              if (!mounted) return;
              UiUtilsService.showTrialRestrictionDialog(context);
              return;
            }
          }
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 650), // smoother
            pageBuilder: (_, animation, __) => const LocalAuthScreen(),
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
      });
    });
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
          child: Image.asset(
            "assets/images/splash_screen_image.png",
            width: AppDimensions.dim329.w,
            height: AppDimensions.dim73.h,
          ),
        ),
      ),
    );
  }
}
