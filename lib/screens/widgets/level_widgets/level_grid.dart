// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class LevelGridItem extends StatelessWidget {
//   final int level;
//   final int currentLevel;
//   final VoidCallback onTap;

//   const LevelGridItem({
//     super.key,
//     required this.level,
//     required this.currentLevel,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isUnlocked = level <= currentLevel;

//     return GestureDetector(
//       onTap: onTap,
//       child: Padding(
//         padding: EdgeInsets.only(bottom: 0.h),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(
//               width: 190.w,
//               height: 100.h,
//               child: Padding(
//                 padding: EdgeInsets.only(left: 12.w),
//                 child: Center(
//                   child: Image.asset(
//                     isUnlocked ? 'assets/img$level.png' : 'assets/lockimg.png',
//                     fit: BoxFit.cover,
//                     color: isUnlocked ? null : const Color(0xff888593),
//                   ),
//                 ),
//               ),
//             ),
//             Transform.translate(
//               offset: Offset(0, -26.h),
//               child: Column(
//                 children: [
//                   Text(
//                     'Level $level',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontFamily: 'urbanist-bold',
//                       fontWeight: FontWeight.w700,
//                       fontSize: 14.sp,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 4.h),
//                   Text(
//                     level == currentLevel
//                         ? 'Current level'
//                         : 'Weekly Intake: 15.4L',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontFamily: 'urbanist-regular',
//                       fontWeight: FontWeight.w500,
//                       fontSize: 12.sp,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//=========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LevelGridItem extends StatelessWidget {
  final int level;
  final int currentLevel;
  final VoidCallback onTap;

  const LevelGridItem({
    super.key,
    required this.level,
    required this.currentLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = level <= currentLevel;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: 0.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190.w,
              height: 100.h,
              child: Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: Center(
                  child: Image.asset(
                    isUnlocked ? 'assets/img$level.png' : 'assets/lockimg.png',
                    fit: BoxFit.cover,
                    color: isUnlocked ? null : const Color(0xff888593),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -26.h),
              child: Column(
                children: [
                  Text(
                    'Level $level',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'urbanist-bold',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    level == currentLevel
                        ? 'Current level'
                        : 'Weekly Intake: 15.4L',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'urbanist-regular',
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
