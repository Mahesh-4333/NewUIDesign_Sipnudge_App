// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:wave/config.dart';
// import 'package:wave/wave.dart';

// class DailyGoalPage extends StatefulWidget {
//   const DailyGoalPage({super.key});

//   @override
//   State<DailyGoalPage> createState() => _DailyGoalPageState();
// }

// class _DailyGoalPageState extends State<DailyGoalPage> {
//   double waterAmount = 2500;
//   bool isML = true;

//   @override
//   Widget build(BuildContext context) {
//     ScreenUtil.init(context); // Required for flutter_screenutil

//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       body: Container(
//         width: screenWidth,
//         height: screenHeight,
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
//               SizedBox(height: screenHeight * 0.09),
//               const Text(
//                 "Your Daily goal is",
//                 style: TextStyle(
//                   fontFamily: 'MuseoModerno-Bold',
//                   fontSize: 24,
//                   color: Colors.white,
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.12),
//               RichText(
//                 text: TextSpan(
//                   children: [
//                     TextSpan(
//                       text: isML
//                           ? waterAmount.toInt().toString()
//                           : (waterAmount / 1000).toStringAsFixed(2),
//                       style: TextStyle(
//                         fontFamily: 'MuseoModerno-Bold',
//                         fontSize: 36.sp,
//                         color: Color(0xFFB3F0F8),
//                         shadows: [
//                           Shadow(
//                             offset: Offset(0, 4),
//                             blurRadius: 4,
//                             color: Color(0x40000000),
//                           ),
//                         ],
//                       ),
//                     ),
//                     TextSpan(
//                       text: isML ? ' mL' : ' L',
//                       style: TextStyle(
//                         fontFamily: 'MuseoModerno-Regular',
//                         fontSize: 32.sp,
//                         color: Color(0xFFFFFFFF),
//                         shadows: [
//                           Shadow(
//                             offset: Offset(0, 4),
//                             blurRadius: 4,
//                             color: Color(0x40000000),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.042),

//               // Wave Widget
//               Container(
//                 margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(100),
//                   boxShadow: [
//                     BoxShadow(
//                       offset: Offset(2, 2),
//                       blurRadius: 10,
//                       color: Color(0x40000000),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(100),
//                   child: SizedBox(
//                     height: screenHeight * 0.07,
//                     child: WaveWidget(
//                       config: CustomConfig(
//                         gradients: [
//                           [
//                             const Color(0xFFB3F0F8).withOpacity(0.6),
//                             const Color(0xFF70D6ED).withOpacity(0.6),
//                           ],
//                           [
//                             const Color(0xFF70D6ED).withOpacity(0.5),
//                             const Color(0xFF1C7FA7).withOpacity(0.5),
//                           ],
//                           [
//                             const Color(0xFF1C7FA7).withOpacity(0.4),
//                             const Color(0xFF005D84).withOpacity(0.4),
//                           ],
//                           [
//                             const Color(0xFF005D84).withOpacity(0.3),
//                             const Color(0xFF003D64).withOpacity(0.3),
//                           ],
//                         ],
//                         durations: [
//                           12000,
//                           8000,
//                           6000,
//                           4000,
//                         ], // Speeds of each layer
//                         heightPercentages: [0.30, 0.38, 0.42, 0.5],
//                         gradientBegin: Alignment.centerLeft,
//                         gradientEnd: Alignment.centerRight,
//                       ),
//                       waveAmplitude: 4,
//                       backgroundColor: Colors.transparent,
//                       size: const Size(double.infinity, double.infinity),
//                       waveFrequency:
//                           3, // Controls number of waves; leave positive for left-to-right
//                       isLoop: true,
//                     ),
//                   ),
//                 ),
//               ),

//               SizedBox(height: screenHeight * 0.09),

