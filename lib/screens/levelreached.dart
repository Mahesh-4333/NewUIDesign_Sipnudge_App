import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

void showLevelUpDialog(BuildContext context, int level, String totalLitres) {
  // Create a ScreenshotController to capture the dialog widget
  final ScreenshotController screenshotController = ScreenshotController();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 80.h),
        child: Screenshot(
          controller: screenshotController,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              image: const DecorationImage(
                image: AssetImage('assets/popupscreenimage.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Badge with Gradient Level Number
                  Padding(
                    padding: EdgeInsets.only(left: 30.w),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(-15.w,
                                0), // move 15px LEFT (adjust value as needed)
                            child: Image.asset(
                              'assets/images/goals_new_img.png',
                              width: 330.w,
                              height: 320.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 30.w),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF16446F),
                                  Color(0xFF2569A9),
                                  Color(0xFF59ADFB),
                                ],
                              ).createShader(
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                              blendMode: BlendMode.srcIn,
                              child: Transform.translate(
                                offset: Offset(0, -5.h),
                                child: Text(
                                  '$level',
                                  style: TextStyle(
                                    fontSize: 74.sp,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'poppins-Bold',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 25.w, top: 240.h),
                            child: Text(
                              "You've Reached Level $level!",
                              style: TextStyle(
                                fontSize: AppFontStyles.fontSize_24,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: AppColors.bluegray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Message
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      '"Way to go! Your $totalLitres water goal is complete. Keep the good habits flowing!"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontStyles.fontSize_16,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.bluegray,
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      'Share your achievements with friends',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontStyles.fontSize_16,
                        fontVariations: [AppFontStyles.semiBoldFontVariation],
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.bluegray,
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  /// Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Capture the dialog as image bytes
                          Uint8List? imageBytes =
                              await screenshotController.capture(
                            pixelRatio:
                                2.0, // you can adjust to improve resolution
                          );

                          if (imageBytes == null) {
                            print("Error: imageBytes is null");
                            return;
                          }

                          // Get a temporary directory
                          final tempDir = await getTemporaryDirectory();
                          String filePath = '${tempDir.path}/level_up.png';

                          // Write the bytes to a file
                          File file = await File(filePath).create();
                          await file.writeAsBytes(imageBytes);

                          // Use share_plus to share this image file
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: "I've reached Level $level on Sipnudge! 💧",
                            subject: "My Hydration Achievement",
                          );

                          // Optionally close the dialog
                          Navigator.pop(context);
                        } catch (e) {
                          print("Error capturing or sharing: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF369FFF),
                        minimumSize:
                            Size(double.maxFinite, AppDimensions.dim50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: Text(
                        'Share',
                        style: TextStyle(
                          fontSize: AppFontStyles.fontSize_16,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
