import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/forgot_password_screen.dart';
import 'package:hydrify/screens/auth/otp_verification_screen.dart';
import 'package:hydrify/screens/bottom_nav_screen_new.dart';
import 'package:hydrify/screens/info/terms_of_service.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/screens/widgets/custom_textfield.dart';
import 'package:hydrify/services/firebase_functions_service.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class SigninSignupScreen extends StatefulWidget {
  const SigninSignupScreen({super.key, required this.isSigninFlow});

  final bool isSigninFlow;

  @override
  State<SigninSignupScreen> createState() => _SigninSignupScreenState();
}

class _SigninSignupScreenState extends State<SigninSignupScreen> {
  final GlobalKey<CustomTextFieldState> _emailFieldKey =
      GlobalKey<CustomTextFieldState>();
  final GlobalKey<CustomTextFieldState> _passwordFieldKey =
      GlobalKey<CustomTextFieldState>();

  Color? _emailFieldBorderColor;
  Color? _passwordFieldBorderColor;
  final TextEditingController _emailController =
      TextEditingController(text: "");
  final TextEditingController _passwordController =
      TextEditingController(text: "");
  bool isCheckBoxChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
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
      body: SingleChildScrollView(
        reverse: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Container(
            padding: EdgeInsets.only(
              top: AppDimensions.padding_20.h,
              left: AppDimensions.dim33.w,
              right: AppDimensions.dim33.w,
            ),
            width: double.maxFinite,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/app_background.png"), // your image path
                fit: BoxFit.cover,
              ),
              // gradient: LinearGradient(
              //   begin: Alignment.topCenter,
              //   end: Alignment.bottomCenter,
              //   colors: [
              //     AppColors.gradientStart,
              //     AppColors.gradientEnd,
              //   ],
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
                  height: AppDimensions.dim36.h,
                ),
                _buildInputFields(),
                SizedBox(
                  height: AppDimensions.dim16.h,
                ),
                Visibility(
                  visible: widget.isSigninFlow == false,
                  child: Align(
                    alignment: Alignment.center,
                    child: _buildAccountAlreadyPresent(),
                  ),
                ),
                Visibility(
                  visible: widget.isSigninFlow == false,
                  child: SizedBox(
                    height: AppDimensions.dim5.h,
                  ),
                ),
                // _buildDivider(),
                SizedBox(
                  height: AppDimensions.dim10.h,
                ),
                _buildSSOButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.isSigninFlow
              ? AppStrings.gladToSeeYou
              : AppStrings.getStartedWithSipnudge,
          style: TextStyle(
            color: AppColors.bluegray,
            height:
                AppFontStyles.getLineHeight(AppFontStyles.fontSize_24.sp, 160),
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
          widget.isSigninFlow
              ? AppStrings.signinToYourAccount
              : AppStrings.createAnAccount,
          style: TextStyle(
            color: AppColors.bluegray,
            height: AppFontStyles.getLineHeight(
                AppFontStyles.fontSize_16.sp, AppFontStyles.lineHeight_160),
            fontSize: AppFontStyles.fontSize_16.sp,
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
        // Email Label
        Text(
          AppStrings.email,
          style: TextStyle(
            color: AppColors.raisinblack,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.fontSize_18.sp,
            fontVariations: [AppFontStyles.fontWeightVariation600],
            // shadows: [
            //   Shadow(
            //     blurRadius: AppDimensions.dim5,
            //     color: Colors.black.withOpacity(.2),
            //     offset: Offset(0, AppDimensions.dim3),
            //   ),
            // ],
          ),
        ),
        SizedBox(height: AppDimensions.dim8.h),
        CustomTextField(
          key: _emailFieldKey,
          borderColor: _emailFieldBorderColor,
          controller: _emailController,
          prefixIcon: SvgPicture.asset(
            "assets/images/email_ic.svg",
            fit: BoxFit.fitWidth,
          ),
          hint: AppStrings.email,
        ),
        SizedBox(height: AppDimensions.dim16.h),
        // Password Label
        Text(
          AppStrings.password,
          style: TextStyle(
            color: AppColors.raisinblack,
            fontSize: AppFontStyles.fontSize_18.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.fontWeightVariation600],
            // shadows: [
            //   Shadow(
            //     blurRadius: AppDimensions.dim5,
            //     color: Colors.black.withOpacity(.2),
            //     offset: Offset(0, AppDimensions.dim3),
            //   ),
            // ],
          ),
        ),
        SizedBox(height: AppDimensions.dim8.h),
        CustomTextField(
          key: _passwordFieldKey,
          borderColor: _passwordFieldBorderColor,
          controller: _passwordController,
          isPasswordField: true,
          prefixIcon: SvgPicture.asset(
            "assets/images/lock_ic.svg",
            fit: BoxFit.fitHeight,
          ),
          hint: AppStrings.password,
        ),
        SizedBox(height: AppDimensions.dim16.h),
        Row(
          children: [
            SizedBox(
              width: AppDimensions.dim32.w,
              height: AppDimensions.dim32.w,
              child: Checkbox(
                checkColor: AppColors.white,
                activeColor: AppColors.lightBlue400,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radius_5.w),
                ),
                side: BorderSide(
                  color: AppColors.lightBlue400,
                  width: AppDimensions.dim3.w,
                ),
                value: isCheckBoxChecked,
                onChanged: (newValue) {
                  // ✅ Only update state, no OTP logic here
                  setState(() {
                    isCheckBoxChecked = newValue ?? false;
                  });
                },
              ),
            ),
            SizedBox(width: AppDimensions.dim16.w),
            Visibility(
              visible: widget.isSigninFlow == false,
              replacement: Text(
                AppStrings.rememberMe,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: AppFontStyles.fontSize_18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.semiBoldFontVariation,
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: () {},
                child: RichText(
                  text: TextSpan(
                    text: AppStrings.iAgree,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: AppFontStyles.fontSize_17.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [
                        AppFontStyles.semiBoldFontVariation,
                      ],
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TermsOfServiceScreen(),
                              ),
                            );
                          },
                          child: Text(
                            AppStrings.termsAndConditions,
                            style: TextStyle(
                              color: AppColors.blueGradient,
                              fontSize: AppFontStyles.fontSize_17,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [
                                AppFontStyles.semiBoldFontVariation,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // TextSpan(
                      //   text: AppStrings.clickToContinue,
                      //   style: TextStyle(
                      //     color: AppColors.white,
                      //     fontSize: AppFontStyles.fontSize_17,
                      //     fontFamily: AppFontStyles.urbanistFontFamily,
                      //     fontVariations: [
                      //       AppFontStyles.semiBoldFontVariation,
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            Spacer(),
            Visibility(
              visible: widget.isSigninFlow,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  AppStrings.forgotPassword,
                  style: TextStyle(
                    color: AppColors.blueGradient,
                    fontSize: AppFontStyles.fontSize_18,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [
                      AppFontStyles.semiBoldFontVariation,
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        //   ],
        // ),
        SizedBox(height: AppDimensions.dim20.h),
        // Sign In / Sign Up Button
        AuthButton(
          text: widget.isSigninFlow ? AppStrings.signIn : AppStrings.signUp,
          color: widget.isSigninFlow
              ? AppColors.blueSecondary
              : AppColors.blueGradient,
          textColor: widget.isSigninFlow
              ? AppColors.buttonTextPurpleColor
              : AppColors.white,
          areTwoItems: false,
          onTap: () async {
            FocusScope.of(context).unfocus();
            setState(() {
              _emailFieldBorderColor = _passwordFieldBorderColor = null;
            });

            // Input validation
            if (_emailController.text.trim().isEmpty &&
                _passwordController.text.trim().isEmpty) {
              setState(() {
                _emailFieldBorderColor =
                    _passwordFieldBorderColor = AppColors.errorRedColor;
              });
              _emailFieldKey.currentState?.triggerShake();
              _passwordFieldKey.currentState?.triggerShake();
              UiUtilsService.showToast(
                  context: context, text: "Please enter email and password");
              return;
            } else if (_emailController.text.trim().isEmpty) {
              setState(() {
                _emailFieldBorderColor = AppColors.errorRedColor;
              });
              _emailFieldKey.currentState?.triggerShake();
              UiUtilsService.showToast(
                  context: context, text: "Please enter email");
              return;
            } else if (_passwordController.text.trim().isEmpty) {
              setState(() {
                _passwordFieldBorderColor = AppColors.errorRedColor;
              });
              _passwordFieldKey.currentState?.triggerShake();
              UiUtilsService.showToast(
                  context: context, text: "Please enter password");
              return;
            }

            if (widget.isSigninFlow) {
              // ✅ Sign-In logic
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(_emailController.text)) {
                _emailFieldKey.currentState?.triggerShake();
                UiUtilsService.showToast(
                    context: context, text: "Please enter a valid email");
                return;
              }

              UiUtilsService.showLoading(context, "Sign in");
              final responseSigninResponse =
                  await ApiService().signIn(
                      _emailController.text, _passwordController.text);
              if (!mounted) return;
              UiUtilsService.dismissLoading(context);

              if (responseSigninResponse.status == "success" &&
                  responseSigninResponse.statusCode == 200) {
                
                final bool shutdownApp = responseSigninResponse.data?.userDetails?.shutdownApp ?? false;
                if (shutdownApp) {
                  await SharedPrefsHelper.setAppShutdownStatus(true);
                  if (!mounted) return;
                  UiUtilsService.showTrialRestrictionDialog(context);
                  return;
                }

                SharedPrefsHelper.setUserEmail(_emailController.text);
                final hasUserFilledInPersonalInfo =
                    await SharedPrefsHelper.isPersonalInfoSubmitted();
                final hasUserSelectedPersonalGoal =
                    await SharedPrefsHelper.getUserGoal();

                if (!mounted) return;
                
                if (hasUserFilledInPersonalInfo &&
                    hasUserSelectedPersonalGoal != null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BottomNavScreenNew()),
                    (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserInfoInputScreen()),
                    (route) => false,
                  );
                }
              } else {
                // Error handling
                final statusCode = responseSigninResponse.statusCode;
                final message = responseSigninResponse.message ??
                    "Unexpected error occurred";

                if (statusCode == 401) {
                  setState(() {
                    _passwordFieldBorderColor = AppColors.errorRedColor;
                  });
                  _passwordFieldKey.currentState?.triggerShake();
                } else if (statusCode == 404) {
                  setState(() {
                    _passwordFieldBorderColor = AppColors.errorRedColor;
                    _emailFieldBorderColor = AppColors.errorRedColor;
                  });
                  _passwordFieldKey.currentState?.triggerShake();
                  _emailFieldKey.currentState?.triggerShake();
                } else {
                  setState(() {
                    _passwordFieldBorderColor = AppColors.errorRedColor;
                    _emailFieldBorderColor = AppColors.errorRedColor;
                  });
                  _passwordFieldKey.currentState?.triggerShake();
                  _emailFieldKey.currentState?.triggerShake();
                }

                UiUtilsService.showToast(
                  context: context,
                  text: message,
                );
              }
            } else {
              // ✅ Sign-Up logic
              if (!isCheckBoxChecked) {
                UiUtilsService.showToast(
                    context: context,
                    text: "Please accept the terms and conditions");
                return;
              }

              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(_emailController.text)) {
                _emailFieldKey.currentState?.triggerShake();
                UiUtilsService.showToast(
                    context: context, text: "Please enter a valid email");
                return;
              }

              UiUtilsService.showLoading(context, "Sending OTP");
              var sendOtpResponse =
                  await FirebaseFunctionsService.requestSignupOTP(
                      _emailController.text, _passwordController.text);
              if (!mounted) return;
              UiUtilsService.dismissLoading(context);

              if (sendOtpResponse["status"] == "success" &&
                  sendOtpResponse["statusCode"] == 200) {
                UiUtilsService.showToast(
                    context: context, text: sendOtpResponse["message"]);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OtpVerificationScreen(userEmail: _emailController.text),
                  ),
                );
              } else {
                UiUtilsService.showToast(
                    context: context,
                    text: sendOtpResponse["message"] ??
                        "Unexpected error occurred");
              }
            }
          },
        ),
        SizedBox(
          height: AppDimensions.dim20.h,
        ),
        _buildDivider()
      ],
    );
  }

  Widget _buildAccountAlreadyPresent() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SigninSignupScreen(isSigninFlow: true),
          ),
        );
      },
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: AppStrings.alreadyHaveAnAccount,
              style: TextStyle(
                color: AppColors.raisinblack,
                fontSize: AppFontStyles.fontSize_18.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.regularFontVariation],
              ),
              children: [
                TextSpan(
                  text: AppStrings.signIn,
                  style: TextStyle(
                    color: AppColors.blueGradient,
                    fontSize: AppFontStyles.fontSize_18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: AppDimensions.dim10.h,
          ),
          _buildDivider()
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: <Widget>[
      Expanded(
        child: Divider(
          color: AppColors.lightgray,
          thickness: 2,
        ),
      ),
      SizedBox(
        height: AppDimensions.dim29.h,
        width: AppDimensions.dim10.w,
      ),
      Text(
        AppStrings.or,
        style: TextStyle(
          color: AppColors.greyColor,
          fontSize: AppFontStyles.fontSize_18.sp,
          fontVariations: [AppFontStyles.semiBoldFontVariation],
        ),
      ),
      SizedBox(
        width: AppDimensions.dim10.w,
      ),
      Expanded(
        child: Divider(
          color: AppColors.lightgray,
          thickness: 2,
        ),
      ),
    ]);
  }

  Widget _buildSSOButtons() {
    return Column(
      children: [
        Visibility(
          visible: Platform.isIOS,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthButton(
                iconPath: "assets/images/apple_ic.svg",
                text: AppStrings.continueWithApple,
                color: AppColors.white,
                onTap: () async {
                  UiUtilsService.showLoading(
                      context, "Signing you in via Apple");

                  var signInWithAppleRes =
                      await FirebaseFunctionsService.signInWithApple();

                  if (!mounted) return;

                  UiUtilsService.dismissLoading(context);

                  if (signInWithAppleRes['success'] == true) {
                    // Fetch userId from backend using email
                    final userCredential =
                        signInWithAppleRes['userCredential'] as UserCredential?;
                    final email = userCredential?.user?.email;
                    if (email != null) {
                      final userData = await ApiService().getUserByEmail(email);
                      if (userData != null && userData['_id'] != null) {
                        await SharedPrefsHelper.setUserId(userData['_id']);
                        Console.log(
                            tag: "AUTH",
                            value:
                                "Social Login (Apple): UserId saved: ${userData['_id']}");
                      }
                    }

                    if (!mounted) return;

                    UiUtilsService.showToast(
                        context: context, text: "Signin Successful");

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserInfoInputScreen(),
                      ),
                      (route) => false,
                    );
                  } else {
                    UiUtilsService.showToast(
                        context: context,
                        text: signInWithAppleRes['message'] ??
                            'Apple Sign-In failed');
                  }
                },
              ),
              SizedBox(height: AppDimensions.dim20.h),
            ],
          ),
        ),
        AuthButton(
          iconPath: "assets/images/google_ic.svg",
          text: AppStrings.continueWithGoogle,
          color: AppColors.white,
          onTap: () async {
            UiUtilsService.showLoading(context, "Signing you in via Google");
            var signInWithGoogleRes =
                await FirebaseFunctionsService.signInWithGoogle();
            if (!mounted) return;
            UiUtilsService.dismissLoading(context);

            if (signInWithGoogleRes != null) {
              // Fetch userId from backend using email
              final email = signInWithGoogleRes.user?.email;
              if (email != null) {
                final userData = await ApiService().getUserByEmail(email);
                if (userData != null && userData['_id'] != null) {
                  await SharedPrefsHelper.setUserId(userData['_id']);
                  Console.log(
                      tag: "AUTH",
                      value: "Social Login: UserId saved: ${userData['_id']}");
                }
              }

              if (!mounted) return;

              UiUtilsService.showToast(
                  context: context, text: "Signin Successful");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomNavScreenNew(),
                ),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }
}

