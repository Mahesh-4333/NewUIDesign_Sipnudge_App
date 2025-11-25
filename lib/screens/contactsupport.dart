// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class CustomerSupportPage extends StatefulWidget {
//   const CustomerSupportPage({super.key});

//   @override
//   State<CustomerSupportPage> createState() => _CustomerSupportPageState();
// }

// class _CustomerSupportPageState extends State<CustomerSupportPage> {
//   String title = 'Home';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFFB586BE), Color(0xFF131313)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // Top bar
//                   Padding(
//                     padding: EdgeInsets.only(
//                       top: 40.h,
//                       left: 20.w,
//                       right: 20.w,
//                     ),
//                     child: Row(
//                       children: [
//                         IconButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           icon: Icon(
//                             Icons.arrow_back,
//                             color: Color(0xFF212121),
//                             size: 30.sp,
//                           ),
//                         ),
//                         SizedBox(width: 50.w),
//                         Text(
//                           'Customer Support',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 24.sp,
//                             fontFamily: 'urbanist-Bold',
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 50.h),

//                   // Buttons
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 30.w),
//                     child: Column(
//                       children: [
//                         buildSocialButton(
//                           iconPath: 'assets/customersupporticon.png',
//                           label: 'Customer Support',
//                           onPressed: () {},
//                         ),
//                         SizedBox(height: 20.h),
//                         buildSocialButton(
//                           iconPath: 'assets/websiteicon.png',
//                           label: 'Website',
//                           onPressed: () {},
//                         ),
//                         SizedBox(height: 20.h),
//                         buildSocialButton(
//                           iconPath: 'assets/whatsappicon.png',
//                           label: 'WhatsApp',
//                           onPressed: () {},
//                         ),
//                         SizedBox(height: 20.h),
//                         buildSocialButton(
//                           iconPath: 'assets/instaicon.png',
//                           label: 'Instagram',
//                           onPressed: () {},
//                         ),
//                       ],
//                     ),
//                   ),

//                   const Spacer(),

//                   // Bottom Navigation
//                   Container(
//                     height: 70.h,
//                     margin: EdgeInsets.symmetric(horizontal: 20.w),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(90.r),
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF3F3F3F), Color(0xFFFFFFFF)],
//                         begin: Alignment.bottomCenter,
//                         end: Alignment.topCenter,
//                       ),
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.all(1.w),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(horizontal: 8.w),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2B2536),
//                           borderRadius: BorderRadius.circular(90.r),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             _buildNavItem(Icons.home, 'Home', title == 'Home'),
//                             _buildNavItem(
//                               Icons.analytics_outlined,
//                               'Analysis',
//                               title == 'Analysis',
//                             ),
//                             _buildNavItem(
//                               Icons.lightbulb_outline,
//                               'Goals',
//                               title == 'Goals',
//                             ),
//                             _buildNavItem(
//                               Icons.settings,
//                               'Settings',
//                               title == 'Settings',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildSocialButton({
//     required String iconPath,
//     required String label,
//     Color? iconColor,
//     required VoidCallback onPressed,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(1000.r),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0x40000000),
//             offset: Offset(4.r, 4.r),
//             blurRadius: 4.r,
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: Colors.white,
//           padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(1000.r),
//           ),
//         ),
//         child: Row(
//           children: [
//             Image.asset(iconPath, width: 24.w, height: 24.w, color: iconColor),
//             SizedBox(width: 16.w),
//             Text(
//               label,
//               style: TextStyle(
//                 color: const Color(0xFF212121),
//                 fontFamily: 'Urbanist-Bold',
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const Spacer(),
//             Icon(Icons.chevron_right, color: Colors.black, size: 24.sp),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(IconData icon, String label, bool isActive) {
//     final assetPath = 'assets/${label.toLowerCase()}.png';
//     double scale = 1.0;

//     return StatefulBuilder(
//       builder: (context, setState) {
//         return GestureDetector(
//           onTapDown: (_) => setState(() => scale = 0.9),
//           onTapUp: (_) => setState(() => scale = 1.0),
//           onTapCancel: () => setState(() => scale = 1.0),
//           onTap: () => _handleBottomNavigation(label),
//           child: AnimatedScale(
//             scale: scale,
//             duration: const Duration(milliseconds: 100),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 60.w,
//                   height: 50.h,
//                   decoration: BoxDecoration(
//                     gradient:
//                         isActive
//                             ? const LinearGradient(
//                               colors: [Color(0xFFFAFAFA), Color(0xFF3E3E3E)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             )
//                             : null,
//                     color: isActive ? null : Colors.transparent,
//                     borderRadius: BorderRadius.circular(48.r),
//                     boxShadow:
//                         isActive
//                             ? [
//                               BoxShadow(
//                                 offset: const Offset(4, 4),
//                                 color: const Color(0x40000000),
//                                 blurRadius: 4.r,
//                               ),
//                             ]
//                             : [],
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(1.w),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient:
//                             isActive
//                                 ? const LinearGradient(
//                                   colors: [
//                                     Color(0xFFB182BA),
//                                     Color(0xFF2D1B31),
//                                   ],
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                 )
//                                 : null,
//                         color: isActive ? null : Colors.transparent,
//                         borderRadius: BorderRadius.circular(46.r),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             assetPath,
//                             width: 20.w,
//                             height: 20.w,
//                             color: Colors.white,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Icon(
//                                 icon,
//                                 size: 20.sp,
//                                 color: Colors.white,
//                               );
//                             },
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             label,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12.sp,
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

//   void _handleBottomNavigation(String label) {
//     setState(() {
//       title = label;
//     });

//     switch (label) {
//       case 'Home':
//         Navigator.pushNamed(context, '/homepage');
//         break;
//       case 'Analysis':
//         Navigator.pushNamed(context, '/analysis');
//         break;
//       case 'Goals':
//         Navigator.pushNamed(context, '/dailygoalpage');
//         break;
//       case 'Settings':
//         Navigator.pushNamed(context, '/preferences');
//         break;
//       default:
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('$label screen coming soon!')));
//     }
//   }
// }
