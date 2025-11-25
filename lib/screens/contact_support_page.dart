import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/screens/widgets/animated_bottom_navbar_widget.dart';
import 'package:hydrify/screens/widgets/contact_support_widget/contact_support_buttons.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppStrings.contactsupport,
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
        width: AppDimensions.dim1.sw,
        height: AppDimensions.dim1.sh,
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
          child: Column(
            children: [
              /// 🔹 Top Bar
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
              //           color: AppColors.black,
              //           size: AppFontStyles.fontSize_30.sp,
              //         ),
              //       ),
              //       SizedBox(width: AppDimensions.dim60.w),
              //       Text(
              //         AppStrings.contactsupport,
              //         style: TextStyle(
              //           color: AppColors.bluegray,
              //           fontSize: AppFontStyles.fontSize_24.sp,
              //           fontFamily: AppFontStyles.urbanistFontFamily,
              //           fontVariations: [AppFontStyles.boldFontVariation],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              SizedBox(height: AppDimensions.dim30.h),

              /// 🔹 Support Options
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim30.w,
                ),
                child: Column(
                  children: [
                    // SupportButton(
                    //   iconPath: 'assets/customersupporticon.png',
                    //   label: 'Customer Support',
                    //   iconpatharrow: "assets/arrow.png",
                    //   url: "https://sipnudge.com/pages/contact",
                    // ),
                    // SizedBox(height: AppDimensions.dim20.h),
                    SupportButton(
                      iconPath: 'assets/websiteicon.png',
                      iconColor: AppColors.bluegray,
                      label: 'Website',
                      iconpatharrow: "assets/arrow.png",
                      url: "https://sipnudge.com/",
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// 🔹 Bottom Navigation
              Padding(
                  padding: EdgeInsets.only(
                    bottom: AppDimensions.dim5.h,
                    right: AppDimensions.dim15.w,
                    left: AppDimensions.dim15.w,
                  ),
                  child: AnimatedBottomNavBar()),
            ],
          ),
        ),
      ),
    );
  }
}
