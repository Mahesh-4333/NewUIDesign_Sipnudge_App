// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class FAQ_Page extends StatefulWidget {
//   const FAQ_Page({super.key});

//   @override
//   State<FAQ_Page> createState() => _FAQ_PageState();
// }

// class _FAQ_PageState extends State<FAQ_Page>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   final TextEditingController _searchController = TextEditingController();
//   String selected = 'General';
//   bool isExpanded = true;
//   bool isExpanded2 = false;
//   String title = 'Home';

//   Map<String, List<Map<String, String>>> faqData = {
//     'General': [
//       {
//         'question': 'What is Sipnudge?',
//         'answer':
//             'Sipnudge is a smart hydration bottle designed to help you stay properly hydrated throughout the day...',
//       },
//       {
//         'question': 'What makes SipNudge different from other water bottles?',
//         'answer':
//             'Unlike regular water bottles, SipNudge actively encourages you to drink through personalized reminders...',
//       },
//     ],
//     'Usage': [
//       {
//         'question': 'How does SipNudge work?',
//         'answer':
//             'SipNudge uses a combination of sensors to track how much water you drink...',
//       },
//       {
//         'question': 'Is SipNudge dishwasher safe?',
//         'answer':
//             'The bottle body is dishwasher safe (top rack recommended). Remove the smart sensor before washing...',
//       },
//       {
//         'question': 'What is the battery life of SipNudge?',
//         'answer': 'Typically lasts for several weeks on a single charge...',
//       },
//       {
//         'question': 'How do I charge SipNudge?',
//         'answer':
//             'SipNudge comes with a USB charging cable that connects to the sensor unit.',
//       },
//       {
//         'question': 'What if I lose my charging cable?',
//         'answer':
//             'You can contact our customer support to purchase a replacement charging cable.',
//       },
//     ],
//     'App': [
//       {
//         'question': 'Do I need a smartphone to use SipNudge?',
//         'answer':
//             'While SipNudge can function independently, connecting it to the SipNudge app (available for iOS and Android) unlocks its full potential. The app allows you to personalize your hydration goals, track your progress, and receive detailed insights into your hydration habits.',
//       },
//       {
//         'question': 'How do I connect SipNudge to the app?',
//         'answer':
//             'The connection process is simple and guided within the app. Typically, it involves enabling Bluetooth on your smartphone and following the on-screen instructions.',
//       },
//       {
//         'question': 'What if I have trouble connecting to the app?',
//         'answer':
//             'Check that Bluetooth is enabled on your phone and that your phone is compatible with the SipNudge app. If you continue to experience issues, please contact our customer support.',
//       },
//       {
//         'question': 'Can I use SipNudge without the app?',
//         'answer':
//             "Yes, SipNudge can function without the app. It will still track your water intake and provide basic hydration reminders. However, you won't be able to personalize your goals or access detailed tracking information.",
//       },
//     ],
//     'Tracking': [
//       {
//         'question': "How accurate is SipNudge's hydration tracking?",
//         'answer':
//             "SipNudge uses advanced sensors to accurately measure your water intake. However, slight variations may occur. It’s designed to provide a reliable estimate of your hydration levels.",
//       },
//       {
//         'question': 'Can I customize the reminders?',
//         'answer':
//             "Yes, you can customize the frequency and intensity of the reminders through the app. You can also choose between vibration and light cues, or a combination of both.",
//       },
//       {
//         'question': "What if I don't want to be reminded at certain times?",
//         'answer':
//             "You can set 'quiet hours' within the app to disable reminders during specific periods, such as when you're sleeping.",
//       },
//     ],
//     'Troubleshooting': [
//       {
//         'question':
//             "What if SipNudge isn't tracking my water intake correctly?",
//         'answer':
//             "Ensure that the sensor unit is properly attached and clean. If the issue persists, please contact our customer support.",
//       },
//       {
//         'question': "What if the reminders aren't working?",
//         'answer':
//             "Check that the reminders are enabled in the app and that the battery is sufficiently charged. Also, make sure the vibration and light settings are configured correctly.",
//       },
//     ],
//     'Support': [
//       {
//         'question': 'What is the warranty period for SipNudge?',
//         'answer':
//             "SipNudge comes with a [Insert Warranty Period] warranty against manufacturing defects.",
//       },
//       {
//         'question': 'How do I contact customer support?',
//         'answer':
//             "You can contact our customer support team through our website or by emailing [Insert Email Address].",
//       },
//       {
//         'question': 'What is the return policy?',
//         'answer':
//             "Please refer to our website for details on our return policy.",
//       },
//     ],
//     // Add more categories like 'App', 'Tracking', etc. here...
//   };

