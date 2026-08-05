import 'package:hydrify/helpers/logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/helpers/vibration_helper.dart';

class CustomRadioSelectionWidget extends StatelessWidget {
  const CustomRadioSelectionWidget({super.key, required this.type});

  final int type;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserInfoCubit, UserInfoState>(
      builder: (context, state) {
        if (type == 1) {
          return _buildGenderSelectionRow(context, state);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final double totalSpacing = AppDimensions.dim10.h;
            final double tileWidth = (constraints.maxWidth - totalSpacing) / 2;

            return Wrap(
              runSpacing: AppDimensions.dim10.h,
              spacing: AppDimensions.dim10.h,
              children: getRadioOptionsBasedOnType(context, state, tileWidth),
            );
          },
        );
      },
    );
  }

  Widget _buildGenderSelectionRow(BuildContext context, UserInfoState state) {
    final cubit = context.read<UserInfoCubit>();
    return Row(
      children: [
        Expanded(
          child: _buildGenderTile(
            name: AppStrings.male,
            iconData: Icons.male_rounded,
            isSelected: state.gender == Gender.male,
            onTap: () => cubit.setGender(Gender.male),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildGenderTile(
            name: AppStrings.female,
            iconData: Icons.female_rounded,
            isSelected: state.gender == Gender.female,
            onTap: () => cubit.setGender(Gender.female),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildGenderTile(
            name: "Other",
            iconData: Icons.transgender_rounded,
            isSelected: state.gender == Gender.preferNotToSay,
            onTap: () => cubit.setGender(Gender.preferNotToSay),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderTile({
    required String name,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        VibrationHelper.vibrate(duration: 15, amplitude: 100);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 104.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.offwhiteblue : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.bluegray
                : AppColors.greywith80.withValues(alpha: 0.5),
            width: isSelected ? 2.w : 1.w,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radius_16.w),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.bluegray
                    : const Color(0xFFE9EDF0),
              ),
              child: Icon(
                iconData,
                size: 26.sp,
                color: isSelected ? Colors.white : const Color(0xFF9EA3A8),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: AppFontStyles.fontSize_15,
                color:
                    isSelected ? AppColors.bluegray : const Color(0xFF9EA3A8),
                fontVariations: [
                  isSelected
                      ? AppFontStyles.boldFontVariation
                      : AppFontStyles.semiBoldFontVariation,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getRadioOptionsBasedOnType(
      BuildContext context, UserInfoState state, double tileWidth) {
    final cubit = context.read<UserInfoCubit>();
    if (type == 1) {
      return [];
    } else if (type == 2) {
      return [
        buildTile(
          name: AppStrings.sedentary,
          icon: "assets/images/selentaryicon_selected.svg",
          description: AppStrings.sedentaryDes,
          // subDescription: "less than 5000 steps",
          isSelected: state.activityLevel == ActivityLevel.sedentary,
          onTap: () {
            cubit.setActivityLevel(ActivityLevel.sedentary);
          },
          width: tileWidth,
        ),
        buildTile(
          name: AppStrings.lightlyActive,
          icon: "assets/images/lightlyactiveicon_selected.svg",
          description: AppStrings.lightActivityDes,
          // subDescription: "5,000 - 7,500 steps",
          isSelected: state.activityLevel == ActivityLevel.lightActivity,
          onTap: () {
            cubit.setActivityLevel(ActivityLevel.lightActivity);
          },
          width: tileWidth,
        ),
        buildTile(
          name: AppStrings.moderatelyActive,
          icon: "assets/images/moderatelyactiveicon_selected.svg",
          description: AppStrings.midActivityDes,
          // subDescription: "7,500 - 10,000 steps",
          isSelected: state.activityLevel == ActivityLevel.midActive,
          onTap: () {
            cubit.setActivityLevel(ActivityLevel.midActive);
          },
          width: tileWidth,
        ),
        buildTile(
          name: AppStrings.veryActive,
          icon: "assets/images/veryactiveicon_selected.svg",
          description: AppStrings.veryActivityDes,
          isSelected: state.activityLevel == ActivityLevel.veryActive,
          onTap: () {
            cubit.setActivityLevel(ActivityLevel.veryActive);
          },
          width: tileWidth,
        ),
      ];
    } else if (type == 3) {
      return [
        buildTile(
          name: AppStrings.standardBalancedDiet,
          icon: "assets/images/Standarddieticon_selected.svg",
          isSelected: state.dietType == DietType.balanced,
          onTap: () {
            cubit.setDietType(DietType.balanced);
          },
          width: tileWidth,
        ),
        buildTile(
          name: AppStrings.vegan,
          icon: "assets/images/vegdieticon_selected.svg",
          isSelected: state.dietType == DietType.vegetarian,
          onTap: () {
            cubit.setDietType(DietType.vegetarian);
          },
          width: tileWidth,
        ),
        buildTile(
          name: AppStrings.highSodiumDiet,
          icon: "assets/images/highsodiumdieticon_selected.svg",
          isSelected: state.dietType == DietType.processed,
          onTap: () {
            cubit.setDietType(DietType.processed);
          },
          width: tileWidth,
        ),
        buildTile(
          name: AppStrings.highProtein,
          icon: "assets/images/highproteindieticon_selected.svg",
          isSelected: state.dietType == DietType.highProtein,
          onTap: () {
            cubit.setDietType(DietType.highProtein);
          },
          width: tileWidth,
        )
      ];
    }
    return [];
  }

  Widget buildTile({
    required String name,
    String? description,
    String? subDescription,
    required String icon,
    required bool isSelected,
    required Function() onTap,
    required double width,
  }) {
    String displayIcon = isSelected
        ? icon
        : icon.replaceFirst('_selected.svg', '_unselected.svg');

    return InkWell(
      onTap: () async {
        VibrationHelper.vibrate(duration: 15, amplitude: 100);
        onTap();
      },
      splashColor: AppColors.selectedPurpleToggle,
      child: Container(
        width: width,
        height: type == 1 ? AppDimensions.dim82.h : AppDimensions.dim85.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.offwhiteblue : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.bluegray : AppColors.greywith80,
            width: isSelected ? AppDimensions.dim3.w : AppDimensions.dim1.w,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radius_15.w),
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.dim4,
              color: Colors.black.withOpacity(.4),
              offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: AppDimensions.dim12.w,
          top: AppDimensions.dim12.w,
          bottom: AppDimensions.dim6.h,
          right: AppDimensions.dim10.w,
        ),
        child: Stack(
          children: [
            // ▣ TEXT CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_16,
                    color:
                        isSelected ? AppColors.bluegray : AppColors.lightgray,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: AppDimensions.dim10.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_14,
                      color:
                          isSelected ? AppColors.bluegray : AppColors.lightgray,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                ],
                if (subDescription != null) ...[
                  SizedBox(height: AppDimensions.dim5.h),
                  Text(
                    subDescription,
                    style: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontSize: AppFontStyles.fontSize_14,
                      color:
                          isSelected ? AppColors.bluegray : AppColors.lightgray,
                      fontVariations: [AppFontStyles.semiBoldFontVariation],
                    ),
                  ),
                ],
              ],
            ),

            // ▣ ICON WITH CONDITIONAL ALIGNMENT
            if (icon.isNotEmpty)
              Align(
                alignment:
                    type == 1 ? Alignment.bottomRight : Alignment.topRight,
                child: SvgPicture.asset(displayIcon),
              ),
          ],
        ),
      ),
    );
  }
}


  //=======================================================================

  // List<Widget> getRadioOptionsBasedOnType(
  //     BuildContext context, UserInfoState state, double tileWidth) {
  //   final cubit = context.read<UserInfoCubit>();

  //   if (type == 1) {
  //     // 🔹 Gender selection
  //     return [
  //       buildTile(
  //         name: AppStrings.male,
  //         icon: "assets/images/male_ic_11_selected.svg",
  //         isSelected: state.gender == Gender.male,
  //         onTap: () => cubit.setGender(Gender.male),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.female,
  //         icon: "assets/images/female_unselected.svg",
  //         isSelected: state.gender == Gender.female,
  //         onTap: () => cubit.setGender(Gender.female),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.preferNotToSay,
  //         icon: "",
  //         isSelected: state.gender == Gender.preferNotToSay,
  //         onTap: () => cubit.setGender(Gender.preferNotToSay),
  //         width: tileWidth,
  //       ),
  //     ];
  //   } else if (type == 2) {
  //     // 🔹 Activity Level
  //     return [
  //       buildTile(
  //         name: AppStrings.sedentary,
  //         icon: "assets/images/sedentary_selected.svg",
  //         description: AppStrings.sedentaryDes,
  //         subDescription: "less than 5000 steps",
  //         isSelected: state.activityLevel == ActivityLevel.sedentary,
  //         onTap: () => cubit.setActivityLevel(ActivityLevel.sedentary),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.lightlyActive,
  //         icon: "assets/images/lightly_active_selected.svg",
  //         description: AppStrings.lightActivityDes,
  //         subDescription: "5,000 - 7,500 steps",
  //         isSelected: state.activityLevel == ActivityLevel.lightActivity,
  //         onTap: () => cubit.setActivityLevel(ActivityLevel.lightActivity),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.moderatelyActive,
  //         icon: "assets/images/moderately_active_selected.svg",
  //         description: AppStrings.midActivityDes,
  //         subDescription: "7,500 - 10,000 steps",
  //         isSelected: state.activityLevel == ActivityLevel.midActive,
  //         onTap: () => cubit.setActivityLevel(ActivityLevel.midActive),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.veryActive,
  //         icon: "assets/images/very_active1_selected.svg",
  //         description: AppStrings.veryActivityDes,
  //         subDescription: "More than 10,000 steps",
  //         isSelected: state.activityLevel == ActivityLevel.veryActive,
  //         onTap: () => cubit.setActivityLevel(ActivityLevel.veryActive),
  //         width: tileWidth,
  //       ),
  //     ];
  //   } else if (type == 3) {
  //     // 🔹 Diet Type
  //     return [
  //       buildTile(
  //         name: AppStrings.balanced,
  //         icon: "assets/images/standard_balanced_diet_selected.svg",
  //         isSelected: state.dietType == DietType.balanced,
  //         onTap: () => cubit.setDietType(DietType.balanced),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.veg,
  //         icon: "assets/images/veg_diet_selected.svg",
  //         isSelected: state.dietType == DietType.vegetarian,
  //         onTap: () => cubit.setDietType(DietType.vegetarian),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.processedDiet,
  //         icon: "assets/images/processed_diet_selected.svg",
  //         isSelected: state.dietType == DietType.processed,
  //         onTap: () => cubit.setDietType(DietType.processed),
  //         width: tileWidth,
  //       ),
  //       buildTile(
  //         name: AppStrings.highProtein,
  //         icon: "assets/images/high_protein_diet_selected.svg",
  //         isSelected: state.dietType == DietType.highProtein,
  //         onTap: () => cubit.setDietType(DietType.highProtein),
  //         width: tileWidth,
  //       ),
  //     ];
  //   }

  //   return [];
  // }

  //=======================================================================

  // Widget buildTile({
  //   required String name,
  //   String? description,
  //   String? subDescription,
  //   required String icon,
  //   required bool isSelected,
  //   required Function() onTap,
  //   required double width,
  // }) {
  //   // Determine which icon to show based on selection
  //   String displayIcon = isSelected
  //       ? icon // selected icon
  //       : icon.replaceFirst('.svg', '_unselected.svg'); // unselected version

  //   return InkWell(
  //     onTap: onTap,
  //     splashColor: AppColors.selectedPurpleToggle,
  //     child: Container(
  //       width: width,
  //       height: type == 1 ? AppDimensions.dim92.h : AppDimensions.dim122.h,
  //       decoration: BoxDecoration(
  //         color: isSelected ? AppColors.offwhiteblue : AppColors.white,
  //         border: Border.all(
  //           color: isSelected ? AppColors.bluegray : AppColors.greywith80,
  //           width: isSelected ? AppDimensions.dim3.w : AppDimensions.dim1.w,
  //         ),
  //         borderRadius: BorderRadius.circular(AppDimensions.radius_15.w),
  //         boxShadow: [
  //           BoxShadow(
  //             blurRadius: AppDimensions.dim4,
  //             color: Colors.black.withOpacity(.4),
  //             offset: Offset(AppDimensions.dim2.w, AppDimensions.dim2.h),
  //           ),
  //         ],
  //       ),
  //       padding: EdgeInsets.only(
  //         left: AppDimensions.dim12.w,
  //         top: AppDimensions.dim12.w,
  //         bottom: AppDimensions.dim6.h,
  //         right: AppDimensions.dim10.w,
  //       ),
  //       child: Stack(
  //         children: [
  //           // Main content column
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // 🔹 Name
  //               Text(
  //                 name,
  //                 style: TextStyle(
  //                   fontFamily: AppFontStyles.urbanistFontFamily,
  //                   fontSize: AppFontStyles.fontSize_16,
  //                   color:
  //                       isSelected ? AppColors.bluegray : AppColors.lightgray,
  //                   fontVariations: [AppFontStyles.boldFontVariation],
  //                 ),
  //               ),

  //               if (description != null) ...[
  //                 SizedBox(height: AppDimensions.dim4.h),
  //                 Text(
  //                   description,
  //                   style: TextStyle(
  //                     fontFamily: AppFontStyles.urbanistFontFamily,
  //                     fontSize: AppFontStyles.fontSize_14,
  //                     color: AppColors.white.withAlpha(160),
  //                     fontVariations: [AppFontStyles.semiBoldFontVariation],
  //                   ),
  //                 ),
  //               ],

  //               if (subDescription != null) ...[
  //                 SizedBox(height: AppDimensions.dim3.h),
  //                 Text(
  //                   subDescription!,
  //                   style: TextStyle(
  //                     fontFamily: AppFontStyles.urbanistFontFamily,
  //                     fontSize: AppFontStyles.fontSize_14,
  //                     color: AppColors.white.withOpacity(0.8),
  //                     fontVariations: [AppFontStyles.semiBoldFontVariation],
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),

  //           // 🔹 Icon alignment depends on type
  //           if (icon.isNotEmpty)
  //             Align(
  //               alignment:
  //                   type == 1 ? Alignment.bottomRight : Alignment.topRight,
  //               child: SvgPicture.asset(
  //                 displayIcon,
  //                 // height:
  //                 //     type == 1 ? AppDimensions.dim40.h : AppDimensions.dim50.h,
  //                 // width:
  //                 //     type == 1 ? AppDimensions.dim40.w : AppDimensions.dim50.w,
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }