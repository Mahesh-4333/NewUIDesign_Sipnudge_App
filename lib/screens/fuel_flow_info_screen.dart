import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/screens/user_info_analyzing_screen.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_radio_selection_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/next_button_widget.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class FuelFlowInfoScreen extends StatefulWidget {
  const FuelFlowInfoScreen({super.key, required this.isViaSettingsScreen});

  final bool isViaSettingsScreen;

  @override
  State<FuelFlowInfoScreen> createState() => _FuelFlowInfoScreenState();
}

class _FuelFlowInfoScreenState extends State<FuelFlowInfoScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfAtBottom();
    });
  }

  void _scrollListener() {
    _checkIfAtBottom();
  }

  void _checkIfAtBottom() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (!_isAtBottom) setState(() => _isAtBottom = true);
      return;
    }
    final isAtBottom = _scrollController.offset >= (maxScroll - 50);
    if (isAtBottom != _isAtBottom) setState(() => _isAtBottom = isAtBottom);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
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
          "Profile Setup",
          style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_AppBar,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation]),
        ),
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset("assets/images/back_ic.svg"),
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
            bottom: AppDimensions.bottomBarHeight),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.defaultPadding.w,
            vertical: AppDimensions.defaultPadding.h,
          ),
          children: [
            // ── Page Header ───────────────────────────────────────────────
            Text(
              "Fuel & Flow 🍴",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_22,
                color: AppColors.black,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
            SizedBox(height: AppDimensions.dim8.h),
            Text(
              "Tell us a bit about your diet to calculate your baseline hydration needs.",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_13,
                color: AppColors.greyColorText1,
                fontVariations: [AppFontStyles.regularFontVariation],
              ),
            ),
            SizedBox(height: AppDimensions.dim24.h),

            // ── Primary Diet Focus ────────────────────────────────────────
            Text(
              "PRIMARY DIET FOCUS",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_13,
                color: AppColors.bluegray,
                fontVariations: [AppFontStyles.fontWeightVariation600],
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: AppDimensions.dim12.h),
            CustomRadioSelectionWidget(type: 3),

            SizedBox(height: AppDimensions.dim24.h),

            // ── Average Daily Water ───────────────────────────────────────
            Text(
              "AVERAGE DAILY WATER",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_13,
                color: AppColors.bluegray,
                fontVariations: [AppFontStyles.fontWeightVariation600],
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: AppDimensions.dim12.h),
            const _WaterCounterCard(),

            SizedBox(height: AppDimensions.dim24.h),

            SizedBox(height: AppDimensions.dim24.h),

            // ── Daily Caffeine Card ─────────────────────────────────────────
            const _CaffeineCounterCard(),

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
            text: _isAtBottom ? AppStrings.next : "Scroll Down",
            onNextPressed: () async {
              if (!_isAtBottom) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                return;
              }

              UiUtilsService.showLoading(context, "Please wait");

              try {
                final cubit = context.read<UserInfoCubit>();
                final state = cubit.state;

                double calculatedGoal =
                    WaterConsumptionCalculator.calculateWaterIntakeGoal(state);
                double waterIntakeGoalInt = calculatedGoal;

                UiUtilsService.dismissLoading(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoAnalyzingScreen(
                      goal: waterIntakeGoalInt.toDouble(),
                      isViaSettingsScreen: widget.isViaSettingsScreen,
                    ),
                  ),
                );
              } catch (e) {
                UiUtilsService.dismissLoading(context);
                UiUtilsService.showToast(
                  context: context,
                  text: 'Error calculating water intake: ${e.toString()}',
                );
              }
            }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Water Counter Card — matches screenshot: header icon top right + large grey circular buttons + hollow slider thumb
// ─────────────────────────────────────────────────────────────────────────────
class _WaterCounterCard extends StatelessWidget {
  const _WaterCounterCard();

