// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_colors.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/screens/widgets/navigation_helper.dart';

// class CustomBottomNavBar extends StatefulWidget {
//   final String activeTab; // current active tab
//   final Function(String) onTabSelected; // callback when tab tapped

//   const CustomBottomNavBar({
//     super.key,
//     required this.activeTab,
//     required this.onTabSelected,
//   });

//   @override
//   State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
// }

// class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
//   Widget _buildNavItem(IconData icon, String label, bool isActive) {
//     final assetPath = 'assets/${label.toLowerCase()}.png';
//     double scale = 1.0;

//     return StatefulBuilder(
//       builder: (context, setState) {
//         return GestureDetector(
//           onTapDown: (_) => setState(() => scale = 0.9),
//           onTapUp: (_) => setState(() => scale = 1.0),
//           onTapCancel: () => setState(() => scale = 1.0),
//           onTap: () {
//             NavigationHelper.navigate(
//               context,
//               label,
//             ); // ✅ centralized navigation
//             widget.onTabSelected(label); // ✅ notify parent
//           },
//           child: AnimatedScale(
//             scale: scale,
//             duration: const Duration(milliseconds: 100),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: AppDimensions.dim80.w,
//                   height: AppDimensions.dim50.h,
//                   decoration: BoxDecoration(
//                     gradient: isActive
//                         ? const LinearGradient(
//                             colors: [AppColors.alabaster, AppColors.iridium],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           )
//                         : null,
//                     color: isActive ? null : Colors.transparent,
//                     borderRadius: BorderRadius.circular(
//                       AppDimensions.radius_48.r,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         offset: Offset(4.r, 4.r),
//                         color:
//                             isActive ? AppColors.black40 : Colors.transparent,
//                         blurRadius: 4.r,
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(AppDimensions.dim1.w),
//                     child: Container(
//                       width: AppDimensions.dim75.w,
//                       height: AppDimensions.dim45.h,
//                       decoration: BoxDecoration(
//                         gradient: isActive
//                             ? const LinearGradient(
//                                 colors: [
//                                   AppColors.navbarSelectedItemGradientStart,
//                                   AppColors.navbarSelectedItemGradientEnd,
//                                   // Color(0xFFB182BA),
//                                   // Color(0xFF2D1B31),
//                                 ],
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                               )
//                             : null,
//                         color: isActive ? null : Colors.transparent,
//                         borderRadius: BorderRadius.circular(
//                           AppDimensions.radius_46.r,
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             assetPath,
//                             width: AppDimensions.dim22.w,
//                             height: AppDimensions.dim22.h,
//                             color: Colors.white,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Icon(
//                                 icon,
//                                 size: AppFontStyles.fontSize_20.w,
//                                 color: AppColors.white,
//                               );
//                             },
//                           ),
//                           SizedBox(height: AppDimensions.dim2.h),
//                           Text(
//                             label,
//                             style: TextStyle(
//                               color: AppColors.white,
//                               fontSize: AppFontStyles.fontSize_10.sp,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tabs = [
//       {'icon': Icons.home, 'label': 'Home'},
//       {'icon': Icons.bar_chart, 'label': 'Analysis'},
//       {'icon': Icons.flag, 'label': 'Goals'},
//       {'icon': Icons.settings, 'label': 'Settings'},
//     ];

//     return Container(
//       height: 75.h,
//       margin: EdgeInsets.only(
//         left: AppDimensions.dim20.w,
//         right: AppDimensions.dim20.w,
//         bottom: AppDimensions.dim4.h,
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(AppDimensions.radius_90.r),
//         gradient: const LinearGradient(
//           colors: [AppColors.charcoalGrey, AppColors.white],
//           begin: Alignment.bottomCenter,
//           end: Alignment.topCenter,
//         ),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(AppDimensions.dim1.w),
//         child: Container(
//           padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim10.w),
//           decoration: BoxDecoration(
//             color: AppColors.bleachedCedar,
//             borderRadius: BorderRadius.circular(AppDimensions.radius_90.r),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: tabs.map((tab) {
//               final label = tab['label'] as String;
//               final icon = tab['icon'] as IconData;
//               return _buildNavItem(icon, label, widget.activeTab == label);
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

//==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/screens/widgets/navigation_helper.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String activeTab; // current active tab
  final Function(String) onTabSelected; // callback when tab tapped

  const CustomBottomNavBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final assetPath = 'assets/${label.toLowerCase()}.png';
    double scale = 1.0;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.9),
          onTapUp: (_) => setState(() => scale = 1.0),
          onTapCancel: () => setState(() => scale = 1.0),
          onTap: () {
            NavigationHelper.navigate(
              context,
              label,
            ); // ✅ centralized navigation
            widget.onTabSelected(label); // ✅ notify parent
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: AppDimensions.dim80.w,
                  height: AppDimensions.dim50.h,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [AppColors.alabaster, AppColors.iridium],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isActive ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radius_48.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(4.r, 4.r),
                        color:
                            isActive ? AppColors.black40 : Colors.transparent,
                        blurRadius: 4.r,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.dim1.w),
                    child: Container(
                      width: AppDimensions.dim75.w,
                      height: AppDimensions.dim45.h,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [
                                  AppColors.navbarSelectedItemGradientStart,
                                  AppColors.navbarSelectedItemGradientEnd,
                                  // Color(0xFFB182BA),
                                  // Color(0xFF2D1B31),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isActive ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radius_46.r,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            assetPath,
                            width: AppDimensions.dim22.w,
                            height: AppDimensions.dim22.h,
                            color: Colors.white,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: AppFontStyles.fontSize_20.w,
                                color: AppColors.white,
                              );
                            },
                          ),
                          SizedBox(height: AppDimensions.dim2.h),
                          Text(
                            label,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: AppFontStyles.fontSize_10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.bar_chart, 'label': 'Analysis'},
      {'icon': Icons.flag, 'label': 'Goals'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    return Container(
      height: 75.h,
      margin: EdgeInsets.only(
        left: AppDimensions.dim20.w,
        right: AppDimensions.dim20.w,
        bottom: AppDimensions.dim4.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radius_90.r),
        gradient: const LinearGradient(
          colors: [AppColors.charcoalGrey, AppColors.white],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.dim1.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim10.w),
          decoration: BoxDecoration(
            color: AppColors.bleachedCedar,
            borderRadius: BorderRadius.circular(AppDimensions.radius_90.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final label = tab['label'] as String;
              final icon = tab['icon'] as IconData;
              return _buildNavItem(icon, label, widget.activeTab == label);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
