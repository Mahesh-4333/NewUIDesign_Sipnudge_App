import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/signin_signup_screen.dart';
import 'package:hydrify/screens/info/privacy_policy_screen.dart';
import 'package:hydrify/screens/info/terms_of_service.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/services/firebase_functions_service.dart';
import 'package:hydrify/services/google_calendar_manager.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({super.key});

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await GoogleCalendarManager().signOut();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.padding33.w),
          child: Column(
            children: [
              SizedBox(
                height: AppDimensions.dim168.h,
              ),
              Image.asset(
                "assets/images/sipnudge1.png",
                width: AppDimensions.dim233.w,
                height: AppDimensions.dim51.h,
              ),
              SizedBox(
                height: AppDimensions.dim25.h,
              ),
              Text(
                AppStrings.beginYourJourney,
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_20.sp,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ],
                  // shadows: [
                  //   Shadow(
                  //     blurRadius: AppDimensions.dim10,
                  //     color: Colors.black.withOpacity(.2),
                  //     offset: Offset(
                  //       0,
                  //       AppDimensions.dim3,
                  //     ),
                  //   )
                  // ]
                ),
              ),
              SizedBox(
                height: AppDimensions.dim12.h,
              ),
              Text(
                AppStrings.letsDive,
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_16.sp,
                  fontVariations: [
                    AppFontStyles.regularFontVariation,
                  ],
                  // shadows: [
                  //   Shadow(
                  //     blurRadius: AppDimensions.dim5,
                  //     color: Colors.black.withOpacity(.2),
                  //     offset: Offset(
                  //       0,
                  //       AppDimensions.dim3,
                  //     ),
                  //   )
                  // ]
                ),
              ),
              SizedBox(
                height: AppDimensions.dim33.h,
              ),
              AuthButton(
                iconPath: "assets/images/google_ic.svg",
                text: AppStrings.continueWithGoogle,
                color: AppColors.white,
                onTap: () async {
                  UiUtilsService.showLoading(
                      context, "Signing you in via Google");
                  var signInWithGoogleRes =
                      await FirebaseFunctionsService.signInWithGoogle();
                  UiUtilsService.dismissLoading(context);
                  if (signInWithGoogleRes != null) {
                    SharedPrefsHelper.setUserEmail(
                        signInWithGoogleRes.user?.email ?? "");
                    UiUtilsService.showToast(
                        context: context, text: "Signin Successful");

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserInfoInputScreen(
                          fromSettings: false,
                        ),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
              // Divider for Android only
              if (!Platform.isIOS)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDimensions.dim20.h,
                    horizontal: AppDimensions.dim16.w,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.lightgray,
                          thickness: 2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Text(
                          "or",
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: AppFontStyles.fontSize_18.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.lightgray,
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              Visibility(
                visible: Platform.isIOS,
                child: Column(
                  children: [
                    SizedBox(height: AppDimensions.dim20.h),
                    AuthButton(
                      iconPath: "assets/images/apple_icon.svg",
                      text: AppStrings.continueWithApple,
                      color: AppColors.white,
                      onTap: () async {
                        UiUtilsService.showLoading(
                            context, "Signing you in via Apple");
                        var signInWithAppleRes =
                            await FirebaseFunctionsService.signInWithApple();

                        UiUtilsService.dismissLoading(context);
                        if (signInWithAppleRes['success'] == true) {
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
                    // Divider for iOS only
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.dim20.h,
                        horizontal: AppDimensions.dim33.w,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.lightgray,
                              thickness: 2,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              "or",
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: AppFontStyles.fontSize_18.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.semiBoldFontVariation
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.lightgray,
                              thickness: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDimensions.dim7.h),
              AuthButton(
                text: AppStrings.signUp,
                color: AppColors.blueGradient,
                areTwoItems: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SigninSignupScreen(
                        isSigninFlow: false,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppDimensions.dim20.h),
              AuthButton(
                text: AppStrings.signIn,
                color: AppColors.blueSecondary,
                textColor: AppColors.buttonTextPurpleColor,
                areTwoItems: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SigninSignupScreen(
                        isSigninFlow: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: AppDimensions.padding_30.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacyPolicyScreen(),
                  ),
                );
              },
              child: Text(
                AppStrings.privacyPolicy,
                style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: AppColors.white,
                    fontSize: AppFontStyles.fontSize_14.sp,
                    fontVariations: [
                      AppFontStyles.regularFontVariation,
                    ]),
              ),
            ),
            SizedBox(
              width: AppDimensions.dim20.w,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TermsOfServiceScreen(),
                  ),
                );
              },
              child: Text(
                AppStrings.termsOfService,
                style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: AppColors.white,
                    fontSize: AppFontStyles.fontSize_14.sp,
                    fontVariations: [
                      AppFontStyles.regularFontVariation,
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
