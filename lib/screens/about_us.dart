import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  State<AboutUs> createState() => _AboutUs();
}

class _AboutUs extends State<AboutUs> {
  String title = 'Home';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      //bottomNavigationBar: _buildBottomNavBar(screenWidth, screenHeight),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB586BE), Color(0xFF131313)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.05,
                  left: screenWidth * 0.06,
                  right: screenWidth * 0.05,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: const Color(0xFF212121),
                        size: 30.sp,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.21),
                    Text(
                      'About Us',
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 24.sp,
                        fontFamily: 'urbanist-Bold',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15.h),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    //vertical: 10.h,
                    horizontal: 25.w,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: 20.h, bottom: 30.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _text("About Us:"),
                        _text_p(
                          "At Sipnudge, we're passionate about empowering individuals to live healthier, more vibrant lives through optimal hydration. We believe that proper hydration is fundamental to well-being, yet it's often overlooked in our busy modern lives.\n\nWe understand the struggle of remembering to drink enough water, and we knew there had to be a smarter, more effective solution. That's why we created Sipnudge. Sipnudge isn't just a water bottle; it's a personalized hydration companion. We've combined cutting-edge sensor technology with a user-friendly app to create a smart hydration system that seamlessly integrates into your daily routine.\n\nSipnudge intelligently tracks your water intake throughout the day, providing valuable insights into your hydration habits. More than just tracking, Sipnudge learns your unique needs. By analyzing your drinking patterns and considering factors like your activity level and environment, Sipnudge delivers personalized hydration recommendations and gentle reminders, nudging you towards your optimal hydration goals.\n\nOur mission is simple: to make staying hydrated effortless and enjoyable. Whether you're a busy professional, a fitness enthusiast, or simply someone who wants to improve their health, Sipnudge is here to support you on your journey to better hydration.\n\nWe're committed to innovation and user-centric design. Our team of engineers, designers, and health enthusiasts is constantly working to improve Sipnudge and enhance your hydration experience. At Sipnudge, we're not just building a product; we're building a community.\n\nWe invite you to join the Sipnudge community and experience the difference that proper hydration can make.",
                        ),
                        _header("Learn more at [Your Website Address]"),
                        _header(
                          "Connect with us on social media: [Your Social Media Links]",
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Container(
              //   height: screenHeight * 0.09,
              //   margin: EdgeInsets.only(
              //     left: screenWidth * 0.05,
              //     right: screenWidth * 0.05,
              //     bottom: screenHeight * 0.01,
              //   ),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(90.r),
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF3F3F3F), Color(0xFFFFFFFF)],
              //       begin: Alignment.bottomCenter,
              //       end: Alignment.topCenter,
              //     ),
              //   ),
              //   child: Padding(
              //     padding: EdgeInsets.all(1.w),
              //     child: Container(
              //       padding: EdgeInsets.only(
              //         left: screenHeight * 0.007.w,
              //         right: screenHeight * 0.006.w,
              //       ),
              //       decoration: BoxDecoration(
              //         color: const Color(0xFF2B2536),
              //         borderRadius: BorderRadius.circular(90.r),
              //       ),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //         children: [
              //           _buildNavItem(
              //             Icons.home,
              //             'Home',
              //             title == 'Home',
              //             screenWidth,
              //             screenHeight,
              //           ),
              //           _buildNavItem(
              //             Icons.analytics_outlined,
              //             'Analysis',
              //             title == 'Analysis',
              //             screenWidth,
              //             screenHeight,
              //           ),
              //           _buildNavItem(
              //             Icons.lightbulb_outline,
              //             'Goals',
              //             title == 'Goals',
              //             screenWidth,
              //             screenHeight,
              //           ),
              //           _buildNavItem(
              //             Icons.settings,
              //             'Settings',
              //             title == 'Settings',
              //             screenWidth,
              //             screenHeight,
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text(String content) => Padding(
        padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
        child: Text(
          content,
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: 20.sp,
            fontFamily: 'urbanist-Bold',
          ),
        ),
      );

  Widget _text_p(String content) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          content,
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: 18.sp,
            fontFamily: 'urbanist-Medium',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2.sp,
          ),
        ),
      );

  Widget _header(String title) => Padding(
        padding: EdgeInsets.only(bottom: 8.h, top: 12.h),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFFFFF),
            fontFamily: 'urbanist-Bold',
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: EdgeInsets.only(bottom: 5.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•  ',
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: 18.sp,
                fontFamily: 'urbanist-Medium',
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2.sp,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 18.sp,
                  fontFamily: 'urbanist-Medium',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2.sp,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    double screenWidth,
    double screenHeight,
  ) {
    final assetPath = 'assets/${label.toLowerCase()}.png';
    double scale = 1.0;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.9),
          onTapUp: (_) => setState(() => scale = 1.0),
          onTapCancel: () => setState(() => scale = 1.0),
          onTap: () {
            debugPrint('Tapped on: $label');
            _handleBottomNavigation(label);
          },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: screenWidth * 0.2,
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFFFAFAFA), Color(0xFF3E3E3E)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isActive ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(48.r),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(4, 4),
                        color: isActive
                            ? const Color(0x40000000)
                            : Colors.transparent,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(
                      width: screenWidth * 0.19,
                      height: screenHeight * 0.055,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFB182BA),
                                  Color(0xFF2D1B31),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isActive ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(46),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            assetPath,
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            color: Colors.white,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                'Error loading image: $assetPath - $error',
                              );
                              return Icon(
                                icon,
                                size: screenWidth * 0.055,
                                color: Colors.white,
                              );
                            },
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
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

  void _handleBottomNavigation(String label) {
    setState(() {
      title = label;
    });

    switch (label) {
      case 'Home':
        Navigator.pushNamed(context, '/homepage');
        break;
      case 'Analysis':
        Navigator.pushNamed(context, '/analysis');
        break;
      case 'Goals':
        Navigator.pushNamed(context, '/dailygoalpage');
        break;
      case 'Settings':
        Navigator.pushNamed(context, '/preferences');
        break;
      default:
        debugPrint('No route defined for $label');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label screen coming soon!')));
    }
  }
}
