import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/contact_support_page.dart';
import 'package:hydrify/screens/faq_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpMenuItem extends StatelessWidget {
  final String title;
  final String? route; // optional navigation route
  final String? url; // optional URL to open
  final String iconPathArrow;
  final bool isRed;

  const HelpMenuItem({
    super.key,
    required this.title,
    required this.iconPathArrow,
    this.route,
    this.url,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (url != null) {
          // Open URL in browser
          final uri = Uri.parse(url!);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not open the webpage")),
            );
          }
        } else if (route != null) {
          final navigator = Navigator.of(context);
          switch (route) {
            case 'faq':
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => FAQ_Page(),
                ),
              );

              break;

            case 'contact_support':
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => ContactSupportPage(),
                ),
              );

              break;

            case 'support_ticket':
              Navigator.of(context, rootNavigator: true)
                  .pushNamed('/help_support_ticket');
              break;

            default:
          }

          // Navigate to internal route
          // Navigator.pushNamed(context, route!);
        } else {
          // No action defined
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No action available")),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.dim16.w,
          vertical: AppDimensions.dim12.h,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isRed ? Colors.red : AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_20.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.fontWeightVariation600],
              ),
            ),
            const Spacer(),
            Image.asset(
              iconPathArrow,
              color: AppColors.bluegray,
              width: AppDimensions.dim9.w,
              height: AppDimensions.dim16.h,
            ),
            SizedBox(width: AppDimensions.dim8.w),
          ],
        ),
      ),
    );
  }
}

//==========================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';

// class HelpMenuItem extends StatelessWidget {
//   final String title;
//   final String route;
//   final String iconPathArrow;
//   final bool isRed;

//   const HelpMenuItem({
//     super.key,
//     required this.title,
//     required this.route,
//     required this.iconPathArrow,
//     this.isRed = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () => Navigator.pushNamed(context, route),
//       child: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: AppDimensions.dim16.w,
//           vertical: AppDimensions.dim12.h,
//         ),
//         child: Row(
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 color: AppColors.white,
//                 fontSize: AppFontStyles.fontSize_20.sp,
//                 fontFamily: AppFontStyles.urbanistFontFamily,
//                 fontVariations: [AppFontStyles.fontWeightVariation600],
//               ),
//             ),
//             const Spacer(),
//             Image.asset(
//               iconPathArrow,
//               color: AppColors.white,
//               width: AppDimensions.dim9.w,
//               height: AppDimensions.dim16.h,
//             ),
//             SizedBox(width: AppDimensions.dim8.w),
//           ],
//         ),
//       ),
//     );
//   }
// }

//============================================================================
