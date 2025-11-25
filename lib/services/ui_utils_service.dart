import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/widgets/animate_dots_widget.dart';
import 'package:hydrify/screens/widgets/custom_circular_loader/paint.dart';
import 'package:hydrify/screens/widgets/custom_circular_loader/widget.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class UiUtilsService {
  static bool isLoadingDisplaying = false;

  static showLoading(BuildContext context, String? text) {
    if (!isLoadingDisplaying) {
      isLoadingDisplaying = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: AppDimensions.dim402.w,
                height: AppDimensions.dim102.h,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("assets/images/loading_bg1.png"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(4.r, 4.r),
                      blurRadius: 5.r,
                      color: AppColors.black.withOpacity(0.25),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            text ?? "",
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: AppFontStyles.fontSize_18.sp,
                              fontVariations: [
                                AppFontStyles.fontWeightVariation600,
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          const AnimatedDots(),
                        ],
                      ),
                      CircularGradientSpinner(
                        endColor: const Color(0XFF131313),
                        color: const Color(0XFFFFFFFF),
                        spinnerDirection: SpinnerDirection.clockwise,
                        size: 50.w, // slightly smaller to match image
                        strokeWidth: 10, // thinner stroke for visual balance
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  static dismissLoading(BuildContext context) {
    if (isLoadingDisplaying) {
      isLoadingDisplaying = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static showToast(
      {required BuildContext context,
      required String text,
      Color textColor = Colors.black,
      Color backgroundColor = AppColors.white,
      EdgeInsetsGeometry margin = const EdgeInsets.all(AppDimensions.dim20)}) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.none,
        margin: margin,
        elevation: 12,
        padding: EdgeInsets.zero,
        duration: const Duration(
          seconds: 1,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: backgroundColor,
            width: AppDimensions.dim1,
          ),
          borderRadius: BorderRadius.circular(
            AppDimensions.dim5,
          ),
        ),
        content: Container(
          color: backgroundColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontVariations: [
                AppFontStyles.boldFontVariation,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatefulWidget {
  final String? text;

  const LoadingIndicator({super.key, this.text});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0, end: 360).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.dim100.h,
      width: AppDimensions.dim100.w,
      child: Transform.rotate(
        angle: _animation.value * (3.14159 / 180),
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 100,
              showLabels: false,
              showTicks: false,
              startAngle: 270,
              endAngle: 270,
              radiusFactor: 0.7,
              axisLineStyle: const AxisLineStyle(
                thickness: 10,
                color: Colors.transparent,
              ),
              pointers: <GaugePointer>[
                RangePointer(
                  value: 120,
                  width: 10,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0XFFA77CB0),
                      Color(0XFF1A181A),
                    ],
                    stops: <double>[0.0, 1],
                  ),
                  cornerStyle: CornerStyle.bothCurve,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
