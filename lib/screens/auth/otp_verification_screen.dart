import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/reset_password_screen.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/services/firebase_functions_service.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.userEmail,
    this.isResetPassFlow = false,
  });

  final String userEmail;
  final bool isResetPassFlow;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isTimerActive = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 60;
      _isTimerActive = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isTimerActive = false;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    UiUtilsService.showLoading(context, "Resending OTP");

    try {
      Map<String, dynamic> resendResponse;
      if (widget.isResetPassFlow) {
        resendResponse =
            await FirebaseFunctionsService.resendOTP(widget.userEmail);
      } else {
        resendResponse =
            await ApiService().resendSignupOTP(widget.userEmail);
      }

      if (!mounted) return;
      UiUtilsService.dismissLoading(context);

      if (resendResponse["status"] == "success" ||
          resendResponse["status"] == "SUCCESS" ||
          resendResponse["statusCode"] == 200) {
        UiUtilsService.showToast(
            context: context, text: resendResponse["message"]);
        _startTimer();
      } else {
        UiUtilsService.showToast(
          context: context,
          text: resendResponse["message"] ?? "Unexpected error occurred",
        );
      }
    } catch (e) {
      if (!mounted) return;
      UiUtilsService.dismissLoading(context);

      String message = e.toString();
      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }
      final regExp = RegExp(r'^\[(\d+)\]');
      message = message.replaceFirst(regExp, '').trim();

      UiUtilsService.showToast(
        context: context,
        text: message,
      );
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.length == 6) {
      UiUtilsService.showLoading(context, "Verifying OTP");

      try {
        Map<String, dynamic> response;
        if (widget.isResetPassFlow) {
          response = await FirebaseFunctionsService.verifyResetOTPOnly(
            widget.userEmail,
            int.parse(enteredOtp),
          );
        } else {
          response = await ApiService().verifySignupOTP(
            widget.userEmail,
            int.parse(enteredOtp),
          );
        }

        if (!mounted) return;
        UiUtilsService.dismissLoading(context);

        if (response["status"] == "success" ||
            response["status"] == "SUCCESS" ||
            response["statusCode"] == 200) {
          UiUtilsService.showToast(
              context: context, text: response["message"] ?? "OTP Verified");

          if (widget.isResetPassFlow) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(
                  userEmail: widget.userEmail,
                ),
              ),
            );
          } else {
            final userId = response["data"]?["_id"];
            if (userId != null) {
              await SharedPrefsHelper.setUserId(userId);
            }
            await SharedPrefsHelper.setUserEmail(widget.userEmail);

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserInfoInputScreen(),
              ),
            );
          }
        } else {
          UiUtilsService.showToast(
            context: context,
            text: response["message"] ?? "Invalid OTP",
          );
        }
      } catch (e) {
        if (!mounted) return;
        UiUtilsService.dismissLoading(context);

        String message = e.toString();
        if (message.startsWith("Exception: ")) {
          message = message.substring("Exception: ".length);
        }
        final regExp = RegExp(r'^\[(\d+)\]');
        message = message.replaceFirst(regExp, '').trim();

        UiUtilsService.showToast(
          context: context,
          text: message,
        );
      }
    } else {
      UiUtilsService.showToast(
        context: context,
        text: "Please enter a valid 6-digit OTP",
      );
    }
  }

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
          icon: SvgPicture.asset("assets/images/back_ic.svg"),
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
            SizedBox(height: AppDimensions.dim100.h),
            _buildGreeting(),
            SizedBox(height: AppDimensions.dim29.h),
            _buildInputField(context),
            SizedBox(height: AppDimensions.dim29.h),
            Align(alignment: Alignment.center, child: _buildOTPTimer()),
            SizedBox(height: AppDimensions.dim24.h),
            AuthButton(
              text: widget.isResetPassFlow
                  ? AppStrings.verifyingOtp
                  : AppStrings.signUp,
              color: AppColors.blueGradient,
              areTwoItems: false,
              onTap: _verifyOtp,
            ),
          ],
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
          AppStrings.enterOTP,
          style: TextStyle(
            color: AppColors.bluegray,
            height: AppFontStyles.getLineHeight(
                AppFontStyles.fontSize_24.sp, AppFontStyles.lineHeight_160),
            fontFamily: AppFontStyles.museoModernoFontFamily,
            fontSize: AppFontStyles.fontSize_24.sp,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
        Text(
          AppStrings.weHaveSentOTP,
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_16,
            height: AppFontStyles.getLineHeight(
                AppFontStyles.fontSize_16, AppFontStyles.lineHeight_160),
            fontFamily: AppFontStyles.museoModernoFontFamily,
            fontVariations: [AppFontStyles.regularFontVariation],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Pinput(
      controller: _otpController,
      length: 6,
      onCompleted: (value) {},
      separatorBuilder: (index) =>
          SizedBox(width: 8.w),
      defaultPinTheme: PinTheme(
        width: 46.w,
        height: 56.h,
        textStyle: TextStyle(
          fontSize: AppFontStyles.fontSize_20.sp, // slightly smaller text for 6 digits
          color: Colors.black,
          fontFamily: AppFontStyles.urbanistFontFamily,
          fontVariations: [AppFontStyles.boldFontVariation],
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_5,
              color: Colors.black.withOpacity(.4),
              offset: Offset(AppDimensions.dim2, AppDimensions.dim2),
            )
          ],
          borderRadius: BorderRadius.circular(AppDimensions.dim12),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 46.w,
        height: 56.h,
        decoration: BoxDecoration(
          color: const Color(0x80369FFF),
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_5,
              color: Colors.black.withOpacity(.4),
              offset: Offset(AppDimensions.dim2, AppDimensions.dim2),
            )
          ],
          border: Border.all(
            color: AppColors.lightgray,
            width: AppDimensions.dim3.w,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radius_10),
        ),
      ),
    );
  }

  Widget _buildOTPTimer() {
    return Column(
      children: [
        if (_isTimerActive) ...[
          RichText(
            text: TextSpan(
              text: AppStrings.youCanResendTheCodeIn,
              style: TextStyle(
                color: AppColors.black,
                fontSize: AppFontStyles.fontSize_18.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
              children: [
                TextSpan(
                  text: " $_remainingSeconds ",
                  style: TextStyle(
                    color: AppColors.mintGreenColor,
                    fontSize: AppFontStyles.fontSize_18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                  ),
                ),
                TextSpan(
                  text: AppStrings.seconds,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: AppFontStyles.fontSize_18.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.fontWeightVariation600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppDimensions.dim16.h),
        ],
        GestureDetector(
          onTap: _isTimerActive ? null : _resendOTP,
          child: Text(
            AppStrings.resendOTP,
            style: TextStyle(
              color: _isTimerActive ? AppColors.greyColor : AppColors.steelblue,
              fontSize: AppFontStyles.fontSize_18.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.fontWeightVariation600],
            ),
          ),
        ),
      ],
    );
  }
}

//=== IGNORE BELOW THIS LINE --- OLD CODE --- IGNORE BELOW THIS LINE ===

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/helpers/shared_pref_helper.dart';
// import 'package:hydrify/screens/auth/reset_password_screen.dart';
// import 'package:hydrify/screens/user_personal_info_input_screen..dart';
// import 'package:hydrify/screens/widgets/auth_button_widget.dart';
// import 'package:hydrify/services/firebase_functions_service.dart';
// import 'package:hydrify/services/ui_utils_service.dart';
// import 'package:pinput/pinput.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   OtpVerificationScreen(
//       {super.key, required this.userEmail, this.isResetPassFlow = false});

//   final String userEmail;
//   bool isResetPassFlow;

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   final TextEditingController _otpController = TextEditingController();
//   Timer? _timer;
//   int _remainingSeconds = 60; // Start with 60 seconds
//   bool _isTimerActive = true;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _otpController.dispose();
//     super.dispose();
//   }

//   void _startTimer() {
//     setState(() {
//       _remainingSeconds = 60; // Reset to 60 seconds
//       _isTimerActive = true;
//     });

//     _timer?.cancel(); // Cancel any existing timer
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (_remainingSeconds > 0) {
//         setState(() {
//           _remainingSeconds--;
//         });
//       } else {
//         setState(() {
//           _isTimerActive = false;
//         });
//         timer.cancel();
//       }
//     });
//   }

//   void _resendOTP() async {
//     UiUtilsService.showLoading(context, "Resending OTP");

//     var resendResponse =
//         await FirebaseFunctionsService.resendOTP(widget.userEmail);

//     UiUtilsService.dismissLoading(context);
//     if (resendResponse["status"] == "success" &&
//         resendResponse["statusCode"] == 200) {
//       UiUtilsService.showToast(
//           context: context, text: resendResponse["message"]);
//       _startTimer();
//     } else {
//       UiUtilsService.showToast(
//           context: context,
//           text: resendResponse["message"] ?? "Unexpected error occurred");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       extendBody: true,
//       appBar: AppBar(
//         elevation: 0.0,
//         backgroundColor: Colors.transparent,
//         centerTitle: true,
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
//       body: Container(
//         width: double.maxFinite,
//         padding: EdgeInsets.only(
//           top: AppDimensions.padding_20.h,
//           left: AppDimensions.dim33.w,
//           right: AppDimensions.dim33.w,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [AppColors.gradientStart, AppColors.gradientEnd],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: AppDimensions.dim100.h,
//             ),
//             _buildGreeting(),
//             SizedBox(
//               height: AppDimensions.dim29.h,
//             ),
//             _buildInputField(context),
//             SizedBox(
//               height: AppDimensions.dim29.h,
//             ),
//             Align(
//               alignment: Alignment.center,
//               child: _buildOTPTimer(),
//             ),
//             SizedBox(
//               height: AppDimensions.dim24.h,
//             ),
//             AuthButton(
//               text: AppStrings.signUp,
//               color: AppColors.blueGradient,
//               areTwoItems: false,
//               onTap: () async {
//                 if (_otpController.text.isEmpty) {
//                   if (widget.isResetPassFlow == true) {
//                     UiUtilsService.showLoading(context, "Verifying OTP");
//                     var verifyOTPResponse =
//                         await FirebaseFunctionsService.verifyResetOTPOnly(
//                       widget.userEmail,
//                       int.parse(
//                         "7194",
//                       ),
//                     );
//                     UiUtilsService.dismissLoading(context);

//                     if (verifyOTPResponse["status"] == "success" &&
//                         verifyOTPResponse["statusCode"] == 200) {
//                       UiUtilsService.showToast(
//                           context: context, text: verifyOTPResponse["message"]);

//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ResetPasswordScreen(
//                             userEmail: widget.userEmail,
//                           ),
//                         ),
//                       );
//                     } else {
//                       UiUtilsService.showToast(
//                           context: context,
//                           text: verifyOTPResponse["message"] ??
//                               "Unexpected error occurred");
//                     }
//                   } else {
//                     UiUtilsService.showLoading(context, "Sign up");

//                     var verifyOtpResponse =
//                         await FirebaseFunctionsService.verifySignupOTP(
//                       widget.userEmail,
//                       int.parse("7194"),
//                     );
//                     UiUtilsService.dismissLoading(
//                       context,
//                     );
//                     if (verifyOtpResponse["status"] == "success" &&
//                         verifyOtpResponse["statusCode"] == 200) {
//                       UiUtilsService.showToast(
//                           context: context, text: verifyOtpResponse["message"]);
//                       await SharedPrefsHelper.setUserEmail(widget.userEmail);
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => UserInfoInputScreen(),
//                         ),
//                       );
//                     } else {
//                       UiUtilsService.showToast(
//                           context: context,
//                           text: verifyOtpResponse["message"] ??
//                               "Unexpected error occurred");
//                     }
//                   }
//                 } else {
//                   UiUtilsService.showToast(
//                       context: context, text: "Please enter valid OTP");
//                 }
//               },
//             ),
//           ],
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
//           AppStrings.enterOTP,
//           style: TextStyle(
//             color: AppColors.white,
//             height: AppFontStyles.getLineHeight(
//                 AppFontStyles.fontSize_24.sp, AppFontStyles.lineHeight_160),
//             fontFamily: AppFontStyles.museoModernoFontFamily,
//             fontSize: AppFontStyles.fontSize_24.sp,
//             fontVariations: [
//               AppFontStyles.boldFontVariation,
//             ],
//           ),
//         ),
//         Text(
//           AppStrings.weHaveSentOTP,
//           style: TextStyle(
//             color: AppColors.white,
//             fontSize: AppFontStyles.fontSize_16,
//             height: AppFontStyles.getLineHeight(
//                 AppFontStyles.fontSize_16, AppFontStyles.lineHeight_160),
//             fontFamily: AppFontStyles.museoModernoFontFamily,
//             fontVariations: [
//               AppFontStyles.regularFontVariation,
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInputField(BuildContext context) {
//     return Pinput(
//       controller: _otpController,
//       length: 4,
//       onCompleted: (value) async {},
//       separatorBuilder: (index) {
//         return SizedBox(
//           width: AppDimensions.defaultPadding.w,
//         );
//       },
//       defaultPinTheme: PinTheme(
//         width: AppDimensions.dim83.w,
//         height: AppDimensions.dim70.h,
//         textStyle: TextStyle(
//             fontSize: AppFontStyles.fontSize_24.sp,
//             color: Colors.black,
//             fontFamily: AppFontStyles.urbanistFontFamily,
//             fontVariations: [
//               AppFontStyles.boldFontVariation,
//             ]),
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           boxShadow: [
//             BoxShadow(
//               blurRadius: AppDimensions.radius_5,
//               color: Colors.black.withOpacity(.4),
//               offset: Offset(AppDimensions.dim5, AppDimensions.dim5),
//             )
//           ],
//           borderRadius: BorderRadius.circular(
//             AppDimensions.dim12,
//           ),
//         ),
//       ),
//       focusedPinTheme: PinTheme(
//         width: AppDimensions.dim83.w,
//         height: AppDimensions.dim70.h,
//         decoration: BoxDecoration(
//           color: Color(0XFF806A96),
//           boxShadow: [
//             BoxShadow(
//               blurRadius: AppDimensions.radius_5,
//               color: Colors.black.withOpacity(.4),
//               offset: Offset(AppDimensions.dim5, AppDimensions.dim5),
//             )
//           ],
//           border: Border.all(
//             color: AppColors.mintGreenColor,
//             width: AppDimensions.dim2.w,
//           ),
//           borderRadius: BorderRadius.circular(
//             AppDimensions.radius_10,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildOTPTimer() {
//     return Column(
//       children: [
//         // Timer text - only visible when timer is active
//         if (_isTimerActive) ...[
//           RichText(
//             text: TextSpan(
//               text: AppStrings.youCanResendTheCodeIn,
//               style: TextStyle(
//                 color: AppColors.white,
//                 fontSize: AppFontStyles.fontSize_18.sp,
//                 fontFamily: AppFontStyles.urbanistFontFamily,
//                 fontVariations: [
//                   AppFontStyles.regularFontVariation,
//                 ],
//               ),
//               children: [
//                 TextSpan(
//                   text: "$_remainingSeconds",
//                   style: TextStyle(
//                     color: AppColors.mintGreenColor,
//                     fontSize: AppFontStyles.fontSize_18.sp,
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [
//                       AppFontStyles.regularFontVariation,
//                     ],
//                   ),
//                 ),
//                 TextSpan(
//                   text: AppStrings.seconds,
//                   style: TextStyle(
//                     color: AppColors.white,
//                     fontSize: AppFontStyles.fontSize_18.sp,
//                     fontFamily: AppFontStyles.urbanistFontFamily,
//                     fontVariations: [
//                       AppFontStyles.regularFontVariation,
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//           SizedBox(
//             height: AppDimensions.dim16.h,
//           ),
//         ],
//         // Resend button - only clickable when timer is not active
//         GestureDetector(
//           onTap: _isTimerActive ? null : _resendOTP,
//           child: Text(
//             AppStrings.resendOTP,
//             style: TextStyle(
//               color:
//                   _isTimerActive ? Colors.grey : AppColors.secondaryMintGreen,
//               fontSize: AppFontStyles.fontSize_18.sp,
//               fontFamily: AppFontStyles.urbanistFontFamily,
//               fontVariations: [
//                 AppFontStyles.fontWeightVariation600,
//               ],
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }
