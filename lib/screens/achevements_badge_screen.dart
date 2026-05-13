import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/screens/widgets/animated_achievement_badge.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/hydration/hydration_state.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/levelreached.dart';
import 'package:hydrify/screens/widgets/level_widgets/concentric_circles_animation.dart';

class AchievementsBadgeScreen extends StatefulWidget {
  const AchievementsBadgeScreen({super.key});

  @override
  State<AchievementsBadgeScreen> createState() =>
      _AchievementsBadgeScreenState();
}

class _AchievementsBadgeScreenState extends State<AchievementsBadgeScreen> {
  bool? isGuest;
  bool _loading = true;
  int _currentLevel = 0;
  int _dailyWaterGoal = 0;
  Map<int, String> _levelToIntakeMap = {};
  Map<int, double> _levelToMlMap = {};
  Map<int, double> _levelToExactMlMap = {};

  bool _didAutoRefresh = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _checkGuestUser();
    final liveTotalDrank =
        BlocProvider.of<HydrationCubit>(context, listen: false)
            .state
            .totalDrank;
    _loadHydrationData(liveTotalDrank: liveTotalDrank);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  Future<void> _checkGuestUser() async {
    final userEmail = await SharedPrefsHelper.getUserEmail();
    setState(() {
      isGuest = userEmail == "guest_user";
    });
  }

