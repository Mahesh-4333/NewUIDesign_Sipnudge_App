import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/auth_options_screen.dart';
import 'package:hydrify/screens/user_lifestyle_info_input_screen.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_cupertino_input_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_radio_selection_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/next_button_widget.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class UserInfoInputScreen extends StatefulWidget {
  final bool fromSettings;
  const UserInfoInputScreen({
    super.key,
    this.fromSettings = false,
  });

  @override
  State<UserInfoInputScreen> createState() => _UserInfoInputScreenState();
}

class _UserInfoInputScreenState extends State<UserInfoInputScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UserInfoCubit>().loadUser();
    context
        .read<UserInfoCubit>()
        .setAchievmentSnackbarStatus(!widget.fromSettings);
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final saved = await SharedPrefsHelper.getUserName();
    if (saved != null && saved.isNotEmpty) {
      _nameController.text = saved;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // <<< FIX: allow pop only when opened from Settings
      canPop: widget.fromSettings,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: Container(
          height: AppDimensions.dim60,
          margin: EdgeInsets.only(
            left: AppDimensions.defaultPadding.w,
            right: AppDimensions.defaultPadding.w,
            bottom: AppDimensions.defaultPadding.w,
          ),
          child: BlocBuilder<UserInfoCubit, UserInfoState>(
            builder: (context, state) {
              return CustomNextButton(
                  text: AppStrings.next,
                  onNextPressed: () async {
                    final height = state.height;
                    final weight = state.weight;
                    final age = state.age;

                    if (height == null || weight == null || age == null) {
                      UiUtilsService.showToast(
                        context: context,
                        text:
                            "Please fill in height, weight, and age before continuing.",
                        textColor: Colors.red,
                      );
                      return;
                    }

                    // Save name to SharedPrefs + cubit
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      await SharedPrefsHelper.setUserName(name);
                      if (context.mounted) {
                        context.read<UserInfoCubit>().setName(name);
                      }
                    }

                    if (!context.mounted) return;
                    // From onboarding → continue next flow
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserLifestyleInfoInputScreen(
                          isViaSettingsScreen: widget.fromSettings,
                        ),
                      ),
                    );
                  });
            },
          ),
        ),
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            AppStrings.personalInformation,
            style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_AppBar,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [
                  AppFontStyles.boldFontVariation,
                ]),
          ),
          leadingWidth: AppDimensions.dim85.w,
          leading: IconButton(
            onPressed: () async {
              if (widget.fromSettings) {
                // If opened from settings, simply pop back
                Navigator.pop(context);
              } else {
                // If onboarding flow, clear prefs and go to AuthOptionsScreen
                await SharedPrefsHelper.clearAll();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AuthOptionsScreen()),
                    (route) => false);
              }
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
          ),
          padding: EdgeInsets.only(
            top: AppDimensions.dim120.h,
          ),
          child: ListView(
            padding: EdgeInsets.all(
              AppDimensions.defaultPadding,
            ),
            children: [
              // ── Gender ──────────────────────────────────────────────────
              Text(
                AppStrings.whatsYourGender,
                style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    height: AppFontStyles.getLineHeight(
                        AppFontStyles.fontSize_16, 160),
                    color: AppColors.bluegray,
                    fontVariations: [
                      AppFontStyles.fontWeightVariation600,
                    ]),
              ),
              SizedBox(
                height: AppDimensions.dim20.h,
              ),
              CustomRadioSelectionWidget(
                type: 1,
              ),
              SizedBox(
                height: AppDimensions.dim32.h,
              ),
              Text(
                AppStrings.howTall,
                style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    color: AppColors.bluegray,
                    fontVariations: [
                      AppFontStyles.fontWeightVariation600,
                    ]),
              ),
              SizedBox(
                height: AppDimensions.dim20.h,
              ),
              BlocBuilder<UserInfoCubit, UserInfoState>(
                builder: (context, state) {
                  final selectedDisplay = (state.displayHeight).isEmpty
                      ? null
                      : state.displayHeight;

                  int cmInitial =
                      state.height != null ? state.height!.round() : 170;
                  final int totalInches = state.height != null
                      ? (state.height! / 2.54).round()
                      : 65; // default 65in
                  final int ftInitial = totalInches ~/ 12;
                  final int inInitial = totalInches % 12;

                  return CustomCupertinoInputWidget(
                    title: AppStrings.heightSelection,
                    placeholderText: AppStrings.enterHeight,
                    leftToggleLabel: "ft",
                    rightToggleLabel: "cm",
                    defaultToggleValue: state.heightUnit ?? "cm",
                    primaryInitialValue: cmInitial,
                    primaryMinValue: 50,
                    primaryMaxValue: 250,
                    primaryInitialFt: ftInitial,
                    primaryMinFt: 3,
                    primaryMaxFt: 8,
                    hasSecondaryValue: false,
                    secondaryInitialValue: inInitial,
                    secondaryMinValue: 0,
                    secondaryMaxValue: 11,
                    selectedValue: selectedDisplay,
                    onUnitChanged: (unit) {
                      final cubit = context.read<UserInfoCubit>();
                      final state = cubit.state;

                      if (state.height == null) {
                        cubit.updateHeight(unit: unit);
                        return;
                      }

                      cubit.updateHeight(height: state.height, unit: unit);
                    },
                    onValueSelected: (result) {
                      if (result["suffix"] == "cm") {
                        final int cmValue = result["primaryValue"];
                        context
                            .read<UserInfoCubit>()
                            .setHeight(cmValue.toDouble(), "cm");
                      } else {
                        final int feet = result["primaryValue"];
                        final int inches = result["secondaryValue"] ?? 0;
                        context
                            .read<UserInfoCubit>()
                            .setHeight(feet.toDouble(), "ft", inches: inches);
                      }
                    },
                  );
                },
              ),
              SizedBox(
                height: AppDimensions.dim20.h,
              ),
              Text(
                AppStrings.howMuchWeight,
                style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    color: AppColors.bluegray,
                    fontVariations: [
                      AppFontStyles.fontWeightVariation600,
                    ]),
              ),
              SizedBox(
                height: AppDimensions.dim20.h,
              ),
              BlocBuilder<UserInfoCubit, UserInfoState>(
                builder: (context, state) {
                  final displayValue = state.displayWeight;

                  return CustomCupertinoInputWidget(
                    title: AppStrings.weightSelection,
                    placeholderText: AppStrings.enterYourWeight,
                    leftToggleLabel: "kg",
                    rightToggleLabel: "lbs",
                    defaultToggleValue: "kg",
                    primaryInitialValue: 40,
                    primaryMinValue: 20,
                    primaryMaxValue: 300,
                    selectedValue: displayValue,
                    hasSecondaryValue: false,
                    onUnitChanged: (value) {
                      context.read<UserInfoCubit>().updateWeight(unit: value);
                    },
                    onValueSelected: (result) {
                      final int userWeight = result["primaryValue"] ?? 0;
                      final String weightUnit = result["suffix"] ?? "kg";
                      context
                          .read<UserInfoCubit>()
                          .setWeight(userWeight.toDouble(), weightUnit);
                    },
                  );
                },
              ),
              SizedBox(
                height: AppDimensions.dim20.h,
              ),
              Text(
                AppStrings.whatIsYourAge,
                style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    color: AppColors.bluegray,
                    fontVariations: [
                      AppFontStyles.fontWeightVariation600,
                    ]),
              ),
              SizedBox(
                height: AppDimensions.dim20.h,
              ),
              BlocBuilder<UserInfoCubit, UserInfoState>(
                builder: (context, state) {
                  final selectedAge = state.age;

                  final displayValue = (selectedAge != null)
                      ? selectedAge.toStringAsFixed(0)
                      : null;
                  return CustomCupertinoInputWidget(
                    title: AppStrings.ageSelection,
                    placeholderText: AppStrings.enterYourAge,
                    leftToggleLabel: "",
                    rightToggleLabel: "",
                    defaultToggleValue: "",
                    suffix: "",
                    primaryInitialValue: 30,
                    primaryMinValue: 10,
                    primaryMaxValue: 150,
                    selectedValue: displayValue,
                    onUnitChanged: (value) {},
                    onValueSelected: (result) {
                      final int userAge = result["primaryValue"] ?? 0;
                      context.read<UserInfoCubit>().setAge(userAge);
                    },
                    unitSelectionRequired: false,
                  );
                },
              ),
              SizedBox(height: AppDimensions.dim32.h),
              // ── Name field ──────────────────────────────────────────────
              Text(
                "What's your name?",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_16,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
              ),
              SizedBox(height: AppDimensions.dim20.h),
              Container(
                padding: EdgeInsets.all(AppDimensions.dim12.w),
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  border: Border.all(
                    color: AppColors.lightgray,
                    width: AppDimensions.dim1,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radius_25),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: AppDimensions.dim4,
                      color: Colors.black.withOpacity(.4),
                      offset:
                          Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    fontVariations: [AppFontStyles.regularFontVariation],
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_16,
                      fontVariations: [AppFontStyles.regularFontVariation],
                      color: const Color(0xCCCFCFCF),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.dim100.h),
            ],
          ),
        ),
      ),
    );
  }
}
