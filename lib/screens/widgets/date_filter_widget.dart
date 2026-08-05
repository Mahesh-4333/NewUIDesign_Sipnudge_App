import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';

import 'package:hydrify/l10n/app_localizations.dart';

class DateFilterWidget extends StatelessWidget {
  const DateFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: AppDimensions.dim10.h,
        bottom: AppDimensions.dim10.h,
        left: AppDimensions.defaultPadding,
        right: AppDimensions.defaultPadding,
      ),
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
      decoration: BoxDecoration(
        color: Color(0XFFFFFFFF),
        borderRadius: BorderRadius.circular(
          AppDimensions.radius_15,
        ),
        border: Border.all(color: AppColors.greywith80, width: 1.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IntervalSelector(),
          SizedBox(height: AppDimensions.dim15.h),
          const DateNavigator(),
        ],
      ),
    );
  }
}

class IntervalSelector extends StatelessWidget {
  const IntervalSelector({super.key});

  String _getLocalizedInterval(BuildContext context, FilterInterval interval) {
    final loc = AppLocalizations.of(context);
    switch (interval) {
      case FilterInterval.weekly:
        return loc?.weeklyTab ?? "Weekly";
      case FilterInterval.monthly:
        return loc?.monthlyTab ?? "Monthly";
      case FilterInterval.yearly:
        return loc?.yearly ?? "Yearly";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, filterState) {
        return Container(
          padding: EdgeInsets.all(AppDimensions.dim3.w),
          decoration: BoxDecoration(
            color: Color(0xFF9CCEFD),
            borderRadius: BorderRadius.circular(
              AppDimensions.radius_25.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: FilterInterval.values.map((interval) {
              bool isSelected = filterState.currentInterval == interval;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<FilterCubit>().changeInterval(interval);
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: AppDimensions.dim12.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0XFF0083FF)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radius_25.w),
                    ),
                    child: Text(
                      _getLocalizedInterval(context, interval),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.bluegray,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontSize: AppFontStyles.fontSize_16,
                        fontVariations: [
                          AppFontStyles.boldFontVariation,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class DateNavigator extends StatelessWidget {
  const DateNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              splashColor: AppColors.gradientEnd,
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFF9CCEFD),
              ),
              onTap: () => context.read<FilterCubit>().navigateDate(false),
            ),
            Text(
              state.getFormattedDateRange(),
              style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.fontWeightVariation600,
                  ]),
            ),
            context.read<FilterCubit>().canNavigateForward()
                ? InkWell(
                    splashColor: AppColors.gradientEnd,
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF9CCEFD),
                    ),
                    onTap: () => context.read<FilterCubit>().navigateDate(true),
                  )
                : SizedBox(width: AppDimensions.dim48.w),
          ],
        );
      },
    );
  }
}
