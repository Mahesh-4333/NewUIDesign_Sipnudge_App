import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/screens/user_info_analyzing_screen.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_radio_selection_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_time_input_widget.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/next_button_widget.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class UserLifestyleInfoInputScreen extends StatefulWidget {
  const UserLifestyleInfoInputScreen(
      {super.key, required this.isViaSettingsScreen});

  final bool isViaSettingsScreen;
  @override
  State<UserLifestyleInfoInputScreen> createState() =>
      _UserLifestyleInfoInputScreenState();
}

class _UserLifestyleInfoInputScreenState
    extends State<UserLifestyleInfoInputScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppStrings.sleepAndLifecycle,
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
          //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
          // ),
        ),
        padding: EdgeInsets.only(
            top: AppDimensions.dim120.h, bottom: AppDimensions.bottomBarHeight),
        child: ListView(
          padding: EdgeInsets.all(
            AppDimensions.defaultPadding,
          ),
          children: [
            Text(
              AppStrings.whenDoYouWakeup,
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
              height: AppDimensions.dim11.h,
            ),
            BlocBuilder<UserInfoCubit, UserInfoState>(
              builder: (context, state) {
                var selectedHours = state.wakeupHour;
                var selectedMins = state.wakeupMinute;
                return CustomTimeInputWidget(
                  isBedtime: false,
                  selectedHours: selectedHours,
                  selectedMins: selectedMins,
                );
              },
            ),
            SizedBox(
              height: AppDimensions.dim15.h,
            ),
            Text(
              AppStrings.whatsBedTime,
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
              height: AppDimensions.dim11.h,
            ),
            BlocBuilder<UserInfoCubit, UserInfoState>(
              builder: (context, state) {
                var selectedHours = state.bedtimeHour;
                var selectedMins = state.bedtimeMinute;
                return CustomTimeInputWidget(
                  isBedtime: true,
                  selectedHours: selectedHours,
                  selectedMins: selectedMins,
                );
              },
            ),
            SizedBox(
              height: AppDimensions.dim20.h,
            ),
            Text(
              AppStrings.whatsYourActivityLevel,
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
              type: 2,
            ),
            SizedBox(
              height: AppDimensions.dim20.h,
            ),
            Text(
              AppStrings.whatsYourDiet,
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
              type: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: AppDimensions.dim60,
        margin: EdgeInsets.only(
          bottom: AppDimensions.dim30.h,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
        ),
        child: CustomNextButton(
            text: AppStrings.submit,
            onNextPressed: () async {
              UiUtilsService.showLoading(context, "Please wait");

              try {
                final cubit = context.read<UserInfoCubit>();
                final state = cubit.state;
                if (state.wakeupHour == null || state.wakeupMinute == null) {
                  UiUtilsService.dismissLoading(context);
                  UiUtilsService.showToast(
                    context: context,
                    textColor: Colors.red,
                    text: "Please enter your wakeup time",
                  );
                  return;
                }

                if (state.bedtimeHour == null || state.bedtimeMinute == null) {
                  UiUtilsService.dismissLoading(context);
                  UiUtilsService.showToast(
                    context: context,
                    textColor: Colors.red,
                    text: "Please enter your bedtime",
                  );
                  return;
                }

                double calculatedGoal =
                    WaterConsumptionCalculator.calculateWaterIntakeGoal(state);

                Map<String, double> breakdown =
                    WaterConsumptionCalculator.getCalculationBreakdown(state);
                print('Water intake calculation breakdown: $breakdown');
                double waterIntakeGoalInt = calculatedGoal;

                UiUtilsService.dismissLoading(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoAnalyzingScreen(
                      goal: waterIntakeGoalInt.toDouble(),
                      isViaSettingsScreen: widget.isViaSettingsScreen,
                    ),
                  ),
                );
              } catch (e) {
                UiUtilsService.dismissLoading(context);
                UiUtilsService.showToast(
                  context: context,
                  text: 'Error calculating water intake: ${e.toString()}',
                );
              }
            }),
      ),
    );
  }
}
