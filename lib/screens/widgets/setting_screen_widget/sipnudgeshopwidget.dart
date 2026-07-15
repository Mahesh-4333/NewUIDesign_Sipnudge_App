import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class SipnudgeShopWidget extends StatelessWidget {
  const SipnudgeShopWidget({super.key});

  Future<void> _openWebsite() async {
    final Uri url = Uri.parse('https://sipnudge.com/#product');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openWebsite,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.dim24.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              spreadRadius: 2.r,
              offset: Offset(0, 4.r),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
          child: Image.asset(
            'assets/images/sipnudge_shop.png', // Your exact image from the screenshot
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback UI if image is not found
              return Container(
                height: 220.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8B7355),
                      Color(0xFFA89080),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                // child: Center(
                //   child: Text(
                //     'Add sipnudge_shop_banner.png to assets',
                //     style: TextStyle(
                //       color: AppColors.white,
                //       fontSize: 14.sp,
                //     ),
                //   ),
                // ),
              );
            },
          ),
        ),
      ),
    );
  }
}
