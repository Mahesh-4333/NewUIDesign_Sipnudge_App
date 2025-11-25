// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class HelpAndSupportPage extends StatefulWidget {
//   const HelpAndSupportPage({super.key});

//   @override
//   State<HelpAndSupportPage> createState() => _HelpAndSupportPage();
// }

// class _HelpAndSupportPage extends State<HelpAndSupportPage> {
//   String title = 'Home'; // Add this line to track active tab

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final screenWidth = size.width;
//     final screenHeight = size.height;

//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFB586BE), Color(0xFF131313)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Top user info
//               Padding(
//                 padding: EdgeInsets.only(
//                   top: screenHeight * 0.05,
//                   left: screenWidth * 0.06,
//                   right: screenWidth * 0.05,
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: const BoxDecoration(
//                         //shape: BoxShape.circle,
//                         color: Colors.transparent,
//                       ),
//                       child: IconButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         icon: Icon(
//                           Icons.arrow_back,
//                           color: Colors.black,
//                           size: 30.sp,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: screenWidth * 0.19),
//                     const Text(
//                       'Help & Support',
//                       style: TextStyle(
//                         color: Color(0xFFFFFFFF),
//                         fontSize: 24,
//                         fontFamily: 'urbanist-Bold',
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: screenHeight * 0.05),

//               // First menu card
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0x1AFFFFFF),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       _buildMenuItem('F&Q'),
//                       _buildMenuItem('Contact Support'),
//                       _buildMenuItem('Privacy Policy'),
//                       _buildMenuItem('Terms of Service'),
//                       _buildMenuItem('About Us'),
//                     ],
//                   ),
//                 ),
//               ),

//               SizedBox(height: screenHeight * 0.042),

//               const Spacer(),

//               // Bottom navigation
//               Container(
//                 height: screenHeight * 0.09,
//                 //width: screenWidth * 0.09,
//                 margin: EdgeInsets.only(
//                   left: screenWidth * 0.05,
//                   right: screenWidth * 0.05,
//                   bottom: screenHeight * 0.0,
//                 ),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(90.r),
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF3F3F3F), Color(0xFFFFFFFF)],
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                   ),
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.all(1.w),
//                   child: Container(
//                     padding: EdgeInsets.only(
//                       left: screenHeight * 0.007.w,
//                       right: screenHeight * 0.006.w,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF2B2536),
//                       borderRadius: BorderRadius.circular(90.r),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildNavItem(
//                           Icons.home,
//                           'Home',
//                           title == 'Home',
//                           screenWidth,
//                           screenHeight,
//                         ),
//                         _buildNavItem(
//                           Icons.analytics_outlined,
//                           'Analysis',
//                           title == 'Analysis',
//                           screenWidth,
//                           screenHeight,
//                         ),
//                         _buildNavItem(
//                           Icons.lightbulb_outline,
//                           'Goals',
//                           title == 'Goals',
//                           screenWidth,
//                           screenHeight,
//                         ),
//                         _buildNavItem(
//                           Icons.settings,
//                           'Settings',
//                           title == 'Settings',
//                           screenWidth,
//                           screenHeight,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuItem(String title, {bool isRed = false}) {
//     return InkWell(
//       onTap: () {
//         debugPrint('Tapped on: $title');
//         _handleNavigation(title);

//         /*if (isRed) {
//           _showLogoutConfirmation();
//         } else {
//           _handleNavigation(title);
//         }*/
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Row(
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 color: isRed ? Colors.redAccent : Colors.white,
//                 fontFamily: 'urbanist-Bold',
//                 fontSize: 18.sp,
//               ),
//             ),
//             const Spacer(),
//             const SizedBox(width: 15),
//             Icon(Icons.chevron_right, color: Color(0xFFFFFFFF), size: 24.sp),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleNavigation(String title) {
//     switch (title) {
//       case 'F&Q':
//         Navigator.pushNamed(context, '/f&q');
//         break;
//       case 'Contact Support':
//         Navigator.pushNamed(context, '/contact_support');
//         break;
//       case 'Privacy Policy':
//         Navigator.pushNamed(context, '/privacy_policy');
//         break;
//       case 'Terms of Service':
//         Navigator.pushNamed(context, '/terms_of_service');
//         break;
//       case 'About Us':
//         Navigator.pushNamed(context, '/about_us');
//         break;
//       default:
//         debugPrint('No route defined for $title');
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('$title screen coming soon!')));
//     }
//   }

//   //void _showLogoutConfirmation() {
//   /*showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF2A2A2A),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           'Logout',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         content: const Text(
//           'Are you sure you want to logout?',
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Logged out successfully')),
//               );
//             },
//             child: const Text(
//               'Logout',
//               style: TextStyle(color: Colors.redAccent),
//             ),
//           ),
//         ],
//       ),
//     );
//   }*/

//   Widget _buildNavItem(
//     IconData icon,
//     String label,
//     bool isActive,
//     double screenWidth,
//     double screenHeight,
//   ) {
//     final assetPath = 'assets/${label.toLowerCase()}.png';
//     double scale = 1.0;

