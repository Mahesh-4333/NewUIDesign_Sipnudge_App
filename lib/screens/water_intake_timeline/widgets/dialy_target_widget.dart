import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';

class DailyTargetWidget extends StatelessWidget {
  const DailyTargetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottleDataCubit, BottleDataState>(
        buildWhen: (previous, current) => previous.volume != current.volume,
        builder: (context, state) {
          return FutureBuilder<double>(
            future: () async {
              final historyData = await context
                  .read<BottleDataCubit>()
                  .getCurrentDayHistory();

              double waterVolumeConsumed = historyData;

              double completionPercent = await WaterConsumptionCalculator
                  .calculateCompletionPercentage(
                waterVolumeConsumed,
              );

              return completionPercent;
            }(),
            builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
              double completionPercent = snapshot.data ?? 0.0;

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${completionPercent.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: AppColors.blueWaterIntake,
                            fontSize: 22.sp,
                            fontFamily:
                            AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.boldFontVariation
                            ],
                          ),
                        ),
                        TextSpan(
                          text: " of Daily Target",
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: 20.sp,
                            fontFamily:
                            AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.boldFontVariation
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  BlocBuilder<BleCubit, BleState>(
                    builder: (context, bleState) {
                      Color syncColor = bleState.status != BleStatus.connected
                          ? AppColors.redColor
                          : Color(0xff46E73D);

                      return RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: 15.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.semiBoldFontVariation],
                          ),
                          children: [
                            const TextSpan(text: "Connect your Bottle to "),
                            TextSpan(
                              text: "sync",
                              style: TextStyle(color: syncColor, fontVariations: [AppFontStyles.extraBoldFontVariation]),
                            ),
                            const TextSpan(text: " data"),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        });
  }
}
