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
                // gradient: LinearGradient(
                //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                // ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // ✅ Header
                    // Padding(
                    //   padding: EdgeInsets.only(
                    //     top: AppDimensions.dim40.h,
                    //     left: AppDimensions.dim20.w,
                    //     right: AppDimensions.dim20.w,
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       IconButton(
                    //         onPressed: () => Navigator.pop(context),
                    //         icon: Icon(
                    //           Icons.arrow_back,
                    //           color: AppColors.black,
                    //           size: AppFontStyles.fontSize_30.sp,
                    //         ),
                    //       ),
                    //       SizedBox(width: AppDimensions.dim100.w),
                    //       Text(
                    //         AppStrings.preferences,
                    //         style: TextStyle(
                    //           color: AppColors.bluegray,
                    //           fontSize: AppFontStyles.fontSize_24.sp,
                    //           fontFamily: AppFontStyles.urbanistFontFamily,
                    //           fontVariations: [AppFontStyles.boldFontVariation],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    SizedBox(height: AppDimensions.dim30.h),

                    // ✅ Menu Group
                    // Padding(
                    //   padding: EdgeInsets.symmetric(
                    //     horizontal: AppDimensions.dim28.w,
                    //   ),
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(
                    //         AppDimensions.dim50.r,
                    //       ),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: Colors.black.withOpacity(
                    //             0.10,
                    //           ), // shadow color only
                    //           blurRadius: 2.r,
                    //           spreadRadius: 3.r,
                    //           offset: Offset(2.r, 3.r), // even shadow
                    //         ),
                    //       ],
                    //     ),
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         color: AppColors.white1A,
                    //         borderRadius: BorderRadius.circular(
                    //           AppDimensions.dim50.r,
                    //         ),
                    //       ),
                    //       child: Column(
                    //         children: [
                    //           MenuItemTile(
                    //               title: AppStrings.waterIntakeGoal,
                    //               info: '2,500 mL',
                    //               iconpatharrow: "assets/arrow.png",
                    //               onTap: () {
                    //                 Navigator.push(
                    //                   context,
                    //                   MaterialPageRoute(
                    //                       builder: (_) =>
                    //                           const UserInfoDailyGoalScreen(
                    //                             waterGoal: 0,
                    //                           )), // ✅ replace with your page
                    //                 );
                    //               }),
                    //           // MenuItemTile(
                    //           //   title: AppStrings.cupUnits,
                    //           //   info: 'mL',
                    //           //   iconpatharrow: ("assets/arrow.png"),
                    //           // ),
                    //           // MenuItemTile(
                    //           //   title: AppStrings.weightUnit,
                    //           //   info: 'kg',
                    //           //   iconpatharrow: ("assets/arrow.png"),
                    //           // ),
                    //           // MenuItemTile(
                    //           //   title: AppStrings.heightUnit,
                    //           //   info: 'cm',
                    //           //   iconpatharrow: ("assets/arrow.png"),
                    //           // ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.dim28.w),
                      // child: Container(
                      //   decoration: BoxDecoration(
                      //     borderRadius:
                      //         BorderRadius.circular(AppDimensions.dim50.r),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.10),
                      //         blurRadius: 2.r,
                      //         spreadRadius: 3.r,
                      //         offset: Offset(2.r, 3.r),
                      //       ),
                      //     ],
                      //   ),
                      // child: Container(
                      //   decoration: BoxDecoration(
                      //     color: AppColors.white,
                      //     borderRadius:
                      //         BorderRadius.circular(AppDimensions.dim50.r),
                      //   ),
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
                                  Navigator.of(context, rootNavigator: true)
                                      .push(
                                    //context,
                                    MaterialPageRoute(
                                      builder: (_) => UserInfoDailyGoalScreen(
                                        waterGoal: goal.toDouble(),
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
                                onChanged: cubit
                                    .toggleRingtoneFeedback, // ✔ direct method reference
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

                    // ✅ Toggles
                    // Padding(
                    //   padding: EdgeInsets.symmetric(
                    //     horizontal: AppDimensions.dim28.w,
                    //   ),
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(
                    //         AppDimensions.dim16.r,
                    //       ),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: Colors.black.withOpacity(
                    //             0.10,
                    //           ), // shadow color only
                    //           blurRadius: 2.r,
                    //           spreadRadius: 3.r,
                    //           offset: Offset(3.5.r, 3.5.r), // even shadow
                    //         ),
                    //       ],
                    //     ),
                    //     child: Container(
                    //       padding: EdgeInsets.all(AppDimensions.dim16.w),
                    //       decoration: BoxDecoration(
                    //         color: AppColors.white1A,
                    //         borderRadius: BorderRadius.circular(
                    //           AppDimensions.dim16.r,
                    //         ),
                    //       ),
                    //       child: Column(
                    //         children: [
                    //           ToggleTile(
                    //             title: AppStrings.hapticFeedback,
                    //             value: state.hapticFeedback,
                    //             onChanged: cubit.toggleHapticFeedback,
                    //           ),
                    //           SizedBox(height: AppDimensions.dim12.h),
                    //           ToggleTile(
                    //             title: AppStrings.wakeUpTimeAsAlarm,
                    //             value: state.wakeUpAlarm,
                    //             onChanged: cubit.toggleWakeUpAlarm,
                    //           ),
                    //           SizedBox(height: AppDimensions.dim12.h),
                    //           ToggleTile(
                    //             title: AppStrings.ledFeedback,
                    //             value: state.ledFeedback,
                    //             onChanged: cubit.toggleLedFeedback,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    //SizedBox(height: AppDimensions.dim20.h),

                    // ✅ Restart Button
                    // Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 28.w),
                    //   child: Container(
                    //     width: double.infinity,
                    //     decoration: BoxDecoration(
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: Colors.black.withOpacity(
                    //             0.25,
                    //           ), // Shadow color
                    //           //spreadRadius: 1,
                    //           blurRadius: AppDimensions.radius_4.r,
                    //           offset: Offset(
                    //             AppDimensions.radius_4.r,
                    //             AppDimensions.radius_4.r,
                    //           ), // Shadow position
                    //         ),
                    //       ],
                    //       borderRadius: BorderRadius.circular(
                    //         AppDimensions.radius_50.r,
                    //       ),
                    //     ),
                    //     child: ElevatedButton(
                    //       onPressed: () async {
                    //         // 1️⃣ Clear local database
                    //         //   try {
                    //         //     final dbHelper = DatabaseHelper();
                    //         //     await dbHelper
                    //         //         .clearAllSlots(); // make sure you have this method
                    //         //     Fluttertoast.showToast(
                    //         //         msg: "Local data cleared.");
                    //         //   } catch (e) {
                    //         //     Fluttertoast.showToast(
                    //         //         msg: "Error clearing local data: $e");
                    //         //     return;
                    //         //   }

                    //         //   // 2️⃣ Forget saved BLE device (optional: reset BLE)
                    //         //   final bleCubit = context.read<BleCubit>();
                    //         //   await bleCubit.forgetDevice();

                    //         //   // 3️⃣ Optionally, notify user
                    //         //   Fluttertoast.showToast(
                    //         //       msg:
                    //         //           "Tracking restarted. Connect your device again.");

                    //         //   // 4️⃣ Optional: Navigate back to home or refresh UI
                    //         //   // Navigator.pushReplacementNamed(context, '/home');
                    //       },
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: AppColors.peachOrange,
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(
                    //               AppDimensions.radius_50.r),
                    //         ),
                    //         padding: EdgeInsets.symmetric(
                    //           vertical: AppDimensions.dim10.h,
                    //         ),
                    //         elevation: 0,
                    //       ),
                    //       child: Text(
                    //         AppStrings.restartalltracking,
                    //         style: TextStyle(
                    //           color: AppColors.raisinblack,
                    //           fontSize: AppFontStyles.fontSize_20.sp,
                    //           fontFamily: AppFontStyles.urbanistFontFamily,
                    //           fontVariations: [
                    //             FontVariation('wght',
                    //                 AppFontStyles.boldFontVariation.value),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //     // child: ElevatedButton(
                    //     //   onPressed: () {
                    //     //     // Add cubit reset logic if needed
                    //     //   },
                    //     //   style: ElevatedButton.styleFrom(
                    //     //     backgroundColor: AppColors.peachOrange,
                    //     //     shape: RoundedRectangleBorder(
                    //     //       borderRadius: BorderRadius.circular(
                    //     //         AppDimensions.radius_50.r,
                    //     //       ),
                    //     //     ),
                    //     //     padding: EdgeInsets.symmetric(
                    //     //       vertical: AppDimensions.dim10.h,
                    //     //     ),
                    //     //     elevation: 0, // Set to 0 to avoid default shadow
                    //     //   ),
                    //     //   child: Text(
                    //     //     AppStrings.restartalltracking,
                    //     //     style: TextStyle(
                    //     //       color: AppColors.raisinblack,
                    //     //       fontSize: AppFontStyles.fontSize_20.sp,
                    //     //       fontFamily: AppFontStyles.urbanistFontFamily,
                    //     //       fontVariations: [
                    //     //         AppFontStyles.boldFontVariation,
                    //     //       ],
                    //     //     ),
                    //     //   ),
                    //     // ),
                    //   ),
                    // ),

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

                            // 2️⃣ Forget saved BLE device (optional: reset BLE)
                            final bleCubit = context.read<BleCubit>();
                            await bleCubit.forgetDevice();

                            // 3️⃣ Optionally, notify user
                            Fluttertoast.showToast(
                                msg:
                                    "Tracking restarted. Connect your device again.");

                            // 4️⃣ Optional: Navigate back to home or refresh UI
                            // Navigator.pushReplacementNamed(context, '/home');
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

                    // Padding(
                    //     padding: EdgeInsets.only(
                    //       bottom: AppDimensions.dim5.h,
                    //       right: AppDimensions.dim15.w,
                    //       left: AppDimensions.dim15.w,
                    //     ),
                    //     child: AnimatedBottomNavBar()),
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

//=============================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/Preferences/preferences_cubit.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/account&security_widgets/toggle_state_widget.dart';
// import 'package:hydrify/screens/widgets/preferences_widgets/menu_item_tile.dart';

// class PreferencesPage extends StatelessWidget {
//   const PreferencesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => PreferencesCubit(),
//       child: BlocBuilder<PreferencesCubit, PreferencesState>(
//         builder: (context, state) {
//           final cubit = context.read<PreferencesCubit>();

//           return Scaffold(
//             body: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [AppColors.gradientStart, AppColors.gradientEnd],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: SafeArea(
//                 child: Column(
//                   children: [
//                     // ✅ Header
//                     Padding(
//                       padding: EdgeInsets.only(
//                         top: AppDimensions.dim40.h,
//                         left: AppDimensions.dim20.w,
//                         right: AppDimensions.dim20.w,
//                       ),
//                       child: Row(
//                         children: [
//                           IconButton(
//                             onPressed: () => Navigator.pop(context),
//                             icon: Icon(
//                               Icons.arrow_back,
//                               color: AppColors.black,
//                               size: AppFontStyles.fontSize_30.sp,
//                             ),
//                           ),
//                           SizedBox(width: AppDimensions.dim100.w),
//                           Text(
//                             AppStrings.preferences,
//                             style: TextStyle(
//                               color: AppColors.white,
//                               fontSize: AppFontStyles.fontSize_24.sp,
//                               fontFamily: AppFontStyles.urbanistFontFamily,
//                               fontVariations: [
//                                 FontVariation(
//                                   'wght',
//                                   AppFontStyles.boldFontVariation.value,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     SizedBox(height: 30.h),

//                     // ✅ Menu Group
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppDimensions.dim28.w,
//                       ),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(
//                             AppDimensions.dim16.r,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(
//                                 0.10,
//                               ), // shadow color only
//                               blurRadius: 2.r,
//                               spreadRadius: 3.r,
//                               offset: Offset(3.5.r, 3.5.r), // even shadow
//                             ),
//                           ],
//                         ),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.white1A,
//                             borderRadius: BorderRadius.circular(
//                               AppDimensions.dim16.r,
//                             ),
//                             // boxShadow: [
//                             //   BoxShadow(
//                             //     color: Colors.black.withOpacity(0.25),
//                             //     offset: const Offset(4, 4),
//                             //     blurRadius: 8.r,
//                             //   ),
//                             // ],
//                           ),
//                           child: Column(
//                             children: [
//                               MenuItemTile(
//                                 title: AppStrings.waterIntakeGoal,
//                                 info: '2,500 mL',
//                                 iconpatharrow: ("assets/arrow.png"),
//                               ),
//                               MenuItemTile(
//                                 title: AppStrings.cupUnits,
//                                 info: 'mL',
//                                 iconpatharrow: ("assets/arrow.png"),
//                               ),
//                               MenuItemTile(
//                                 title: AppStrings.weightUnit,
//                                 info: 'kg',
//                                 iconpatharrow: ("assets/arrow.png"),
//                               ),
//                               MenuItemTile(
//                                 title: AppStrings.heightUnit,
//                                 info: 'cm',
//                                 iconpatharrow: ("assets/arrow.png"),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: AppDimensions.dim25.h),

//                     // ✅ Toggles
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppDimensions.dim28.w,
//                       ),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(
//                             AppDimensions.dim16.r,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(
//                                 0.10,
//                               ), // shadow color only
//                               blurRadius: 2.r,
//                               spreadRadius: 3.r,
//                               offset: Offset(3.5.r, 3.5.r), // even shadow
//                             ),
//                           ],
//                         ),
//                         child: Container(
//                           padding: EdgeInsets.all(AppDimensions.dim16.w),
//                           decoration: BoxDecoration(
//                             color: AppColors.white1A,
//                             borderRadius: BorderRadius.circular(
//                               AppDimensions.dim16.r,
//                             ),
//                           ),
//                           child: Column(
//                             children: [
//                               ToggleTile(
//                                 title: AppStrings.hapticFeedback,
//                                 value: state.hapticFeedback,
//                                 onChanged: cubit.toggleHapticFeedback,
//                               ),
//                               SizedBox(height: AppDimensions.dim12.h),
//                               ToggleTile(
//                                 title: AppStrings.wakeUpTimeAsAlarm,
//                                 value: state.wakeUpAlarm,
//                                 onChanged: cubit.toggleWakeUpAlarm,
//                               ),
//                               SizedBox(height: AppDimensions.dim12.h),
//                               ToggleTile(
//                                 title: AppStrings.ledFeedback,
//                                 value: state.ledFeedback,
//                                 onChanged: cubit.toggleLedFeedback,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: AppDimensions.dim20.h),

//                     // ✅ Restart Button
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 28.w),
//                       child: Container(
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(
//                                 0.25,
//                               ), // Shadow color
//                               //spreadRadius: 1,
//                               blurRadius: AppDimensions.radius_4.r,
//                               offset: Offset(
//                                 AppDimensions.radius_4.r,
//                                 AppDimensions.radius_4.r,
//                               ), // Shadow position
//                             ),
//                           ],
//                           borderRadius: BorderRadius.circular(
//                             AppDimensions.radius_50.r,
//                           ),
//                         ),
//                         child: ElevatedButton(
//                           onPressed: () {
//                             // Add cubit reset logic if needed
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.peachOrange,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(
//                                 AppDimensions.radius_50.r,
//                               ),
//                             ),
//                             padding: EdgeInsets.symmetric(
//                               vertical: AppDimensions.dim10.h,
//                             ),
//                             elevation: 0, // Set to 0 to avoid default shadow
//                           ),
//                           child: Text(
//                             AppStrings.restartalltracking,
//                             style: TextStyle(
//                               color: AppColors.raisinblack,
//                               fontSize: AppFontStyles.fontSize_20.sp,
//                               fontFamily: AppFontStyles.urbanistFontFamily,
//                               fontVariations: [
//                                 FontVariation(
//                                   'wght',
//                                   AppFontStyles.boldFontVariation.value,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const Spacer(),

//                     // ✅ Reusable BottomNav
//                     CustomBottomNavBar(
//                       activeTab: 'Home',
//                       onTabSelected: cubit.updateActiveTab,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

//=============================================================================
