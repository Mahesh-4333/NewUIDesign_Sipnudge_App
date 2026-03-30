import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class EraseDataDialog extends StatefulWidget {
  final VoidCallback onErase;

  const EraseDataDialog({Key? key, required this.onErase}) : super(key: key);

  @override
  State<EraseDataDialog> createState() => _EraseDataDialogState();
}

class _EraseDataDialogState extends State<EraseDataDialog> {
  bool _isSwiped = false;
  int _secondsRemaining = 10;
  Timer? _timer;
  double _dragPosition = 0;
  final double _buttonWidth = 280.w;
  final double _sliderWidth = 50.w;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    setState(() {
      _isSwiped = true;
      _dragPosition = _buttonWidth - _sliderWidth;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        Navigator.pop(context);
        widget.onErase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.r),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert Icon
            Center(
              child: Image.asset(
                AssetsPath.alertIcon,
                width: 70.w,
                height: 70.w,
              ),
            ),
            SizedBox(height: 20.h),

            // Title
            Text(
              "Erase All Data",
              style: TextStyle(
                  color: const Color(0xffB91C1C),
                  fontSize: 22.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontWeight: FontWeight.w700,
                  fontVariations: [AppFontStyles.boldFontVariation]),
            ),
            SizedBox(height: 12.h),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                "Are you sure that erasing your data is permanent. All your history, preferences, and saved content will be deleted immediately.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.greyColorText1,
                  fontSize: 14.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // Timer Circle
            CircularPercentIndicator(
              radius: 65.r,
              lineWidth: 8.w,
              percent: _secondsRemaining / 10,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$_secondsRemaining",
                    style: TextStyle(
                        height: 1,
                        color: AppColors.bluegray,
                        fontSize: 40.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation]),
                  ),
                  Text(
                    "SECONDS",
                    style: TextStyle(
                      height: 2,
                      color: AppColors.greyColor,
                      fontSize: 10.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              progressColor: const Color(0xffEF4444),
              backgroundColor: const Color(0xffEF4444).withOpacity(0.1),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            SizedBox(height: 35.h),

            // Swipe to Erase Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xffE53935).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffE53935).withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                width: _buttonWidth,
                padding: EdgeInsets.symmetric(horizontal: 0.w),
                height: 56.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: 30.w),
                        child: Text(
                          _isSwiped
                              ? "ERASING IN $_secondsRemaining..."
                              : "SLIDE TO EARSE ALL DATA",
                          style: TextStyle(
                            color: const Color(0xffB91C1C),
                            fontSize: 15.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _dragPosition,
                      top: 2.h,
                      bottom: 2.h,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (_isSwiped) return;
                          setState(() {
                            _dragPosition += details.delta.dx;
                            if (_dragPosition < 0) _dragPosition = 0;
                            // Adjust the max position so it doesn't cut off at the right edge
                            final maxDrag = _buttonWidth - (_sliderWidth - 10.w);
                            if (_dragPosition > maxDrag) {
                              _dragPosition = maxDrag;
                              _startTimer();
                            }
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (!_isSwiped) {
                            setState(() {
                              _dragPosition = 0;
                            });
                          }
                        },
                        child: Container(
                          width: _sliderWidth,
                          margin: EdgeInsets.only(
                              left: 0.w, right: 100.w, top: 2.w, bottom: 2.w),
                          decoration: BoxDecoration(
                            color: const Color(0xffB91C1C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffB91C1C).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(AssetsPath.sliderIcon),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Cancel Button
            GestureDetector(
              onTap: () {
                _timer?.cancel();
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.only(
                    bottom: 1.h), // Adds space between text and underline
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.bluegray,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Text(
                  "Cancel Action",
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: 15.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.semiBoldFontVariation],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}
