import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/signin_signup_screen.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/auth_button_widget.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/firebase_functions_service.dart';
import 'package:hydrify/services/google_calendar_manager.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum LinkType { privacy, terms }

class AuthOptionsScreen extends StatefulWidget {
  const AuthOptionsScreen({super.key});

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  bool _isTermsAccepted = false;

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
                height: AppDimensions.dim180.h,
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
                AppLocalizations.of(context)?.beginYourJourney ??
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
                AppLocalizations.of(context)?.letsDive ?? AppStrings.letsDive,
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
              Opacity(
                opacity: _isTermsAccepted ? 1.0 : 0.6,
                child: AuthButton(
                  iconPath: "assets/images/google_ic.svg",
                  text: AppLocalizations.of(context)?.continueWithGoogle ??
                      AppStrings.continueWithGoogle,
                  color: AppColors.white,
                  onTap: () async {
                    if (!_isTermsAccepted) {
                      UiUtilsService.showToast(
                          context: context,
                          text:
                              AppLocalizations.of(context)?.pleaseAcceptTerms ??
                                  "Please accept the terms and conditions");
                      return;
                    }
                    UiUtilsService.showLoading(
                        context,
                        AppLocalizations.of(context)?.signingInGoogle ??
                            "Signing you in via Google");
                    var signInWithGoogleRes =
                        await FirebaseFunctionsService.signInWithGoogle();
                    UiUtilsService.dismissLoading(context);
                    if (signInWithGoogleRes != null) {
                      final email = signInWithGoogleRes.user?.email ?? "";
                      await SharedPrefsHelper.setUserEmail(email);

                      if (email.isNotEmpty) {
                        try {
                          final userData =
                              await ApiService().getUserByEmail(email);
                          if (userData != null && userData['_id'] != null) {
                            await SharedPrefsHelper.setUserId(userData['_id']);
                            Console.log(
                                tag: "AUTH",
                                value:
                                    "Google Login: UserId saved: ${userData['_id']}");
                          }
                        } catch (e) {
                          Console.log(
                              tag: "AUTH",
                              value:
                                  "Failed to fetch user by email on Google login: $e");
                        }
                      }

                      UiUtilsService.showToast(
                          context: context,
                          text:
                              AppLocalizations.of(context)?.signinSuccessful ??
                                  "Signin Successful");

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
              ),

              SizedBox(
                height: AppDimensions.dim20.h,
              ),

              // Continue as Guest button for ANDROID (below Google)
              // if (!Platform.isIOS)
              //   AuthButton(
              //     text: "Continue as Guest",
              //     gradient: AppColors.guestButtonColor,
              //     textColor: AppColors.buttonTextPurpleColor,
              //     areTwoItems: false,
              //     borderColor: AppColors.bluegray,
              //     onTap: () {
              //       SharedPrefsHelper.setUserEmail("guest_user");
              //     },
              //   ),
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
                    Opacity(
                      opacity: _isTermsAccepted ? 1.0 : 0.6,
                      child: AuthButton(
                        iconPath: "assets/images/apple_icon.svg",
                        text: AppLocalizations.of(context)?.continueWithApple ??
                            AppStrings.continueWithApple,
                        color: AppColors.white,
                        onTap: () async {
                          if (!_isTermsAccepted) {
                            UiUtilsService.showToast(
                                context: context,
                                text: AppLocalizations.of(context)
                                        ?.pleaseAcceptTerms ??
                                    "Please accept the terms and conditions");
                            return;
                          }
                          UiUtilsService.showLoading(
                              context,
                              AppLocalizations.of(context)?.signingInApple ??
                                  "Signing you in via Apple");
                          var signInWithAppleRes =
                              await FirebaseFunctionsService.signInWithApple();

                          UiUtilsService.dismissLoading(context);
                          if (signInWithAppleRes['success'] == true) {
                            final userCredential =
                                signInWithAppleRes['userCredential']
                                    as UserCredential?;
                            final email = userCredential?.user?.email;
                            if (email != null && email.isNotEmpty) {
                              await SharedPrefsHelper.setUserEmail(email);
                              try {
                                final userData =
                                    await ApiService().getUserByEmail(email);
                                if (userData != null &&
                                    userData['_id'] != null) {
                                  await SharedPrefsHelper.setUserId(
                                      userData['_id']);
                                  Console.log(
                                      tag: "AUTH",
                                      value:
                                          "Apple Login: UserId saved: ${userData['_id']}");
                                }
                              } catch (e) {
                                Console.log(
                                    tag: "AUTH",
                                    value:
                                        "Failed to fetch user by email on Apple login: $e");
                              }
                            }

                            UiUtilsService.showToast(
                                context: context,
                                text: AppLocalizations.of(context)
                                        ?.signinSuccessful ??
                                    "Signin Successful");

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
                    ),
                    SizedBox(height: AppDimensions.dim20.h),
                    // // Continue as Guest button for iOS (after Apple button)
                    // AuthButton(
                    //   text: "Continue as Guest",
                    //   gradient: AppColors.guestButtonColor,
                    //   textColor: AppColors.buttonTextPurpleColor,
                    //   areTwoItems: false,
                    //   borderColor: AppColors.bluegray,
                    //   onTap: () {
                    //     SharedPrefsHelper.setUserEmail("guest_user");

                    //     UiUtilsService.showToast(
                    //       context: context,
                    //       text: "Continuing as Guest",
                    //     );

                    //     Navigator.pushAndRemoveUntil(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => UserInfoInputScreen(),
                    //       ),
                    //       (route) => false,
                    //     );
                    //   },
                    // ),
                    // // Divider for iOS only
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
              Opacity(
                opacity: _isTermsAccepted ? 1.0 : 0.6,
                child: AuthButton(
                  text:
                      AppLocalizations.of(context)?.signUp ?? AppStrings.signUp,
                  color: AppColors.blueGradient,
                  areTwoItems: false,
                  onTap: () {
                    if (!_isTermsAccepted) {
                      UiUtilsService.showToast(
                          context: context,
                          text:
                              AppLocalizations.of(context)?.pleaseAcceptTerms ??
                                  "Please accept the terms and conditions");
                      return;
                    }
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
              ),
              SizedBox(height: AppDimensions.dim20.h),
              Opacity(
                opacity: _isTermsAccepted ? 1.0 : 0.6,
                child: AuthButton(
                  text:
                      AppLocalizations.of(context)?.signIn ?? AppStrings.signIn,
                  color: AppColors.blueSecondary,
                  textColor: AppColors.buttonTextPurpleColor,
                  areTwoItems: false,
                  onTap: () {
                    if (!_isTermsAccepted) {
                      UiUtilsService.showToast(
                          context: context,
                          text:
                              AppLocalizations.of(context)?.pleaseAcceptTerms ??
                                  "Please accept the terms and conditions");
                      return;
                    }
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
              ),
              SizedBox(height: AppDimensions.dim32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: AppDimensions.dim32.w,
                    height: AppDimensions.dim32.w,
                    child: Checkbox(
                      checkColor: AppColors.white,
                      activeColor: AppColors.lightBlue400,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radius_5.w),
                      ),
                      side: BorderSide(
                        color: AppColors.lightBlue400,
                        width: AppDimensions.dim3.w,
                      ),
                      value: _isTermsAccepted,
                      onChanged: (newValue) {
                        setState(() {
                          _isTermsAccepted = newValue ?? false;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: AppDimensions.dim12.w),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isTermsAccepted = !_isTermsAccepted;
                      });
                    },
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        text: AppLocalizations.of(context)?.iAgreeToThe ??
                            "I agree to the ",
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: AppFontStyles.fontSize_15.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            AppFontStyles.semiBoldFontVariation,
                          ],
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () =>
                                  _launchURL("https://sipnudge.com/terms"),
                              child: Text(
                                AppLocalizations.of(context)?.termsOfService ??
                                    "Terms of Service",
                                style: TextStyle(
                                  color: AppColors.blueGradient,
                                  fontSize: AppFontStyles.fontSize_15.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.semiBoldFontVariation,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          TextSpan(text: " & "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () =>
                                  _launchURL("https://sipnudge.com/privacy"),
                              child: Text(
                                AppLocalizations.of(context)?.privacyPolicy ??
                                    "Privacy Policy",
                                style: TextStyle(
                                  color: AppColors.blueGradient,
                                  fontSize: AppFontStyles.fontSize_15.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.semiBoldFontVariation,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),

              /// 🔹 FOOTER TEXT
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: 25.h),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/app_background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: AppFontStyles.fontSize_13,
                          color: Colors.black,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          fontFamily: AppFontStyles.urbanistFontFamily),
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context)?.privacyPolicy ??
                              'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: AppFontStyles.fontSize_13,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _onFooterLinkTap(LinkType.privacy);
                            },
                        ),
                        TextSpan(
                          text: '     .     ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)?.termsOfService ??
                              'Terms of Service',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: AppFontStyles.fontSize_13,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _onFooterLinkTap(LinkType.terms);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
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
              onTap: () => _launchURL("https://sipnudge.com/privacy"),
              child: Text(
                AppLocalizations.of(context)?.privacyPolicy ??
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
              onTap: () => _launchURL("https://sipnudge.com/terms"),
              child: Text(
                AppLocalizations.of(context)?.termsOfService ??
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

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)?.couldNotOpenWebpage ??
                  "Could not open the webpage")),
        );
      }
    }
  }

  void _onFooterLinkTap(LinkType type) {
    _launchURL(type == LinkType.privacy
        ? "https://sipnudge.com/privacy"
        : "https://sipnudge.com/terms");
  }
}
