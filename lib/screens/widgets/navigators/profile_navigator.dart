// import 'package:flutter/material.dart';
// import 'package:hydrify/screens/account&security_page.dart';
// import 'package:hydrify/screens/data_and_analytics_screen.dart';
// import 'package:hydrify/screens/drink_reminder_page.dart';
// import 'package:hydrify/screens/help&support_page.dart';
// import 'package:hydrify/screens/personalinfo.dart';
// import 'package:hydrify/screens/preferences_page.dart';
// import 'package:hydrify/screens/profile_screen_page.dart';
// import 'package:hydrify/screens/water_intake_timeline_screen.dart';

// class ProfileNavigator extends StatelessWidget {
//   const ProfileNavigator({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Navigator(
//       initialRoute: '/profile/home',
//       onGenerateRoute: (settings) {
//         Widget page;
//         switch (settings.name) {
//           case '/profile/home':
//             page = ProfileScreenPage();
//             break;
//           case '/profile/personalinfo':
//             page = PersonalInfoPage();
//             break;
//           case '/profile/drinkreminder':
//             page = DrinkReminder();
//             break;
//           case "/profile/waterintaketimeline":
//             page = WaterIntakeTimelineScreen();
//             break;
//           case "/profile/preferences":
//             page = PreferencesPage();
//             break;
//           case "/profile/data&analytics":
//             page = DataAndAnalyticsPage();
//             break;
//           case "/profile/support":
//             page = HelpAndSupportPage();
//             break;
//           case "/profile/account_security":
//             page = AccountAndSecurityPage();
//             break;

//           default:
//             page = ProfileScreenPage();
//         }

//         return MaterialPageRoute(
//           builder: (_) => page,
//           settings: settings,
//         );
//       },
//     );
//   }
// }
