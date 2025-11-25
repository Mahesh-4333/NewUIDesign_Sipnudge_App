import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';

import '../../../constants/app_dimensions.dart';

class DrinkTypesWidget extends StatelessWidget {
  DrinkTypesWidget({super.key});

  double waterIntakePercent = .0;
  double waterVolumeConsumed = 0.0;
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
                            "100%",
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
                          "Water(80%)",
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
                        Text(
                          "Food  (20%)",
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
