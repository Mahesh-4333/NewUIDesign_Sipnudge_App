import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomerSupportPage extends StatefulWidget {
  const CustomerSupportPage({super.key});

  @override
  State<CustomerSupportPage> createState() => _CustomerSupportPageState();
}

class _CustomerSupportPageState extends State<CustomerSupportPage> {
  String title = 'Home'; // Add this line to track active tab
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final fontScale = screenWidth / 375;

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  // Top user info
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.05,
                      left: screenWidth * 0.06,
                      right: screenWidth * 0.05,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            //shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: IconButton(
                            onPressed: (){
                              Navigator.pop(context);
                            }, icon: Icon(Icons.arrow_back, color: Colors.black, size: 30,
                            )),
                        ),
                        SizedBox(width: screenWidth  * 0.14),
                        const Text(
                          'Customer Support',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 24,
                            fontFamily: 'urbanist-Bold',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.08, right: screenWidth * 0.08),
                      child: Column(
                        children: [
                          buildSocialButton(
                            iconPath: 'assets/cs.png', 
                            label: 'Customer Support', 
                            onPressed: (){
                              //Navigator.pushNamed(context, '/contact_support');
                            }, 
                            fontScale: fontScale),
                            SizedBox(height: screenHeight * 0.025),
                            buildSocialButton(
                            iconPath: 'assets/Website.png', 
                            label: 'Website', 
                            onPressed: (){
                              //Navigator.pushNamed(context, '/website');
                            }, 
                            fontScale: fontScale),
                            SizedBox(height: screenHeight * 0.025),
                            buildSocialButton(
                            iconPath: 'assets/Whatsapp.png', 
                            label: 'WhatsApp', 
                            onPressed: (){
                              //Navigator.pushNamed(context, '/whatsapp');
                            }, 
                            fontScale: fontScale),
                            SizedBox(height: screenHeight * 0.025),
                            buildSocialButton(
                            iconPath: 'assets/Instagram.png', 
                            label: 'Instagram', 
                            onPressed: (){
                              //Navigator.pushNamed(context, '/instagram');
                            }, 
                            fontScale: fontScale),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: screenHeight * 0.09,
                      margin: EdgeInsets.only(
                      left: screenWidth * 0.05,
                      right: screenWidth * 0.05,
                      bottom: screenHeight * 0.03,
                      top: screenHeight * 0.05,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(90),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3F3F3F), Color(0xFFFFFFFF)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2536),
                          borderRadius: BorderRadius.circular(90),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(Icons.home, 'Home', title == 'Home'),
                            _buildNavItem(Icons.analytics_outlined, 'Analysis', title == 'Analysis'),
                            _buildNavItem(Icons.lightbulb_outline, 'Goals', title == 'Goals'),
                            _buildNavItem(Icons.settings, 'Settings', title == 'Settings'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ),
    );
  }
  Widget buildSocialButton({
    required String iconPath,
    required String label,
    Color? iconColor,
    required VoidCallback onPressed,
    required double fontScale,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1000),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: const Offset(0, 4),
            blurRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: 20 * fontScale, vertical: 16 * fontScale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(iconPath,
                width: 24 * fontScale,
                height: 24 * fontScale,
                color: iconColor),
            SizedBox(width: 46 * fontScale),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF212121),
                fontFamily: 'Urbanist-Bold',
                fontSize: 16 * fontScale,
              ),
            ),
            //SizedBox(width: 46 * fontScale),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Color(0xFF000000),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final assetPath = 'assets/${label.toLowerCase()}.png';

    return InkWell(
      onTap: () {
        debugPrint('Tapped on: $label');
        _handleNavigation(label);
      },
      child:  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 60,
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFFFAFAFA), Color(0xFF3E3E3E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: isActive ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(4, 4),
                  color: isActive ? const Color(0x40000000) : Colors.transparent,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Container(
                width: 80,
                height: 58,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFFB182BA), Color(0xFF2D1B31)],
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
                      width: 24,
                      height: 24,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading image: $assetPath - $error');
                        return Icon(icon, size: 22, color: Colors.white);
                      },
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 12.sp,
                        fontFamily: 'Lexend-Regular',
                        fontWeight:
                            isActive ? FontWeight.w300 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      )
    );
  }
  void _handleNavigation(String label) {   
    setState(() {
      title = label; // Update active tab
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label screen coming soon!')),
        );
    }
  }

}
