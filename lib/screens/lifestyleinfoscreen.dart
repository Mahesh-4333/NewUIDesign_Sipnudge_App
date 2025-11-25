import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LifeStyleInfoPage extends StatefulWidget {
  const LifeStyleInfoPage({super.key});

  @override
  State<LifeStyleInfoPage> createState() => _LifeStyleInfoPage();
}

class _LifeStyleInfoPage extends State<LifeStyleInfoPage> {
  String selectedActivity = '';
  String selectedDiet = '';
  bool showError = false;

  String wakeHour = '07', wakeMinute = '00';
  String bedHour = '11', bedMinute = '30';
  bool isWakePM = false, isBedPM = true;

  Future<void> showNumberPickerBottomSheet({
    required String initialValue,
    required ValueChanged<String> onSelected,
  }) async {
    String selectedValue = initialValue;
    int initialIndex = int.tryParse(initialValue) ?? 0;

    await showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      FixedExtentScrollController scrollController =
          FixedExtentScrollController(initialItem: initialIndex);

      return Container(
        height: 420.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF735E7F), Color(0xFF211C2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(52.r),
            topRight: Radius.circular(52.r),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 34.h, right: 34.w),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(selectedValue);
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontFamily: 'Urbanist-SemiBold',
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4,
                          color: Color(0x40000000),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ListWheelScrollView.useDelegate(
                    controller: scrollController,
                    itemExtent: 50.h,
                    diameterRatio: 1.4,
                    perspective: 0.006,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      selectedValue = index.toString().padLeft(2, '0');
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 59) return null;
                        final value = index.toString().padLeft(2, '0');
                        return Center(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 26.sp,
                              color: Colors.white,
                              fontFamily: 'Urbanist-Medium',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Center highlight overlay
                  IgnorePointer(
                    child: Container(
                      height: 50.h,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 180.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB586BE), Color(0xFF131313)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12.w,
              top: 32.h,
              right: 12.w,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black, size: 30.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          'Sleep and Lifestyle Information',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontFamily: 'Urbanist-ExtraBold',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  buildTimePicker('What’s your wake-up?', wakeHour, wakeMinute, isWakePM, (isPM) {
                    setState(() => isWakePM = isPM);
                  }),
                  SizedBox(height: 15.h),
                  buildTimePicker('What’s your bedtime?', bedHour, bedMinute, isBedPM, (isPM) {
                    setState(() => isBedPM = isPM);
                  }),
                  SizedBox(height: 25.h),
                  buildSectionTitle("What's your activity level?"),
                  SizedBox(height: 10.h),
                  buildOptionsGrid([
                    ('Sedentary', 'less than 5000 steps', 'assets/sedentary.png'),
                    ('Lightly Active', '5,000 - 7,500 steps', 'assets/lightly active.png'),
                    ('Moderately Active', '7,500 - 10,000 steps', 'assets/moderately active.png'),
                    ('Very Active', 'More than 10,000 steps', 'assets/very active.png'),
                  ], selectedActivity, (val) => setState(() => selectedActivity = val)),
                  SizedBox(height: 20.h),
                  buildSectionTitle("What's your diet type?"),
                  SizedBox(height: 10.h),
                  buildOptionsGrid([
                    ('Standard\nBalanced Diet', '', 'assets/sb diet.png'),
                    ('Vegetarian', '', 'assets/veg.png'),
                    ('High Sodium\nProcessed Diet', '', 'assets/hsp diet.png'),
                    ('High Protein Diet', '', 'assets/h pro diet.png'),
                  ], selectedDiet, (val) => setState(() => selectedDiet = val)),
                  SizedBox(height: 30.h), // replaces Spacer
                  //Spacer(),
                  Center(
                    child: Container(
                      padding: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: Offset(4, 4),
                            blurRadius: 4.r,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/loadingscreen');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF9EF3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 165.w, vertical: 16.h),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: 'Urbanist-SemiBold',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTimePicker(String label, String hour, String minute, bool isPM, ValueChanged<bool> onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontFamily: 'Urbanist-SemiBold',
              //shadows: const [Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x40000000))],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Row(
            children: [
              timeBox("Hour", hour, () async {
                await showNumberPickerBottomSheet(
                  initialValue: hour,
                  onSelected: (selected) {
                    setState(() {
                      if (label.contains('wake')) {
                        wakeHour = selected;
                      } else {
                        bedHour = selected;
                      }
                    });
                  },
                );
              }),
              Text(": ", style: TextStyle(fontSize: 22.sp, color: Colors.white)),
              timeBox("Minute", minute, () async {
                await showNumberPickerBottomSheet(
                  initialValue: minute,
                  onSelected: (selected) {
                    setState(() {
                      if (label.contains('wake')) {
                        wakeMinute = selected;
                      } else {
                        bedMinute = selected;
                      }
                    });
                  },
                );
              }),
              SizedBox(width: 16.w),
              toggleAMPM(isPM, onToggle),
            ],
          ),
        ),
      ],
    );
  }

