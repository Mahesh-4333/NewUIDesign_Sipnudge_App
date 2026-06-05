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

class GreetingWidget extends StatefulWidget {
  const GreetingWidget({super.key});

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget> with WidgetsBindingObserver {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();

    // Listen for username changes
    UserManager().addListener(_onUserNameChanged);
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
        Text(
          _userName,
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_20,
            fontFamily: AppFontStyles.museoModernoFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
      ],
    );
  }
}
