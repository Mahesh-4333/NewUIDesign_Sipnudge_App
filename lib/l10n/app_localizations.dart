import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SipNudge'**
  String get appTitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @hapticsAndVisuals.
  ///
  /// In en, this message translates to:
  /// **'Haptics & Visuals'**
  String get hapticsAndVisuals;

  /// No description provided for @waterIntakeGoal.
  ///
  /// In en, this message translates to:
  /// **'Water Intake Goal'**
  String get waterIntakeGoal;

  /// No description provided for @ringtoneFeedback.
  ///
  /// In en, this message translates to:
  /// **'Ringtone Feedback'**
  String get ringtoneFeedback;

  /// No description provided for @playAudioWhenTargetIsMet.
  ///
  /// In en, this message translates to:
  /// **'Play audio when target is met'**
  String get playAudioWhenTargetIsMet;

  /// No description provided for @ringtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get ringtone;

  /// No description provided for @vibrationHapticIntensity.
  ///
  /// In en, this message translates to:
  /// **'Vibration: Haptic Intensity'**
  String get vibrationHapticIntensity;

  /// No description provided for @ledNotificationLight.
  ///
  /// In en, this message translates to:
  /// **'LED: Notification Light'**
  String get ledNotificationLight;

  /// No description provided for @uvCleaning.
  ///
  /// In en, this message translates to:
  /// **'UV Cleaning'**
  String get uvCleaning;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @dim.
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get dim;

  /// No description provided for @bright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get bright;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @resetAllTrackings.
  ///
  /// In en, this message translates to:
  /// **'RESET ALL TRACKINGS'**
  String get resetAllTrackings;

  /// No description provided for @localDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared.'**
  String get localDataCleared;

  /// No description provided for @trackingRestarted.
  ///
  /// In en, this message translates to:
  /// **'Tracking restarted. Connect your device again.'**
  String get trackingRestarted;

  /// No description provided for @errorClearingLocalData.
  ///
  /// In en, this message translates to:
  /// **'Error clearing local data: '**
  String get errorClearingLocalData;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi (हिंदी)'**
  String get hindi;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish (Español)'**
  String get spanish;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German (Deutsch)'**
  String get german;

  /// No description provided for @eraseAllData.
  ///
  /// In en, this message translates to:
  /// **'Erase All Data'**
  String get eraseAllData;

  /// No description provided for @eraseAllDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure that erasing your data is permanent. All your history, preferences, and saved content will be deleted immediately.'**
  String get eraseAllDataDescription;

  /// No description provided for @secondsUpper.
  ///
  /// In en, this message translates to:
  /// **'SECONDS'**
  String get secondsUpper;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get deleting;

  /// No description provided for @slideToEraseAllData.
  ///
  /// In en, this message translates to:
  /// **'SLIDE TO EARSE ALL DATA'**
  String get slideToEraseAllData;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Action'**
  String get cancelAction;

  /// No description provided for @selectRingtone.
  ///
  /// In en, this message translates to:
  /// **'Select Ringtone'**
  String get selectRingtone;

  /// No description provided for @topPicks.
  ///
  /// In en, this message translates to:
  /// **'Top Picks'**
  String get topPicks;

  /// No description provided for @natureCategory.
  ///
  /// In en, this message translates to:
  /// **'NATURE'**
  String get natureCategory;

  /// No description provided for @electronicCategory.
  ///
  /// In en, this message translates to:
  /// **'ELECTRONIC'**
  String get electronicCategory;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @ringtoneSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ringtone saved successfully!'**
  String get ringtoneSavedSuccessfully;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes: '**
  String get failedToSaveChanges;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get setting;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievement;

  /// No description provided for @drinkreminder.
  ///
  /// In en, this message translates to:
  /// **'Drink Reminder'**
  String get drinkreminder;

  /// No description provided for @accountandsecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountandsecurity;

  /// No description provided for @helpandsupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpandsupport;

  /// No description provided for @waterintaketimeline.
  ///
  /// In en, this message translates to:
  /// **'Water Intake Timeline'**
  String get waterintaketimeline;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesLogout.
  ///
  /// In en, this message translates to:
  /// **'Yes, Logout'**
  String get yesLogout;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @personalinfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalinfo;

  /// No description provided for @itsA.
  ///
  /// In en, this message translates to:
  /// **'It\'s a '**
  String get itsA;

  /// No description provided for @sunnyDay.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get sunnyDay;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **' today!'**
  String get today;

  /// No description provided for @waterBottleReminder.
  ///
  /// In en, this message translates to:
  /// **'Remember to stay hydrated throughout the day'**
  String get waterBottleReminder;

  /// No description provided for @touchTheCapToSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Touch the cap to sync now'**
  String get touchTheCapToSyncNow;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: '**
  String get lastSynced;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntake;

  /// No description provided for @drinkCompletion.
  ///
  /// In en, this message translates to:
  /// **'Drink Completion'**
  String get drinkCompletion;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @searchingBottle.
  ///
  /// In en, this message translates to:
  /// **'Searching bottle...'**
  String get searchingBottle;

  /// No description provided for @letsHitHydrationGoals.
  ///
  /// In en, this message translates to:
  /// **'Let\'s hit our hydration goals'**
  String get letsHitHydrationGoals;

  /// No description provided for @dataAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Data & Analytics'**
  String get dataAnalytics;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @todayTab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// No description provided for @weeklyTab.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyTab;

  /// No description provided for @monthlyTab.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyTab;

  /// No description provided for @averageIntake.
  ///
  /// In en, this message translates to:
  /// **'Average Intake'**
  String get averageIntake;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached'**
  String get goalReached;

  /// No description provided for @totalDrank.
  ///
  /// In en, this message translates to:
  /// **'Total Drank'**
  String get totalDrank;

  /// No description provided for @hydrationScore.
  ///
  /// In en, this message translates to:
  /// **'Hydration Score'**
  String get hydrationScore;

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get dailyAverage;

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get bestDay;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @drinkTypes.
  ///
  /// In en, this message translates to:
  /// **'Drink Types'**
  String get drinkTypes;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @tea.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get tea;

  /// No description provided for @coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffee;

  /// No description provided for @juice.
  ///
  /// In en, this message translates to:
  /// **'Juice'**
  String get juice;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission Needed'**
  String get permissionNeeded;

  /// No description provided for @grantHealthPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant access to sync health data'**
  String get grantHealthPermission;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get dailyGoal;

  /// No description provided for @setYourGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Your Goal'**
  String get setYourGoal;

  /// No description provided for @yourDailyGoalIs.
  ///
  /// In en, this message translates to:
  /// **'Your Daily goal is '**
  String get yourDailyGoalIs;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoal;

  /// No description provided for @customGoal.
  ///
  /// In en, this message translates to:
  /// **'Custom Goal'**
  String get customGoal;

  /// No description provided for @calculateRecommendedGoal.
  ///
  /// In en, this message translates to:
  /// **'Calculate Recommended Goal'**
  String get calculateRecommendedGoal;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended: '**
  String get recommended;

  /// No description provided for @congratulationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulationsTitle;

  /// No description provided for @levelReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve Reached Level'**
  String get levelReachedTitle;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @supportTickets.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get supportTickets;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'F&Q'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @sipnudgeBottle.
  ///
  /// In en, this message translates to:
  /// **'Sipnudge Bottle'**
  String get sipnudgeBottle;

  /// No description provided for @connectWifi.
  ///
  /// In en, this message translates to:
  /// **'Connect Wi-Fi'**
  String get connectWifi;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @accountRemoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and data. Proceed with caution.'**
  String get accountRemoveDesc;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download My Data'**
  String get downloadMyData;

  /// No description provided for @downloadMyDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Request a copy of your data. Your information, your control.'**
  String get downloadMyDataDesc;

  /// No description provided for @biometricsId.
  ///
  /// In en, this message translates to:
  /// **'Biometrics ID'**
  String get biometricsId;

  /// No description provided for @faceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get faceId;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @linkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get linkedAccounts;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @reminderMode.
  ///
  /// In en, this message translates to:
  /// **'Reminder Mode'**
  String get reminderMode;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @specificTimes.
  ///
  /// In en, this message translates to:
  /// **'Specific Times'**
  String get specificTimes;

  /// No description provided for @selectSipInterval.
  ///
  /// In en, this message translates to:
  /// **'Select Sip Interval'**
  String get selectSipInterval;

  /// No description provided for @alarmRepeat.
  ///
  /// In en, this message translates to:
  /// **'Alarm Repeat'**
  String get alarmRepeat;

  /// No description provided for @stopWhen100.
  ///
  /// In en, this message translates to:
  /// **'Stop When 100%'**
  String get stopWhen100;

  /// No description provided for @wakeUpTimeAsAlarm.
  ///
  /// In en, this message translates to:
  /// **'Wake-up Time as Alarm'**
  String get wakeUpTimeAsAlarm;

  /// No description provided for @steadySipReminder.
  ///
  /// In en, this message translates to:
  /// **'Steady Sip Reminder'**
  String get steadySipReminder;

  /// No description provided for @aiDrivenSmartReminder.
  ///
  /// In en, this message translates to:
  /// **'AI-Driven Smart Reminder'**
  String get aiDrivenSmartReminder;

  /// No description provided for @restartAllTracking.
  ///
  /// In en, this message translates to:
  /// **'Restart All Tracking'**
  String get restartAllTracking;

  /// No description provided for @vibrationStrength.
  ///
  /// In en, this message translates to:
  /// **'Vibration Strength'**
  String get vibrationStrength;

  /// No description provided for @ledIndicator.
  ///
  /// In en, this message translates to:
  /// **'LED Indicator'**
  String get ledIndicator;

  /// No description provided for @selectColorOfLed.
  ///
  /// In en, this message translates to:
  /// **'Select Color of LED'**
  String get selectColorOfLed;

  /// No description provided for @todaysRefills.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Refills'**
  String get todaysRefills;

  /// No description provided for @ambientTemperature.
  ///
  /// In en, this message translates to:
  /// **'Ambient Temperature'**
  String get ambientTemperature;

  /// No description provided for @roomTemperature.
  ///
  /// In en, this message translates to:
  /// **'Room Temperature: '**
  String get roomTemperature;

  /// No description provided for @youHaveReachedGoal.
  ///
  /// In en, this message translates to:
  /// **'You have reached  {percent}% of today\'s goal'**
  String youHaveReachedGoal(String percent);

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @logHydration.
  ///
  /// In en, this message translates to:
  /// **'Log Hydration'**
  String get logHydration;

  /// No description provided for @goalTracking.
  ///
  /// In en, this message translates to:
  /// **'Goal Tracking'**
  String get goalTracking;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @todaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goal'**
  String get todaysGoal;

  /// No description provided for @achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get achieved;

  /// No description provided for @snapFoodPics.
  ///
  /// In en, this message translates to:
  /// **'Snap food pics for quick \nAI-driven nutrition facts'**
  String get snapFoodPics;

  /// No description provided for @clickToScanOrAdd.
  ///
  /// In en, this message translates to:
  /// **'Click to scan or add food item'**
  String get clickToScanOrAdd;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @allTab.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTab;

  /// No description provided for @offSlot.
  ///
  /// In en, this message translates to:
  /// **'Off-slot'**
  String get offSlot;

  /// No description provided for @scheduledRecords.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Records'**
  String get scheduledRecords;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No History'**
  String get noHistory;

  /// No description provided for @recordYourSips.
  ///
  /// In en, this message translates to:
  /// **'Record your sips'**
  String get recordYourSips;

  /// No description provided for @globalImpact.
  ///
  /// In en, this message translates to:
  /// **'Global Impact'**
  String get globalImpact;

  /// No description provided for @trackYourContribution.
  ///
  /// In en, this message translates to:
  /// **'Track your contribution and social standing.'**
  String get trackYourContribution;

  /// No description provided for @globalRanking.
  ///
  /// In en, this message translates to:
  /// **'Global Ranking'**
  String get globalRanking;

  /// No description provided for @topPercent.
  ///
  /// In en, this message translates to:
  /// **'Top {percent}%'**
  String topPercent(String percent);

  /// No description provided for @progressTo.
  ///
  /// In en, this message translates to:
  /// **'progress to {tier}'**
  String progressTo(String tier);

  /// No description provided for @socialImpactMap.
  ///
  /// In en, this message translates to:
  /// **'Social Impact Map'**
  String get socialImpactMap;

  /// No description provided for @expandMap.
  ///
  /// In en, this message translates to:
  /// **'Expand Map'**
  String get expandMap;

  /// No description provided for @yourImpactStory.
  ///
  /// In en, this message translates to:
  /// **'Your Impact Story'**
  String get yourImpactStory;

  /// No description provided for @bottleSaved.
  ///
  /// In en, this message translates to:
  /// **'Bottles Saved'**
  String get bottleSaved;

  /// No description provided for @carbonReduced.
  ///
  /// In en, this message translates to:
  /// **'Carbon Reduced'**
  String get carbonReduced;

  /// No description provided for @socialLeague.
  ///
  /// In en, this message translates to:
  /// **'Social League'**
  String get socialLeague;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @completedSlots.
  ///
  /// In en, this message translates to:
  /// **'Completed Slots'**
  String get completedSlots;

  /// No description provided for @pendingSlots.
  ///
  /// In en, this message translates to:
  /// **'Pending Slots'**
  String get pendingSlots;

  /// No description provided for @noCompletedSlotsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed slots yet'**
  String get noCompletedSlotsYet;

  /// No description provided for @allSlotsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All slots completed!'**
  String get allSlotsCompleted;

  /// No description provided for @targetMet.
  ///
  /// In en, this message translates to:
  /// **'Target Met'**
  String get targetMet;

  /// No description provided for @cancelUpper.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelUpper;

  /// No description provided for @updateUpper.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateUpper;

  /// No description provided for @timeSlotOverlapping.
  ///
  /// In en, this message translates to:
  /// **'Time slot overlapping!'**
  String get timeSlotOverlapping;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @foodIntake.
  ///
  /// In en, this message translates to:
  /// **'Food Intake'**
  String get foodIntake;

  /// No description provided for @liquidIntake.
  ///
  /// In en, this message translates to:
  /// **'Liquid Intake'**
  String get liquidIntake;

  /// No description provided for @recentLogs.
  ///
  /// In en, this message translates to:
  /// **'Recent Logs'**
  String get recentLogs;

  /// No description provided for @profileSetup.
  ///
  /// In en, this message translates to:
  /// **'Profile Setup'**
  String get profileSetup;

  /// No description provided for @quietHoursAndActivity.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours & Activity'**
  String get quietHoursAndActivity;

  /// No description provided for @sleepScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your sleep schedule so Sipnudge stays\ncompletely silent overnight.'**
  String get sleepScheduleSubtitle;

  /// No description provided for @sleepCycle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Cycle'**
  String get sleepCycle;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake Time'**
  String get wakeTime;

  /// No description provided for @bedTime.
  ///
  /// In en, this message translates to:
  /// **'Bed Time'**
  String get bedTime;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY LEVEL'**
  String get activityLevel;

  /// No description provided for @enterWakeupTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter your wakeup time'**
  String get enterWakeupTime;

  /// No description provided for @enterBedtime.
  ///
  /// In en, this message translates to:
  /// **'Please enter your bedtime'**
  String get enterBedtime;

  /// No description provided for @selectWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Select Wake Time'**
  String get selectWakeTime;

  /// No description provided for @selectBedTime.
  ///
  /// In en, this message translates to:
  /// **'Select Bed Time'**
  String get selectBedTime;

  /// No description provided for @fuelAndFlow.
  ///
  /// In en, this message translates to:
  /// **'Fuel & Flow'**
  String get fuelAndFlow;

  /// No description provided for @dietSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about your diet to calculate your baseline hydration needs.'**
  String get dietSubtitle;

  /// No description provided for @primaryDietFocus.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY DIET FOCUS'**
  String get primaryDietFocus;

  /// No description provided for @averageDailyWater.
  ///
  /// In en, this message translates to:
  /// **'AVERAGE DAILY WATER'**
  String get averageDailyWater;

  /// No description provided for @roughEstimateFine.
  ///
  /// In en, this message translates to:
  /// **'Rough estimate is fine'**
  String get roughEstimateFine;

  /// No description provided for @dailyCaffeine.
  ///
  /// In en, this message translates to:
  /// **'DAILY CAFFEINE'**
  String get dailyCaffeine;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @scrollDown.
  ///
  /// In en, this message translates to:
  /// **'Scroll Down'**
  String get scrollDown;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @yourState.
  ///
  /// In en, this message translates to:
  /// **'Your State'**
  String get yourState;

  /// No description provided for @personalizeProfile.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize your hydration profile.'**
  String get personalizeProfile;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get username;

  /// No description provided for @usernameRequirements.
  ///
  /// In en, this message translates to:
  /// **'3-15 alphanumeric characters or underscores only.'**
  String get usernameRequirements;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken.'**
  String get usernameTaken;

  /// No description provided for @usernameCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be changed once set.'**
  String get usernameCannotBeChanged;

  /// No description provided for @checkingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Checking availability...'**
  String get checkingAvailability;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username available'**
  String get usernameAvailable;

  /// No description provided for @useLettersNumbersUnderscores.
  ///
  /// In en, this message translates to:
  /// **'Use 3-15 letters, numbers, or underscores.'**
  String get useLettersNumbersUnderscores;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'AGE'**
  String get age;

  /// No description provided for @genderIdentity.
  ///
  /// In en, this message translates to:
  /// **'GENDER IDENTITY'**
  String get genderIdentity;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get weight;

  /// No description provided for @fillHeightWeightAge.
  ///
  /// In en, this message translates to:
  /// **'Please fill in height, weight, and age before continuing.'**
  String get fillHeightWeightAge;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username.'**
  String get enterUsername;

  /// No description provided for @usernameMustBeAlphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-15 alphanumeric characters or underscores.'**
  String get usernameMustBeAlphanumeric;

  /// No description provided for @yourDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Your Daily goal'**
  String get yourDailyGoal;

  /// No description provided for @rotateBezelToAdjustVolume.
  ///
  /// In en, this message translates to:
  /// **'Rotate bezel to adjust volume'**
  String get rotateBezelToAdjustVolume;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'NEW GOAL'**
  String get newGoal;

  /// No description provided for @unitPerDay.
  ///
  /// In en, this message translates to:
  /// **'{unit} / day'**
  String unitPerDay(String unit);

  /// No description provided for @targetCalibration.
  ///
  /// In en, this message translates to:
  /// **'Target Calibration'**
  String get targetCalibration;

  /// No description provided for @adjustDailyIntakeGoal.
  ///
  /// In en, this message translates to:
  /// **'Adjust your daily intake goal based on precision metrics.'**
  String get adjustDailyIntakeGoal;

  /// No description provided for @avgIntake.
  ///
  /// In en, this message translates to:
  /// **'Avg Intake'**
  String get avgIntake;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @hydrationTipMetabolism.
  ///
  /// In en, this message translates to:
  /// **'Drinking water before meals can boost \nyour metabolism by up to 30%.'**
  String get hydrationTipMetabolism;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @googleCalendarSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar sign-in might be required for smart snooze and calendar sync'**
  String get googleCalendarSignInRequired;

  /// No description provided for @iGiveMyConsent.
  ///
  /// In en, this message translates to:
  /// **'I give my consent'**
  String get iGiveMyConsent;

  /// No description provided for @chooseYourFinish.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Finish'**
  String get chooseYourFinish;

  /// No description provided for @selectColorDailyRhythm.
  ///
  /// In en, this message translates to:
  /// **'Select the color that matches your\ndaily rhythm.'**
  String get selectColorDailyRhythm;

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelection;

  /// No description provided for @midnightBlack.
  ///
  /// In en, this message translates to:
  /// **'Midnight Black'**
  String get midnightBlack;

  /// No description provided for @descMidnightBlack.
  ///
  /// In en, this message translates to:
  /// **'“Minimal, Timeless. Built for every environment”'**
  String get descMidnightBlack;

  /// No description provided for @candyRed.
  ///
  /// In en, this message translates to:
  /// **'Candy Red'**
  String get candyRed;

  /// No description provided for @descCandyRed.
  ///
  /// In en, this message translates to:
  /// **'“Bold, Energetic, and Impossible to ignore”'**
  String get descCandyRed;

  /// No description provided for @deepPurple.
  ///
  /// In en, this message translates to:
  /// **'Deep Purple'**
  String get deepPurple;

  /// No description provided for @descDeepPurple.
  ///
  /// In en, this message translates to:
  /// **'“Creative, Premium, and uniquely yours”'**
  String get descDeepPurple;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @yourSipnudgeBottle.
  ///
  /// In en, this message translates to:
  /// **'Your Sipnudge Bottle'**
  String get yourSipnudgeBottle;

  /// No description provided for @bluetoothRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is required to sync your\nhydration data from your smart bottle\nto the app in real-time.'**
  String get bluetoothRequiredDescription;

  /// No description provided for @realTimeTracking.
  ///
  /// In en, this message translates to:
  /// **'Real-time tracking'**
  String get realTimeTracking;

  /// No description provided for @instantLiquidLevelUpdates.
  ///
  /// In en, this message translates to:
  /// **'Instant liquid level updates.'**
  String get instantLiquidLevelUpdates;

  /// No description provided for @smartNudges.
  ///
  /// In en, this message translates to:
  /// **'Smart nudges'**
  String get smartNudges;

  /// No description provided for @personalizedHabitBuilding.
  ///
  /// In en, this message translates to:
  /// **'Personalized habit building.'**
  String get personalizedHabitBuilding;

  /// No description provided for @accurateHistory.
  ///
  /// In en, this message translates to:
  /// **'Accurate history'**
  String get accurateHistory;

  /// No description provided for @detailedConsumptionLogs.
  ///
  /// In en, this message translates to:
  /// **'Detailed consumption logs.'**
  String get detailedConsumptionLogs;

  /// No description provided for @enableBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth'**
  String get enableBluetooth;

  /// No description provided for @skipNoBottle.
  ///
  /// In en, this message translates to:
  /// **'Skip: I don\'t have a bottle'**
  String get skipNoBottle;

  /// No description provided for @bottleActivation.
  ///
  /// In en, this message translates to:
  /// **'Bottle Activation'**
  String get bottleActivation;

  /// No description provided for @wakeUpSmartBottleDescription.
  ///
  /// In en, this message translates to:
  /// **'Let\'s wake up your smart bottle and get it\nconnected to your wellness profile.'**
  String get wakeUpSmartBottleDescription;

  /// No description provided for @wakeYourBottle.
  ///
  /// In en, this message translates to:
  /// **'Wake Your Bottle'**
  String get wakeYourBottle;

  /// No description provided for @touchCapDescription.
  ///
  /// In en, this message translates to:
  /// **'Gently touch the cap to activate the\nsensor and start advertising.'**
  String get touchCapDescription;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'SCANNING...'**
  String get scanning;

  /// No description provided for @discoveredDevices.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERED DEVICES'**
  String get discoveredDevices;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @readyToPair.
  ///
  /// In en, this message translates to:
  /// **'Ready to pair'**
  String get readyToPair;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @noDeviceFound.
  ///
  /// In en, this message translates to:
  /// **'No device found'**
  String get noDeviceFound;

  /// No description provided for @tapOn.
  ///
  /// In en, this message translates to:
  /// **'Tap on '**
  String get tapOn;

  /// No description provided for @toEstablishSecureConnection.
  ///
  /// In en, this message translates to:
  /// **' to establish a secure connection and verify sensor calibration.'**
  String get toEstablishSecureConnection;

  /// No description provided for @environmentalHarmony.
  ///
  /// In en, this message translates to:
  /// **'Environmental\nHarmony'**
  String get environmentalHarmony;

  /// No description provided for @environmentalHarmonyDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect seamlessly with your \nsurroundings. Sipnudge harmonizes \nwith local climate conditions to \ndynamically balance your hydration \nneeds, maintaining optimal wellness \nwherever you are.'**
  String get environmentalHarmonyDescription;

  /// No description provided for @temperatureCalibrationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Temperature data is primary sourced from your Sipnudge bottle to estimate surrounding conditions. If the bottle is unavailable, the model automatically switches to your city\'s local temperature for calibration.'**
  String get temperatureCalibrationDisclaimer;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @illDoItLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do it later'**
  String get illDoItLater;

  /// No description provided for @eg.
  ///
  /// In en, this message translates to:
  /// **'e.g.'**
  String get eg;

  /// No description provided for @freshStart.
  ///
  /// In en, this message translates to:
  /// **'Fresh Start'**
  String get freshStart;

  /// No description provided for @freshStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill bottle until the float disc aligns with the maximum\nlevel marker. Do not exceed capacity to maintain\nsensor accuracy.'**
  String get freshStartDescription;

  /// No description provided for @targetVolume.
  ///
  /// In en, this message translates to:
  /// **'TARGET VOLUME'**
  String get targetVolume;

  /// No description provided for @maxVolumeFormat.
  ///
  /// In en, this message translates to:
  /// **'/{volume} ml'**
  String maxVolumeFormat(String volume);

  /// No description provided for @calibrated.
  ///
  /// In en, this message translates to:
  /// **'Calibrated'**
  String get calibrated;

  /// No description provided for @calibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration'**
  String get calibration;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get max;

  /// No description provided for @overfillingWarning.
  ///
  /// In en, this message translates to:
  /// **'Overfilling may cause cap displacement \nand interfere with hydration tracking \nsensors.'**
  String get overfillingWarning;

  /// No description provided for @precision.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get precision;

  /// No description provided for @precisionDescription.
  ///
  /// In en, this message translates to:
  /// **'Ensures accurate \nhydration \ntracking.'**
  String get precisionDescription;

  /// No description provided for @seal.
  ///
  /// In en, this message translates to:
  /// **'Seal'**
  String get seal;

  /// No description provided for @sealDescription.
  ///
  /// In en, this message translates to:
  /// **'Prevents leaks \nand pressure \nbuild-up.'**
  String get sealDescription;

  /// No description provided for @calibrating.
  ///
  /// In en, this message translates to:
  /// **'Caliberating..'**
  String get calibrating;

  /// No description provided for @finalizeCalibration.
  ///
  /// In en, this message translates to:
  /// **'Finalize Calibration'**
  String get finalizeCalibration;

  /// No description provided for @startCalibration.
  ///
  /// In en, this message translates to:
  /// **'Start Calibration'**
  String get startCalibration;

  /// No description provided for @walkthroughTitle1.
  ///
  /// In en, this message translates to:
  /// **'Sipnudge - Your Ultimate\nHydration Co-pilot!'**
  String get walkthroughTitle1;

  /// No description provided for @walkthroughSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Stay healthy, & conquer your hydration goals!\nTrack your water intake, set reminders, and\nunlock achievements for a healthier you.'**
  String get walkthroughSubtitle1;

  /// No description provided for @walkthroughTitle2.
  ///
  /// In en, this message translates to:
  /// **'Track Your Hydration &\nVisualize Your Progress'**
  String get walkthroughTitle2;

  /// No description provided for @walkthroughSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Set reminders to stay consistent, review your\ndaily hydration history, and visualize your\nprogress over time.'**
  String get walkthroughSubtitle2;

  /// No description provided for @walkthroughTitle3.
  ///
  /// In en, this message translates to:
  /// **'Achieve Your Hydration\nGoals with Sipnudge Now'**
  String get walkthroughTitle3;

  /// No description provided for @walkthroughSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Level up your hydration game with Sipnudge\nachievements. Unlock premium features, and\nmake hydration a lifelong habit.'**
  String get walkthroughSubtitle3;

  /// No description provided for @walkthroughTitle4.
  ///
  /// In en, this message translates to:
  /// **'Uncover the Hidden\nHydration in Your Meals'**
  String get walkthroughTitle4;

  /// No description provided for @walkthroughSubtitle4.
  ///
  /// In en, this message translates to:
  /// **'Scan your food to instantly calculate its water\ncontent and auto-correct your daily drinking\ngoals for effortless, total hydration.'**
  String get walkthroughSubtitle4;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Lets get started'**
  String get letsGetStarted;

  /// No description provided for @beginYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey'**
  String get beginYourJourney;

  /// No description provided for @letsDive.
  ///
  /// In en, this message translates to:
  /// **'Let\'s dive in into your account'**
  String get letsDive;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @pleaseAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get pleaseAcceptTerms;

  /// No description provided for @signingInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signing you in via Google'**
  String get signingInGoogle;

  /// No description provided for @signingInApple.
  ///
  /// In en, this message translates to:
  /// **'Signing you in via Apple'**
  String get signingInApple;

  /// No description provided for @signinSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Signin Successful'**
  String get signinSuccessful;

  /// No description provided for @couldNotOpenWebpage.
  ///
  /// In en, this message translates to:
  /// **'Could not open the webpage'**
  String get couldNotOpenWebpage;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @gladToSeeYou.
  ///
  /// In en, this message translates to:
  /// **'Glad to see you again! 👋'**
  String get gladToSeeYou;

  /// No description provided for @getStartedWithSipnudge.
  ///
  /// In en, this message translates to:
  /// **'Get started with SipNudge ✨'**
  String get getStartedWithSipnudge;

  /// No description provided for @signinToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue your journey towards a healthier you.'**
  String get signinToYourAccount;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account to track your water intake, set reminders, and unlock achievements.'**
  String get createAnAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @iAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to Sipnudge '**
  String get iAgree;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAnAccount;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @pleaseEnterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get pleaseEnterEmailAndPassword;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @sendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP'**
  String get sendingOtp;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @analyingYourData.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your data to create a personalized hydration plan...'**
  String get analyingYourData;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Your personalized hydration plan is coming right up.'**
  String get almostThere;

  /// No description provided for @bluetoothPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Permission Required'**
  String get bluetoothPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @stayConnectedAndOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected\n& On Track'**
  String get stayConnectedAndOnTrack;

  /// No description provided for @understandingHydrationRingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Understanding your hydration ring helps you crush your goals.'**
  String get understandingHydrationRingSubtitle;

  /// No description provided for @letsHitTodaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Let’s hit today’s goal'**
  String get letsHitTodaysGoal;

  /// No description provided for @keepSippingText.
  ///
  /// In en, this message translates to:
  /// **'Keep Sipping'**
  String get keepSippingText;

  /// No description provided for @youreOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You’re on track'**
  String get youreOnTrack;

  /// No description provided for @seeYourDayAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'See Your Day at a Glance'**
  String get seeYourDayAtAGlance;

  /// No description provided for @ringShowsDailyHydrationGoal.
  ///
  /// In en, this message translates to:
  /// **'Your ring shows how close you are to your daily hydration goal.'**
  String get ringShowsDailyHydrationGoal;

  /// No description provided for @stayOnYourNextGoal.
  ///
  /// In en, this message translates to:
  /// **'Stay on Your Next Goal'**
  String get stayOnYourNextGoal;

  /// No description provided for @yellowRingHighlightsMicroGoal.
  ///
  /// In en, this message translates to:
  /// **'Your yellow ring highlights the micro-goal to focus on right now.'**
  String get yellowRingHighlightsMicroGoal;

  /// No description provided for @watchYourProgressBuild.
  ///
  /// In en, this message translates to:
  /// **'Watch Your Progress Build'**
  String get watchYourProgressBuild;

  /// No description provided for @everySipAddsToBlueRing.
  ///
  /// In en, this message translates to:
  /// **'Every sip adds to your blue ring and moves you closer to your goal.'**
  String get everySipAddsToBlueRing;

  /// No description provided for @sipSmartStaySharp.
  ///
  /// In en, this message translates to:
  /// **'Sip Smart, Stay Sharp'**
  String get sipSmartStaySharp;

  /// No description provided for @keepYellowSegmentSmall.
  ///
  /// In en, this message translates to:
  /// **'Keep the yellow segment as small as possible or gone entirely to stay ahead of schedule.'**
  String get keepYellowSegmentSmall;

  /// No description provided for @theProGoal.
  ///
  /// In en, this message translates to:
  /// **'THE PRO GOAL'**
  String get theProGoal;

  /// No description provided for @currentGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Goal'**
  String get currentGoalLabel;

  /// No description provided for @nextGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Goal'**
  String get nextGoalLabel;

  /// No description provided for @wakeupLabel.
  ///
  /// In en, this message translates to:
  /// **'Wakeup'**
  String get wakeupLabel;

  /// No description provided for @breakfastLabel.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfastLabel;

  /// No description provided for @midMorningLabel.
  ///
  /// In en, this message translates to:
  /// **'Mid-Morning'**
  String get midMorningLabel;

  /// No description provided for @lunchLabel.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunchLabel;

  /// No description provided for @midAfternoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Mid-Afternoon'**
  String get midAfternoonLabel;

  /// No description provided for @eveningLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get eveningLabel;

  /// No description provided for @dinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinnerLabel;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @addTheWidgetToHomeScreenInstruction.
  ///
  /// In en, this message translates to:
  /// **'Add the widget to your Home Screen and\nsee your goal and progress at a glance'**
  String get addTheWidgetToHomeScreenInstruction;

  /// No description provided for @touchAndHoldHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold your Home Screen'**
  String get touchAndHoldHomeScreen;

  /// No description provided for @tapEditThenAddWidget.
  ///
  /// In en, this message translates to:
  /// **'Tap Edit, then Add Widget'**
  String get tapEditThenAddWidget;

  /// No description provided for @chooseMyWaterAndTapAddWidget.
  ///
  /// In en, this message translates to:
  /// **'Choose My Water and tap Add Widget'**
  String get chooseMyWaterAndTapAddWidget;

  /// No description provided for @smartReminders.
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get smartReminders;

  /// No description provided for @smartRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive timely nudges based on your activity and environment.'**
  String get smartRemindersDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
