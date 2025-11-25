import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppFontStyles {
  static String museoModernoFontFamily = "MuseoModerno";
  static String urbanistFontFamily = "Urbanist";
  static String lexendFontFamily = "Lexend";
  static String poppinsFamily = "Poppins";
  static String fontWeightVariationKey = "wght";
  static double fontWeightExtraBoldValue = 900;
  static double fontWeightBoldValue = 700;
  static double fontWeight600Value = 600;
  static double fontWeightSemiBoldValue = 500;
  static double fontWeightRegularValue = 400;
  static double fontWeightExtraLightValue = 200;
  static double fontWeightLightValue = 300;

  static double lineHeight_160 = 160;
  static double fontSize_1 = 1.sp;
  static double fontSize_16 = 16.sp;
  static double fontSize_14 = 14.sp;
  static double fontSize_12 = 12.sp;
  static double fontSize_13 = 13.sp;
  static double fontSize_15 = 15.sp;
  static double fontSize_10 = 10.sp;
  static double fontSize_18 = 18.sp;
  static double fontSize_17 = 17.sp;
  static double fontSize_19 = 19.sp;
  static double fontSize_20 = 20.sp;
  static double fontSize_22 = 22.sp;
  static double fontSize_30 = 30.sp;
  static double fontSize_35 = 35.sp;
  static double fontSize_24 = 24.sp;
  static double fontSize_28 = 28.sp;
  static double fontSize_32 = 32.sp;
  static double fontSize_36 = 36.sp;
  static double fontSize_72 = 72.sp;
  static double fontSize_74 = 74.sp;
  static double fontSize_80 = 80.sp;

  static double fontSize_AppBar = fontSize_20;
  static double textFieldInputSize = fontSize_18;
  static double unSelectedTabTextSize = fontSize_16;
  static double selectedTabTextSize = fontSize_16;

  static FontVariation semiBoldFontVariation =
      FontVariation(fontWeightVariationKey, fontWeightSemiBoldValue);
  static FontVariation lightFontWeightVariation =
      FontVariation(fontWeightVariationKey, fontWeightLightValue);
  static FontVariation fontWeightVariation600 =
      FontVariation(fontWeightVariationKey, fontWeight600Value);
  static FontVariation boldFontVariation =
      FontVariation(fontWeightVariationKey, fontWeightBoldValue);
  static FontVariation regularFontVariation =
      FontVariation(fontWeightVariationKey, fontWeightRegularValue);
  static FontVariation extraBoldFontVariation = FontVariation(
    fontWeightVariationKey,
    fontWeightExtraBoldValue,
  );

  static double getLineHeight(double fontSize, double lineHeightPercent) {
    return lineHeightPercent / 100;
  }
}
