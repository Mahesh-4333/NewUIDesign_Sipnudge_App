import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/l10n/app_localizations.dart';

class DailyTargetWidget extends StatelessWidget {
  const DailyTargetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<BleCubit, BleState>(
        buildWhen: (previous, current) =>
            previous.currentHydrationValue != current.currentHydrationValue,
        builder: (context, state) {
          return FutureBuilder<double>(
            future: () async {
              final historyData =
                  await context.read<BottleDataCubit>().getCurrentDayHistory();

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
                return Center(
                  child: SizedBox(
                      height: 30.h,
                      width: 30.h,
                      child: const CircularProgressIndicator()),
                );
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
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        TextSpan(
                          text: l10n?.ofDailyTarget ?? " of Daily Target",
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: 20.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
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
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                          children: [
                            TextSpan(
                                text: l10n?.connectBottleTo ??
                                    "Connect your Bottle to "),
                            TextSpan(
                              text: l10n?.syncWord ?? "sync",
                              style: TextStyle(
                                  color: syncColor,
                                  fontVariations: [
                                    AppFontStyles.extraBoldFontVariation
                                  ]),
                            ),
                            TextSpan(text: l10n?.dataWord ?? " data"),
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
