import 'package:googleapis/digitalassetlinks/v1.dart';
import 'package:hydrify/constants/assets_path.dart';

class Ringtone {
  final int id;
  final String title;
  final String category;
  final String duration;
  final String assetPath;
  final String? subTitle;
  final String iconPath;
  final String iconPathUnselected;
  bool isFavourite;

  Ringtone({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.assetPath,
    this.subTitle,
    required this.iconPath,
    required this.iconPathUnselected,
    this.isFavourite = false,
  });
}

final List<Ringtone> mockRingtones = [
  Ringtone(
    id: 1,
    title: "Morning Dew",
    category: "Nature",
    duration: "0:15",
    assetPath: "ringtones/ringtone1.mp3",
    subTitle: "Nature",
    iconPath: AssetsPath.song,
    iconPathUnselected: AssetsPath.songUnselected,
  ),
  Ringtone(
    id: 3,
    title: "Crystal Clear",
    category: "Nature",
    duration: "0:12",
    assetPath: "ringtones/ringtone3.mp3",
    subTitle: "Nature",
    iconPath: AssetsPath.forest,
    iconPathUnselected: AssetsPath.forestUnselected,
  ),
  Ringtone(
    id: 4,
    title: "Ocean Mist",
    category: "Nature",
    duration: "0:12",
    assetPath: "ringtones/ringtone4.mp3",
    subTitle: "Nature",
    iconPath: AssetsPath.oceanMist,
    iconPathUnselected: AssetsPath.oceanMistUnselected,
  ),
  Ringtone(
    id: 5,
    title: "Breeze",
    category: "Nature",
    duration: "0:12",
    assetPath: "ringtones/ringtone5.mp3",
    subTitle: "Nature",
    iconPath: AssetsPath.forest,
    iconPathUnselected: AssetsPath.forestUnselected,
  ),
  Ringtone(
    id: 6,
    title: "Forest Stream",
    category: "Nature",
    duration: "0:12",
    assetPath: "ringtones/ringtone6.mp3",
    subTitle: "Nature",
    iconPath: AssetsPath.forest,
    iconPathUnselected: AssetsPath.forestUnselected,
  ),
  Ringtone(
    id: 7,
    title: "Midnight Forest",
    category: "Nature",
    duration: "0:12",
    assetPath: "ringtones/ringtone7.mp3",
    subTitle: "Nature",
    iconPath: AssetsPath.forest,
    iconPathUnselected: AssetsPath.forestUnselected,
  ),
  Ringtone(
    id: 8,
    title: "Crystal Clear",
    category: "Electronic",
    duration: "0:12",
    assetPath: "ringtones/ringtone8.mp3",
    subTitle: "High Pitch",
    iconPath: AssetsPath.dotcircle,
    iconPathUnselected: AssetsPath.dotcircleUnselected,
  ),
  Ringtone(
    id: 9,
    title: "Pulse Wave",
    category: "Electronic",
    duration: "0:12",
    assetPath: "ringtones/ringtone9.mp3",
    subTitle: "Rhythmic",
    iconPath: AssetsPath.phoneWave,
    iconPathUnselected: AssetsPath.phoneWaveUnselected,
  ),
];
