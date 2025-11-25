import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubit/reminder time&mode/reminder_cubit.dart';
import '../cubit/reminder time&mode/reminder_state.dart';

class ReminderBottomSheet extends StatelessWidget {
  const ReminderBottomSheet({super.key, required this.aiReminder, this.onSave});

  final bool aiReminder;
  final void Function(List<TimeOfDay> enabledTimes)? onSave;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(30.r);

    return FractionallySizedBox(
      heightFactor: 0.8, // 80% of screen height
      child: ClipRRect(
        borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB586BE), Color(0xFF131313)],
            ),
          ),
          child: SafeArea(
            top: false,
            child: BlocBuilder<ReminderIntervalCubit, ReminderIntervalState>(
              builder: (context, state) {
                final cubit = context.read<ReminderIntervalCubit>();
                final entries = cubit.state.slots.entries.toList();

                return SingleChildScrollView(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Reminder Time',
                              style: TextStyle(
                                fontFamily: 'Urbanist-SemiBold',
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 19.h),

                      /// Time slots
                      ...entries.map((e) {
                        final enabled = e.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _TimeRow(
                            timeLabel: _formatAmPm(e.key),
                            value: enabled,
                            onChanged: (v) => cubit.toggle(e.key, v),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String _formatAmPm(String key) {
    final h = int.parse(key.substring(0, 2));
    final m = key.substring(3, 5);
    final period = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:$m $period';
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.timeLabel,
    required this.value,
    required this.onChanged,
  });

  final String timeLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF735E7F),
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(color: const Color(0xFF9982A6), width: 1.w),
        boxShadow: [
          BoxShadow(
            offset: Offset(3.r, 4.r),
            color: Color(0x40000000),
            blurRadius: 4.r,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            timeLabel,
            style: TextStyle(
              fontFamily: 'Urbanist-SemiBold',
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (states) =>
                  Colors.white, // same thumb color for active & inactive
            ),
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF7A2CF8); // active track
              }
              return Color(0xFFE0E0E0); // inactive track
            }),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
