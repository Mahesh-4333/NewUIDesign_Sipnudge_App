import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});
  final textColor = AppColors.white;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leadingWidth: AppDimensions.dim85.w,
        title: Text(
          AppStrings.termsOfService,
          style: TextStyle(
            color: AppColors.white,
            fontSize: AppFontStyles.fontSize_AppBar,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              AppFontStyles.boldFontVariation,
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset("assets/images/back_ic.svg"),
        ),
      ),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        padding: EdgeInsets.only(
            top: AppDimensions.dim120.h,
            bottom: AppDimensions.dim34.h,
            left: AppDimensions.dim34.w,
            right: AppDimensions.dim34.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Effective Date: 1 January 2025",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_22,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Welcome to Sipnudge! These Terms of Service (\"Terms\") govern your access to and use of the Sipnudge smart hydration bottle, the Sipnudge mobile application (the \"App\"), and all related services provided by SIPNUDGE TECHNOLOGIES PRIVATE LIMITED (\"we,\" \"us,\" or \"our\"). By accessing or using Sipnudge and the App, you agree to be bound by these Terms.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_18,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("1. Acceptance of Terms:"),
              Text(
                "By using Sipnudge and the App, you represent and warrant that you have the legal capacity to enter into these Terms and that you agree to be bound by them. If you do not agree to these Terms, do not use Sipnudge or the App.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("2. Description of Service:"),
              Text(
                "Sipnudge is a smart hydration system that includes a smart bottle, a mobile application, and related services such as personalized hydration recommendations, reminders, and data tracking.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("3. User Accounts:"),
              Text(
                "To access certain features, you may need to create an account. You are responsible for maintaining your credentials and must notify us of unauthorized access.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("4. Use of the App and Sipnudge:"),
              _bullet(
                  "Use only for lawful purposes in accordance with these Terms."),
              _bullet(
                  "Do not damage, disable, overburden, or impair our servers or networks."),
              _bullet(
                  "No unauthorized access to parts of the App or connected systems."),
              _bullet("No interference with the App’s operation."),
              _bullet("No impersonation or misrepresentation."),
              _bullet("No viruses, malware, or harmful code."),
              SizedBox(height: 16),
              _sectionTitle("5. Intellectual Property:"),
              Text(
                "All content in Sipnudge and the App is owned by SIPNUDGE TECHNOLOGIES PRIVATE LIMITED or licensors and is protected by intellectual property laws.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("6. Disclaimer of Warranties:"),
              Text(
                "The App is provided \"as is\" without warranties. We don’t guarantee it will be uninterrupted or error-free and disclaim all implied warranties.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("7. Limitation of Liability:"),
              Text(
                "We are not liable for indirect or consequential damages. Total liability will not exceed what you paid in the 12 months before a claim.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("8. Indemnification:"),
              Text(
                "You agree to indemnify us against claims from your use of the App or violation of these Terms or others' rights.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("9. Governing Law:"),
              Text(
                "These Terms are governed by Indian law.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("10. Changes to Terms:"),
              Text(
                "We may update the Terms. Continued use of the App after changes means acceptance of the updated Terms.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("11. Termination:"),
              Text(
                "We may terminate these Terms or your access at any time, with or without cause.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("12. Entire Agreement:"),
              Text(
                "These Terms are the entire agreement between us regarding Sipnudge.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("13. Contact Us:"),
              Text(
                "SIPNUDGE TECHNOLOGIES PRIVATE LIMITED\nPlot No:-172  Sambhaji nagar, Priyadarshani colony, jalna-431203\nEmail: newton.ns34@gmail.com",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("14. Severability:"),
              Text(
                "If any part of these Terms is found invalid, the rest will still apply.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 16),
              _sectionTitle("15. Waiver:"),
              Text(
                "Failure to enforce any provision is not a waiver of that provision.",
                style: TextStyle(
                  color: textColor,
                  fontSize: AppFontStyles.fontSize_16,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: AppFontStyles.fontSize_22,
        fontFamily: AppFontStyles.urbanistFontFamily,
        fontVariations: [
          AppFontStyles.boldFontVariation,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("●  ",
              style: TextStyle(
                color: textColor,
                fontSize: AppFontStyles.fontSize_16,
              )),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: textColor,
                fontSize: AppFontStyles.fontSize_16,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [
                  AppFontStyles.regularFontVariation,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
