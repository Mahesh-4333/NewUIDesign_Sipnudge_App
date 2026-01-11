import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/screens/auth/local_auth_screen.dart';
import 'package:hydrify/services/location_service.dart';

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

        try {
          await LocationService().handlePermission();
        } catch (e) {
          print(e);
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
