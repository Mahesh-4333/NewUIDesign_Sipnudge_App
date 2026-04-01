import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';

import '../../../constants/app_dimensions.dart';

class DrinkTypesWidget extends StatefulWidget {
  const DrinkTypesWidget({super.key});

  @override
  State<DrinkTypesWidget> createState() => _DrinkTypesWidgetState();
}

class _DrinkTypesWidgetState extends State<DrinkTypesWidget> {
  double _waterIntake = 0.0;
  int _stepCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWaterIntake();
  }

  Future<void> _fetchWaterIntake() async {
    try {
      final history =
          await context.read<BottleDataCubit>().getCurrentDayHistory();
      setState(() {
        _waterIntake = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(AppDimensions.defaultPadding.w),
      margin: EdgeInsets.only(
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
          bottom: AppDimensions.dim80.h),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_4,
              color: AppColors.black.withOpacity(.25),
              offset: Offset(
                AppDimensions.dim2,
                AppDimensions.dim2,
              ),
            )
          ],
          borderRadius: BorderRadius.circular(
            AppDimensions.radius_10.w,
          ),
          color: Color(0XFFFFFFFF),
          border: Border.all(color: AppColors.greywith80)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Hydration Source",
                style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_20,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ],
          ),
          SizedBox(
            height: AppDimensions.dim10.h,
          ),
          Row(
            children: [
              SizedBox(
                width: AppDimensions.dim120.w,
                height: AppDimensions.dim120.w,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/img_hydration_source.png",
                      ),
                    ),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${_waterIntake.toStringAsFixed(0)} ml",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: AppFontStyles.fontSize_24,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                          Text(
                            "Water Intake",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: AppFontStyles.fontSize_10,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [
                                AppFontStyles.regularFontVariation
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: AppDimensions.dim18.w,
              ),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: AppDimensions.dim14.w,
                          height: AppDimensions.dim14.w,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.dim2),
                            color: Color(
                              0XFF369FFF,
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: AppDimensions.dim2,
                                color: Colors.black.withOpacity(.3),
                                offset: Offset(
                                  AppDimensions.dim2,
                                  AppDimensions.dim2,
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          width: AppDimensions.dim8.w,
                        ),
                        Text(
                          "Water",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppFontStyles.fontSize_16,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.fontWeightVariation600
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: AppDimensions.dim12.h,
                    ),
                    Row(
                      children: [
                        Container(
                          width: AppDimensions.dim14.w,
                          height: AppDimensions.dim14.w,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.dim2),
                            color: Color(
                              0XFF81CC72,
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: AppDimensions.dim2,
                                color: Colors.black.withOpacity(.3),
                                offset: Offset(
                                  AppDimensions.dim2,
                                  AppDimensions.dim2,
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          width: AppDimensions.dim8.w,
                        ),
                        _isLoading
                            ? SizedBox(
                                width: AppDimensions.dim16.w,
                                height: AppDimensions.dim16.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.bluegray),
                                ),
                              )
                            : Text(
                                "Steps: $_stepCount",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: AppFontStyles.fontSize_16,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontVariations: [
                                    AppFontStyles.fontWeightVariation600
                                  ],
                                ),
                              ),
                      ],
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