  Widget timeBox(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        height: 50.h,
        margin: EdgeInsets.only(right: 11.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: const Color(0xFF735E7F),
          border: Border.all(color: const Color(0xFF9982A6), width: 1.0.w),
          boxShadow: const [
            BoxShadow(offset: Offset(4, 4), blurRadius: 4, color: Color(0x40000000))
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(fontSize: 24.sp, fontFamily: 'Urbanist-SemiBold', color: Colors.white),
        ),
      ),
    );
  }

  Widget toggleAMPM(bool isPM, ValueChanged<bool> onToggle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.r),
        color: const Color(0xFF5F4E6A),
        border: Border.all(color: const Color(0xFF9982A6), width: 1),
      ),
      child: Row(
        children: [
          toggleButton('AM', !isPM, () => onToggle(false)),
          toggleButton('PM', isPM, () => onToggle(true)),
        ],
      ),
    );
  }

  Widget toggleButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCF9EF3) : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontFamily: 'Urbanist-Medium', fontSize: 16.sp),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 12.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          fontFamily: 'Urbanist-SemiBold',
          color: Color(0xFFFFFFFF),
          //shadows: const [Shadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x40000000))],
        ),
      ),
    );
  }

  Widget buildOptionsGrid(
    List<(String title, String subtitle, String imagePath)> options,
    String selectedValue,
    ValueChanged<String> onSelect,
  ) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 10.h,
      children: options.map((opt) {
        return buildOptionCard(
          title: opt.$1,
          subtitle: opt.$2,
          imagePath: opt.$3,
          isSelected: selectedValue == opt.$1,
          onTap: () => onSelect(opt.$1),
        );
      }).toList(),
    );
  }

  Widget buildOptionCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      //child: Padding(
        //padding: EdgeInsets.only(left: 10.w, right: 10.w),
        child: Container(
        width: 186.w,
        height: 120.h,
        margin: EdgeInsets.only(left: 10.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C7CA2) : const Color(0xFF735E7F),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isSelected ? Color(0xFFF0C7FF) : Color(0xFF9982A6),
            width: isSelected ? 3.w : 1.w,
          ),
          boxShadow: const [
            BoxShadow(offset: Offset(4, 4), blurRadius: 4, color: Color(0x40000000))
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10.w, top: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontFamily: 'Urbanist-Medium',
                          fontSize: 16.sp)),
                  SizedBox(height: 12.h),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(
                          color: Color(0x60FFFFFF),
                          //color: Colors.white60,
                          fontFamily: 'Urbanist-Medium', 
                          fontSize: 14.sp)),
                ],
              ),
            ),
            Positioned(
              right: 10.w,
              bottom: 4.h,
              child: Image.asset(imagePath, height: 30.h, width: 30.w),
            )
          ],
        ),
      ),
      //)
    );
  }
}