//   // Track expansion state for each question
//   Map<String, List<bool>> isExpandedMap = {};

//   final List<String> allFAQs = [
//     "How to use SipNudge?",
//     "How to clean the bottle?",
//     "Battery life of the device?",
//     "Is the app compatible with iOS?",
//     "How to sync data with Bluetooth?",
//     "How much water should I drink daily?",
//     "What happens when battery is low?",
//   ];

//   List<String> filteredFAQs = []; // filtered search results

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this);

//     for (var key in faqData.keys) {
//       isExpandedMap[key] = List.generate(faqData[key]!.length, (_) => false);
//     }
//     filteredFAQs = List.from(allFAQs);
//     _searchController.addListener(() {
//       filterSearchResults(_searchController.text);
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void filterSearchResults(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredFAQs = List.from(allFAQs);
//       } else {
//         filteredFAQs =
//             allFAQs
//                 .where((faq) => faq.toLowerCase().contains(query.toLowerCase()))
//                 .toList();
//       }
//     });
//   }
//   // void filterSearchResults(String query) {
//   //   final results =
//   //       allFAQs
//   //           .where((item) => item.toLowerCase().contains(query.toLowerCase()))
//   //           .toList();
//   //   setState(() {
//   //     filteredFAQs = results;
//   //   });
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final screenWidth = size.width;
//     final screenHeight = size.height;

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
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
//               Expanded(
//                 child: SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   child: Padding(
//                     padding: EdgeInsets.only(
//                       bottom: screenHeight * 0.02, // Prevent overflow
//                     ),
//                     child: Column(
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.only(
//                             top: screenHeight * 0.05,
//                             left: screenWidth * 0.06,
//                             right: screenWidth * 0.05,
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 40.w,
//                                 height: 40.h,
//                                 decoration: const BoxDecoration(
//                                   color: Colors.transparent,
//                                 ),
//                                 child: IconButton(
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                   },
//                                   icon: Icon(
//                                     Icons.arrow_back,
//                                     color: Colors.black,
//                                     size: 30.sp,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(width: screenWidth * 0.32),
//                               Text(
//                                 'FAQ',
//                                 style: TextStyle(
//                                   color: Color(0xFFFFFFFF),
//                                   fontSize: 24,
//                                   fontFamily: 'urbanist-Bold',
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(height: screenHeight * 0.03),

//                         //Search Box
//                         Container(
//                           width: 380.w,
//                           height: 65.h,
//                           padding: EdgeInsets.symmetric(horizontal: 20.w),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(40.r),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Color(0xFF000000).withOpacity(0.25),
//                                 offset: Offset(4.r, 4.r),
//                                 blurRadius: 4.r,
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               //Icon(Icons.search, color: Colors.grey),
//                               Image.asset(
//                                 'assets/searchicon.png', // Update the path as per your project
//                                 width: 16.23.w,
//                                 height: 16.23.h,
//                                 fit: BoxFit.cover,
//                                 color: Color(
//                                   0xFFBDBDBD,
//                                 ), // Optional: applies tint similar to icon color
//                               ),
//                               SizedBox(width: 12.w),
//                               Expanded(
//                                 child: TextField(
//                                   controller: _searchController,
//                                   onChanged: filterSearchResults,
//                                   decoration: InputDecoration(
//                                     hintText: 'Search',
//                                     hintStyle: TextStyle(
//                                       fontFamily: 'urbanist-Regular',
//                                       fontWeight: FontWeight.w400,
//                                       color: Color(0xFFBDBDBD),
//                                       fontSize: 18.sp,
//                                       letterSpacing: 0.2.sp,
//                                     ),
//                                     border: InputBorder.none,
//                                     suffixIcon:
//                                         _searchController.text.isNotEmpty
//                                             ? IconButton(
//                                               icon: Icon(
//                                                 Icons.clear,
//                                                 color: Colors.grey,
//                                               ),
//                                               onPressed: () {
//                                                 _searchController.clear();
//                                                 filterSearchResults('');
//                                               },
//                                             )
//                                             : null,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         SizedBox(height: screenHeight * 0.03),
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: screenWidth * 0.07,
//                           ),
//                           child: SingleChildScrollView(
//                             scrollDirection: Axis.horizontal,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 _buildToggleButton('General'),
//                                 SizedBox(width: 12.w),
//                                 _buildToggleButton('Usage'),
//                                 SizedBox(width: 12.w),
//                                 _buildToggleButton('App'),
//                                 SizedBox(width: 12.w),
//                                 _buildToggleButton('Tracking'),
//                                 SizedBox(width: 12.w),
//                                 _buildToggleButton('Troubleshooting'),
//                                 SizedBox(width: 12.w),
//                                 _buildToggleButton('Support'),
//                               ],
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: screenHeight * 0.03),
//                         //       child: Column(
//                         //         crossAxisAlignment: CrossAxisAlignment.start,
//                         //         children: [
//                         //           Row(
//                         //             children: [
//                         //               Expanded(
//                         //                 child: Text(
//                         //                   'What is Sipnudge?',
//                         //                   style: TextStyle(
//                         //                     fontWeight: FontWeight.bold,
//                         //                     fontSize: 17.sp,
//                         //                     color: Colors.white,
//                         //                   ),
//                         //                 ),
//                         //               ),
//                         //               GestureDetector(
//                         //                 onTap: () {
//                         //                   setState(() {
//                         //                     isExpanded = !isExpanded;
//                         //                   });
//                         //                 },
//                         //                 child: Icon(
//                         //                   isExpanded
//                         //                       ? Icons.expand_less
//                         //                       : Icons.expand_more,
//                         //                   color: Colors.white,
//                         //                 ),
//                         //               ),
//                         //             ],
//                         //           ),
//                         //           SizedBox(height: 10.h),
//                         //           Divider(color: Colors.white, thickness: 1),
//                         //           if (isExpanded) ...[
//                         //             SizedBox(height: 10.h),
//                         //             Text(
//                         //               'Sipnudge is a smart hydration bottle designed to help you stay properly hydrated throughout the day. It tracks your water intake and provides gentle nudges (via subtle vibrations and light cues) to remind you to drink.',
//                         //               style: TextStyle(
//                         //                 fontSize: 14.5.sp,
//                         //                 color: Colors.white,
//                         //                 height: 1.5,
//                         //               ),
//                         //             ),
//                         //           ],
//                         //         ],
//                         //       ),
//                         //     ),
//                         //     SizedBox(height: screenHeight * 0.03),
//                         //     Container(
//                         //       width: 380.w,
//                         //       padding: EdgeInsets.all(20.w),
//                         //       decoration: BoxDecoration(
//                         //         color: Color(0xFF735E7F),
//                         //         borderRadius: BorderRadius.circular(16.r),
//                         //         boxShadow: [
//                         //           BoxShadow(
//                         //             color: Color(0xFF000000).withOpacity(0.25),
//                         //             blurRadius: 4.r,
//                         //             offset: Offset(0, 4.r),
//                         //           ),
//                         //         ],
//                         //       ),
//                         //       child: Column(
//                         //         crossAxisAlignment: CrossAxisAlignment.start,
//                         //         children: [
//                         //           Row(
//                         //             children: [
//                         //               Expanded(
//                         //                 child: Text(
//                         //                   'What makes SipNudge different from other water bottles?',
//                         //                   style: TextStyle(
//                         //                     fontWeight: FontWeight.bold,
//                         //                     fontSize: 17.sp,
//                         //                     color: Colors.white,
//                         //                   ),
//                         //                 ),
//                         //               ),
//                         //               GestureDetector(
//                         //                 onTap: () {
//                         //                   setState(() {
//                         //                     isExpanded2 = !isExpanded2;
//                         //                   });
//                         //                 },
//                         //                 child: Icon(
//                         //                   isExpanded2
//                         //                       ? Icons.expand_less
//                         //                       : Icons.expand_more,
//                         //                   color: Colors.white,
//                         //                 ),
//                         //               ),
//                         //             ],
//                         //           ),
//                         //           SizedBox(height: 10.h),
//                         //           Divider(color: Colors.white, thickness: 1),
//                         //           if (isExpanded2) ...[
//                         //             SizedBox(height: 10.h),
//                         //             Text(
//                         //               "Unlike regular water bottles, SipNudge actively encourages you to drink through personalized reminders. It'snot just about carrying water; it's about helping you develop healthy hydration habits.",
//                         //               style: TextStyle(
//                         //                 fontSize: 14.5.sp,
//                         //                 color: Colors.white,
//                         //                 height: 1.5,
//                         //               ),
//                         //             ),
//                         //           ],
//                         //         ],
//                         //       ),
//                         //     ),
//                         //   ],
//                         // ),
//                         Column(
//                           children: List.generate(faqData[selected]!.length, (
//                             index,
//                           ) {
//                             final question =
//                                 faqData[selected]![index]['question']!;
//                             final answer = faqData[selected]![index]['answer']!;
//                             final isExpanded = isExpandedMap[selected]![index];
//                             return Column(
//                               children: [
//                                 Container(
//                                   width: 380.w,
//                                   padding: EdgeInsets.all(20.w),
//                                   decoration: BoxDecoration(
//                                     color: Color(0xFF735E7F),
//                                     borderRadius: BorderRadius.circular(16.r),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Color(
//                                           0xFF000000,
//                                         ).withOpacity(0.25),
//                                         blurRadius: 4.r,
//                                         offset: Offset(4.r, 4.r),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: Text(
//                                               question,
//                                               style: TextStyle(
//                                                 fontFamily: 'urbanist-SemiBold',
//                                                 fontWeight: FontWeight.w600,
//                                                 fontSize: 18.sp,
//                                                 color: Color(0xFFFFFFFF),
//                                               ),
//                                             ),
//                                           ),
//                                           GestureDetector(
//                                             onTap: () {
//                                               setState(() {
//                                                 isExpandedMap[selected]![index] =
//                                                     !isExpandedMap[selected]![index];
//                                               });
//                                             },
//                                             child: Icon(
//                                               isExpanded
//                                                   ? Icons.expand_less
//                                                   : Icons.expand_more,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: 10.h),
//                                       if (isExpanded) ...[
//                                         Divider(
//                                           color: Colors.white,
//                                           thickness: 1,
//                                         ),
//                                         SizedBox(height: 10.h),
//                                         Text(
//                                           answer,
//                                           style: TextStyle(
//                                             fontFamily: 'urbanist-medium',
//                                             fontWeight: FontWeight.w500,
//                                             fontSize: 16.sp,
//                                             color: Color(0xFFFFFFFF),
//                                             letterSpacing: 0.2.sp,
//                                             height: 1.5,
//                                           ),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(height: 20.h),
//                               ],
//                             );
//                           }),
//                         ),
//                         //),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               // Bottom Navigation
//               Container(
//                 height: screenHeight * 0.09,
//                 margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
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
//                     padding: EdgeInsets.symmetric(
//                       horizontal: screenHeight * 0.007.w,
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

//   Widget _buildToggleButton(String label) {
//     final bool isSelected = selected == label;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selected = label;
//         });
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF369FFF) : Colors.transparent,
//           borderRadius: BorderRadius.circular(30.r),
//           border:
//               isSelected
//                   ? null
//                   : Border.all(color: Color(0xFFFFFFFF), width: 1.2.w),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 16.sp,
//             color: Color(0xFFFFFFFF),
//             fontFamily: 'urbanist-SemiBold',
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.2.sp,
//           ),
//         ),
//       ),
//     );
//   }

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
//         debugPrint('No route defined for $label');
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('$label screen coming soon!')));
//     }
//   }
// }