//               // Smooth Slider
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: SliderTheme(
//                   data: SliderTheme.of(context).copyWith(
//                     trackShape: GradientSliderTrackShape(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFFA4ECFB), Color(0xFF1C7FA7)],
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                       ),
//                     ),
//                     trackHeight: 8,
//                     thumbShape: const GradientThumbShape(thumbRadius: 10),
//                     overlayColor: Colors.cyan.withOpacity(0.2),
//                   ),
//                   child: Slider(
//                     min: 1000,
//                     max: 3700,
//                     value: waterAmount,
//                     onChanged: (value) => setState(() => waterAmount = value),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.085,
//                   vertical: screenHeight * 0.010,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "1L",
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: const Color(0x40FFFFFF),
//                         fontFamily: 'Urbanist-Medium',
//                       ),
//                     ),
//                     Text(
//                       "2L",
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: const Color(0x40FFFFFF),
//                         fontFamily: 'Urbanist-Medium',
//                       ),
//                     ),
//                     Text(
//                       "2.5L",
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: const Color(0x40FFFFFF),
//                         fontFamily: 'Urbanist-Medium',
//                       ),
//                     ),
//                     Text(
//                       "3L",
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: const Color(0x40FFFFFF),
//                         fontFamily: 'Urbanist-Medium',
//                       ),
//                     ),
//                     Text(
//                       "3.7L",
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         color: Color(0x40FFFFFF),
//                         fontFamily: 'Urbanist-Medium',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.07),

//               // Unit Toggle
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(50.r),
//                   color: Color(0xFF5F4E6A),
//                   boxShadow: [
//                     BoxShadow(
//                       offset: Offset(4, 4),
//                       blurRadius: 4,
//                       color: Color(0x40000000),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     buildUnitToggle(true, 'ml'),
//                     buildUnitToggle(false, 'Litres'),
//                   ],
//                 ),
//               ),
//               const Spacer(),
//               Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(50.r),
//                     boxShadow: [
//                       BoxShadow(
//                         offset: Offset(4.r, 4.r),
//                         blurRadius: 4.r,
//                         color: Color(0x40000000),
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.lightBlueAccent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(50.r),
//                       ),
//                       padding: EdgeInsets.symmetric(vertical: 13.h),
//                     ),
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/homepage');
//                     },
//                     child: const Text(
//                       "Let's hit our hydration goals",
//                       style: TextStyle(
//                         fontFamily: 'MuseoModerno-Bold',
//                         fontSize: 18,
//                         color: Colors.white,
//                       ),
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

//   Widget buildUnitToggle(bool value, String label) {
//     bool selected = isML == value;
//     return GestureDetector(
//       onTap: () => setState(() => isML = value),
//       child: Container(
//         width: 80.w, // Fixed width for both options
//         padding: EdgeInsets.symmetric(vertical: 10.h),
//         decoration: BoxDecoration(
//           gradient: selected
//               ? const LinearGradient(
//                   colors: [Color(0xFFA4ECFB), Color(0xFF1C7FA7)],
//                   begin: Alignment.centerLeft,
//                   end: Alignment.centerRight,
//                 )
//               : null,
//           color: selected ? null : Colors.transparent,
//           borderRadius: BorderRadius.horizontal(
//             left: value ? Radius.circular(100.r) : Radius.circular(100.r),
//             right: !value ? Radius.circular(100.r) : Radius.circular(100.r),
//           ),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               fontFamily: 'Urbanist-Medium',
//               fontSize: 16.sp,
//               color: Color(0xFFFFFFFF),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class GradientSliderTrackShape extends SliderTrackShape {
//   final LinearGradient gradient;
//   final Color inactiveColor;

//   GradientSliderTrackShape({
//     required this.gradient,
//     this.inactiveColor = const Color(0x20FFFFFF),
//   });

//   @override
//   Rect getPreferredRect({
//     required RenderBox parentBox,
//     Offset offset = Offset.zero,
//     required SliderThemeData sliderTheme,
//     bool isEnabled = false,
//     bool isDiscrete = false,
//   }) {
//     final double trackHeight = sliderTheme.trackHeight ?? 4;
//     final double thumbWidth =
//         sliderTheme.thumbShape?.getPreferredSize(isEnabled, isDiscrete).width ??
//             0;
//     final double trackLeft = offset.dx + thumbWidth / 2;
//     final double trackTop =
//         offset.dy + (parentBox.size.height - trackHeight) / 2;
//     final double trackWidth = parentBox.size.width - thumbWidth;

