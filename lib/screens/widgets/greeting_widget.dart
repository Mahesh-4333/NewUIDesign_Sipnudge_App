import 'package:hydrify/helpers/logger.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/data_verification_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/user_manager.dart';
import 'package:hydrify/screens/message_screen.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrify/constants/assets_path.dart';

class GreetingWidget extends StatefulWidget {
  const GreetingWidget({super.key});

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget> with WidgetsBindingObserver {
  String _userName = '';
  int _unreadCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();

    // Listen for username changes
    UserManager().addListener(_onUserNameChanged);

    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final data = await _apiService.getUserMessages(userId);
        if (data['data'] != null && mounted) {
          setState(() {
            _unreadCount = data['data']['unreadPersonalCount'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  void _onUserNameChanged(String newName) {
    if (mounted) {
      setState(() {
        _userName = newName;
      });
    }
  }

  Future<void> _loadUserName() async {
    final userManager = UserManager();
    final name = userManager.userName;

    if (name.isEmpty) {
      final userEmail = await SharedPrefsHelper.getUserName() ?? "";
      String finalName = "";
      finalName = userEmail;

      setState(() {
        _userName = finalName;
      });
    } else {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserManager().removeListener(_onUserNameChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUnreadCount();
      if (mounted) {
        setState(() {});
      }
    }
  }

  String _getGreeting() {
    final hourNow = DateTime.now().hour;

    if (hourNow >= 5 && hourNow < 12) {
      return AppStrings.goodMorning;
    } else if (hourNow >= 12 && hourNow < 17) {
      return AppStrings.goodAfternoon;
    } else if (hourNow >= 17 && hourNow < 21) {
      return AppStrings.goodEvening;
    } else {
      return AppStrings.goodNight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userName.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: TextStyle(
            fontSize: AppFontStyles.fontSize_14,
            fontFamily: AppFontStyles.museoModernoFontFamily,
            color: AppColors.bluegray,
            fontVariations: [AppFontStyles.semiBoldFontVariation],
          ),
        ),
        SizedBox(height: AppDimensions.dim4.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _userName,
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_20,
                fontFamily: AppFontStyles.museoModernoFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MessageScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    AssetsPath.message,
                    width: 24.w,
                    height: 24.h,
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: -2.w,
                      top: -2.h,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