  Future<void> _loadHydrationData(
      {int? liveTotalDrank, bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }

    final userGoal = await SharedPrefsHelper.getUserGoal();
    final dailyGoalMl = userGoal ?? 1400;

    // Use the cubit's already-computed level data — refreshAchievementStats()
    // keeps this authoritative and up-to-date (including today).
    final hydrationState =
        BlocProvider.of<HydrationCubit>(context, listen: false).state;

    final int cubitLevel = hydrationState.currentLevel;
    final Map<int, String> cubitLevelMap = hydrationState.levelToIntakeMap;
    final Map<int, String> cubitExactLevelMap =
        hydrationState.exactLevelToIntakeMap;

    // Build the ml map from the string map (e.g. "2.2L" → 2200.0)
    final Map<int, double> localMlMap = {};
    final Map<int, double> localExactMlMap = {};
    cubitLevelMap.forEach((level, litresStr) {
      final parsed = double.tryParse(litresStr.replaceAll('L', ''));
      if (parsed != null) {
        localMlMap[level] = parsed * 1000;
      }
    });

    cubitExactLevelMap.forEach((level, litresStr) {
      final parsed = double.tryParse(litresStr.replaceAll('L', ''));
      localExactMlMap[level] = parsed!;
    });

    if (!mounted) return;

    setState(() {
      _currentLevel = cubitLevel.clamp(0, 365);
      _levelToIntakeMap = cubitLevelMap;
      _levelToMlMap = localMlMap;
      _levelToExactMlMap = localExactMlMap;
      _dailyWaterGoal = dailyGoalMl;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getWaterIntakeForLevel(int level) {
    if (level <= 0 || !_levelToExactMlMap.containsKey(level)) return '0';
    return _levelToExactMlMap[level]!.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didAutoRefresh) {
        _didAutoRefresh = true;
      }
    });

    if (isGuest == null || _loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _buildRegularScreen();
  }

  // ===================== REGULAR SCREEN + GUEST OVERLAY =====================

  Widget _buildRegularScreen() {
    return BlocConsumer<HydrationCubit, HydrationState>(
        listener: (context, state) {
      _loadHydrationData(liveTotalDrank: state.totalDrank, silent: true);
    }, builder: (context, state) {
      final int currentLevelNum = int.tryParse(_currentLevel.toString()) ?? 0;
      final bool hasAchievedAnyLevel = currentLevelNum > 0;
      return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/app_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        if (hasAchievedAnyLevel)
                          const ConcentricCirclesAnimation(),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: getCurrentLevelBadge(
                            _currentLevel.toString(),
                          ),
                        ),
                        Positioned(
                            top: AppDimensions.dim380.h,
                            left: 0,
                            right: 0,
                            child: getCongratulationsText(
                                _currentLevel.toString(), _currentLevel)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.padding_20.w,
                      ),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              AppDimensions.radius_24.r,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .1),
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ]),
                      child: GridView.builder(
                        itemCount: 52,
                        padding: EdgeInsets.only(bottom: 120.h, top: 60.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2.r,
                          mainAxisSpacing: 24.h,
                        ),
                        itemBuilder: (context, index) {
                          final level = index + 1;
                          final isUnlocked = level <= _currentLevel;

                          final intakeInfo = _levelToIntakeMap[level] ?? '';

                          return Builder(
                            builder: (itemContext) {
                              return GestureDetector(
                                onTap: () async {
                                  if (isUnlocked && !isGuest!) {
                                    _confettiController.play();
                                    VibrationHelper.vibrate(duration: 250);
                                    final ScreenshotController
                                        screenshotController =
                                        ScreenshotController();

                                    await showLevelUpDialog(context, level,
                                        _getWaterIntakeForLevel(level),
                                        screenshotController:
                                            screenshotController,
                                        confettiController: _confettiController,
                                        createParticlePath: drawRandomShape,
                                        onShare: (dialogContext) async {
                                      _confettiController.stop();
                                      try {
                                        // Capture the dialog as image bytes
                                        final Uint8List? imageBytes =
                                            await screenshotController.capture(
                                          pixelRatio:
                                              2.0, // adjust to improve resolution
                                        );

                                        if (imageBytes == null) {
                                          debugPrint(
                                              "Error: imageBytes is null");
                                          return;
                                        }

                                        // Get a temporary directory
                                        final tempDir =
                                            await getTemporaryDirectory();
                                        final String filePath =
                                            '${tempDir.path}/level_up.png';

                                        // Write the bytes to a file
                                        final File file =
                                            await File(filePath).create();
                                        await file.writeAsBytes(imageBytes);

                                        // Pop the dialog explicitly using its own context
                                        Navigator.pop(dialogContext);

                                        if (!itemContext.mounted) return;

                                        // Use share_plus to share this image file
                                        final box = itemContext
                                            .findRenderObject() as RenderBox;
                                        await Share.shareXFiles(
                                            [XFile(file.path)],
                                            text:
                                                "I've reached Level $level on Sipnudge! 💧",
                                            subject: "My Hydration Achievement",
                                            sharePositionOrigin:
                                                box.localToGlobal(Offset.zero) &
                                                    box.size);
                                      } catch (e) {
                                        debugPrint(
                                            "Error capturing or sharing: $e");
                                      }
                                    });
                                    _confettiController.stop();
                                  }
                                },
                                child: getLevelBadges(
                                  level.toString(),
                                  isUnlocked,
                                  intakeInfo,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- GUEST BLUR + DIALOG ----------------
            if (isGuest == true) ...[
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: Platform.isIOS
                      ? AppDimensions.dim340.w
                      : AppDimensions.dim380.w,
                  height: Platform.isIOS
                      ? AppDimensions.dim75.h
                      : AppDimensions.dim75.h,
                  margin:
                      EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: Platform.isIOS
                        ? AppDimensions.dim20.w
                        : AppDimensions.dim11.w,
                    vertical: Platform.isIOS
                        ? AppDimensions.dim16.h
                        : AppDimensions.dim13.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius_100.r),
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/images/guest_dialog.png",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Text(
                    "Connect to Sipnudge bottle to access analysis",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.bluegray,
                      fontFamily: AppFontStyles.museoModernoFontFamily,
                      fontSize: AppFontStyles.fontSize_16.sp,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
                createParticlePath: drawRandomShape,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget getCurrentLevelBadge(String level) {
    final int currentLevelNum = int.tryParse(level) ?? 0;
    final bool hasAchievedAnyLevel = currentLevelNum > 0;
    return SizedBox(
      width: AppDimensions.dim330.w,
      height: AppDimensions.dim320.h,
      child: Stack(
        children: [
          hasAchievedAnyLevel
              ? Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(-0.w, 0),
                      child: AnimatedAchievementBadge(),
                    ),
                  ),
                )
              : Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(-0.w, 0),
                      child: Image.asset(
                        hasAchievedAnyLevel
                            ? "assets/images/goals_new_img.png"
                            : "assets/images/level_lock_img1.png",
                        width: hasAchievedAnyLevel
                            ? AppDimensions.dim330.w
                            : AppDimensions.dim280.w,
                        height: hasAchievedAnyLevel
                            ? AppDimensions.dim320.h
                            : AppDimensions.dim280.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
          if (hasAchievedAnyLevel)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 165.h,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF16446F),
                    Color(0xFF2569A9),
                    Color(0xFF59ADFB),
                  ],
                ).createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                blendMode: BlendMode.srcIn,
                child: Transform.translate(
                  offset: Offset(-2, 0.h),
                  child: Text(
                    level,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 90.sp,
                      fontVariations: [AppFontStyles.extraBoldFontVariation],
                      fontFamily: AppFontStyles.poppinsFamily,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget getLevelBadges(String level, bool isUnlocked, String waterIntake) {
    return SizedBox(
      height: isUnlocked ? AppDimensions.dim137.h : AppDimensions.dim1.h,
      width: AppDimensions.dim115.w,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: isUnlocked
                ? AnimatedAchievementBadge()
                : Padding(
                    padding: EdgeInsets.only(top: AppDimensions.dim22.h),
                    child: Image.asset(
                      "assets/images/level_lock_img1.png",
                      width: AppDimensions.dim70.w,
                      height: AppDimensions.dim70.h,
                    ),
                  ),
          ),
          if (isUnlocked)
            Positioned.fill(
              child: Align(
                alignment: Platform.isIOS
                    ? const Alignment(0, -0.1)
                    : const Alignment(0, -0.1),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF16446F),
                      Color(0xFF2569A9),
                      Color(0xFF59ADFB),
                    ],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    level,
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.extraBoldFontVariation],
                      fontSize: AppFontStyles.fontSize_35,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: isUnlocked ? AppDimensions.dim93.h : AppDimensions.dim80.h,
            left: isUnlocked ? AppDimensions.dim5.w : 0.w,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isUnlocked ? 'Level $level' : 'Level $level',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.bluegray
                        : AppColors.bluegray.withOpacity(0.5),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    fontSize: AppFontStyles.fontSize_14,
                  ),
                ),
                SizedBox(height: AppDimensions.dim4.h),
                Text(
                  isUnlocked ? 'Intake: $waterIntake' : 'Intake : 0',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.bluegray
                        : AppColors.bluegray.withOpacity(0.5),
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                    fontSize: AppFontStyles.fontSize_10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget getCongratulationsText(String level, int currentLevel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (currentLevel != 0)
            Text(
              '${AppStrings.levelreach} $level!',
              style: TextStyle(
                color: AppColors.bluegray,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
          SizedBox(height: AppDimensions.dim10.h),
          Text(
            currentLevel > 0
                ? AppStrings.congratulations(
                    _getWaterIntakeForLevel(currentLevel),
                    _dailyWaterGoal.toString())
                : AppStrings.achievementMsgWhenNoGoalNotReached(
                    _dailyWaterGoal.toString()),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.fontWeightVariation600],
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(-90);

    path.moveTo(halfWidth + externalRadius * cos(fullAngle),
        halfWidth + externalRadius * sin(fullAngle));

    for (double step = 0; step < 360; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step + fullAngle),
          halfWidth + externalRadius * sin(step + fullAngle));
      path.lineTo(
          halfWidth +
              internalRadius * cos(step + halfDegreesPerStep + fullAngle),
          halfWidth +
              internalRadius * sin(step + halfDegreesPerStep + fullAngle));
    }
    path.close();
    return path;
  }

  Path drawRandomShape(Size size) {
    final random = Random();
    final choice = random.nextInt(4);

    switch (choice) {
      case 0:
        return drawStar(size);
      case 1:
        return Path()
          ..addOval(Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2));
      case 2:
        return Path()
          ..addRect(Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: size.width,
              height: size.height));
      case 3:
        final path = Path();
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(0, size.height / 2);
        path.close();
        return path;
      default:
        return drawStar(size);
    }
  }
}
