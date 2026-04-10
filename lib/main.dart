import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/Preferences/preferences_cubit.dart';
import 'package:hydrify/cubit/account&security/account&security_cubit.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/drinkreminder/drink_reminder_cubit.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/cubit/help&support/help&support_cubil.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/cubit/level/level_cubit.dart';
import 'package:hydrify/cubit/linkaccounts/link_accounts_cubit.dart';
import 'package:hydrify/cubit/personal_info_in_profile/personal_info_cubit.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_cubit.dart';
import 'package:hydrify/cubit/reminder%20time&mode/reminder_cubit.dart';
import 'package:hydrify/cubit/reminder%20time&mode/reminder_mode_cubit.dart';
import 'package:hydrify/cubit/reminder%20time&mode/reminder_time_cubit.dart';
import 'package:hydrify/cubit/user_info/user_info_cubit.dart';
import 'package:hydrify/firebase_options.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/providers/authentication_provider.dart';
import 'package:hydrify/providers/user_info_provider.dart';
import 'package:hydrify/providers/weather_provider.dart';
import 'package:hydrify/screens/about_us.dart';
import 'package:hydrify/screens/account&security_page.dart';
import 'package:hydrify/screens/achevements_badge_screen.dart';
import 'package:hydrify/screens/analysis_screen.dart';
import 'package:hydrify/screens/contact_support_page.dart';
import 'package:hydrify/screens/data_and_analytics_screen.dart';
import 'package:hydrify/screens/drink_reminder_page.dart';
import 'package:hydrify/screens/faq_page.dart';
import 'package:hydrify/screens/help&support_page.dart';
import 'package:hydrify/screens/link_accounts_page.dart';
import 'package:hydrify/screens/personal_info_in_setting.dart';
import 'package:hydrify/screens/preferences_page.dart';
import 'package:hydrify/screens/settings_screen.dart';
import 'package:hydrify/screens/splash_screen.dart';
import 'package:hydrify/screens/user_info_daily_goal_screen.dart';
import 'package:hydrify/screens/user_lifestyle_info_input_screen.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/water_intake_timeline/water_intake_timeline_screen.dart';
import 'package:hydrify/services/location_service.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:hydrify/services/weather_service.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
    } catch (e) {
      print('Error connecting to functions emulator: $e');
    }
  }

  final httpClient = http.Client();
  final locationService = LocationService();
  final weatherService = WeatherService(
    client: httpClient,
    apiKey: '4fa9cd3687912a01b9c5c66718b2b99f',
  );

  FlutterBluePlus.setLogLevel(LogLevel.none);

  await UserManager().init();

  FlutterError.onError = (FlutterErrorDetails details) {
    //this line prints the default flutter gesture caught exception in console
    //FlutterError.dumpErrorToConsole(details);
    print("Error From INSIDE FRAME_WORK");
    print("----------------------");
    print("Error :  ${details.exception}");
    print("StackTrace :  ${details.stack}");
  };


  runApp(
    MyApp(
      httpClient: httpClient,
      weatherService: weatherService,
      locationService: locationService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final http.Client httpClient;
  final WeatherService weatherService;
  final LocationService locationService;

  const MyApp({
    super.key,
    required this.httpClient,
    required this.weatherService,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper();
    final bleCubit = BleCubit();
    final hydrationCubit = HydrationCubit(ble: bleCubit);

    return MultiProvider(
      providers: [
        BlocProvider(create: (_) => bleCubit),
        BlocProvider(create: (_) => hydrationCubit),
        BlocProvider(create: (_) => UserInfoCubit(dbHelper)),
        BlocProvider(create: (_) => BottomNavCubit()),
        ChangeNotifierProvider(
            lazy: false, create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => UserInfoProvider()),
        BlocProvider(create: (context) => FilterCubit()),
        ChangeNotifierProvider(
            create: (_) => WeatherProvider(weatherService, locationService)),
        BlocProvider(create: (context) => BottleDataCubit(bleCubit)),
        BlocProvider(create: (context) => ReminderCubit()),
        BlocProvider(create: (context) => ReminderTimeCubit()),
        BlocProvider(create: (context) => ReminderIntervalCubit()),
        BlocProvider(create: (context) => LevelCubit()),
        BlocProvider(create: (context) => ProfileCubit()),
        BlocProvider(create: (context) => LinkAccountsCubit()),
        BlocProvider(create: (context) => AccountSecurityCubit()),
        BlocProvider(create: (context) => HelpAndSupportCubit()),
        BlocProvider(create: (context) => PersonalInfoCubit()),
        BlocProvider(create: (context) => DrinkReminderCubit(hydrationCubit: hydrationCubit, bottleDataCubit: context.read<BottleDataCubit>())),
        BlocProvider(create: (context) => PersonalInfoCubit()),
        BlocProvider(create: (context) => PreferencesCubit()),
        // BlocProvider(create: (Context) => NotificationCubit()),
      ],
      child: Builder(
        builder: (context) {
          return ScreenUtilInit(
            minTextAdapt: true,
            designSize: const Size(440, 956),
            builder: (_, child) {
              return Padding(
                  padding: EdgeInsets.only(bottom: 0),
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData(
                      appBarTheme: const AppBarTheme(
                        systemOverlayStyle: SystemUiOverlayStyle(
                          statusBarIconBrightness: Brightness.dark,
                          statusBarBrightness: Brightness.light,
                        ),
                        centerTitle: true,
                        iconTheme: IconThemeData(),
                      ),
                      fontFamily: AppFontStyles.museoModernoFontFamily,
                    ),
                    home: child,
                    routes: {
                      //'/dailygoalpage': (context) => DailyGoalPage(),

                      '/dailygoalpage': (context) => UserInfoDailyGoalScreen(
                            waterGoal: 0,
                            isViaSettingsScreen: false,
                          ),

                      '/homepage': (context) => HomeScreen(),

                      '/analysis': (context) => AnalysisScreen(),

                      // '/lifestyleinfo': (context) => LifeStyleInfoPage(),

                      '/lifestyleinfo': (context) =>
                          UserLifestyleInfoInputScreen(
                            isViaSettingsScreen: false,
                          ),

                      //'/profilescreen': (context) => ProfileScreenPage(),

                      '/settingscreen': (context) => SettingScreen(),

                      '/personalinfo': (context) =>
                          UserInfoInputScreen(fromSettings: true),

                      //'/personalinfo': (context) => PersonalInfoPage(),

                      '/achievement': (context) => AchievementsBadgeScreen(),

                      '/personalinfoinsetting': (context) =>
                          PersonalInfoScreenInSetting(),

                      '/drinkreminder': (context) => DrinkReminderPage(),

                      '/preferences': (context) => PreferencesPage(),

                      '/account_security': (context) =>
                          AccountAndSecurityPage(),

                      '/linked_accounts': (context) => LinkAccountsPage(),

                      '/support': (context) => HelpAndSupportPage(),

                      '/waterintaketimeline': (context) =>
                          WaterIntakeTimelineScreen(),

                      '/faq': (context) => FAQ_Page(),

                      '/aboutus': (context) => AboutUs(),

                      '/contact_support': (context) => ContactSupportPage(),

                      '/data&analytics': (context) => DataAndAnalyticsPage(),

                      // '/privacypolicy': (context) => PrivacyPolicy(),

                      // '/termsofservices': (context) => TermsOfServices(),
                    },
                  ));
              //);
              // );
            },
            child: SplashScreen(),
          );
        },
      ),
    );
  }
}
