import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';

class BeverageIntakeWidget extends StatelessWidget {
  const BeverageIntakeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(AppDimensions.dim20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radius_20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBeverageSection(
            context: context,
            isCoffee: true,
            title: "Daily Coffee Intake",
            subtitle: "Caffeine affects hydration. Help us\nadjust your goals.",
            icon: Icons.local_cafe_rounded,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.dim20.h),
            child: Divider(color: AppColors.greywith80, thickness: 1),
          ),
          _buildBeverageSection(
            context: context,
            isCoffee: false,
            title: "Daily Tea Intake",
            subtitle: "Tea also impacts your daily water\nneeds.",
            icon: Icons.emoji_food_beverage_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildBeverageSection({
    required BuildContext context,
    required bool isCoffee,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return BlocBuilder<UserInfoCubit, UserInfoState>(
      builder: (context, state) {
        BeverageIntake currentIntake = isCoffee
            ? (state.coffeeIntake ?? BeverageIntake.none)
            : (state.teaIntake ?? BeverageIntake.none);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppDimensions.dim40.w,
                  height: AppDimensions.dim40.w,
                  decoration: BoxDecoration(
                    color: Color(0xff4DA6CD).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xff4DA6CD),
                    size: AppDimensions.dim20.w,
                  ),
                ),
                SizedBox(width: AppDimensions.dim15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: AppFontStyles.fontSize_18,
                          color: AppColors.black,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                      SizedBox(height: AppDimensions.dim5.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontSize: AppFontStyles.fontSize_14,
                          color: AppColors.darkgray,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.dim20.h),
            Wrap(
              spacing: AppDimensions.dim10.w,
              runSpacing: AppDimensions.dim10.h,
              children: [
                _buildPillButton(
                  context: context,
                  label: "None",
                  intakeValue: BeverageIntake.none,
                  currentIntake: currentIntake,
                  isCoffee: isCoffee,
                ),
                _buildPillButton(
                  context: context,
                  label: "1-2 cups",
                  intakeValue: BeverageIntake.oneToTwo,
                  currentIntake: currentIntake,
                  isCoffee: isCoffee,
                ),
                _buildPillButton(
                  context: context,
                  label: "3-4 cups",
                  intakeValue: BeverageIntake.threeToFour,
                  currentIntake: currentIntake,
                  isCoffee: isCoffee,
                ),
                _buildPillButton(
                  context: context,
                  label: "5+ cups",
                  intakeValue: BeverageIntake.fivePlus,
                  currentIntake: currentIntake,
                  isCoffee: isCoffee,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required String label,
    required BeverageIntake intakeValue,
    required BeverageIntake currentIntake,
    required bool isCoffee,
  }) {
    bool isSelected = intakeValue == currentIntake;

    return InkWell(
      onTap: () {
        final cubit = context.read<UserInfoCubit>();
        if (isCoffee) {
          cubit.setCoffeeIntake(intakeValue);
        } else {
          cubit.setTeaIntake(intakeValue);
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radius_20.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim20.w,
          vertical: AppDimensions.dim10.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xffF8FEFF) : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radius_20.w),
          border: Border.all(
            color: isSelected ? AppColors.bluegray : AppColors.greywith80,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.fontSize_14,
            color: isSelected ? AppColors.bluegray : AppColors.bluegray,
            fontVariations: [
              isSelected
                  ? AppFontStyles.boldFontVariation
                  : AppFontStyles.boldFontVariation,
            ],
          ),
        ),
      ),
    );
  }
}