  static const double _min = 0.0;
  static const double _max = 4.0;
  static const double _step = 0.5;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserInfoCubit, UserInfoState>(
      builder: (context, state) {
        final double intake = state.typicalWaterIntake ?? 2.0;

        return Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Subtitle on Left, Glass Icon on Right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AVERAGE DAILY WATER",
                          style: TextStyle(
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontSize: 13.sp,
                            color: AppColors.bluegray,
                            fontVariations: [
                              AppFontStyles.fontWeightVariation600
                            ],
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Rough estimate is fine",
                          style: TextStyle(
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontSize: 13.sp,
                            color: AppColors.greyColorText1,
                            fontVariations: [
                              AppFontStyles.regularFontVariation
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Glass Icon in Light Blue Circle with Blue Border
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00A3FF),
                        width: 1.5.w,
                      ),
                    ),
                    child: Icon(
                      Icons.local_drink_outlined,
                      color: const Color(0xFF00A3FF),
                      size: 22.sp,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Counter: Large Light Grey Circles − | 2.0 L | +
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large Minus Circle Button
                  GestureDetector(
                    onTap: intake > _min
                        ? () {
                            VibrationHelper.vibrate(
                                duration: 10, amplitude: 80);
                            context.read<UserInfoCubit>().setTypicalWaterIntake(
                                (intake - _step).clamp(_min, _max));
                          }
                        : null,
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEEF2F6),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: intake > _min
                            ? const Color(0xFF3A506B)
                            : const Color(0xFFBDC3C7),
                        size: 24.sp,
                      ),
                    ),
                  ),

                  SizedBox(width: 24.w),

                  // Value display ("2.0 L")
                  Text(
                    "${intake.toStringAsFixed(1)} L",
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 26.sp,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),

                  SizedBox(width: 24.w),

                  // Large Plus Circle Button
                  GestureDetector(
                    onTap: intake < _max
                        ? () {
                            VibrationHelper.vibrate(
                                duration: 10, amplitude: 80);
                            context.read<UserInfoCubit>().setTypicalWaterIntake(
                                (intake + _step).clamp(_min, _max));
                          }
                        : null,
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEEF2F6),
                      ),
                      child: Icon(
                        Icons.add,
                        color: intake < _max
                            ? const Color(0xFF3A506B)
                            : const Color(0xFFBDC3C7),
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18.h),

              // Slider with Hollow White Thumb & Dark Blue-Gray Track
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.bluegray,
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  thumbColor: Colors.white,
                  overlayColor: AppColors.bluegray.withValues(alpha: 0.1),
                  thumbShape: _HollowSliderThumbShape(
                    thumbRadius: 13.r,
                    borderWidth: 3.w,
                    borderColor: AppColors.bluegray,
                  ),
                  trackHeight: 6.h,
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  value: intake.clamp(_min, _max),
                  min: _min,
                  max: _max,
                  divisions: ((_max - _min) / _step).toInt(),
                  onChanged: (val) {
                    final snapped = (val / _step).round() * _step;
                    context
                        .read<UserInfoCubit>()
                        .setTypicalWaterIntake(snapped.clamp(_min, _max));
                  },
                ),
              ),

              SizedBox(height: 4.h),

              // Slider labels below ("0L", "4L+")
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "0L",
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: 13.sp,
                        color: AppColors.bluegray,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    Text(
                      "4L+",
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: 13.sp,
                        color: AppColors.bluegray,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Slider Thumb Shape: White Circle with Ring Border
class _HollowSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double borderWidth;
  final Color borderColor;

  const _HollowSliderThumbShape({
    required this.thumbRadius,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // White fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, fillPaint);

    // Blue-gray ring border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, thumbRadius - (borderWidth / 2), borderPaint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Caffeine Counter Card — Coffee & Tea with +/- counter buttons (matches screenshot)
// ─────────────────────────────────────────────────────────────────────────────
class _CaffeineCounterCard extends StatelessWidget {
  const _CaffeineCounterCard();

  static const List<BeverageIntake> _intakeOrder = [
    BeverageIntake.none,
    BeverageIntake.oneToTwo,
    BeverageIntake.threeToFour,
    BeverageIntake.fivePlus,
  ];

  static const List<String> _intakeLabels = ["0", "1", "2", "3+"];

  int _indexFor(BeverageIntake intake) => _intakeOrder.indexOf(intake);

  BeverageIntake _intakeAt(int index) =>
      _intakeOrder[index.clamp(0, _intakeOrder.length - 1)];

  String _labelFor(BeverageIntake intake) =>
      _intakeLabels[_intakeOrder.indexOf(intake)];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserInfoCubit, UserInfoState>(
      builder: (context, state) {
        final coffee = state.coffeeIntake ?? BeverageIntake.none;
        final tea = state.teaIntake ?? BeverageIntake.none;
        final coffeeIdx = _indexFor(coffee);
        final teaIdx = _indexFor(tea);

        return Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Icon + Title
              Row(
                children: [
                  Icon(
                    Icons.local_cafe_outlined,
                    color: AppColors.bluegray,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "DAILY CAFFEINE",
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: 13.sp,
                      color: AppColors.bluegray,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14.h),

              // Coffee Capsule Row
              _buildCaffeineCapsule(
                context: context,
                icon: Icons.local_cafe_rounded,
                label: "Coffee",
                volume: "200 ml",
                backgroundColor: const Color(0xFFF7F0E8),
                borderColor: const Color(0xFFEDE4DA),
                volumeColor: const Color(0xFFC0A288),
                buttonBorderColor: const Color(0xFFC5C0B8),
                displayLabel: _labelFor(coffee),
                onDecrement: coffeeIdx > 0
                    ? () {
                        VibrationHelper.vibrate(duration: 10, amplitude: 80);
                        context
                            .read<UserInfoCubit>()
                            .setCoffeeIntake(_intakeAt(coffeeIdx - 1));
                      }
                    : null,
                onIncrement: coffeeIdx < _intakeOrder.length - 1
                    ? () {
                        VibrationHelper.vibrate(duration: 10, amplitude: 80);
                        context
                            .read<UserInfoCubit>()
                            .setCoffeeIntake(_intakeAt(coffeeIdx + 1));
                      }
                    : null,
              ),

              SizedBox(height: 12.h),

              // Tea Capsule Row
              _buildCaffeineCapsule(
                context: context,
                icon: Icons.emoji_food_beverage_rounded,
                label: "Tea",
                volume: "200 ml",
                backgroundColor: const Color(0xFFF4F9EB),
                borderColor: const Color(0xFFE5EFD3),
                volumeColor: const Color(0xFF99A96E),
                buttonBorderColor: const Color(0xFFBCCAA0),
                displayLabel: _labelFor(tea),
                onDecrement: teaIdx > 0
                    ? () {
                        VibrationHelper.vibrate(duration: 10, amplitude: 80);
                        context
                            .read<UserInfoCubit>()
                            .setTeaIntake(_intakeAt(teaIdx - 1));
                      }
                    : null,
                onIncrement: teaIdx < _intakeOrder.length - 1
                    ? () {
                        VibrationHelper.vibrate(duration: 10, amplitude: 80);
                        context
                            .read<UserInfoCubit>()
                            .setTeaIntake(_intakeAt(teaIdx + 1));
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaffeineCapsule({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String volume,
    required Color backgroundColor,
    required Color borderColor,
    required Color volumeColor,
    required Color buttonBorderColor,
    required String displayLabel,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
  }) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          // Icon Circle Container
          Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECEF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2C3E50),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Name Text ("Coffee" / "Tea")
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontSize: 16.sp,
              color: const Color(0xFF2C3E50),
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(width: 16.w),
          // Volume Text ("200 ml")
          Text(
            volume,
            style: TextStyle(
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontSize: 14.sp,
              color: volumeColor,
              fontVariations: [AppFontStyles.semiBoldFontVariation],
            ),
          ),
          const Spacer(),
          // Counter: - count +
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                borderColor: buttonBorderColor,
                enabled: onDecrement != null,
                onTap: onDecrement,
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 24.w,
                child: Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: 16.sp,
                    color: const Color(0xFF2C3E50),
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              _buildCircleButton(
                icon: Icons.add,
                borderColor: buttonBorderColor,
                enabled: onIncrement != null,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color borderColor,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? borderColor : borderColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF2C3E50) : const Color(0xFFBDC3C7),
          size: 18.sp,
        ),
      ),
    );
  }
}
