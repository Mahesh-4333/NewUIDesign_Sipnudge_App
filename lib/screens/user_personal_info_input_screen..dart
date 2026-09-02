import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/page_transitions.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/auth/auth_options_screen.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/screens/user_lifestyle_info_input_screen.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_cupertino_input_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_radio_selection_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/next_button_widget.dart';
import 'package:hydrify/services/ui_utils_service.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/helpers/logger.dart';

import 'package:hydrify/services/health_service.dart';

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
  final FocusNode _nameFocusNode = FocusNode();
  bool _isKeyboardVisible = false;
  bool _isUsernameReadOnly = false;

  Timer? _debounce;
  String? _usernameError;
  bool _isCheckingUsername = false;
  bool _isUsernameValid = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onFocusChange);
    _loadInitialUserData();
  }

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _nameFocusNode.hasFocus && !_isUsernameReadOnly;
    });
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final name = value.trim();
    if (name.isEmpty) {
      setState(() {
        _usernameError = null;
        _isUsernameValid = false;
        _isCheckingUsername = false;
      });
      return;
    }

    final regex = RegExp(r'^[a-zA-Z0-9]{3,15}$');
    if (!regex.hasMatch(name)) {
      setState(() {
        _usernameError = AppLocalizations.of(context)?.usernameRequirements ??
            "3-15 alphanumeric characters only.";
        _isUsernameValid = false;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
      _isUsernameValid = false;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final userId = await SharedPrefsHelper.getUserId();
      final isUnique = await ApiService().checkNameUniqueness(name, userId);
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        if (isUnique) {
          _isUsernameValid = true;
          _usernameError = null;
        } else {
          _isUsernameValid = false;
          _usernameError = AppLocalizations.of(context)?.usernameTaken ??
              "Username is already taken.";
        }
      });
    });
  }

  Future<void> _loadInitialUserData() async {
    final cubit = context.read<UserInfoCubit>();
    await cubit.loadUser();

    // if (cubit.state.name != null && cubit.state.name!.isNotEmpty) {
    //   setState(() {
    //     _isUsernameReadOnly = true;
    //     _nameController.text = cubit.state.name!;
    //   });
    // }

    // if (cubit.state.height == null ||
    //     cubit.state.weight == null ||
    //     cubit.state.name == null) {

    // }

    final email = await SharedPrefsHelper.getUserEmail();
    if (email != null && email.isNotEmpty && email != "guest_user") {
      try {
        final serverData = await ApiService().getUserByEmail(email);
        Console.log(
            tag: "USER_INFO",
            value: "Fetched user profile from server: $serverData");
        if (serverData != null && serverData['exists'] == true) {
          if (serverData['_id'] != null) {
            await SharedPrefsHelper.setUserId(serverData['_id']);
            Console.log(
                tag: "USER_INFO",
                value: "Saved userId from server profile: ${serverData['_id']}");
          }
          final genderStr = serverData['gender']?.toString().toLowerCase();
          Gender gender = Gender.male;
          if (genderStr == 'female')
            gender = Gender.female;
          else if (genderStr == 'prefernottosay' ||
              genderStr == 'prefer_not_to_say') gender = Gender.preferNotToSay;

          final activityStr =
              serverData['activityLevel']?.toString().toLowerCase();
          ActivityLevel activity = ActivityLevel.lightActivity;
          if (activityStr == 'sedentary')
            activity = ActivityLevel.sedentary;
          else if (activityStr == 'midactive' || activityStr == 'mid_active')
            activity = ActivityLevel.midActive;
          else if (activityStr == 'veryactive' || activityStr == 'very_active')
            activity = ActivityLevel.veryActive;

          final dietStr = serverData['dietType']?.toString().toLowerCase();
          DietType diet = DietType.balanced;
          if (dietStr == 'vegetarian')
            diet = DietType.vegetarian;
          else if (dietStr == 'processed')
            diet = DietType.processed;
          else if (dietStr == 'highprotein' || dietStr == 'high_protein')
            diet = DietType.highProtein;

          final coffeeStr =
              serverData['coffeeIntake']?.toString().toLowerCase();
          BeverageIntake coffee = BeverageIntake.none;
          if (coffeeStr == 'onetotwo' || coffeeStr == 'one_to_two')
            coffee = BeverageIntake.oneToTwo;
          else if (coffeeStr == 'threetofour' || coffeeStr == 'three_to_four')
            coffee = BeverageIntake.threeToFour;
          else if (coffeeStr == 'fiveplus' || coffeeStr == 'five_plus')
            coffee = BeverageIntake.fivePlus;

          final teaStr = serverData['teaIntake']?.toString().toLowerCase();
          BeverageIntake tea = BeverageIntake.none;
          if (teaStr == 'onetotwo' || teaStr == 'one_to_two')
            tea = BeverageIntake.oneToTwo;
          else if (teaStr == 'threetofour' || teaStr == 'three_to_four')
            tea = BeverageIntake.threeToFour;
          else if (teaStr == 'fiveplus' || teaStr == 'five_plus')
            tea = BeverageIntake.fivePlus;

          final double? height = serverData['height'] != null
              ? (serverData['height'] as num).toDouble()
              : null;
          final double? weight = serverData['weight'] != null
              ? (serverData['weight'] as num).toDouble()
              : null;
          final int? age = serverData['age'] != null
              ? (serverData['age'] as num).toInt()
              : null;
          final String? name = serverData['userName'];

          final newState = UserInfoState(
            gender: gender,
            height: height,
            heightUnit: serverData['heightUnit'] ?? 'cm',
            weight: weight,
            weightUnit: serverData['weightUnit'] ?? 'kg',
            age: age,
            name: name,
            wakeupHour: serverData['wakeupHour'],
            wakeupMinute: serverData['wakeupMinute'],
            wakeupPeriod: serverData['wakeupPeriod'],
            bedtimeHour: serverData['bedtimeHour'],
            bedtimeMinute: serverData['bedtimeMinute'],
            bedtimePeriod: serverData['bedtimePeriod'],
            activityLevel: activity,
            dietType: diet,
            stepGoal: serverData['stepGoal'],
            coffeeIntake: coffee,
            teaIntake: tea,
            typicalWaterIntake: serverData['typicalWaterIntake'] != null
                ? (serverData['typicalWaterIntake'] as num).toDouble()
                : null,
            waterUnit: serverData['waterUnit'] ?? 'mL',
          );

          cubit.emit(newState);
          await cubit.saveUser(newState);

          if (name != null && name.isNotEmpty) {
            setState(() {
              _isUsernameReadOnly = true;
            });
            _nameController.text = name;
            _onUsernameChanged(name);
          }
        }
      } catch (e) {
        Console.log(
            tag: "USER_INFO",
            value: "Failed to fetch initial profile from server: $e");
      }
    }

    if (_nameController.text.isEmpty) {
      final savedName = await SharedPrefsHelper.getUserName();
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _isUsernameReadOnly = true;
        });
        _nameController.text = savedName;
        _onUsernameChanged(savedName);
      }
    }

    // Autofill height, weight, and gender from Health (Apple HealthKit / Google Health Connect) if missing
    if (mounted) {
      final cubit = context.read<UserInfoCubit>();
      final currentState = cubit.state;
      if (currentState.height == null || currentState.weight == null) {
        try {
          final healthData = await HealthService().fetchUserProfileFromHealth();
          if (healthData.isNotEmpty && mounted) {
            final double? newHeight = currentState.height ??
                (healthData['height'] as num?)?.toDouble();
            final double? newWeight = currentState.weight ??
                (healthData['weight'] as num?)?.toDouble();
            Gender? newGender = currentState.gender;
            if (healthData['gender'] != null) {
              if (healthData['gender'] == 'Female') {
                newGender = Gender.female;
              } else if (healthData['gender'] == 'Male') {
                newGender = Gender.male;
              }
            }

            final updatedState = currentState.copyWith(
              height: newHeight,
              weight: newWeight,
              gender: newGender,
            );
            cubit.emit(updatedState);
            await cubit.saveUser(updatedState);
            Console.log(
                tag: "USER_INFO",
                value:
                    "Autofilled height/weight/gender from Health: $healthData");
          }
        } catch (e) {
          Console.log(
              tag: "USER_INFO",
              value: "Error fetching profile from Health: $e");
        }
      }
    }

    if (mounted) {
      context
          .read<UserInfoCubit>()
          .setAchievmentSnackbarStatus(!widget.fromSettings);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFocusNode.removeListener(_onFocusChange);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.fromSettings,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: _isKeyboardVisible
            ? null
            : Container(
                height: AppDimensions.dim60,
                margin: EdgeInsets.only(
                  left: AppDimensions.defaultPadding.w,
                  right: AppDimensions.defaultPadding.w,
                  bottom: AppDimensions.defaultPadding.w,
                ),
                child: BlocBuilder<UserInfoCubit, UserInfoState>(
                  builder: (context, state) {
                    return CustomNextButton(
                        text: AppLocalizations.of(context)?.next ??
                            AppStrings.next,
                        onNextPressed: () async {
                          final height = state.height;
                          final weight = state.weight;
                          final age = state.age;

                          if (height == null || weight == null || age == null) {
                            UiUtilsService.showToast(
                              context: context,
                              text: AppLocalizations.of(context)
                                      ?.fillHeightWeightAge ??
                                  "Please fill in height, weight, and age before continuing.",
                              textColor: Colors.red,
                            );
                            return;
                          }

                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            UiUtilsService.showToast(
                              context: context,
                              text:
                                  AppLocalizations.of(context)?.enterUsername ??
                                      "Please enter your username.",
                              textColor: Colors.red,
                            );
                            return;
                          }

                          final regex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
                          if (!regex.hasMatch(name)) {
                            UiUtilsService.showToast(
                              context: context,
                              text: AppLocalizations.of(context)
                                      ?.usernameMustBeAlphanumeric ??
                                  "Username must be 3-15 alphanumeric characters or underscores.",
                              textColor: Colors.red,
                            );
                            return;
                          }

                          // Save name to SharedPrefs + cubit
                          await SharedPrefsHelper.setUserName(name);
                          if (context.mounted) {
                            context.read<UserInfoCubit>().setName(name);
                          }

                          if (!context.mounted) return;
                          // From onboarding → continue next flow
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              page: UserLifestyleInfoInputScreen(
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
            AppLocalizations.of(context)?.profileSetup ?? "Profile Setup",
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
            padding: EdgeInsets.only(
              left: AppDimensions.defaultPadding.w + 12,
              right: AppDimensions.defaultPadding.w + 12,
              top: AppDimensions.defaultPadding.h,
              bottom: AppDimensions.dim80.h,
            ),
            children: [
              // ── Header ──────────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)?.yourState ?? "Your State",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_16,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
              ),
              SizedBox(height: AppDimensions.dim8.h),
              Text(
                AppLocalizations.of(context)?.personalizeProfile ??
                    "Let's personalize your hydration profile.",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_14,
                  color: AppColors.greyColorText1,
                  fontVariations: [AppFontStyles.regularFontVariation],
                ),
              ),
              SizedBox(height: AppDimensions.dim24.h),

              // ── Username ────────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)?.username ?? "USERNAME",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_13,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppDimensions.dim12.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim16.w,
                  vertical: AppDimensions.dim14.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.greywith80,
                    width: AppDimensions.dim1,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radius_25),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: AppDimensions.dim4,
                      color: Colors.black.withValues(alpha: 0.08),
                      offset:
                          Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
                    ),
                  ],
                ),
                child: TextField(
                  focusNode: _nameFocusNode,
                  controller: _nameController,
                  onChanged: _onUsernameChanged,
                  readOnly: _isUsernameReadOnly,
                  enableInteractiveSelection: !_isUsernameReadOnly,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  scrollPadding:
                      EdgeInsets.only(bottom: AppDimensions.dim140.h),
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    fontVariations: [AppFontStyles.regularFontVariation],
                    color: _isUsernameReadOnly ? Colors.grey : AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Ram1z1',
                    hintStyle: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_16,
                      fontVariations: [AppFontStyles.regularFontVariation],
                      color: AppColors.greywith80,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.dim8.h),
              if (_isUsernameReadOnly)
                Text(
                  AppLocalizations.of(context)?.usernameCannotBeChanged ??
                      "Username cannot be changed once set.",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: AppFontStyles.fontSize_13.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                )
              else ...[
                if (_isCheckingUsername)
                  Text(
                    AppLocalizations.of(context)?.checkingAvailability ??
                        "Checking availability...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: AppFontStyles.fontSize_13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.regularFontVariation],
                    ),
                  )
                else if (_usernameError != null)
                  Text(
                    _usernameError!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: AppFontStyles.fontSize_13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.regularFontVariation],
                    ),
                  )
                else if (_isUsernameValid)
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 16.r),
                      SizedBox(width: 4.w),
                      Text(
                        AppLocalizations.of(context)?.usernameAvailable ??
                            "Username available",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: AppFontStyles.fontSize_13.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: AppDimensions.dim4.h),
                Text(
                  AppLocalizations.of(context)?.useLettersNumbersUnderscores ??
                      "Use 3-15 letters, numbers, or underscores.",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: AppFontStyles.fontSize_11.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.regularFontVariation],
                  ),
                ),
              ],

              SizedBox(height: AppDimensions.dim24.h),

              // ── Age ─────────────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)?.age ?? "AGE",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_13,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppDimensions.dim12.h),
              BlocBuilder<UserInfoCubit, UserInfoState>(
                builder: (context, state) {
                  final selectedAge = state.age;
                  final displayValue =
                      (selectedAge != null) ? "$selectedAge YRS" : null;
                  return CustomCupertinoInputWidget(
                    title: AppStrings.ageSelection,
                    placeholderText: "25",
                    leftToggleLabel: "",
                    rightToggleLabel: "YRS",
                    defaultToggleValue: "",
                    suffix: "YRS",
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

              SizedBox(height: AppDimensions.dim24.h),

              // ── Gender ──────────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)?.genderIdentity ??
                    "GENDER IDENTITY",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_13,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppDimensions.dim12.h),
              CustomRadioSelectionWidget(type: 1),
              SizedBox(height: AppDimensions.dim24.h),

              // ── Height ──────────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)?.height ?? "HEIGHT",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_13,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 0.8,
                ),
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
              SizedBox(height: AppDimensions.dim24.h),
              // ── Weight ──────────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)?.weight ?? "WEIGHT",
                style: TextStyle(
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontSize: AppFontStyles.fontSize_13,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppDimensions.dim12.h),
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
              SizedBox(height: AppDimensions.dim80.h),
            ],
          ),
        ),
      ),
    );
  }
}
