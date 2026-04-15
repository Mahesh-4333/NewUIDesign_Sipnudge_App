import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class TimezoneChangeDialog extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const TimezoneChangeDialog({
    super.key,
    required this.onRefresh,
  });

  @override
  State<TimezoneChangeDialog> createState() => _TimezoneChangeDialogState();
}

class _TimezoneChangeDialogState extends State<TimezoneChangeDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    await widget.onRefresh();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        Center(
          child: Container(
            width: AppDimensions.dim310.w,
            height: 300.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(AppDimensions.radius_10.r),
              border: Border.all(
                color: AppColors.startJourneyPopupBorderColor,
                width: AppDimensions.dim1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.25),
                  blurRadius: AppDimensions.dim4.r,
                  offset: Offset(AppDimensions.dim4.w, AppDimensions.dim4.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
              child: Column(
                children: [
                  SizedBox(height: AppDimensions.dim17.h),
                  Icon(
                    Icons.public_outlined,
                    size: AppDimensions.dim80.w,
                    color: AppColors.blueWaterIntake,
                  ),
                  SizedBox(height: AppDimensions.dim15.h),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.dim10.w),
                    child: Text(
                      'Timezone Changed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.greyColorText1,
                        fontFamily: AppFontStyles.museoModernoFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        fontSize: AppDimensions.dim18.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.dim8.h),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.dim15.w),
                    child: Text(
                      'We detected a timezone change. Would you like to refresh your hydration schedule and notifications?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.greyColor,
                        fontFamily: AppFontStyles.museoModernoFontFamily,
                        fontVariations: [AppFontStyles.regularFontVariation],
                        fontSize: AppDimensions.dim12.sp,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: AppDimensions.dim15.h,
                      left: AppDimensions.dim15.w,
                      right: AppDimensions.dim15.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _handleRefresh,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.dim10.h,
                              ),
                              decoration: BoxDecoration(
                                color: _isLoading
                                    ? AppColors.greyColor
                                    : AppColors.darkgray,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radius_8.r),
                              ),
                              child: _isLoading
                                  ? _buildLoadingIndicator()
                                  : Text(
                                      'Refresh',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: AppFontStyles
                                            .museoModernoFontFamily,
                                        fontVariations: [
                                          AppFontStyles.boldFontVariation
                                        ],
                                        fontSize: AppDimensions.dim14.sp,
                                      ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            SizedBox(width: AppDimensions.dim4.w),
            _buildDot(1),
            SizedBox(width: AppDimensions.dim4.w),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final double baseDelay = 0.2;
    final double opacity = (0.5 +
            0.5 *
                (((_animationController.value - (index * baseDelay)) % 1.0)
                                .abs() *
                            2 -
                        1)
                    .abs())
        .clamp(0.3, 1.0);

    return Container(
      width: AppDimensions.dim8.w,
      height: AppDimensions.dim8.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
