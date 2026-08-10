import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/l10n/app_localizations.dart';

class ChooseFinishScreen extends StatefulWidget {
  final ValueChanged<int> onConfirm;
  final VoidCallback? onBack;

  const ChooseFinishScreen({
    super.key,
    required this.onConfirm,
    this.onBack,
  });

  @override
  State<ChooseFinishScreen> createState() => _ChooseFinishScreenState();
}

class _ChooseFinishScreenState extends State<ChooseFinishScreen> {
  int _selectedIndex = 0; // Default: Candy Red (Index 0)

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> bottleOptions = [
      {
        'key': 'red',
        'name': AppLocalizations.of(context)?.candyRed ?? 'Candy Red',
        'color': const Color(0xFF9E1F27),
        'asset': AssetsPath.onboardingRed,
        'description': AppLocalizations.of(context)?.descCandyRed ?? '“Bold, Energetic, and Impossible to ignore”',
      },
      {
        'key': 'black',
        'name': AppLocalizations.of(context)?.midnightBlack ?? 'Midnight Black',
        'color': const Color(0xFF2B2E33),
        'asset': AssetsPath.onboardingBlack,
        'description': AppLocalizations.of(context)?.descMidnightBlack ?? '“Minimal, Timeless. Built for every environment”',
      },
      {
        'key': 'purple',
        'name': AppLocalizations.of(context)?.deepPurple ?? 'Deep Purple',
        'color': const Color(0xFF56396F),
        'asset': AssetsPath.onboardingPurple,
        'description': AppLocalizations.of(context)?.descDeepPurple ?? '“Creative, Premium, and uniquely yours”',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 8.h),

              // Top Bar with Back Arrow
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1E293B),
                      size: 24,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Title Header
              Text(
                AppLocalizations.of(context)?.chooseYourFinish ?? "Choose Your Finish",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: 32.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)?.selectColorDailyRhythm ?? "Select the color that matches your\ndaily rhythm.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7A8E9E),
                  fontSize: 17.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                  height: 1.3,
                ),
              ),

              const Spacer(),

              // 3 Bottles Display
              SizedBox(
                height: 320.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(bottleOptions.length, (index) {
                    final isSelected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: isSelected ? 330.h : 260.h,
                        width: 95.w,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: isSelected ? 1.0 : 0.7,
                          child: isSelected
                              ? Image.asset(
                                  bottleOptions[index]['asset'],
                                  fit: BoxFit.contain,
                                )
                              : ImageFiltered(
                                  imageFilter: ui.ImageFilter.blur(
                                    sigmaX: 1.3,
                                    sigmaY: 1.3,
                                    tileMode: ui.TileMode.decal,
                                  ),
                                  child: Image.asset(
                                    bottleOptions[index]['asset'],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 24.h),
              const Spacer(),
//Color Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  bottleOptions[_selectedIndex]['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF7A8E9E),
                    fontSize: 17.sp,
                    fontStyle: FontStyle.italic,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),

              SizedBox(height: 20.h),
              // Color Selection Dots & Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(bottleOptions.length, (index) {
                  final isSelected = index == _selectedIndex;
                  final color = bottleOptions[index]['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2.w,
                        ),
                      ),
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),

// Selected
              SizedBox(height: 10.h),

              // Selected Color Label Text
              Text(
                bottleOptions[_selectedIndex]['name'],
                style: TextStyle(
                  color: const Color(0xFF2C434C),
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 6.h),

              const Spacer(),

              // Confirm Selection Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final colorKeys = ['red', 'black', 'purple'];
                    await SharedPrefsHelper.setBottleColor(colorKeys[_selectedIndex]);
                    widget.onConfirm(_selectedIndex);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.confirmSelection ?? "Confirm Selection",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
