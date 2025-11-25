import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PersonalInfoApp extends StatelessWidget {
  const PersonalInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        home: const PersonalInfoPage(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          ScreenUtil.init(context);
          return child!;
        },
      ),
    );
  }
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  String selectedGender = 'Male';
  String heightUnit = 'in';
  String weightUnit = 'kg';

  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  String selectedValue = "00"; // Shared for temporary selection

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB586BE), Color(0xFF131313)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 25.h),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  offset: Offset(4.w, 4.h),
                  blurRadius: 4.r,
                  color: const Color(0x40000000),
                ),
              ],
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/lifestyleinfo');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB889D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 18.h),
                elevation: 0,
              ),
              child: Text(
                "Next",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontFamily: 'Urbanist-SemiBold',
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 10,
                      color: Color(0x40000000),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20.w, top: 48.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: const Color(0xFF212121), size: 30.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 60.w),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontFamily: 'Urbanist-ExtraBold',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: buildGenderSection(),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: buildInputWithUnit(
                    label: "How tall are you?",
                    hint: 'Enter your height',
                    unit1: "in",
                    unit2: "cm",
                    selectedUnit: heightUnit,
                    onUnitChanged: (val) => setState(() => heightUnit = val),
                    controller: heightController,
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: buildInputWithUnit(
                    label: "How much do you weigh?",
                    hint: 'Enter your weight',
                    unit1: "kg",
                    unit2: "lbs",
                    selectedUnit: weightUnit,
                    onUnitChanged: (val) => setState(() => weightUnit = val),
                    controller: weightController,
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel("What's your age?"),
                      SizedBox(height: 8.h),
                      buildInputField(
                          hint: "Enter your age",
                          suffix: "in years",
                          controller: ageController),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontFamily: 'Urbanist-SemiBold',
      ),
    );
  }

  Widget buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel("What's your gender?"),
        SizedBox(height: 16.h),
        Row(
          children: [
            genderButton('Male'),
            SizedBox(width: 10.w),
            genderButton('Female'),
          ],
        ),
        SizedBox(height: 10.h),
        genderButton('Prefer not to say', width: 180.w),
      ],
    );
  }

  Widget genderButton(String gender, {double? width}) {
    bool isSelected = selectedGender == gender;
    String? genderImage;

    if (gender == 'Male') genderImage = 'assets/male.png';
    if (gender == 'Female') genderImage = 'assets/female.png';

    return Container(
      width: width ?? 180.w,
      height: 92.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: const [
          BoxShadow(
              offset: Offset(4, 4), blurRadius: 4, color: Color(0x40000000)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => setState(() => selectedGender = gender),
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          padding: EdgeInsets.zero,
          backgroundColor:
              isSelected ? const Color(0xFF98729F) : const Color(0xFF735E7F),
          side: BorderSide(
            color:
                isSelected ? const Color(0xFFF0C7FF) : const Color(0xFF9982A6),
            width: isSelected ? 3.w : 1.w,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16.h,
              left: 16.w,
              child: Text(
                gender,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontFamily: 'Urbanist-Medium',
                ),
              ),
            ),
            if (genderImage != null)
              Positioned(
                bottom: 10.h,
                right: 14.w,
                child: Image.asset(
                  genderImage,
                  color: const Color(0xFFC7A2DC),
                  width: 24.w,
                  height: 28.h,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildInputWithUnit({
    required String label,
    required String hint,
    required String unit1,
    required String unit2,
    required String selectedUnit,
    required Function(String) onUnitChanged,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
                child: buildInputField(hint: hint, controller: controller)),
            SizedBox(width: 26.w),
            Container(
              width: 90.w,
              height: 45.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                color: const Color(0x80735E7F),
                boxShadow: const [
                  BoxShadow(
                      offset: Offset(2, 2),
                      blurRadius: 3,
                      color: Color(0x40000000)),
                ],
                border: Border.all(color: const Color(0xFF9982A6)),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 1),
                    alignment: selectedUnit == unit1
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      margin: EdgeInsets.symmetric(horizontal: 0.w),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC7A2DC),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onUnitChanged(unit1),
                          child: Center(
                            child: Text(
                              unit1,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontFamily: 'Urbanist-Medium'),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onUnitChanged(unit2),
                          child: Center(
                            child: Text(
                              unit2,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontFamily: 'Urbanist-Medium'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildInputField(
      {required String hint,
      String? suffix,
      required TextEditingController controller}) {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF131313),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(50.r))),
          builder: (_) => buildNumberPicker(controller),
        );
      },
      child: AbsorbPointer(
        child: Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: const Color(0x80735E7F),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: const Color(0xFF9982A6), width: 1.0.w),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x40000000), blurRadius: 3, offset: Offset(2, 2))
            ],
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14.sp, color: Color(0x50FFFFFF)),
              suffixText: suffix,
              suffixStyle: TextStyle(color: Color(0x50FFFFFF), fontSize: 14.sp),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNumberPicker(TextEditingController controller) {
    return Container(
      height: 420.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF735E7F), Color(0xFF211C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(52),
          topRight: Radius.circular(52),
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
                  controller.text = selectedValue;
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
                  controller: FixedExtentScrollController(
                      initialItem: int.tryParse(selectedValue) ?? 0),
                  itemExtent: 50.h,
                  diameterRatio: 1.4,
                  perspective: 0.006,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedValue = index.toString().padLeft(2, '0');
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 199) return null;
                      final value = index.toString().padLeft(2, '0');
                      return Center(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 24.sp,
                            color: Colors.white,
                            fontFamily: 'Urbanist-Medium',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Center Highlight Overlay
                IgnorePointer(
                  child: Container(
                    height: 50.h,
                    width: double.infinity,
                    alignment: Alignment.center,
                    margin: EdgeInsets.symmetric(horizontal: 180.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
