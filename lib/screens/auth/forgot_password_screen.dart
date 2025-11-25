import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/screens/auth/otp_verification_screen.dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/screens/widgets/custom_textfield.dart';
import 'package:hydrify/services/firebase_functions_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<CustomTextFieldState> _emailFieldKey =
      GlobalKey<CustomTextFieldState>();

  final TextEditingController _emailController = TextEditingController();

  late final Color? _emailFieldBorderColor;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: AppDimensions.dim100.h,
            ),
            _buildGreeting(),
            SizedBox(
              height: AppDimensions.dim32.h,
            ),
            _buildInputField(),
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
            text: AppStrings.sendOTP,
            color: AppColors.lightBlue400,
            areTwoItems: false,
            onTap: () async {
              if (_emailController.text.trim() == "" ||
                  !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(_emailController.text)) {
                _emailFieldKey.currentState?.triggerShake();

                UiUtilsService.showToast(
                  context: context,
                  text: "Please enter valid email",
                );
              } else {
                UiUtilsService.showLoading(context, "Sending OTP");
                var sendPassResetOtpResponse =
                    await FirebaseFunctionsService.requestResetOTP(
                        _emailController.text);
                UiUtilsService.dismissLoading(context);
                if (sendPassResetOtpResponse["status"] == "success" &&
                    sendPassResetOtpResponse["statusCode"] == 200) {
                  UiUtilsService.showToast(
                      context: context,
                      text: sendPassResetOtpResponse["message"]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtpVerificationScreen(
                        userEmail: _emailController.text,
                        isResetPassFlow: true,
                      ),
                    ),
                  );
                } else {
                  UiUtilsService.showToast(
                      context: context,
                      text: sendPassResetOtpResponse["message"] ??
                          "Unexpected error ocurred");
                }
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
          AppStrings.forgotYourPassword,
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_24.sp,
            fontVariations: [
              AppFontStyles.boldFontVariation,
            ],
          ),
        ),
        SizedBox(
          height: AppDimensions.dim8.h,
        ),
        Text(
          AppStrings.noWorries,
          style: TextStyle(
            color: AppColors.bluegray,
            height: AppFontStyles.getLineHeight(
              AppFontStyles.fontSize_18,
              160,
            ),
            fontSize: AppFontStyles.fontSize_18,
            fontVariations: [
              AppFontStyles.regularFontVariation,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.registeredEmail,
          style: TextStyle(
            color: AppColors.bluegray,
            fontFamily: AppFontStyles.museoModernoFontFamily,
            height: AppFontStyles.getLineHeight(AppFontStyles.fontSize_18, 160),
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
          key: _emailFieldKey,
          controller: _emailController,
          prefixIcon: SvgPicture.asset(
            "assets/images/email_ic.svg",
            fit: BoxFit.fitWidth,
          ),
          hint: AppStrings.email,
        ),
        SizedBox(
          height: AppDimensions.dim16.h,
        ),
      ],
    );
  }
}
