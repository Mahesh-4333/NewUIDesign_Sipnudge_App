import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
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
                    SizedBox(width: screenWidth * 0.19),
                    Text(
                      'Privacy Policy',
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
                        _text("Effective Date: 1 January 2025"),
                        _text_p(
                          "This Privacy Policy describes how SIPNUDGE TECHNOLOGIES PRIVATE LIMITED (\"we,\" \"us,\" or \"our\") collects, uses, and shares your information when you use the SipNudge smart hydration bottle and related services, including the SipNudge mobile application (the \"App\"). We are committed to protecting your privacy and handling your information responsibly.\n",
                        ),
                        _header("1) Information We Collect:"),
                        _bullet(
                          "Personal Information: This may include your name, email, and age.",
                        ),
                        _bullet(
                          "Usage Data: Data about how you use SipNudge, your sips, and app interactions.",
                        ),
                        _bullet(
                          "Device Information: Your device model, OS, IP address, etc.",
                        ),
                        _bullet(
                          "Health-Related Information: Used only for hydration insights. No sensitive health data collected without your consent.",
                        ),
                        _bullet(
                          "Aggregated and Anonymized Data: Used for improving services and analytics.\n",
                        ),
                        _header("2) How We Use Your Information:"),
                        _bullet(
                          "Providing and Improving the Service: Tracking intake, reminders, app enhancements.",
                        ),
                        _bullet(
                          "Personalization: Custom goals based on activity and environment.",
                        ),
                        _bullet(
                          "Communication: Notify about updates, not marketing without consent.",
                        ),
                        _bullet(
                          "Analytics: Understand user trends and behaviors.",
                        ),
                        _bullet("Legal Compliance: When necessary.\n"),
                        _header("3) How We Share Your Information:"),
                        _bullet(
                          "Service Providers: For hosting, analytics, and customer support.",
                        ),
                        _bullet("Legal Compliance: Only if required by law."),
                        _bullet(
                          "Business Transfers: In case of mergers or acquisitions.",
                        ),
                        _bullet(
                          "With Your Consent: Only if you explicitly allow it.\n",
                        ),
                        _header("4) Data Security:"),
                        _bullet(
                          "We take reasonable measures to protect your data, but no system is 100% secure.\n",
                        ),
                        _header("Your Choices:"),
                        _bullet(
                          "Account Info: You can view and update in the app.",
                        ),
                        _bullet("Notifications: Control via app settings."),
                        _bullet(
                          "Data Deletion: Email us at newton.ns34@gmail.com\n",
                        ),
                        _header("Children’s Privacy:"),
                        _bullet(
                          "We do not knowingly collect info from children under 13. Contact us if you learn otherwise.\n",
                        ),
                        _header("Changes to Policy:"),
                        _bullet(
                          "We may update this policy and will notify via the app or website.\n",
                        ),
                        _header("Contact Us:"),
                        _text_p("SIPNUDGE TECHNOLOGIES PRIVATE LIMITED"),
                        _text_p(
                          "Plot No:-172 Sambhaji Nagar, Priyadarshani Colony, Jalna-431203",
                        ),
                        _text_p("Email: newton.ns34@gmail.com"),
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
