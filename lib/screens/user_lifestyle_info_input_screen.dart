import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/cupertino_bottom_sheet.dart';
import 'package:hydrify/helpers/page_transitions.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/screens/fuel_flow_info_screen.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_radio_selection_widget.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/next_button_widget.dart';

class UserLifestyleInfoInputScreen extends StatefulWidget {
  const UserLifestyleInfoInputScreen(
      {super.key, required this.isViaSettingsScreen});

  final bool isViaSettingsScreen;
  @override
  State<UserLifestyleInfoInputScreen> createState() =>
      _UserLifestyleInfoInputScreenState();
}

class _UserLifestyleInfoInputScreenState
    extends State<UserLifestyleInfoInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _bellController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bellRotationAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _bellRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.06, end: 0.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: -0.04)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.04, end: 0.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.03, end: -0.015)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.015, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_bellController);

    _animController.forward().then((_) {
      // Loop the bell wiggle animation
      _bellController.repeat();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)?.profileSetup ?? "Profile Setup",
          style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_AppBar,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                AppFontStyles.boldFontVariation,
              ]),
        ),
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            "assets/images/back_ic.svg",
          ),
        ),
        ),
      body: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.only(
          top: AppDimensions.dim120.h,
          bottom: AppDimensions.bottomBarHeight,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.defaultPadding.w,
            vertical: AppDimensions.defaultPadding.h,
          ),
          children: [
            // ── Centered Page Header ─────────────────────────────────────
            Column(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: RotationTransition(
                      turns: _bellRotationAnimation,
                      alignment: Alignment.topCenter,
                      child: Transform.scale(
                        scale: 1.5,
                        child: Image.asset(
                          AssetsPath.onboardingQuitHour,
                          width: 70.w,
                          height: 70.w,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  AppLocalizations.of(context)?.quietHoursAndActivity ?? "Quiet Hours & Activity",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_24,
                    color: AppColors.bluegray,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  AppLocalizations.of(context)?.sleepScheduleSubtitle ?? "Set your sleep schedule so Sipnudge stays\ncompletely silent overnight.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_15,
                    color: AppColors.bluegray,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimensions.dim24.h),

            // ── Sleep Cycle Card ─────────────────────────────────────────
            Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: const Color(0xFF38BDF8),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocalizations.of(context)?.sleepCycle ?? "Sleep Cycle",
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: AppFontStyles.fontSize_16,
                          color: const Color(0xFF475569),
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Wake Time Row
                  BlocBuilder<UserInfoCubit, UserInfoState>(
                    builder: (context, state) {
                      return _buildTimeCapsule(
                        context: context,
                        label: AppLocalizations.of(context)?.wakeTime ?? "Wake Time",
                        icon: AssetsPath.onboardingWakeUpHour,
                        iconColor: const Color(0xFF38BDF8),
                        hour: state.wakeupHour,
                        minute: state.wakeupMinute,
                        period: state.wakeupPeriod ?? "AM",
                        isBedtime: false,
                      );
                    },
                  ),

                  SizedBox(height: 12.h),

                  Divider(
                    color: const Color(0xFFF1F5F9),
                    thickness: 1,
                    height: 1,
                  ),

                  SizedBox(height: 12.h),

                  // Bed Time Row
                  BlocBuilder<UserInfoCubit, UserInfoState>(
                    builder: (context, state) {
                      return _buildTimeCapsule(
                        context: context,
                        label: AppLocalizations.of(context)?.bedTime ?? "Bed Time",
                        icon: AssetsPath.onboardingSleep,
                        iconColor: const Color(0xFFFACC15),
                        hour: state.bedtimeHour,
                        minute: state.bedtimeMinute,
                        period: state.bedtimePeriod ?? "PM",
                        isBedtime: true,
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: AppDimensions.dim24.h),

            // ── Activity Level Section ───────────────────────────────────
            Text(
              AppLocalizations.of(context)?.activityLevel ?? "ACTIVITY LEVEL",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_13,
                color: AppColors.bluegray,
                fontVariations: [AppFontStyles.boldFontVariation],
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: AppDimensions.dim12.h),
            const CustomRadioSelectionWidget(type: 2),
            SizedBox(height: AppDimensions.dim80.h),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: AppDimensions.dim60,
        margin: EdgeInsets.only(
          bottom: AppDimensions.dim30.h,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
        ),
        child: CustomNextButton(
            text: "Next",
            onNextPressed: () async {
              final cubit = context.read<UserInfoCubit>();
              var state = cubit.state;

              if (state.wakeupHour == null || state.wakeupMinute == null) {
                cubit.updateWakeupTime(hour: 7, minute: 0, period: 'AM');
              }

              if (state.bedtimeHour == null || state.bedtimeMinute == null) {
                cubit.updateBedTime(hour: 10, minute: 30, period: 'PM');
              }

              if (!context.mounted) return;

              Navigator.push(
                context,
                SlidePageRoute(
                  page: FuelFlowInfoScreen(
                    isViaSettingsScreen: widget.isViaSettingsScreen,
                  ),
                ),
              );
            }),
      ),
    );
  }

  // ── Time Capsule Row Widget (Capsule shape matching mockup) ─────────────
  Widget _buildTimeCapsule({
    required BuildContext context,
    required String label,
    required String icon,
    required Color iconColor,
    required int? hour,
    required int? minute,
    required String period,
    required bool isBedtime,
  }) {
    final displayHour =
        (hour ?? (isBedtime ? 10 : 6)).toString().padLeft(2, '0');
    final displayMinute =
        (minute ?? (isBedtime ? 30 : 30)).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => _pickTime(
        context: context,
        isBedtime: isBedtime,
        currentHour: hour,
        currentMinute: minute,
      ),
      child: Container(
        padding: EdgeInsets.only(left: 16.w, right: 0.w, top: 0.h, bottom: 0.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              color: iconColor,
              width: 20.w,
              height: 20.h,
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: 16.sp,
                color: const Color(0xFF4A5A67),
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            const Spacer(),
            Text(
              "$displayHour:$displayMinute",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: 18.sp,
                color: const Color(0xFF2C3E50),
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
            const Spacer(),
            _AmPmToggle(
              currentPeriod: period,
              onChanged: (newPeriod) {
                VibrationHelper.vibrate(duration: 10, amplitude: 80);
                final cubit = context.read<UserInfoCubit>();
                if (isBedtime) {
                  cubit.updateBedTime(period: newPeriod);
                } else {
                  cubit.updateWakeupTime(period: newPeriod);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({
    required BuildContext context,
    required bool isBedtime,
    required int? currentHour,
    required int? currentMinute,
  }) async {
    VibrationHelper.vibrate(duration: 10, amplitude: 80);
    final cubit = context.read<UserInfoCubit>();
    final h = currentHour ?? (isBedtime ? 10 : 6);
    final m = currentMinute ?? 30;

    final result = await showCupertinoPickerBottomSheet(
      context: context,
      title: isBedtime
          ? (AppLocalizations.of(context)?.selectBedTime ?? 'Select Bed Time')
          : (AppLocalizations.of(context)?.selectWakeTime ?? 'Select Wake Time'),
      initialValue: h,
      minValue: 1,
      maxValue: 12,
      suffix: 'hrs',
      hasSecondaryValue: true,
      secondaryInitialValue: m,
      secondaryMinValue: 0,
      secondaryMaxValue: 59,
      secondarySuffix: 'min',
    );

    if (result != null && result.isNotEmpty) {
      final returnedHour = result['primaryValue'] as int?;
      final returnedMinute = result['secondaryValue'] as int?;

      if (isBedtime) {
        cubit.updateBedTime(
          hour: returnedHour ?? h,
          minute: returnedMinute ?? m,
        );
      } else {
        cubit.updateWakeupTime(
          hour: returnedHour ?? h,
          minute: returnedMinute ?? m,
        );
      }
    }
  }
}

// ── Custom AM/PM Toggle Pill ──────────────────────────────────────────────────
class _AmPmToggle extends StatelessWidget {
  final String currentPeriod;
  final ValueChanged<String> onChanged;

  const _AmPmToggle({
    required this.currentPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isAm = currentPeriod == "AM";
    final double circleSize = 42.w;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFDCDCDC), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onChanged("AM"),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAm ? const Color(0xFFD5DBDE) : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  "AM",
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: 13.sp,
                    color: isAm
                        ? const Color(0xFF3B5266)
                        : const Color(0xFFCCCCCC),
                    fontVariations: [
                      isAm
                          ? AppFontStyles.boldFontVariation
                          : AppFontStyles.regularFontVariation
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () => onChanged("PM"),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !isAm ? const Color(0xFFD5DBDE) : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  "PM",
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: 13.sp,
                    color: !isAm
                        ? const Color(0xFF3B5266)
                        : const Color(0xFFCCCCCC),
                    fontVariations: [
                      !isAm
                          ? AppFontStyles.boldFontVariation
                          : AppFontStyles.regularFontVariation
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
