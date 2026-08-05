import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/cubit/locale/locale_cubit.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            image: const DecorationImage(
              image: AssetImage("assets/images/app_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: BlocBuilder<LocaleCubit, Locale>(
              builder: (context, currentLocale) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.selectLanguage ??
                              AppStrings.selectLanguage,
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: 20.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontWeight: FontWeight.bold,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.bluegray),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildLanguageOption(
                      context,
                      title: AppLocalizations.of(context)?.english ?? AppStrings.english,
                      subtitle: "English",
                      languageCode: 'en',
                      isSelected: currentLocale.languageCode == 'en',
                    ),
                    SizedBox(height: 10.h),
                    Divider(height: 1, color: AppColors.stonegray.withOpacity(0.15)),
                    SizedBox(height: 10.h),
                    _buildLanguageOption(
                      context,
                      title: AppLocalizations.of(context)?.hindi ?? AppStrings.hindi,
                      subtitle: "हिंदी",
                      languageCode: 'hi',
                      isSelected: currentLocale.languageCode == 'hi',
                    ),
                    SizedBox(height: 10.h),
                    Divider(height: 1, color: AppColors.stonegray.withOpacity(0.15)),
                    SizedBox(height: 10.h),
                    _buildLanguageOption(
                      context,
                      title: AppLocalizations.of(context)?.spanish ?? "Spanish (Español)",
                      subtitle: "Español",
                      languageCode: 'es',
                      isSelected: currentLocale.languageCode == 'es',
                    ),
                    SizedBox(height: 10.h),
                    Divider(height: 1, color: AppColors.stonegray.withOpacity(0.15)),
                    SizedBox(height: 10.h),
                    _buildLanguageOption(
                      context,
                      title: AppLocalizations.of(context)?.german ?? "German (Deutsch)",
                      subtitle: "Deutsch",
                      languageCode: 'de',
                      isSelected: currentLocale.languageCode == 'de',
                    ),
                    SizedBox(height: 16.h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String languageCode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        context.read<LocaleCubit>().changeLanguage(languageCode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007BFF).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007BFF)
                : AppColors.stonegray.withOpacity(0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.bluegray,
                      fontSize: 16.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontVariations: [
                        isSelected
                            ? AppFontStyles.boldFontVariation
                            : AppFontStyles.semiBoldFontVariation
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF007BFF),
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: AppColors.bluegray.withOpacity(0.4),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
