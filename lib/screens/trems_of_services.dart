import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsOfServices extends StatefulWidget {
  const TermsOfServices({super.key});

  @override
  State<TermsOfServices> createState() => _TermsOfServices();
}

class _TermsOfServices extends State<TermsOfServices> {
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
                    SizedBox(width: screenWidth * 0.13),
                    Text(
                      'Terms Of Services',
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
                          'Welcome to Sipnudge! These Terms of Service ("Terms") govern your access to and use of the Sipnudge smart hydration bottle, the Sipnudge mobile application (the "App"), and all related services provided by Sipnudge TECHNOLOGIES PRIVATE LIMITED ("we," "us," or "our"). By accessing or using Sipnudge and the App, you agree to be bound by these Terms. Please read them carefully.',
                        ),
                        _header("1) Acceptance of Terms:"),
                        _bullet(
                          "By using Sipnudge and the App, you represent and warrant that you have the legal capacity to enter into these Terms and that you agree to be bound by them. If you do not agree to these Terms, do not use Sipnudge or the App.",
                        ),
                        _header("2) Description of Service:"),
                        _bullet(
                          "Sipnudge is a smart hydration system designed to help you track and improve your water intake. It includes a smart bottle, a mobile application, and related services, which may include personalized hydration recommendations, reminders, and data tracking.",
                        ),
                        _header("3) User Accounts:"),
                        _bullet(
                          "To access certain features of the App, you may need to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized access to or use of your account.",
                        ),
                        _header("4) Use of the App and Sipnudge:"),
                        _bullet(
                          "You agree to use Sipnudge and the App only for lawful purposes and in accordance with these Terms. You agree not to use Sipnudge or the App in any way that could damage, disable, overburden, or impair our servers or networks. You agree not to attempt to gain unauthorized access to any part of Sipnudge or the App, or any other systems or networks connected to them. You agree not to interfere with or disrupt the operation of Sipnudge or the App, or the servers or networks connected to them. You agree not to impersonate any other person or entity, or falsely state or otherwise misrepresent your affiliation with a person or entity. You agree not to use Sipnudge or the App to transmit or distribute any viruses, malware, or other harmful code.",
                        ),
                        _header("5) Intellectual Property:"),
                        _bullet(
                          "All content included in Sipnudge and the App, including but not limited to text, graphics, logos, images, software, and trademarks, is the property of SIPNUDGE TECHNOLOGIES PRIVATE LIMITED or its licensors and is protected by copyright and other intellectual property laws. You may not use any content from Sipnudge or the App without our prior written consent.",
                        ),
                        _header("6) Disclaimer of Warranties:"),
                        _bullet(
                          'Sipnudge and the App are provided "as is" and "as available" without any warranties of any kind, either express or implied. We do not warrant that Sipnudge or the App will be uninterrupted, error-free, or that any defects will be corrected. We do not make any warranties regarding the accuracy, completeness, reliability, or suitability of the information or content provided through Sipnudge and the App. We specifically disclaim any implied warranties of merchantability, fitness for a particular purpose, and non-infringement.',
                        ),
                        _header("7) Limitation of Liability:"),
                        _bullet(
                          "To the maximum extent permitted by applicable law, we will not be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, arising out of or related to your use of Sipnudge or the App, even if we have been advised of the possibility of such damages. Our total liability to you for any claim arising out of or related to these Terms or your use of Sipnudge and the App will not exceed the amount you paid us, if any, for the use of Sipnudge and the App during the twelve (12) months preceding the claim.",
                        ),
                        _header("8) Indemnification:"),
                        _text_p(
                          "You agree to indemnify and hold us harmless from any claims, damages, liabilities, and expenses (including attorneys' fees) arising out of or related to your use of Sipnudge and the App, your violation of these Terms, or your violation of any rights of another.",
                        ),
                        _header("9) Governing Law:"),
                        _bullet(
                          "These Terms will be governed by and construed in accordance with the laws of India, without regard to its conflict of law principles. Since SIPNUDGE TECHNOLOGIES PRIVATE LIMITED is presumably operating within Jalna, Maharashtra, India, the applicable laws would be Indian law. Specifying Jalna within the governing law clause isn't necessary as Indian law will apply regardless.",
                        ),
                        _header("10) Changes to Terms:"),
                        _bullet(
                          "We may update these Terms from time to time. We will notify you of any changes by posting the updated Terms on our website and/or through the App. Your continued use of Sipnudge and the App after the effective date of the updated Terms constitutes your acceptance of the changes.",
                        ),
                        _header("11) Termination:"),
                        _bullet(
                          "We may terminate these Terms or your access to Sipnudge and the App at any time, with or wihout cause, by providing notice to you.",
                        ),
                        _header("12) Entire Agreement:"),
                        _bullet(
                          "These Terms constitute the entire agreement between you and us regarding Sipnudge and the App and supersede all prior agreements and understandings, whether written or oral.",
                        ),
                        _header("13) Contact Us:"),
                        _text_p(
                          "If you have any questions about these Terms, please contact us at: SIPNUDGE TECHNOLOGIES PRIVATE LIMITED Plot No:-172 Sambhaji nagar, Priyadarshani colony, jalna-431203 newton.ns34@gmail.com",
                        ),
                        _header("14) Severability:"),
                        _bullet(
                          "If any provision of these Terms is held to be invalid or unenforceable, the remaining provisions will remain in full force and effect.",
                        ),
                        _header("15) Waiver:"),
                        _bullet(
                          "Our failure to enforce any provision of these Terms will not be deemed a waiver of such provision.",
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
