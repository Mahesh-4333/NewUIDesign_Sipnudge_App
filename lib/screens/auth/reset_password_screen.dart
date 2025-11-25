import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/screens/auth/all_set_screen.dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/screens/widgets/custom_textfield.dart';
import 'package:hydrify/services/firebase_functions_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({super.key, required this.userEmail});

  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<CustomTextFieldState> _confirmFieldKey =
      GlobalKey<CustomTextFieldState>();
  final GlobalKey<CustomTextFieldState> _passwordFieldKey =
      GlobalKey<CustomTextFieldState>();

  final String userEmail;

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
          children: [
            SizedBox(
              height: AppDimensions.dim100.h,
            ),
            _buildGreeting(),
            SizedBox(
              height: AppDimensions.dim32.h,
            ),
            _buildInputFields(),
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
            text: AppStrings.saveNewPass,
            color: AppColors.lightBlue400,
            areTwoItems: false,
            onTap: () async {
              if ((_confirmPassController.text == _passwordController.text) &&
                  _confirmPassController.text.isNotEmpty) {
                UiUtilsService.showLoading(context, "Changing your password");
                var passwordChangeResponse =
                    await FirebaseFunctionsService.resetPassword(
                        userEmail, _confirmPassController.text);
                UiUtilsService.dismissLoading(context);
                if (passwordChangeResponse["status"] == "success" &&
                    passwordChangeResponse["statusCode"] == 200) {
                  UiUtilsService.showToast(
                      context: context,
                      text: passwordChangeResponse["message"]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllSetScreen(),
                    ),
                  );
                } else {
                  UiUtilsService.showToast(
                      context: context,
                      text: passwordChangeResponse["message"] ??
                          "Unexpected error occurred");
                }
              } else {
                _confirmFieldKey.currentState?.triggerShake();
                _passwordFieldKey.currentState?.triggerShake();
                UiUtilsService.showToast(
                    context: context, text: "The passwords do not match");
              }
            }),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.secureYourAccount,
          style: TextStyle(
            color: AppColors.bluegray,
            height: AppFontStyles.getLineHeight(
                AppFontStyles.fontSize_24, AppFontStyles.lineHeight_160),
            fontFamily: AppFontStyles.museoModernoFontFamily,
            fontSize: AppFontStyles.fontSize_24.sp,
            fontVariations: [
              AppFontStyles.boldFontVariation,
            ],
          ),
        ),
        Text(
          AppStrings.chooseNewPass,
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_16,
            fontFamily: AppFontStyles.museoModernoFontFamily,
            fontVariations: [
              AppFontStyles.regularFontVariation,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.newPass,
          style: TextStyle(
            color: AppColors.black,
            fontFamily: AppFontStyles.urbanistFontFamily,
            height: AppFontStyles.getLineHeight(
                AppFontStyles.fontSize_18, AppFontStyles.lineHeight_160),
            fontSize: AppFontStyles.fontSize_18,
            fontVariations: [
              AppFontStyles.fontWeightVariation600,
            ],
          ),
        ),
        SizedBox(
          height: AppDimensions.dim8.h,
        ),
        CustomTextField(
          key: _passwordFieldKey,
          controller: _passwordController,
          isPasswordField: true,
          prefixIcon: SvgPicture.asset(
            "assets/images/lock_ic.svg",
            fit: BoxFit.fitWidth,
          ),
          hint: AppStrings.newPass,
        ),
        SizedBox(
          height: AppDimensions.dim16.h,
        ),
        Text(
          AppStrings.confirmNewPass,
          style: TextStyle(
            color: AppColors.black,
            fontSize: AppFontStyles.fontSize_18.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [
              AppFontStyles.semiBoldFontVariation,
            ],
          ),
        ),
        SizedBox(
          height: AppDimensions.dim8.h,
        ),
        CustomTextField(
          key: _confirmFieldKey,
          controller: _confirmPassController,
          isPasswordField: true,
          prefixIcon: SvgPicture.asset(
            "assets/images/lock_ic.svg",
            fit: BoxFit.fitHeight,
          ),
          hint: AppStrings.confirmNewPass,
        ),
        SizedBox(
          height: AppDimensions.dim16.h,
        ),
      ],
    );
  }
}
