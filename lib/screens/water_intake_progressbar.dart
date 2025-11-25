import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _ProgressCircle extends StatelessWidget {
  final int drank;
  final int goal;

  const _ProgressCircle({required this.drank, required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = (drank / goal).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$drank ml",
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            Text(
              "/$goal ml",
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
            ),
          ],
        ),
      ],
    );
  }
}
