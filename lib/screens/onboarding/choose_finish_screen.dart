import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class ChooseFinishScreen extends StatefulWidget {
  final VoidCallback onConfirm;

  const ChooseFinishScreen({
    super.key,
    required this.onConfirm,
  });

  @override
  State<ChooseFinishScreen> createState() => _ChooseFinishScreenState();
}

class _ChooseFinishScreenState extends State<ChooseFinishScreen> {
  int _selectedIndex = 1; // Default: Candy Red (Index 1)

  final List<Map<String, dynamic>> _bottleOptions = [
    {
      'name': 'Obsidian Black',
      'color': const Color(0xFF2B2E33),
      'asset': AssetsPath.onboardingBlack,
    },
    {
      'name': 'Candy Red',
      'color': const Color(0xFF9E1F27),
      'asset': AssetsPath.onboardingRed,
    },
    {
      'name': 'Deep Purple',
      'color': const Color(0xFF56396F),
      'asset': AssetsPath.onboardingPurple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Title Header
              Text(
                "Choose Your Finish",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3B5B66),
                  fontSize: 26.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Select the color that matches your\ndaily rhythm.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7A8E9E),
                  fontSize: 14.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
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
                  children: List.generate(_bottleOptions.length, (index) {
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
                        height: isSelected ? 300.h : 260.h,
                        width: 95.w,
                        child: Image.asset(
                          _bottleOptions[index]['asset'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 24.h),

              // Color Selection Dots & Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_bottleOptions.length, (index) {
                  final isSelected = index == _selectedIndex;
                  final color = _bottleOptions[index]['color'] as Color;

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

              SizedBox(height: 10.h),

              // Selected Color Label Text
              Text(
                _bottleOptions[_selectedIndex]['name'],
                style: TextStyle(
                  color: const Color(0xFF2C434C),
                  fontSize: 15.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
              ),

              const Spacer(),

              // Confirm Selection Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: widget.onConfirm,
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
                        "Confirm Selection",
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
