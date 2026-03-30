import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/Preferences/preferences_cubit.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:hydrify/helpers/vibration_helper.dart';
import 'package:hydrify/models/ringtone_model.dart';
import 'package:hydrify/screens/widgets/ringtone_screen_widget/category_header.dart';
import 'package:hydrify/screens/widgets/ringtone_screen_widget/ringtone_list_item.dart';
import 'package:hydrify/screens/widgets/ringtone_screen_widget/top_pick_card.dart';

class RingtoneScreen extends StatefulWidget {
  const RingtoneScreen({super.key});

  @override
  State<RingtoneScreen> createState() => _RingtoneScreenState();
}

class _RingtoneScreenState extends State<RingtoneScreen> {
  int selectedIndex = 0;
  int? playingIndex;
  Set<int> favoriteIds = {};
  late final AudioPlayer _audioPlayer;

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

  Future<void> _loadSavedRingtone() async {
    final saved = await SharedPrefsHelper.getSelectedRingtone();
    final favorites = await SharedPrefsHelper.getFavoriteRingtones();
    if (mounted) {
      setState(() {
        if (saved != null) selectedIndex = saved;
        favoriteIds = favorites.toSet();
      });
    }
  }

  Future<void> _onFavoriteTap(int id) async {
    setState(() {
      if (favoriteIds.contains(id)) {
        favoriteIds.remove(id);
      } else {
        favoriteIds.add(id);
      }
    });
    await SharedPrefsHelper.setFavoriteRingtones(favoriteIds.toList());
  }

  Future<void> _onRingtoneTap(int index) async {
    Console.log(tag: "_onRingtoneTap", value: index.toString());
    setState(() => selectedIndex = index);
    await _onPlayTap(index);
  }

  Future<void> _onPlayTap(int index) async {
    if (playingIndex == index) {
      await _audioPlayer.stop();
      setState(() => playingIndex = null);
      return;
    }

    setState(() => playingIndex = index);

    final state = context.read<PreferencesCubit>().state;
    if (state.ringtoneFeedback) {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);

      final assetPath =
          mockRingtones.firstWhere((r) => r.id == index).assetPath;
      await _audioPlayer.play(AssetSource(assetPath));

      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() => playingIndex = null);
        }
      });
    } else {
      await VibrationHelper.vibrate();
      setState(() => playingIndex = null);
    }
  }

  Future<void> _saveChanges() async {
    Console.log(tag: "ringtoneIndex", value: selectedIndex.toString());
    await SharedPrefsHelper.setSelectedRingtone(selectedIndex);

    // Reschedule all notifications so they use the newly selected ringtone.
    // The sound is baked into the notification at schedule time (Android uses
    // it as part of the channel ID), so we must cancel and re-schedule.
    final slots = await DatabaseHelper().getAllSlots();
    if (slots.isNotEmpty) {
      await NotificationService().resetAllHydrationReminders(slots);
      await NotificationService().scheduleHydrationRemindersForFuture(slots);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ringtone saved successfully!")),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildTopPick(int index) {
    final ringtone = mockRingtones.firstWhere((r) => r.id == index);
    return TopPickCard(
      title: ringtone.title,
      subTitle: ringtone.subTitle ?? "",
      duration: ringtone.duration,
      iconPath: selectedIndex == ringtone.id
          ? ringtone.iconPath
          : ringtone.iconPathUnselected,
      isSelected: selectedIndex == ringtone.id,
      isPlaying: playingIndex == ringtone.id,
      isFavorite: favoriteIds.contains(ringtone.id),
      onTap: () => _onRingtoneTap(ringtone.id),
      onPlayTap: () => _onPlayTap(ringtone.id),
      onFavoriteTap: () => _onFavoriteTap(ringtone.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            scrolledUnderElevation: 0.0,
            forceMaterialTransparency: true,
            elevation: 0.0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              "Select Ringtone",
              style: TextStyle(
                  color: AppColors.bluegray,
                  fontSize: AppFontStyles.fontSize_AppBar,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.boldFontVariation]),
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: SvgPicture.asset("assets/images/back_ic.svg"),
            ),
          ),
          body: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/app_background.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 35.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryHeader(
                          title: "Top Picks",
                          actionText: "",
                          titleSize: 17.sp,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTopPick(1),
                            SizedBox(width: 16.w),
                            _buildTopPick(3),
                          ],
                        ),
                        CategoryHeader(
                          title: "NATURE",
                          actionText: "",
                          titleSize: 13.sp,
                          color: AppColors.greyColorText1,
                        ),
                        ...mockRingtones
                            .where((r) =>
                                r.category == "Nature" &&
                                r.id != 1 &&
                                r.id != 3)
                            .map((ringtone) => RingtoneListItem(
                                  title: ringtone.title,
                                  subTitle: ringtone.subTitle ?? "",
                                  duration: ringtone.duration,
                                  iconPath: selectedIndex == ringtone.id
                                      ? ringtone.iconPath
                                      : ringtone.iconPathUnselected,
                                  isSelected: selectedIndex == ringtone.id,
                                  isPlaying: playingIndex == ringtone.id,
                                  isFavorite: favoriteIds.contains(ringtone.id),
                                  onTap: () => _onRingtoneTap(ringtone.id),
                                  onPlayTap: () => _onPlayTap(ringtone.id),
                                  onFavoriteTap: () =>
                                      _onFavoriteTap(ringtone.id),
                                )),
                        const CategoryHeader(
                          title: "ELECTRONIC",
                          actionText: "",
                        ),
                        ...mockRingtones
                            .where((r) => r.category == "Electronic")
                            .map((ringtone) => RingtoneListItem(
                                  title: ringtone.title,
                                  subTitle: ringtone.subTitle ?? "",
                                  duration: ringtone.duration,
                                  iconPath: selectedIndex == ringtone.id
                                      ? ringtone.iconPath
                                      : ringtone.iconPathUnselected,
                                  isSelected: selectedIndex == ringtone.id,
                                  isPlaying: playingIndex == ringtone.id,
                                  isFavorite: favoriteIds.contains(ringtone.id),
                                  onTap: () => _onRingtoneTap(ringtone.id),
                                  onPlayTap: () => _onPlayTap(ringtone.id),
                                  onFavoriteTap: () =>
                                      _onFavoriteTap(ringtone.id),
                                )),
                        SizedBox(height: 100.h), // Space for button
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20.h,
                    left: 80.w,
                    right: 80.w,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff3B82F6),
                        minimumSize: Size(double.infinity, 56.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Save Changes",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ]),
                          ),
                          SizedBox(width: 8.w),
                          const Icon(Icons.check_circle, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
