import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_cubit.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';
import 'package:hydrify/screens/custom_bttom_sheet_rm.dart';
import 'package:hydrify/screens/water_intake_timeline_screen.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_card.dart';
import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_list_item.dart';

// import 'package:hydrify/screens/widgets/navigation_helper.dart';

class DrinkReminderPage extends StatelessWidget {
  const DrinkReminderPage({super.key});

  void _showReminderMode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ReminderBottomSheet(), // ✅ only sheet stays clear
        );
      },
      //builder: (_) => ReminderBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // return BlocProvider(
    //   create: (_) => DrinkReminderCubit(),
    // child: Scaffold(
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppStrings.drinkreminder,
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
        width: double.infinity,
        height: double.infinity,
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
          child: Stack(
            children: [
              Column(
                children: [
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
                  //           color: AppColors.raisinblack,
                  //           size: AppFontStyles.fontSize_30.sp,
                  //         ),
                  //       ),
                  //       SizedBox(width: AppDimensions.dim70.w),
                  //       Text(
                  //         'Drink Reminder',
                  //         style: TextStyle(
                  //           color: AppColors.bluegray,
                  //           fontSize: AppFontStyles.fontSize_24.sp,
                  //           fontFamily: AppFontStyles.urbanistFontFamily,
                  //           fontVariations: [
                  //             AppFontStyles.boldFontVariation,
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: AppDimensions.dim28.h),

                  /// Main Content
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.dim28.w,
                    ),
                    child: BlocBuilder<DrinkReminderCubit, DrinkReminderState>(
                      builder: (context, state) {
                        // final cubit = context.read<DrinkReminderCubit>();
                        return Column(
                          children: [
                            // ReminderCard(
                            //   children: [
                            //     // ReminderToggleRow(
                            //     //   title: AppStrings.reminder,
                            //     //   value: state.reminderEnabled,
                            //     //   onChanged: cubit.toggleReminder,
                            //     // ),
                            //     ReminderListItem(
                            //       title: AppStrings.reminderMode,
                            //       trailing: state.reminderMode,
                            //       onTap: () => _showReminderMode(context),
                            //       iconPathArrow: ("assets/arrow.png"),
                            //     ),
                            //   ],
                            // ),
                            //SizedBox(height: AppDimensions.dim16.h),
                            // ReminderCard(
                            //   children: [
                            //     // ReminderCycleItem(
                            //     //   title: AppStrings.smartSkip,
                            //     //   value: cubit
                            //     //       .smartSkipOptions[state.smartSkipIndex],
                            //     //   onTap: cubit.cycleSmartSkip,
                            //     // ),
                            //     // ReminderCycleItem(
                            //     //   title: AppStrings.alarmRepeat,
                            //     //   value: cubit.alarmRepeatOptions[
                            //     //       state.alarmRepeatIndex],
                            //     //   onTap: cubit.cycleAlarmRepeat,
                            //     // ),
                            //     // ReminderToggleRow(
                            //     //   title: AppStrings.stopWhen100,
                            //     //   value: state.stopWhenFull,
                            //     //   onChanged: cubit.toggleStopWhenFull,
                            //     // ),
                            //   ],
                            // ),

                            ReminderCard(
                              children: [
                                // Padding(
                                //   padding: EdgeInsets.symmetric(
                                //     horizontal: AppDimensions.dim10.w,
                                //     vertical: AppDimensions.dim10.h,
                                //   ),
                                //   // padding: EdgeInsets.only(
                                //   //   bottom: AppDimensions.dim8.h,
                                //   // ),
                                //   child: Align(
                                //     alignment: Alignment.topLeft,
                                //     child: Text(
                                //       AppStrings.remindersetting,
                                //       style: TextStyle(
                                //         fontSize: AppFontStyles.fontSize_20.sp,
                                //         // fontWeight: FontWeight.w700,
                                //         color: AppColors.white,
                                //         fontFamily:
                                //             AppFontStyles.urbanistFontFamily,
                                //         fontVariations: [
                                //           AppFontStyles.boldFontVariation,
                                //         ],
                                //       ),
                                //     ),
                                //   ),
                                // ),
                                // Divider(
                                //   color: AppColors.white54,
                                //   thickness: AppFontStyles.fontSize_1.sp,
                                // ),
                                ReminderListItem(
                                  title: AppStrings.waterintaketimeline,
                                  trailing: '',
                                  onTap: () {
                                    final navigator = Navigator.of(context);

                                    navigator.push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WaterIntakeTimelineScreen(),
                                      ),
                                    );
                                  },
                                  iconPathArrow: ("assets/arrow.png"),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // const Spacer(),
                  // Padding(
                  //     padding: EdgeInsets.only(
                  //       bottom: AppDimensions.dim5.h,
                  //       right: AppDimensions.dim15.w,
                  //       left: AppDimensions.dim15.w,
                  //     ),
                  //     child: AnimatedBottomNavBar()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    //);
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
// import 'package:hydrify/cubit/drinkreminder/drink_reminder_cubit.dart';
// import 'package:hydrify/cubit/drinkreminder/drink_reminder_state.dart';
// import 'package:hydrify/screens/custom_bttom_sheet_rm.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';
// import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_card.dart';
// import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_cycle_item.dart';
// import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_list_item.dart';
// import 'package:hydrify/screens/widgets/drinkreminder_widget/reminder_toggle_row.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';

// class DrinkReminder extends StatelessWidget {
//   const DrinkReminder({super.key});

//   void _showReminderMode(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Padding(
//         padding: EdgeInsets.only(bottom: AppDimensions.bottomBarHeight.h),
//         child: ReminderBottomSheet(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => DrinkReminderCubit(),
//       child: Scaffold(
//         body: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.gradientStart, AppColors.gradientEnd],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: SafeArea(
//             child: Stack(
//               children: [
//                 Column(
//                   children: [
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
//                               color: AppColors.raisinblack,
//                               size: AppFontStyles.fontSize_30.sp,
//                             ),
//                           ),
//                           SizedBox(width: AppDimensions.dim55.w),
//                           Text(
//                             'Drink Reminder',
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
//                     SizedBox(height: AppDimensions.dim24.h),

//                     /// Main Content
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppDimensions.dim28.w,
//                       ),
//                       child:
//                           BlocBuilder<DrinkReminderCubit, DrinkReminderState>(
//                         builder: (context, state) {
//                           final cubit = context.read<DrinkReminderCubit>();
//                           return Column(
//                             children: [
//                               ReminderCard(
//                                 children: [
//                                   ReminderToggleRow(
//                                     title: AppStrings.reminder,
//                                     value: state.reminderEnabled,
//                                     onChanged: cubit.toggleReminder,
//                                   ),
//                                   ReminderListItem(
//                                     title: AppStrings.reminderMode,
//                                     trailing: state.reminderMode,
//                                     onTap: () => _showReminderMode(context),
//                                     iconPathArrow: ("assets/arrow.png"),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: AppDimensions.dim16.h),
//                               ReminderCard(
//                                 children: [
//                                   ReminderCycleItem(
//                                     title: AppStrings.smartSkip,
//                                     value: cubit
//                                         .smartSkipOptions[state.smartSkipIndex],
//                                     onTap: cubit.cycleSmartSkip,
//                                   ),
//                                   ReminderCycleItem(
//                                     title: AppStrings.alarmRepeat,
//                                     value: cubit.alarmRepeatOptions[
//                                         state.alarmRepeatIndex],
//                                     onTap: cubit.cycleAlarmRepeat,
//                                   ),
//                                   ReminderToggleRow(
//                                     title: AppStrings.stopWhen100,
//                                     value: state.stopWhenFull,
//                                     onChanged: cubit.toggleStopWhenFull,
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: AppDimensions.dim16.h),
//                               ReminderCard(
//                                 children: [
//                                   Padding(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: AppDimensions.dim10.w,
//                                       vertical: AppDimensions.dim10.h,
//                                     ),
//                                     // padding: EdgeInsets.only(
//                                     //   bottom: AppDimensions.dim8.h,
//                                     // ),
//                                     child: Align(
//                                       alignment: Alignment.topLeft,
//                                       child: Text(
//                                         AppStrings.remindersetting,
//                                         style: TextStyle(
//                                           fontSize:
//                                               AppFontStyles.fontSize_20.sp,
//                                           // fontWeight: FontWeight.w700,
//                                           color: AppColors.white,
//                                           fontFamily:
//                                               AppFontStyles.urbanistFontFamily,
//                                           fontVariations: [
//                                             AppFontStyles.boldFontVariation,
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Divider(
//                                     color: AppColors.white54,
//                                     thickness: AppFontStyles.fontSize_1.sp,
//                                   ),
//                                   ReminderListItem(
//                                     title: AppStrings.waterintaketimeline,
//                                     trailing: '',
//                                     onTap: () => Navigator.pushNamed(
//                                       context,
//                                       '/profile/waterintaketimeline',
//                                     ),
//                                     iconPathArrow: ("assets/arrow.png"),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                     const Spacer(),
//                   ],
//                 ),

//                 /// 🔹 Custom Bottom Nav Bar (your provided replacement)
//                 Positioned(
//                   left: AppDimensions.dim6.w,
//                   right: AppDimensions.dim6.w,
//                   bottom: AppDimensions.dim6.h,
//                   child: CustomBottomNavBar(
//                     activeTab: 'Home',
//                     onTabSelected: (label) {
//                       NavigationHelper.navigate(context, label);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//=============================================================================

