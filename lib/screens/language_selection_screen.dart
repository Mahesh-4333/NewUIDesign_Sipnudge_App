import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/locale/locale_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/local_auth_screen.dart';

class LanguageModel {
  final String name;
  final String nativeName;
  final String code;
  final String flag;

  const LanguageModel({
    required this.name,
    required this.nativeName,
    required this.code,
    required this.flag,
  });
}

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFirstTime;

  const LanguageSelectionScreen({
    super.key,
    this.isFirstTime = true,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const List<LanguageModel> _allLanguages = [
    LanguageModel(
        name: 'English',
        nativeName: 'English',
        code: 'en',
        flag: AssetsPath.onboardingEnglish),
    LanguageModel(
        name: 'German',
        nativeName: 'Deutsch',
        code: 'de',
        flag: AssetsPath.onboardingGerman),
    LanguageModel(
        name: 'Hindi',
        nativeName: 'हिंदी',
        code: 'hi',
        flag: AssetsPath.onboardingHindi),
    LanguageModel(
        name: 'Spanish',
        nativeName: 'Español',
        code: 'es',
        flag: AssetsPath.onboardingSpanish),
  ];

  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    final currentLocale = context.read<LocaleCubit>().state.languageCode;
    _selectedCode = currentLocale.isNotEmpty ? currentLocale : 'hi';
  }

  LanguageModel get _selectedLanguage {
    return _allLanguages.firstWhere(
      (lang) => lang.code == _selectedCode,
      orElse: () => _allLanguages.firstWhere((lang) => lang.code == 'hi',
          orElse: () => _allLanguages.first),
    );
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedCode = code;
    });
    context.read<LocaleCubit>().changeLanguage(code);
  }

  Future<void> _onContinue() async {
    if (widget.isFirstTime) {
      await SharedPrefsHelper.setFirstTimeLaunch(false);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LocalAuthScreen(),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLang = _selectedLanguage;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Back Arrow
                      InkWell(
                        onTap: () {
                          if (widget.isFirstTime) {
                            _onContinue();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.bluegray,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Title Block
                      Text(
                        "Choose the language",
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: 24.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        "Select your preferred language below",
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: 14.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // You Selected Section
                      Text(
                        "You Selected",
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: 16.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Selected Language Pill Card
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F8FA),
                          borderRadius: BorderRadius.circular(100.r),
                          border: Border.all(
                            color: const Color(0xFF00BBCA),
                            width: 1.5.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                selectedLang.flag,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Text(
                              selectedLang.name,
                              style: TextStyle(
                                color: AppColors.bluegray,
                                fontSize: 16.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.semiBoldFontVariation
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00BBCA),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // All Languages Section
                      Text(
                        "All Languages",
                        style: TextStyle(
                          color: AppColors.bluegray,
                          fontSize: 16.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Card containing Search Bar + List of Languages
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
                        ),
                        child: Column(
                          children: [
                            // List of languages
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allLanguages.length,
                              separatorBuilder: (ctx, i) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (ctx, index) {
                                final lang = _allLanguages[index];
                                final isSelected = lang.code == _selectedCode;

                                return InkWell(
                                  onTap: () => _selectLanguage(lang.code),
                                  child: Container(
                                    color: isSelected
                                        ? const Color(0xFFE5F8FA)
                                        : Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36.w,
                                          height: 36.w,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFF8FAFC),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.asset(
                                            lang.flag,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(width: 14.w),
                                        Text(
                                          lang.name,
                                          style: TextStyle(
                                            color: AppColors.bluegray,
                                            fontSize: 15.sp,
                                            fontFamily: AppFontStyles
                                                .urbanistFontFamily,
                                            fontVariations: [
                                              isSelected
                                                  ? AppFontStyles
                                                      .semiBoldFontVariation
                                                  : AppFontStyles
                                                      .regularFontVariation
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isSelected)
                                          Container(
                                            width: 22.w,
                                            height: 22.w,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF00BBCA),
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 22.w,
                                            height: 22.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFCBD5E1),
                                                width: 1.5.w,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),

              // Bottom Continue Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2589FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
