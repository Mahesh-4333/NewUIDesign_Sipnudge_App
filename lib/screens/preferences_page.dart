import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/Preferences/preferences_cubit.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/ringtone_screen.dart';
import 'package:hydrify/screens/user_info_daily_goal_screen.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/menu_item_tile.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/toggle_tile.dart';
import 'package:hydrify/services/ui_utils_service.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PreferencesCubit(),
      child: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, state) {
          final cubit = context.read<PreferencesCubit>();

          return Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: AppBar(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                AppStrings.preferences,
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
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      "assets/images/app_background.png"), // your image path
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: AppDimensions.dim30.h),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.dim28.w),
                      child: FutureBuilder<int?>(
                        future: SharedPrefsHelper.getWaterGoal(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          int goal = snapshot.data ?? 2500;
                          String formattedGoal = "${goal.toString()} mL";

                          return Column(
                            children: [
                              MenuItemTile(
                                title: AppStrings.waterIntakeGoal,
                                info: formattedGoal,
                                iconpatharrow: "assets/arrow.png",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserInfoDailyGoalScreen(
                                        waterGoal: goal.toDouble(),
                                        isViaSettingsScreen: false,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: AppDimensions.dim7.h),
                              ToggleTile(
                                title: AppStrings.ringtoneFeedback,
                                value: state
                                    .ringtoneFeedback, // ✔ correct value from state
                                onChanged: (value) {
                                  UiUtilsService.showToast(
                                      context: context,
                                      text: "Updating hydration reminders");
                                  cubit.toggleRingtoneFeedback(value);
                                }, // ✔ direct method reference
                              ),
                              SizedBox(height: AppDimensions.dim7.h),
                              MenuItemTile(
                                title: AppStrings.ringtone,
                                info: "",
                                iconpatharrow: "assets/arrow.png",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RingtoneScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    //),
                    //),

                    SizedBox(height: AppDimensions.dim11.h),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.dim28.w),
                      child: InnerShadow(
                        shadows: [
                          Shadow(
                            color: AppColors.black.withOpacity(0.25),
                            offset: Offset(2.r, 2.r),
                            blurRadius: 20.r,
                          ),
                          // Shadow(
                          //   color: Colors.white.withOpacity(0.55),
                          //   offset: Offset(-2, -2),
                          //   blurRadius: 6,
                          // ),
                        ],
                        child: ElevatedButton(
                          onPressed: () async {
                            // 1️⃣ Clear local database
                            try {
                              // final dbHelper = DatabaseHelper();
                              // await dbHelper
                              //     .clearAllSlots(); // make sure you have this method
                              // 1️⃣ Clear local bottle data via Cubit
                              final bottleDataCubit =
                                  context.read<BottleDataCubit>();
                              await bottleDataCubit.clearAllBottleData();

                              Fluttertoast.showToast(
                                  msg: "Local data cleared.");
                            } catch (e) {
                              Fluttertoast.showToast(
                                  msg: "Error clearing local data: $e");
                              return;
                            }

                            final bleCubit = context.read<BleCubit>();
                            await bleCubit.forgetDevice();

                            Fluttertoast.showToast(
                                msg:
                                    "Tracking restarted. Connect your device again.");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.stonegray,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radius_50.r),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.dim12.h),
                            elevation: 0, // remove default shadow
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.restartalltracking,
                              style: TextStyle(
                                color: AppColors.verydarkred,
                                fontSize: AppFontStyles.fontSize_20.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  FontVariation('wght',
                                      AppFontStyles.boldFontVariation.value),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