//     return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
//   }

//   @override
//   @override
//   void paint(
//     PaintingContext context,
//     Offset offset, {
//     required RenderBox parentBox,
//     required SliderThemeData sliderTheme,
//     required Animation<double> enableAnimation,
//     required TextDirection textDirection,
//     required Offset thumbCenter,
//     Offset? secondaryOffset,
//     bool isEnabled = false,
//     bool isDiscrete = false,
//   }) {
//     final Rect fullTrackRect = getPreferredRect(
//       parentBox: parentBox,
//       offset: offset,
//       sliderTheme: sliderTheme,
//       isEnabled: isEnabled,
//       isDiscrete: isDiscrete,
//     );

//     final double trackRadius = fullTrackRect.height / 2;

//     // Draw shadow first
//     final Paint shadowPaint = Paint()
//       ..color = const Color(0x40000000)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

//     final Rect shadowRect = Rect.fromLTRB(
//       fullTrackRect.left,
//       fullTrackRect.top,
//       fullTrackRect.right,
//       fullTrackRect.bottom,
//     ).translate(4, 4); // Offset for shadow

//     context.canvas.drawRRect(
//       RRect.fromRectAndRadius(shadowRect, Radius.circular(trackRadius)),
//       shadowPaint,
//     );

//     // Draw active track
//     final Rect activeTrack = Rect.fromLTRB(
//       fullTrackRect.left,
//       fullTrackRect.top,
//       thumbCenter.dx,
//       fullTrackRect.bottom,
//     );

//     final Paint activePaint = Paint()
//       ..shader = gradient.createShader(activeTrack)
//       ..style = PaintingStyle.fill;

//     context.canvas.drawRRect(
//       RRect.fromRectAndRadius(activeTrack, Radius.circular(trackRadius)),
//       activePaint,
//     );

//     // Draw inactive track
//     final Rect inactiveTrack = Rect.fromLTRB(
//       thumbCenter.dx,
//       fullTrackRect.top,
//       fullTrackRect.right,
//       fullTrackRect.bottom,
//     );

//     final Paint inactivePaint = Paint()
//       ..color = inactiveColor
//       ..style = PaintingStyle.fill;

//     context.canvas.drawRRect(
//       RRect.fromRectAndRadius(inactiveTrack, Radius.circular(trackRadius)),
//       inactivePaint,
//     );
//   }
// }

// class GradientThumbShape extends SliderComponentShape {
//   final double thumbRadius;

//   const GradientThumbShape({this.thumbRadius = 10});

//   @override
//   Size getPreferredSize(bool isEnabled, bool isDiscrete) {
//     return Size.fromRadius(thumbRadius + 4);
//   }

//   @override
//   void paint(
//     PaintingContext context,
//     Offset center, {
//     required Animation<double> activationAnimation,
//     required Animation<double> enableAnimation,
//     required bool isDiscrete,
//     required TextPainter labelPainter,
//     required RenderBox parentBox,
//     required Size sizeWithOverflow,
//     required SliderThemeData sliderTheme,
//     required TextDirection textDirection,
//     required double textScaleFactor,
//     required double value,
//   }) {
//     final Canvas canvas = context.canvas;

//     final Paint outerPaint = Paint()..color = Colors.white;
//     canvas.drawCircle(center, thumbRadius + 3, outerPaint);

//     final Rect rect = Rect.fromCircle(center: center, radius: thumbRadius);
//     final Paint innerPaint = Paint()
//       ..shader = const LinearGradient(
//         colors: [Color(0xFF9AE9FF), Color(0xFF005D84)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ).createShader(rect);

//     canvas.drawCircle(center, thumbRadius, innerPaint);
//   }
// }