//=============================================================================

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/helpers/shared_pref_helper.dart';
// import 'package:hydrify/screens/auth/forgot_password_screen.dart';
// import 'package:hydrify/screens/auth/otp_verification_screen.dart';
// import 'package:hydrify/screens/bottom_nav_screen_new.dart';
// import 'package:hydrify/screens/info/terms_of_service.dart';
// import 'package:hydrify/screens/user_personal_info_input_screen..dart';
// import 'package:hydrify/screens/widgets/auth_button_widget.dart';
// import 'package:hydrify/screens/widgets/custom_textfield.dart';
// import 'package:hydrify/services/firebase_functions_service.dart';
// import 'package:hydrify/services/ui_utils_service.dart';

// class SigninSignupScreen extends StatefulWidget {
//   const SigninSignupScreen({super.key, required this.isSigninFlow});

//   final bool isSigninFlow;

//   @override
//   State<SigninSignupScreen> createState() => _SigninSignupScreenState();
// }

// class _SigninSignupScreenState extends State<SigninSignupScreen> {
//   final GlobalKey<CustomTextFieldState> _emailFieldKey =
//       GlobalKey<CustomTextFieldState>();
//   final GlobalKey<CustomTextFieldState> _passwordFieldKey =
//       GlobalKey<CustomTextFieldState>();

