import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/screens/widgets/user_info_input_widgets/custom_toggle_button_widget.dart';

class DailyWaterConsumptionWidget extends StatelessWidget {
  const DailyWaterConsumptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserInfoCubit, UserInfoState>(
      builder: (context, state) {
        final typicalIntake = state.typicalWaterIntake ?? 2.0;
        final unit = state.waterUnit ?? "L";

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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppDimensions.dim40.w,
                    height: AppDimensions.dim40.w,
                    decoration: BoxDecoration(
                      color: AppColors.blueWaterIntake.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.blueWaterIntake,
                      size: AppDimensions.dim20.w,
                    ),
                  ),
                  SizedBox(width: AppDimensions.dim15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.estimatedDailyWaterConsumption,
                          style: TextStyle(
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontSize: AppFontStyles.fontSize_18,
                            color: AppColors.black,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        SizedBox(height: AppDimensions.dim5.h),
                        Text(
                          AppStrings.typicalIntakeSubtitle,
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
                  CustomToggleButtonWidget(
                    leftLabel: "L",
                    rightLabel: "mL",
                    initialValue: unit,
                    toggleType: 2,
                    onChanged: (value) {
                      context.read<UserInfoCubit>().setWaterUnit(value);
                    },
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.dim20.h),
              Container(
                width: double.maxFinite,
                height: AppDimensions.dim60.h,
                decoration: BoxDecoration(
                  color: AppColors.blueWaterIntake.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radius_30.w),
                  border:
                      Border.all(color: AppColors.blueWaterIntake, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  unit == "L"
                      ? (typicalIntake % 1 == 0
                          ? typicalIntake.toInt().toString()
                          : typicalIntake.toStringAsFixed(1))
                      : (typicalIntake * 1000).toInt().toString(),
                  style: TextStyle(
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontSize: AppFontStyles.fontSize_28,
                    color: AppColors.bluegray,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.dim20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOptionButton(context, "Under 1L", 0.5, typicalIntake),
                  _buildOptionButton(context, "1-2L", 2.0, typicalIntake),
                  _buildOptionButton(context, "2-3L", 2.5, typicalIntake),
                  _buildOptionButton(context, "3L+", 3.5, typicalIntake),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
      BuildContext context, String label, double value, double currentValue) {
    bool isSelected = false;
    if (label == "Under 1L") {
      isSelected = currentValue < 1.0;
    } else if (label == "1-2L") {
      isSelected = currentValue >= 1.0 && currentValue <= 2.0;
    } else if (label == "2-3L") {
      isSelected = currentValue > 2.0 && currentValue <= 3.0;
    } else if (label == "3L+") {
      isSelected = currentValue > 3.0;
    }

    return InkWell(
      onTap: () {
        context.read<UserInfoCubit>().setTypicalWaterIntake(value);
      },
      borderRadius: BorderRadius.circular(AppDimensions.radius_20.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim15.w,
          vertical: AppDimensions.dim10.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.offwhiteblue : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radius_30.w),
          border: Border.all(
            color:
                isSelected ? AppColors.blueWaterIntake : AppColors.greywith80,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.fontSize_14,
            color: AppColors.bluegray,
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
