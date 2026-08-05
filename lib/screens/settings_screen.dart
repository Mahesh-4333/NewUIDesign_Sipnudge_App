import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/screens/data_n_analytics/data_n_analytics_screen.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/l10n/app_localizations.dart';
import 'package:hydrify/cubit/locale/locale_cubit.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_cubit.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_state.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/bottle_info.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/screens/bottle_info_page.dart';
import 'package:hydrify/screens/wifi_provisioning_screen.dart';
import 'package:hydrify/screens/contact_support_page.dart';
import 'package:hydrify/screens/drink_reminder_page.dart';
import 'package:hydrify/screens/faq_page.dart';
import 'package:hydrify/screens/calendar/calendar_screen.dart';
import 'package:hydrify/screens/help&support_page.dart';
import 'package:hydrify/screens/preferences_page.dart';
import 'package:hydrify/screens/widgets/preferences_widgets/language_selection_dialog.dart';
import 'package:hydrify/screens/language_selection_screen.dart';
import 'package:hydrify/screens/account&security_page.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/logout_widgets/logout_bottom_sheet.dart';
import 'package:hydrify/screens/active_notifications_screen.dart';
import 'package:hydrify/screens/data_and_analytics_screen.dart';
import 'package:hydrify/screens/leaderboard_screen.dart';
import 'package:hydrify/screens/subscription_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hydrify/screens/widgets/setting_screen_widget/editableProfileAvatar.dart';
import 'package:hydrify/screens/widgets/setting_screen_widget/profile_menu_item.dart';
import 'package:hydrify/screens/widgets/setting_screen_widget/sipnudgeshopwidget.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:hydrify/widgets/sipnudge_debug_overlay.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  String _appVersion = '';
  bool _isPremium = false;

  static const String _userNameKey = 'user_display_name';

  @override
  void initState() {
    super.initState();
    // Listen for changes
    UserManager().addListener(_onNameChanged);
    _loadSavedName();
    _loadAppVersion();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final premium = await SharedPrefsHelper.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = premium;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion =
          'Version : ${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  void _onNameChanged(String newName) {
    setState(() {
      _nameController.text = newName;
    });
  }

  Future<void> _loadSavedName() async {
    final name = await SharedPrefsHelper.getUserName();
    String finalName = "";
    if (name == null || name == '') {
      finalName = "";
    } else {
      finalName = name;
    }
    _nameController.text =
        finalName.isNotEmpty ? finalName : AppStrings.username;
  }

  void _saveNameLocally(String name) async {
    await UserManager().setUserName(name);
  }

  @override
  void dispose() {
    UserManager().removeListener(_onNameChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleNavigation(BuildContext context, String title) {
    try {
      final navigator = Navigator.of(context); // this is the tab's Navigator

      switch (title) {
        case AppStrings.personalinfo:
          {
            context.read<BottomNavCubit>().hideBar();
            navigator
                .push(
              MaterialPageRoute(
                builder: (_) => UserInfoInputScreen(fromSettings: true),
              ),
            )
                .then((value) {
              context.read<BottomNavCubit>().showBar();
            });
            break;
          }

        case "Billing & Subscription":
          {
            context.read<BottomNavCubit>().hideBar();
            navigator
                .push(
              MaterialPageRoute(
                builder: (_) => const SubscriptionPage(),
              ),
            )
                .then((value) {
              context.read<BottomNavCubit>().showBar();
              _loadPremiumStatus();
            });
            break;
          }

        case AppStrings.drinkreminder:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const DrinkReminderPage(),
            ),
          );
          break;

        // case AppStrings.sipnudgebottle:
        //   navigator.push(
        //     MaterialPageRoute(
        //       builder: (_) => const SipNudgeBottleScreen(),
        //     ),
        //   );
        //   break;

        case AppStrings.preferences:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const PreferencesPage(),
            ),
          );
          break;

        case "Language":
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const LanguageSelectionScreen(isFirstTime: false),
            ),
          );
          break;

        case AppStrings.dataAnalytics:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => DataNAnalyticsScreen(),
            ),
          );
          break;

        case "Leaderboard":
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const LeaderboardScreen(),
            ),
          );
          break;

        // case AppStrings.linkaccounts:
        //   navigator.push(
        //     MaterialPageRoute(
        //       builder: (_) => const LinkedAccountsScreen(),
        //     ),
        //   );
        //   break;

        case AppStrings.helpandsupport:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const HelpAndSupportPage(),
            ),
          );
          break;
        case "Support Tickets":
          Navigator.of(context, rootNavigator: true)
              .pushNamed('/help_support_ticket');
          break;
        case 'faq':
          navigator.push(
            MaterialPageRoute(
              builder: (_) => FAQ_Page(),
            ),
          );

          break;

        case 'contact_support':
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ContactSupportPage(),
            ),
          );

          break;

        // 🔥 NEW: Sipnudge Bottle Navigation
        case 'Sipnudge Bottle':
          _navigateToBottleInfo(context);

          break;

        case 'Connect Wi-Fi':
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const WifiProvisioningScreen(),
            ),
          );
          break;

        case 'Export Log':
          _exportLog(context);
          break;

        case 'Add Millisecond':
          _showFlushDelayDialog(context);
          break;

        case 'BLE Debug Logs':
        case 'BLE Debug Breadcrumbs':
        case 'Debug Breadcrumbs':
          SipnudgeDebugOverlay.show();
          break;

        case 'Active Notifications':
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const ActiveNotificationsScreen(),
            ),
          );
          break;

        case AppStrings.calendar:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const CalendarScreen(),
            ),
          );
          break;

        case "Account & Security":
        case AppStrings.accountandsecurity:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const AccountAndSecurityPage(),
            ),
          );
          break;

        case "Unlink Device":
          _showUnlinkDeviceDialog(context);
          break;

        case AppStrings.logout:
          _showLogoutConfirmation(context);
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$title screen coming soon!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: AppFontStyles.fontSize_20.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ),
          );
      }
    } catch (e, s) {
      debugPrint("Navigation error for '$title': $e\n$s");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pageComingSoon)),
      );
    }
  }

  Widget _buildUpgradeBanner() {
    if (_isPremium) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim24.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF007BFF),
                Color(0xFF004976),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007BFF).withOpacity(0.2),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF007BFF),
                  size: 24,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Elite Upgrade Active",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Enjoying ad-free tracking and hydration insights!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim24.w),
      child: GestureDetector(
        onTap: () {
          final navigator = Navigator.of(context);
          context.read<BottomNavCubit>().hideBar();
          navigator
              .push(
            MaterialPageRoute(
              builder: (_) => const SubscriptionPage(),
            ),
          )
              .then((value) {
            context.read<BottomNavCubit>().showBar();
            _loadPremiumStatus();
          });
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3393FF),
                Color(0xFF007BFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007BFF).withOpacity(0.3),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                AssetsPath.conftyImg,
                width: 44.w,
                height: 44.h,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.upgradePlan,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation]),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      AppStrings.upgradePlan2,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            AppFontStyles.semiBoldFontVariation
                          ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 NEW: Navigate to Bottle Info Screen
  Future<void> _navigateToBottleInfo(BuildContext context) async {
    try {
      // Get selected bottle color
      final selectedBottle = await SharedPrefsHelper.getBottle() ?? 'black';

      // Get current bottle data from cubit
      final bottleState = context.read<BottleDataCubit>().state;

      // Create BottleInfo instance with current data
      final bottleInfo = BottleInfo.getByColor(
        selectedBottle,
        currentWater: bottleState.volume,
        waterPercentage: bottleState.volumePercent,
      );

      // Navigate to Bottle Info Screen
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => BottleInfoScreen(bottleInfo: bottleInfo),
        ),
      );
    } catch (e) {
      debugPrint("Error navigating to Bottle Info: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.unableToLoadBottleInfo)),
      );
    }
  }

  Future<void> _exportLog(BuildContext context) async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'bottle_history.db');
      final logDir = await getApplicationDocumentsDirectory();
      final logPath = '${logDir.path}/app_logs.txt';

      List<XFile> filesToShare = [];

      Console.log(
          tag: "await File(dbPath).exists()",
          value: await File(dbPath).exists());
      if (await File(dbPath).exists()) {
        filesToShare.add(XFile(dbPath));
      } else {
        debugPrint("DB file not found");
      }

      if (await File(logPath).exists()) {
        filesToShare.add(XFile(logPath));
      } else {
        debugPrint("Log file not found");
      }

      if (filesToShare.isNotEmpty) {
        final box = context.findRenderObject() as RenderBox;
        await Share.shareXFiles(
          filesToShare,
          text: 'SipNudge App Logs and Database',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.noLogsOrDbToExport)),
          );
        }
      }
    } catch (e) {
      debugPrint("Error exporting logs: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.failedToExportLogs)),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withOpacity(0),
      builder: (_) {
        return LogoutBottomSheet(
          onCancel: () => Navigator.pop(context),
          onConfirm: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loggedOutSuccessfully)),
            );
          },
        );
      },
    );
  }

  void _showUnlinkDeviceDialog(BuildContext context) {
    showDialog(
      context: Navigator.of(context, rootNavigator: true).context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: const Color(
              0xFFE8ECEF), // Light greyish background matching screenshot
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AssetsPath.unlink, width: 80.w, height: 80.h),
                SizedBox(height: 20.h),
                Text(
                  "Unlink Device?",
                  style: TextStyle(
                    color: const Color(0xFF004976),
                    fontSize: 22.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.darkgray,
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: "Disconnecting your "),
                      TextSpan(
                        text: "Sipnudge\nPro",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.black),
                      ),
                      const TextSpan(
                        text:
                            " will stop all real-time\nhydration tracking. Your\nhistorical data will remain, but\nnew consumption will not sync\nuntil re-paired.",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext); // Close dialog first

                      try {
                        // Unlink logic here
                        await context.read<BleCubit>().unlinkDevice();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Device unlinked successfully.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to unlink device.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF004976), // Dark blue button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      elevation: 0,
                    ),
                    child: Text(
                      "Unlink",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF004976)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child: Text(
                      "Keep Connected",
                      style: TextStyle(
                        color: const Color(0xFF004976),
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFlushDelayDialog(BuildContext context) async {
    final currentDelay = await SharedPrefsHelper.getFlushDelay();
    final TextEditingController delayController =
        TextEditingController(text: currentDelay.toString());

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Set Flush Delay (ms)",
          style: TextStyle(
            color: AppColors.black,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: delayController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Enter milliseconds (default 200)",
            hintStyle: TextStyle(
              color: AppColors.bluegray.withOpacity(0.5),
              fontFamily: AppFontStyles.urbanistFontFamily,
            ),
          ),
          style: TextStyle(
            color: AppColors.black,
            fontFamily: AppFontStyles.urbanistFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.bluegray,
                fontFamily: AppFontStyles.urbanistFontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newDelay = int.tryParse(delayController.text);
              if (newDelay != null && newDelay > 0) {
                await SharedPrefsHelper.setFlushDelay(newDelay);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Flush delay set to $newDelay ms")),
                  );
                }
              }
            },
            child: Text(
              "Save",
              style: TextStyle(
                color: AppColors.darkgray,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return title;
    switch (title) {
      case "Personal Info":
        return l10n.personalinfo;
      case "Preferences":
        return l10n.preferences;
      case "Language":
        return l10n.language;
      case "Drink Reminder":
        return l10n.drinkreminder;
      case "Account & Security":
        return l10n.accountandsecurity;
      case "Help & Support":
        return l10n.helpandsupport;
      case "Water Intake Timeline":
        return l10n.waterintaketimeline;
      case "Logout":
        return l10n.logout;
      case "Achievement":
        return l10n.achievement;
      case "Leaderboard":
        return l10n.leaderboard;
      case "Support Tickets":
        return l10n.supportTickets;
      case "faq":
      case "F&Q":
      case "FAQ":
        return l10n.faq;
      case "contact_support":
      case "Contact Support":
        return l10n.contactSupport;
      case "Sipnudge Bottle":
        return l10n.sipnudgeBottle;
      case "Connect Wi-Fi":
        return l10n.connectWifi;
      case "Data & Analytics":
        return l10n.dataAnalytics;
      default:
        return title;
    }
  }

  List<Widget> _buildGroupedSections(
      BuildContext context, List<ProfileMenuItem> items) {
    final List<Widget> sections = [];

    // Separate logout (no group) from grouped items
    final groupedItems = items.where((i) => i.groupLabel != null).toList();
    final logoutItem = items.where((i) => i.groupLabel == null).toList();

    // Collect unique group labels (preserving insertion order)
    final groupLabels = <String>[];
    for (final item in groupedItems) {
      if (!groupLabels.contains(item.groupLabel!)) {
        groupLabels.add(item.groupLabel!);
      }
    }

    for (final label in groupLabels) {
      final groupItems =
          groupedItems.where((i) => i.groupLabel == label).toList();
      sections.add(_buildSettingsGroup(context, label, groupItems));
      sections.add(SizedBox(height: 16.h));
    }

    // Logout button standalone below all groups
    if (logoutItem.isNotEmpty) {
      final item = logoutItem.first;
      sections.add(
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.dim24.w,
              vertical: AppDimensions.dim10.h),
          child: GestureDetector(
            onTap: () => _handleNavigation(context, item.title),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.7),
                border: Border.all(color: const Color(0xCCC6C6C6)),
                borderRadius: BorderRadius.circular(AppDimensions.radius_100.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    item.iconPath,
                    width: 20.w,
                    height: 20.h,
                    color: AppColors.redAccent,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.logout,
                      color: AppColors.redAccent,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    _getLocalizedTitle(context, item.title),
                    style: TextStyle(
                      color: AppColors.redAccent,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontSize: AppFontStyles.fontSize_18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildSettingsGroup(
      BuildContext context, String label, List<ProfileMenuItem> items) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim24.w),
      child: Container(
        padding: EdgeInsets.only(bottom: AppDimensions.dim10.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: const Color(0xCCC6C6C6)),
          borderRadius: BorderRadius.circular(AppDimensions.radius_16.r),
          boxShadow: AppStyle.boxShadowVariation3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group label INSIDE the card at top
            Padding(
              padding: EdgeInsets.only(
                left: AppDimensions.dim16.w,
                right: AppDimensions.dim16.w,
                top: 14.h,
                bottom: 4.h,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF369FFF),
                  fontSize: 11.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 1.0,
                ),
              ),
            ),
            // Divider below label
            // Divider(
            //   height: 1,
            //   thickness: 1,
            //   color: const Color(0xCCC6C6C6),
            // ),
            // Items with BLE battery badge
            BlocBuilder<BleCubit, BleState>(
              builder: (context, bleState) {
                return Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isLast = index == items.length - 1;

                    // Battery badge for Sipnudge Bottle
                    Widget? badge;
                    if (item.title == "Sipnudge Bottle" &&
                        bleState.battery != null &&
                        bleState.battery! > 0) {
                      badge = Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          "${bleState.battery}%",
                          style: TextStyle(
                            color: const Color(0xFF2E7D32),
                            fontSize: 12.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [
                              AppFontStyles.semiBoldFontVariation
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ProfileMenuItemWidget(
                          iconPath: item.iconPath,
                          title: _getLocalizedTitle(context, item.title),
                          isRed: item.isRed,
                          iconPathArrow: "assets/arrow.png",
                          onTap: () => _handleNavigation(context, item.title),
                          badge: badge,
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xCCC6C6C6),
                            indent: AppDimensions.dim16.w,
                            endIndent: AppDimensions.dim16.w,
                          ),
                      ],
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, currentLocale) {
        return BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return Scaffold(
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/app_background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: AppDimensions.dim50.h,
                            left: AppDimensions.dim25.w,
                            right: AppDimensions.dim25.w,
                          ),
                          child: Row(
                            children: [
                              const EditableProfileAvatar(),
                              SizedBox(width: AppDimensions.dim16.w),
                              Expanded(
                                child: Text(
                                  _nameController.text,
                                  style: TextStyle(
                                    color: AppColors.bluegray,
                                    fontSize: AppFontStyles.fontSize_18.sp,
                                    fontFamily:
                                        AppFontStyles.museoModernoFontFamily,
                                    fontVariations: [
                                      AppFontStyles.fontWeightVariation600,
                                    ],
                                    shadows: [
                                      Shadow(
                                        offset: Offset(
                                          AppDimensions.radius_1.r,
                                          AppDimensions.radius_1.r,
                                        ),
                                        blurRadius: AppDimensions.radius_4.r,
                                        color:
                                            AppColors.black.withOpacity(0.25),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppDimensions.dim30.h),
                        // _buildUpgradeBanner(),
                        SizedBox(height: AppDimensions.dim20.h),

                        // Build grouped sections
                        ..._buildGroupedSections(context, state.menuItems),

                        SizedBox(height: AppDimensions.dim34.h),
                        const SipnudgeShopWidget(),
                        SizedBox(height: 100.h),
                        if (_appVersion.isNotEmpty)
                          Text(
                            _appVersion,
                            style: TextStyle(
                              color: AppColors.bluegray,
                              fontSize: AppFontStyles.fontSize_14.sp,
                              fontFamily: AppFontStyles.museoModernoFontFamily,
                              fontVariations: [
                                AppFontStyles.semiBoldFontVariation
                              ],
                            ),
                          ),
                        SizedBox(height: AppDimensions.dim149.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