//   Color? _emailFieldBorderColor;
//   Color? _passwordFieldBorderColor;
//   final TextEditingController _emailController =
//       TextEditingController(text: "");
//   final TextEditingController _passwordController =
//       TextEditingController(text: "");
//   bool isCheckBoxChecked = false;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         automaticallyImplyLeading: true,
//         leadingWidth: AppDimensions.dim85.w,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           icon: SvgPicture.asset(
//             "assets/images/back_ic.svg",
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         reverse: true,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minHeight: MediaQuery.of(context).size.height,
//           ),
//           child: Container(
//             padding: EdgeInsets.only(
//               top: AppDimensions.padding_20.h,
//               left: AppDimensions.dim33.w,
//               right: AppDimensions.dim33.w,
//             ),
//             width: double.maxFinite,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   AppColors.gradientStart,
//                   AppColors.gradientEnd,
//                 ],
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(
//                   height: AppDimensions.dim100.h,
//                 ),
//                 _buildGreeting(),
//                 SizedBox(
//                   height: AppDimensions.dim36.h,
//                 ),
//                 _buildInputFields(),
//                 SizedBox(
//                   height: AppDimensions.dim16.h,
//                 ),
//                 Visibility(
//                   visible: widget.isSigninFlow == false,
//                   child: Align(
//                     alignment: Alignment.center,
//                     child: _buildAccountAlreadyPresent(),
//                   ),
//                 ),
//                 Visibility(
//                   visible: widget.isSigninFlow == false,
//                   child: SizedBox(
//                     height: AppDimensions.dim15.h,
//                   ),
//                 ),
//                 _buildDivider(),
//                 SizedBox(
//                   height: AppDimensions.dim15.h,
//                 ),
//                 _buildSSOButtons(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGreeting() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           widget.isSigninFlow
//               ? AppStrings.gladToSeeYou
//               : AppStrings.getStartedWithSipnudge,
//           style: TextStyle(
//             color: Colors.white,
//             height:
//                 AppFontStyles.getLineHeight(AppFontStyles.fontSize_24.sp, 160),
//             fontSize: AppFontStyles.fontSize_24.sp,
//             fontVariations: [
//               AppFontStyles.boldFontVariation,
//             ],
//           ),
//         ),
//         SizedBox(
//           height: AppDimensions.dim8.h,
//         ),
//         Text(
//           widget.isSigninFlow
//               ? AppStrings.signinToYourAccount
//               : AppStrings.createAnAccount,
//           style: TextStyle(
//             color: AppColors.white,
//             height: AppFontStyles.getLineHeight(
//                 AppFontStyles.fontSize_16.sp, AppFontStyles.lineHeight_160),
//             fontSize: AppFontStyles.fontSize_16.sp,
//             fontVariations: [
//               AppFontStyles.regularFontVariation,
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInputFields() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           AppStrings.email,
//           style: TextStyle(
//               color: AppColors.white,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontSize: AppFontStyles.fontSize_18.sp,
//               fontVariations: [
//                 AppFontStyles.semiBoldFontVariation,
//               ],
//               shadows: [
//                 Shadow(
//                   blurRadius: AppDimensions.dim5,
//                   color: Colors.black.withOpacity(.2),
//                   offset: Offset(
//                     0,
//                     AppDimensions.dim3,
//                   ),
//                 )
//               ]),
//         ),
//         SizedBox(
//           height: AppDimensions.dim8.h,
//         ),
//         CustomTextField(
//           key: _emailFieldKey,
//           borderColor: _emailFieldBorderColor,
//           controller: _emailController,
//           prefixIcon: SvgPicture.asset(
//             "assets/images/email_ic.svg",
//             fit: BoxFit.fitWidth,
//           ),
//           hint: AppStrings.email,
//         ),
//         SizedBox(
//           height: AppDimensions.dim16.h,
//         ),
//         Text(
//           AppStrings.password,
//           style: TextStyle(
//               color: AppColors.white,
//               fontSize: AppFontStyles.fontSize_18.sp,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontVariations: [
//                 AppFontStyles.semiBoldFontVariation,
//               ],
//               shadows: [
//                 Shadow(
//                   blurRadius: AppDimensions.dim5,
//                   color: Colors.black.withOpacity(.2),
//                   offset: Offset(
//                     0,
//                     AppDimensions.dim3,
//                   ),
//                 )
//               ]),
//         ),
//         SizedBox(
//           height: AppDimensions.dim8.h,
//         ),
//         CustomTextField(
//           key: _passwordFieldKey,
//           borderColor: _passwordFieldBorderColor,
//           controller: _passwordController,
//           isPasswordField: true,
//           prefixIcon: SvgPicture.asset(
//             "assets/images/lock_ic.svg",
//             fit: BoxFit.fitHeight,
//           ),
//           hint: AppStrings.password,
//         ),
//         SizedBox(
//           height: AppDimensions.dim16.h,
//         ),
//         Row(
//           children: [
//             SizedBox(
//               width: AppDimensions.dim24.w,
//               height: AppDimensions.dim24.w,
//               child: Checkbox(
//                 checkColor: AppColors.white,
//                 activeColor: AppColors.mintGreenColor,
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(
//                     AppDimensions.radius_5.w,
//                   ),
//                 ),
//                 side: BorderSide(
//                   color: AppColors.mintGreenColor,
//                   width: AppDimensions.dim3.w,
//                 ),
//                 value: isCheckBoxChecked,
//                 onChanged: (newValue) async {
//                   isCheckBoxChecked = newValue ?? false;
//                   if (isCheckBoxChecked == true &&
//                       widget.isSigninFlow == false) {
//                     _emailFieldBorderColor = _passwordFieldBorderColor = null;

//                     if (_emailController.text.trim().isEmpty &&
//                         _passwordController.text.trim().isEmpty) {
//                       _emailFieldBorderColor =
//                           _passwordFieldBorderColor = AppColors.errorRedColor;

//                       _emailFieldKey.currentState?.triggerShake();
//                       _passwordFieldKey.currentState?.triggerShake();
//                       isCheckBoxChecked = false;
//                       UiUtilsService.showToast(
//                           context: context,
//                           text: "Please enter email and password");
//                     } else if (_emailController.text.trim().isEmpty) {
//                       isCheckBoxChecked = false;
//                       _emailFieldBorderColor = AppColors.errorRedColor;
//                       _emailFieldKey.currentState?.triggerShake();
//                       UiUtilsService.showToast(
//                           context: context, text: "Please enter email");
//                     } else if (_passwordController.text.trim().isEmpty) {
//                       isCheckBoxChecked = false;
//                       _passwordFieldBorderColor = AppColors.errorRedColor;
//                       _passwordFieldKey.currentState?.triggerShake();
//                       UiUtilsService.showToast(
//                           context: context, text: "Please enter password");
//                     } else {
//                       if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                           .hasMatch(_emailController.text)) {
//                         UiUtilsService.showLoading(context, "Sending OTP");

//                         var sendOtpResponse =
//                             await FirebaseFunctionsService.requestSignupOTP(
//                                 _emailController.text,
//                                 _passwordController.text);

//                         UiUtilsService.dismissLoading(context);

//                         if (sendOtpResponse["status"] == "success" &&
//                             sendOtpResponse["statusCode"] == 200) {
//                           UiUtilsService.showToast(
//                               context: context,
//                               text: sendOtpResponse["message"]);
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => OtpVerificationScreen(
//                                 userEmail: _emailController.text,
//                               ),
//                             ),
//                           );
//                         } else {
//                           UiUtilsService.showToast(
//                               context: context,
//                               text: sendOtpResponse["message"] ??
//                                   "Unexpected error occurred");
//                         }
//                       } else {
//                         _emailFieldKey.currentState?.triggerShake();
//                         UiUtilsService.showToast(
//                             context: context,
//                             text: "Please enter a valid email");
//                       }
//                     }
//                     if (mounted) {
//                       setState(() {});
//                     }
//                   } else {
//                     setState(() {});
//                   }
//                 },
//               ),
//             ),
//             SizedBox(
//               width: AppDimensions.dim16.w,
//             ),
//             Visibility(
//               visible: widget.isSigninFlow == false,
//               replacement: Text(
//                 AppStrings.rememberMe,
//                 style: TextStyle(
//                   color: AppColors.white,
//                   fontSize: AppFontStyles.fontSize_18.sp,
//                   fontFamily: AppFontStyles.urbanistFontFamily,
//                   fontVariations: [
//                     AppFontStyles.semiBoldFontVariation,
//                   ],
//                 ),
//               ),
//               child: GestureDetector(
//                 onTap: () {},
//                 child: RichText(
//                   text: TextSpan(
//                     text: AppStrings.iAgree,
//                     style: TextStyle(
//                       color: AppColors.white,
//                       fontSize: AppFontStyles.fontSize_17.sp,
//                       fontFamily: AppFontStyles.urbanistFontFamily,
//                       fontVariations: [
//                         AppFontStyles.semiBoldFontVariation,
//                       ],
//                     ),
//                     children: [
//                       WidgetSpan(
//                           child: GestureDetector(
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => TermsOfServiceScreen(),
//                             ),
//                           );
//                         },
//                         child: Text(
//                           AppStrings.termsAndConditions,
//                           style: TextStyle(
//                             color: AppColors.blueGradient,
//                             fontSize: AppFontStyles.fontSize_17,
//                             fontFamily: AppFontStyles.urbanistFontFamily,
//                             fontVariations: [
//                               AppFontStyles.semiBoldFontVariation,
//                             ],
//                           ),
//                         ),
//                       )),
//                       TextSpan(
//                         text: AppStrings.clickToContinue,
//                         style: TextStyle(
//                           color: AppColors.white,
//                           fontSize: AppFontStyles.fontSize_17,
//                           fontFamily: AppFontStyles.urbanistFontFamily,
//                           fontVariations: [
//                             AppFontStyles.semiBoldFontVariation,
//                           ],
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Spacer(),
//             Visibility(
//               visible: widget.isSigninFlow,
//               child: GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ForgotPasswordScreen(),
//                     ),
//                   );
//                 },
//                 child: Text(
//                   AppStrings.forgotPassword,
//                   style: TextStyle(
//                     color: AppColors.blueGradient,
//                     fontSize: AppFontStyles.fontSize_18,
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [
//                       AppFontStyles.semiBoldFontVariation,
//                     ],
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//         SizedBox(height: AppDimensions.dim20.h),
//         Visibility(
//           visible: widget.isSigninFlow,
//           child: AuthButton(
//             text: widget.isSigninFlow ? AppStrings.signIn : AppStrings.signUp,
//             color: widget.isSigninFlow
//                 ? AppColors.blueSecondary
//                 : AppColors.blueGradient,
//             textColor: widget.isSigninFlow
//                 ? AppColors.buttonTextPurpleColor
//                 : AppColors.white,
//             areTwoItems: false,
//             onTap: () async {
//               FocusScope.of(context).unfocus();
//               setState(() {
//                 _emailFieldBorderColor = _passwordFieldBorderColor = null;
//               });
//               if (_emailController.text.trim().isEmpty &&
//                   _passwordController.text.trim().isEmpty) {
//                 setState(() {
//                   _emailFieldBorderColor =
//                       _passwordFieldBorderColor = AppColors.errorRedColor;
//                 });

//                 _emailFieldKey.currentState?.triggerShake();
//                 _passwordFieldKey.currentState?.triggerShake();
//                 UiUtilsService.showToast(
//                     context: context, text: "Please enter email and password");
//               } else if (_emailController.text.trim().isEmpty) {
//                 setState(() {
//                   _emailFieldBorderColor = AppColors.errorRedColor;
//                 });
//                 _emailFieldKey.currentState?.triggerShake();
//                 UiUtilsService.showToast(
//                     context: context, text: "Please enter email");
//               } else if (_passwordController.text.trim().isEmpty) {
//                 setState(() {
//                   _passwordFieldBorderColor = AppColors.errorRedColor;
//                 });
//                 _passwordFieldKey.currentState?.triggerShake();
//                 UiUtilsService.showToast(
//                     context: context, text: "Please enter password");
//               } else {
//                 if (widget.isSigninFlow) {
//                   if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                       .hasMatch(_emailController.text)) {
//                     UiUtilsService.showLoading(context, "Sign in");
//                     var responseSigninResponse =
//                         await FirebaseFunctionsService.signIn(
//                             _emailController.text, _passwordController.text);
//                     UiUtilsService.dismissLoading(context);

//                     if (responseSigninResponse["status"] == "success" &&
//                         responseSigninResponse["statusCode"] == 200) {
//                       UiUtilsService.showToast(
//                         context: context,
//                         text: responseSigninResponse["message"],
//                       );

//                       SharedPrefsHelper.setUserEmail(_emailController.text);
//                       final hasUserFilledInPersonalInfo =
//                           await SharedPrefsHelper.isPersonalInfoSubmitted();
//                       final hasUserSelectedPersonalGoal =
//                           await SharedPrefsHelper.getUserGoal();

//                       if (hasUserFilledInPersonalInfo &&
//                           hasUserSelectedPersonalGoal != null) {
//                         Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => BottomNavScreenNew()),
//                           (route) => false,
//                         );
//                       } else {
//                         Navigator.pushAndRemoveUntil(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => UserInfoInputScreen()),
//                           (route) => false,
//                         );
//                       }
//                     } else {
//                       final statusCode = responseSigninResponse["statusCode"];
//                       final message = responseSigninResponse["message"] ??
//                           "Unexpected error occurred";

//                       if (statusCode == 401) {
//                         setState(() {
//                           _passwordFieldBorderColor = AppColors.errorRedColor;
//                         });
//                         _passwordFieldKey.currentState?.triggerShake();
//                       } else if (statusCode == 404) {
//                         setState(() {
//                           _passwordFieldBorderColor = AppColors.errorRedColor;
//                           _emailFieldBorderColor = AppColors.errorRedColor;
//                         });
//                         _passwordFieldKey.currentState?.triggerShake();
//                         _emailFieldKey.currentState?.triggerShake();
//                       } else {
//                         setState(() {
//                           _passwordFieldBorderColor = AppColors.errorRedColor;
//                           _emailFieldBorderColor = AppColors.errorRedColor;
//                         });
//                         _passwordFieldKey.currentState?.triggerShake();
//                         _emailFieldKey.currentState?.triggerShake();
//                       }

//                       UiUtilsService.showToast(
//                         context: context,
//                         text: message,
//                       );
//                     }
//                   } else {
//                     _emailFieldKey.currentState?.triggerShake();
//                     UiUtilsService.showToast(
//                         context: context, text: "Please enter a valid email");
//                   }
//                 } else if (widget.isSigninFlow == false) {
//                   if (isCheckBoxChecked == false) {
//                     UiUtilsService.showToast(
//                         context: context,
//                         text: "Please accept the terms and conditions");
//                   } else {
//                     UiUtilsService.showLoading(context, "Sign up ...");
//                     await Future.delayed(Duration(seconds: 5), () {
//                       UiUtilsService.dismissLoading(context);
//                     });
//                   }
//                 }
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAccountAlreadyPresent() {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => SigninSignupScreen(isSigninFlow: true),
//           ),
//         );
//       },
//       child: RichText(
//         text: TextSpan(
//             text: AppStrings.alreadyHaveAnAccount,
//             style: TextStyle(
//               color: AppColors.white,
//               fontSize: AppFontStyles.fontSize_18.sp,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontVariations: [
//                 AppFontStyles.regularFontVariation,
//               ],
//             ),
//             children: [
//               TextSpan(
//                 text: AppStrings.signIn,
//                 style: TextStyle(
//                   color: AppColors.blueGradient,
//                   fontSize: AppFontStyles.fontSize_18.sp,
//                   fontFamily: AppFontStyles.urbanistFontFamily,
//                   fontVariations: [
//                     AppFontStyles.boldFontVariation,
//                   ],
//                 ),
//               )
//             ]),
//       ),
//     );
//   }

//   Widget _buildDivider() {
//     return Row(children: <Widget>[
//       Expanded(
//           child: Divider(
//         color: AppColors.dividerColor,
//       )),
//       SizedBox(
//         height: AppDimensions.dim29.h,
//         width: AppDimensions.dim10.w,
//       ),
//       Text(
//         AppStrings.or,
//         style: TextStyle(
//           color: AppColors.greyColor,
//           fontSize: AppFontStyles.fontSize_18.sp,
//           fontVariations: [
//             AppFontStyles.semiBoldFontVariation,
//           ],
//         ),
//       ),
//       SizedBox(
//         width: AppDimensions.dim10.w,
//       ),
//       Expanded(
//         child: Divider(
//           color: AppColors.dividerColor,
//         ),
//       ),
//     ]);
//   }

//   Widget _buildSSOButtons() {
//     return Column(
//       children: [
//         Visibility(
//           visible: Platform.isIOS,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AuthButton(
//                 iconPath: "assets/images/apple_ic.svg",
//                 text: AppStrings.continueWithApple,
//                 color: AppColors.white,
//                 onTap: () async {
//                   UiUtilsService.showLoading(
//                       context, "Signing you in via Apple");
//                   var signInWithGoogleRes =
//                       await FirebaseFunctionsService.signInWithApple();

//                   UiUtilsService.dismissLoading(context);
//                   if (signInWithGoogleRes != null) {
//                     SharedPrefsHelper.setUserEmail(
//                         signInWithGoogleRes.user?.email ?? "email");
//                     UiUtilsService.showToast(
//                         context: context, text: "Signin Successful");

//                     Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => UserInfoInputScreen(),
//                       ),
//                       (route) => false,
//                     );
//                   }
//                 },
//               ),
//               SizedBox(height: AppDimensions.dim20.h),
//             ],
//           ),
//         ),
//         AuthButton(
//           iconPath: "assets/images/google_ic.svg",
//           text: AppStrings.continueWithGoogle,
//           color: AppColors.white,
//           onTap: () async {
//             UiUtilsService.showLoading(context, "Signing you in via Google");
//             var signInWithGoogleRes =
//                 await FirebaseFunctionsService.signInWithGoogle();
//             UiUtilsService.dismissLoading(context);
//             if (signInWithGoogleRes != null) {
//               UiUtilsService.showToast(
//                   context: context, text: "Signin Successful");
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => BottomNavScreenNew(),
//                 ),
//                 (route) => false,
//               );
//             }
//           },
//         ),
//       ],
//     );
//   }

//   bool validateInputs() {
//     return true;
//   }
// }
