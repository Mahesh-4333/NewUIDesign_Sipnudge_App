import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_cubit.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_state.dart';
import 'package:hydrify/screens/contact_support_page.dart';
import 'package:hydrify/screens/drink_reminder_page.dart';
import 'package:hydrify/screens/faq_page.dart';
import 'package:hydrify/screens/help&support_page.dart';
import 'package:hydrify/screens/preferences_page.dart';
import 'package:hydrify/screens/user_personal_info_input_screen..dart';
import 'package:hydrify/screens/widgets/logout_widgets/logout_bottom_sheet.dart';
import 'package:hydrify/screens/widgets/setting_screen_widget/editableProfileAvatar.dart';
import 'package:hydrify/screens/widgets/setting_screen_widget/profile_menu_item.dart';
import 'package:hydrify/services/user_manager.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  static const String _userNameKey = 'user_display_name';

  @override
  void initState() {
    super.initState();
    // Listen for changes
    UserManager().addListener(_onNameChanged);
    _loadSavedName();
  }

  void _onNameChanged(String newName) {
    setState(() {
      _nameController.text = newName;
    });
  }

  Future<void> _loadSavedName() async {
    final name = UserManager().userName;
    _nameController.text = name.isNotEmpty ? name : AppStrings.newtonsingh;
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

  // void _handleNavigation(BuildContext context, String title) {
  //   try {
  //     switch (title) {
  //       case AppStrings.personalinfo:
  //         Navigator.pushNamed(context, '/personalinfo');
  //         break;
  //       case AppStrings.drinkreminder:
  //         Navigator.pushNamed(context, '/drinkreminder');
  //         break;
  //       case AppStrings.sipnudgebottle:
  //         Navigator.pushNamed(context, '/sipnudge_bottle');
  //         break;
  //       case AppStrings.preferences:
  //         Navigator.pushNamed(context, '/preferences');
  //         break;
  //       case AppStrings.dataAnalytics:
  //         Navigator.pushNamed(context, '/data&analytics');
  //         break;
  //       case AppStrings.linkaccounts:
  //         Navigator.pushNamed(context, '/linked_accounts');
  //         break;
  //       case AppStrings.helpandsupport:
  //         Navigator.pushNamed(context, '/support');
  //         break;
  //       case AppStrings.accountandsecurity:
  //         Navigator.pushNamed(context, '/account_security');
  //         break;
  //       case AppStrings.logout:
  //         _showLogoutConfirmation(context);
  //         break;
  //       default:
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('$title screen coming soon!',
  //                 style: TextStyle(
  //                   color: AppColors.white,
  //                   fontSize: AppFontStyles.fontSize_20.sp,
  //                   fontFamily: AppFontStyles.urbanistFontFamily,
  //                   fontVariations: [AppFontStyles.boldFontVariation],
  //                 )),
  //           ),
  //         );
  //     }
  //   } catch (e, s) {
  //     debugPrint("Navigation error for '$title': $e\n$s");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Page Coming Soon...')),
  //     );
  //   }
  // }

  void _handleNavigation(BuildContext context, String title) {
    try {
      final navigator = Navigator.of(context); // this is the tab's Navigator

      switch (title) {
        case AppStrings.personalinfo:
<<<<<<< HEAD
          Navigator.of(context, rootNavigator: true).push(
=======
          navigator.push(
>>>>>>> origin/develop
            MaterialPageRoute(
              builder: (_) => UserInfoInputScreen(fromSettings: true),
            ),
          );
          break;

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

        // case AppStrings.dataAnalytics:
        //   navigator.push(
        //     MaterialPageRoute(
        //       builder: (_) => const DataAnalyticsScreen(),
        //     ),
        //   );
        //   break;

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
        // case AppStrings.accountandsecurity:
        //   navigator.push(
        //     MaterialPageRoute(
        //       builder: (_) => const AccountSecurityScreen(),
        //     ),
        //   );
        //   break;

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
        const SnackBar(content: Text('Page Coming Soon...')),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      useRootNavigator: true,
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
            // TODO: Handle logout logic
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    "assets/images/app_background.png"), // your image path
                fit: BoxFit.cover,
              ),
              // gradient: LinearGradient(
              //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                ),
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    onChanged: (value) {
                                      _saveNameLocally(value);
                                    },
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
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    FocusScope.of(context)
                                        .requestFocus(_nameFocusNode);
                                  },
                                  icon: Image.asset(
                                    "assets/images/editicon.png",
                                    width: AppFontStyles.fontSize_24.sp,
                                    height: AppFontStyles.fontSize_24.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppDimensions.dim30.h),

                    // Menu group 1
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.dim24.w,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radius_16.r),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withOpacity(0.10),
                          //     blurRadius: 4.r,
                          //     spreadRadius: 3.r,
                          //     offset: Offset(4.r, 4.r),
                          //   ),
                          // ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white1A,
                            border: Border.all(color: Color(0xCCC6C6C6)),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radius_16.r),
                          ),
                          child: Column(
                            children: state.menuItems
                                .map(
                                  (item) => ProfileMenuItemWidget(
                                    iconPath: item.iconPath,
                                    title: item.title,
                                    isRed: item.isRed,
                                    iconPathArrow: "assets/arrow.png",
                                    onTap: () => _handleNavigation(
                                      context,
                                      item.title,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.dim34.h),

                    // Menu group 2
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.dim24.w,
                      ),
                      // child: Container(
                      //   decoration: BoxDecoration(
                      //     borderRadius:
                      //         BorderRadius.circular(AppDimensions.radius_16.r),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.black.withOpacity(0.10),
                      //         blurRadius: 2.r,
                      //         spreadRadius: 3.r,
                      //         offset: Offset(3.5.r, 3.5.r),
                      //       ),
                      //     ],
                      //   ),
                      //   // child: Container(
                      //   //   decoration: BoxDecoration(
                      //   //     color: AppColors.white1A,
                      //   //     borderRadius: BorderRadius.circular(
                      //   //         AppDimensions.radius_16.r),
                      //   //   ),
                      //   //   child: Column(
                      //   //     children: state.secondaryMenuItems
                      //   //         .map(
                      //   //           (item) => ProfileMenuItemWidget(
                      //   //             iconPath: item.iconPath,
                      //   //             title: item.title,
                      //   //             isRed: item.isRed,
                      //   //             iconPathArrow: "assets/arrow.png",
                      //   //             onTap: () => _handleNavigation(
                      //   //               context,
                      //   //               item.title,
                      //   //             ),
                      //   //           ),
                      //   //         )
                      //   //         .toList(),
                      //   //   ),
                      //   // ),
                      // ),
                    ),
                    SizedBox(height: AppDimensions.dim165.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
