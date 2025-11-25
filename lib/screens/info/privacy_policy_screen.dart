import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
            AppStrings.privacyPolicy,
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
          padding: EdgeInsets.only(
              top: AppDimensions.dim120.h,
              bottom: AppDimensions.dim34.h,
              left: AppDimensions.dim34.w,
              right: AppDimensions.dim34.w),
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
                  "This Privacy Policy describes how SIPNUDGE TECHNOLOGIES PRIVATE LIMITED (\"we,\" \"us,\" or \"our\") collects, uses, and shares your information when you use the SipNudge smart hydration bottle and related services, including the SipNudge mobile application (the \"App\"). We are committed to protecting your privacy and handling your information responsibly.",
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
                _sectionTitle("Information We Collect:"),
                _bullet("Personal Information: Name, email, age (optional)."),
                _bullet(
                    "Usage Data: Water intake, sip timing, feature interaction."),
                _bullet("Device Info: Model, OS, IP address, unique IDs."),
                _bullet(
                    "Health Info: Only hydration-related. Integration with other health apps is optional."),
                _bullet(
                    "Aggregated Data: Used anonymously for analysis and improvement."),
                SizedBox(height: 16),
                _sectionTitle("How We Use Your Information:"),
                _bullet("Providing & improving the service."),
                _bullet("Personalization of hydration experience."),
                _bullet("Communication (no marketing emails without consent)."),
                _bullet("Analytics and service improvement."),
                _bullet("Legal compliance."),
                SizedBox(height: 16),
                _sectionTitle("How We Share Your Information:"),
                _bullet("With service providers under contract."),
                _bullet("For legal obligations."),
                _bullet("During business transfers with notice."),
                _bullet("With your explicit consent."),
                SizedBox(height: 16),
                _sectionTitle("Data Security:"),
                Text(
                  "We take reasonable measures to protect your information, but no method is 100% secure.",
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
                _sectionTitle("Your Choices:"),
                _bullet("You can update your account info via the App."),
                _bullet("Notification settings are adjustable."),
                _bullet(
                    "You can request account deletion at newton.ns34@gmail.com."),
                SizedBox(height: 16),
                _sectionTitle("Children's Privacy:"),
                Text(
                  "SipNudge is not intended for children under 13. We do not knowingly collect data from children under 13.",
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
                _sectionTitle("Changes to this Policy:"),
                Text(
                  "We may update this policy and notify you via the app or website. Continued use means acceptance of the changes.",
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
                _sectionTitle("Contact Us:"),
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
                SizedBox(height: 24),
              ],
            ),
          ),
        ));
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
