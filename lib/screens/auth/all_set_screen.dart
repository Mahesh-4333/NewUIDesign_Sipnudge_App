import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/screens/auth/signin_signup_screen.dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            "assets/images/back_ic.svg",
          ),
        ),
      ),
      body: Container(
        width: double.maxFinite,
        padding: EdgeInsets.only(
          top: AppDimensions.padding_20.h,
          left: AppDimensions.dim33.w,
          right: AppDimensions.dim33.w,
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/app_background.png"), // your image path
            fit: BoxFit.cover,
          ),
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
          // ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                  blurRadius: AppDimensions.radius_25,
                  //spreadRadius: AppDimensions.radius_1,
                  color: Colors.black.withOpacity(.25),
                  offset: Offset(AppDimensions.dim1, AppDimensions.dim1),
                )
              ]),
              child: SvgPicture.asset(
                "assets/images/password_reset.svg",
              ),
            ),
            SizedBox(
              height: AppDimensions.dim32.h,
            ),
            Text(
              AppStrings.allSet,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_32,
                fontVariations: [
                  AppFontStyles.boldFontVariation,
                ],
              ),
            ),
            SizedBox(
              height: AppDimensions.dim12.h,
            ),
            Text(
              AppStrings.passwordResetSuccess,
              textAlign: TextAlign.center,
              style: TextStyle(
                height:
                    AppFontStyles.getLineHeight(AppFontStyles.fontSize_18, 160),
                fontFamily: AppFontStyles.museoModernoFontFamily,
                color: AppColors.black,
                fontSize: AppFontStyles.fontSize_18,
                fontVariations: [
                  AppFontStyles.regularFontVariation,
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: AppDimensions.dim60,
        margin: EdgeInsets.only(
          bottom: AppDimensions.padding33.h,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
        ),
        child: AuthButton(
            text: AppStrings.gotohomepage,
            color: AppColors.lightBlue400,
            areTwoItems: false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SigninSignupScreen(
                      isSigninFlow: true,
                    ),
                  ),
                  (route) => false);
            }),
      ),
    );
  }
}