//     return StatefulBuilder(
//       builder: (context, setState) {
//         return GestureDetector(
//           onTapDown: (_) => setState(() => scale = 0.9),
//           onTapUp: (_) => setState(() => scale = 1.0),
//           onTapCancel: () => setState(() => scale = 1.0),
//           onTap: () {
//             debugPrint('Tapped on: $label');
//             _handleBottomNavigation(label);
//           },
//           child: AnimatedScale(
//             scale: scale,
//             duration: const Duration(milliseconds: 10),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: screenWidth * 0.2,
//                   height: screenHeight * 0.06,
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
//                     boxShadow: [
//                       BoxShadow(
//                         offset: const Offset(4, 4),
//                         color:
//                             isActive
//                                 ? const Color(0x40000000)
//                                 : Colors.transparent,
//                         blurRadius: 4,
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(1.0),
//                     child: Container(
//                       width: screenWidth * 0.19,
//                       height: screenHeight * 0.055,
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
//                         borderRadius: BorderRadius.circular(46),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             assetPath,
//                             width: screenWidth * 0.06,
//                             height: screenWidth * 0.06,
//                             color: Colors.white,
//                             errorBuilder: (context, error, stackTrace) {
//                               debugPrint(
//                                 'Error loading image: $assetPath - $error',
//                               );
//                               return Icon(
//                                 icon,
//                                 size: screenWidth * 0.055,
//                                 color: Colors.white,
//                               );
//                             },
//                           ),
//                           Text(
//                             label,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: screenWidth * 0.03,
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

//   /* Widget _buildNavItem(
//     IconData icon,
//     String label,
//     bool isActive,
//     double screenWidth,
//     double screenHeight,
//   ) {
//     final assetPath = 'assets/${label.toLowerCase()}.png';
//     double scale = 1.0;

//     return StatefulBuilder(
//       builder: (context, setState) {
//         return GestureDetector(
//           onTapDown: (_) => setState(() => scale = 0.70),
//           onTapUp: (_) => setState(() => scale = 0.90),
//           onTapCancel: () => setState(() => scale = 0.90),
//           onTap: () {
//             debugPrint('Tapped on: $label');
//             _handleBottomNavigation(label);
//           },
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: screenWidth * 0.2,
//                 height: screenHeight * 0.06,
//                 decoration: BoxDecoration(
//                   gradient:
//                       isActive
//                           ? const LinearGradient(
//                             colors: [Color(0xFFFAFAFA), Color(0xFF3E3E3E)],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           )
//                           : null,
//                   color: isActive ? null : Colors.transparent,
//                   borderRadius: BorderRadius.circular(48.r),
//                   boxShadow: [
//                     BoxShadow(
//                       offset: const Offset(4, 4),
//                       color:
//                           isActive
//                               ? const Color(0x40000000)
//                               : Colors.transparent,
//                       blurRadius: 4,
//                     ),
//                   ],
//                 ),
//                 child: AnimatedScale(
//                   scale: scale,
//                   duration: const Duration(milliseconds: 100),
//                   child: Padding(
//                     padding: EdgeInsets.all(1.r),
//                     child: Container(
//                       width: screenWidth * 0.19,
//                       height: screenHeight * 0.055,
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
//                             width: screenWidth * 0.06,
//                             height: screenWidth * 0.06,
//                             color: Colors.white,
//                             errorBuilder: (context, error, stackTrace) {
//                               debugPrint(
//                                 'Error loading image: $assetPath - $error',
//                               );
//                               return Icon(
//                                 icon,
//                                 size: screenWidth * 0.055,
//                                 color: Colors.white,
//                               );
//                             },
//                           ),
//                           Text(
//                             label,
//                             style: TextStyle(
//                               color: const Color(0xFFFFFFFF),
//                               fontSize: screenWidth * 0.03,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }*/

//   void _handleBottomNavigation(String label) {
//     setState(() {
//       title = label; // Update active tab
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
//         debugPrint('No route defined for $label');
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('$label screen coming soon!')));
//     }
//   }
// }

// /*Widget _buildNavItem(IconData icon, String label, bool isActive) {
//     final assetPath = 'assets/${label.toLowerCase()}.png';

//     return InkWell(
//       onTap: () {
//         debugPrint('Tapped on: $label');
//         _handleBottomNavigation(label);
//       },
//       child:  Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 82,
//             height: 60,
//             decoration: BoxDecoration(
//               gradient: isActive
//                   ? const LinearGradient(
//                       colors: [Color(0xFFFAFAFA), Color(0xFF3E3E3E)],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     )
//                   : null,
//               color: isActive ? null : Colors.transparent,
//               borderRadius: BorderRadius.circular(48),
//               boxShadow: [
//                 BoxShadow(
//                   offset: const Offset(4, 4),
//                   color: isActive ? const Color(0x40000000) : Colors.transparent,
//                   blurRadius: 4,
//                 ),
//               ],
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(1),
//               child: Container(
//                 width: 80,
//                 height: 58,
//                 decoration: BoxDecoration(
//                   gradient: isActive
//                       ? const LinearGradient(
//                           colors: [Color(0xFFB182BA), Color(0xFF2D1B31)],
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                         )
//                       : null,
//                   color: isActive ? null : Colors.transparent,
//                   borderRadius: BorderRadius.circular(46),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset(
//                       assetPath,
//                       width: 24,
//                       height: 24,
//                       color: Colors.white,
//                       errorBuilder: (context, error, stackTrace) {
//                         debugPrint('Error loading image: $assetPath - $error');
//                         return Icon(icon, size: 22, color: Colors.white);
//                       },
//                     ),
//                     Text(
//                       label,
//                       style: TextStyle(
//                         color: const Color(0xFFFFFFFF),
//                         fontSize: 12.sp,
//                         fontFamily: 'Lexend-Regular',
//                         fontWeight:
//                             isActive ? FontWeight.w300 : FontWeight.normal,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
//         ],
//       )
//     );
//   }
//   void _handleBottomNavigation(String label) {   
//     setState(() {
//       title = label; // Update active tab
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
//         debugPrint('No route defined for $label');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('$label screen coming soon!')),
//         );
//     }
//   }
// }*/
