import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/Preferences/preferences_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart'; // Make sure this points to SharedPrefsHelper file
import 'package:hydrify/screens/widgets/ringtone_screen_widget/menuItemTileWidget.dart';

class RingtoneScreen extends StatefulWidget {
  const RingtoneScreen({super.key});

  @override
  State<RingtoneScreen> createState() => _RingtoneScreenState();
}

class _RingtoneScreenState extends State<RingtoneScreen> {
  int selectedIndex = 0;
  late final AudioPlayer _audioPlayer;

  final List<String> ringtones = List.generate(
    10,
    (i) => "assets/ringtones/ringtone${i + 1}.mp3",
  );

  //static const String _kSelectedRingtoneKey = "selected_ringtone";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadSavedRingtone();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Load saved ringtone from SharedPreferences
  Future<void> _loadSavedRingtone() async {
    final saved = await SharedPrefsHelper.getSelectedRingtone();

    if (saved != null && mounted) {
      setState(() {
        selectedIndex = saved;
      });
    }
  }

  /// Handle ringtone selection
  Future<void> _onRingtoneTap(BuildContext context, int index) async {
    setState(() => selectedIndex = index);

    await SharedPrefsHelper.setSelectedRingtone(index);

    final prefs = context.read<PreferencesCubit>().state;

    // 🔔 If ringtone feedback is ON → play ringtone
    if (prefs.ringtoneFeedback) {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);

      final assetPath = ringtones[index].replaceFirst("assets/", "");
      await _audioPlayer.play(AssetSource(assetPath));
    }
    // 📳 If OFF → vibration only
    else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // return BlocProvider(
    //   create: (_) => PreferencesCubit(),
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: AppBar(
            elevation: 0.0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              AppStrings.ringtone,
              style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_AppBar,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [
                    AppFontStyles.boldFontVariation,
                  ]),
            ),
            leadingWidth: AppDimensions.dim85.w,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: SvgPicture.asset(
                "assets/images/back_ic.svg",
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/app_background.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  /// Header
                  // Padding(
                  //   padding: EdgeInsets.only(
                  //     top: AppDimensions.dim40.h,
                  //     left: AppDimensions.dim20.w,
                  //     right: AppDimensions.dim20.w,
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       IconButton(
                  //         onPressed: () => Navigator.pop(context),
                  //         icon: Icon(
                  //           Icons.arrow_back,
                  //           color: AppColors.black,
                  //           size: AppFontStyles.fontSize_30.sp,
                  //         ),
                  //       ),
                  //       SizedBox(width: AppDimensions.dim100.w),
                  //       Text(
                  //         AppStrings.preferences,
                  //         style: TextStyle(
                  //           color: AppColors.bluegray,
                  //           fontSize: AppFontStyles.fontSize_24.sp,
                  //           fontFamily: AppFontStyles.urbanistFontFamily,
                  //           fontVariations: [AppFontStyles.boldFontVariation],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  SizedBox(height: AppDimensions.dim20.h),

                  /// Ringtone List
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.dim28.w,
                    ),
                    child: Column(
                      children: List.generate(ringtones.length, (index) {
                        return MenuItemTileWidget(
                          title: "Ringtone",
                          number: "${index + 1}",
                          isSelected: selectedIndex == index,
                          onTap: () => _onRingtoneTap(context, index),
                        );
                      }),
                    ),
                  ),

                  const Spacer(),

                  /// Bottom Navbar
                  // Padding(
                  //   padding: EdgeInsets.only(
                  //     bottom: AppDimensions.dim5.h,
                  //     right: AppDimensions.dim15.w,
                  //     left: AppDimensions.dim15.w,
                  //   ),
                  //   child: const AnimatedBottomNavBar(),
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
