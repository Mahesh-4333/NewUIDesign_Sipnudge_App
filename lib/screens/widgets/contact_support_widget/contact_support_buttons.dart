import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Import this

class SupportButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final String iconpatharrow;
  final String? url;
  final Color? iconColor;

  const SupportButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.iconpatharrow,
    this.url,
    this.iconColor,
  });

  Future<void> _launchURL(BuildContext context) async {
    if (url == null) return;

    final Uri uri = Uri.parse(url!);

    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open URL: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.dim60.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
        border: Border.all(color: AppColors.greywith80),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.25),
            offset: Offset(AppDimensions.radius_4.r, AppDimensions.radius_4.r),
            blurRadius: AppDimensions.radius_4.r,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _launchURL(context), // ✅ Launches URL
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.dim10,
            vertical: AppDimensions.dim14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000.r),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 12.w),
            Image.asset(iconPath, width: 24.w, height: 24.w, color: iconColor),
            SizedBox(width: 18.w),
            Text(
              label,
              style: TextStyle(
                color: AppColors.raisinblack,
                fontSize: AppFontStyles.fontSize_18,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [
                  FontVariation('wght', AppFontStyles.boldFontVariation.value),
                ],
              ),
            ),
            const Spacer(),
            Image.asset(
              iconpatharrow,
              color: AppColors.raisinblack,
              width: AppDimensions.dim9.w,
              height: AppDimensions.dim16.h,
            ),
            SizedBox(width: AppDimensions.dim12.w),
          ],
        ),
      ),
    );
  }
}
