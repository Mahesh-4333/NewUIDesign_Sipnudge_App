part of 'user_info_cubit.dart';

enum Gender { male, female, preferNotToSay }

enum ActivityLevel { sedentary, lightActivity, midActive, veryActive }

enum DietType { balanced, vegetarian, processed, highProtein }

class UserInfoState extends Equatable {
  final Gender? gender;
  final double? height;
  final String? heightUnit; // "cm" or "ft"
  final double? weight;
  final String? weightUnit; // "kg" or "lbs"
  final int? age;

  final int? wakeupHour;
  final int? wakeupMinute;
  final String? wakeupPeriod; // "AM" or "PM"

  final int? bedtimeHour;
  final int? bedtimeMinute;
  final String? bedtimePeriod; // "AM" or "PM"

  final ActivityLevel? activityLevel;
  final DietType? dietType;

  const UserInfoState({
    this.gender = Gender.male,
    this.height,
    this.heightUnit,
    this.weight,
    this.weightUnit,
    this.age,
    this.wakeupHour,
    this.wakeupMinute,
    this.wakeupPeriod,
    this.bedtimeHour,
    this.bedtimeMinute,
    this.bedtimePeriod,
    this.activityLevel = ActivityLevel.lightActivity,
    this.dietType = DietType.balanced,
  });

  UserInfoState copyWith({
    Gender? gender,
    double? height,
    String? heightUnit,
    double? weight,
    String? weightUnit,
    int? age,
    int? wakeupHour,
    int? wakeupMinute,
    String? wakeupPeriod,
    int? bedtimeHour,
    int? bedtimeMinute,
    String? bedtimePeriod,
    ActivityLevel? activityLevel,
    DietType? dietType,
  }) {
    return UserInfoState(
      gender: gender ?? this.gender,
      height: height ?? this.height,
      heightUnit: heightUnit ?? this.heightUnit,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      age: age ?? this.age,
      wakeupHour: wakeupHour ?? this.wakeupHour,
      wakeupMinute: wakeupMinute ?? this.wakeupMinute,
      wakeupPeriod: wakeupPeriod ?? this.wakeupPeriod,
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
      bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
      bedtimePeriod: bedtimePeriod ?? this.bedtimePeriod,
      activityLevel: activityLevel ?? this.activityLevel,
      dietType: dietType ?? this.dietType,
    );
  }

  @override
  List<Object?> get props => [
        gender,
        height,
        heightUnit,
        weight,
        weightUnit,
        age,
        wakeupHour,
        wakeupMinute,
        wakeupPeriod,
        bedtimeHour,
        bedtimeMinute,
        bedtimePeriod,
        activityLevel,
        dietType,
      ];
}

extension HeightConversion on UserInfoState {
  String get displayHeight {
    if (height == null) return "";

    if (heightUnit == "cm") {
      return "${height!.toStringAsFixed(0)} cm";
    } else if (heightUnit == "ft") {
      final totalInches = (height! / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet' $inches\"";
    }
    return "";
  }
}

extension WeightConversion on UserInfoState {
  String get displayWeight {
    if (weight == null) return "";

    if (weightUnit == "kg") {
      return "${weight!.toStringAsFixed(0)} kg";
    } else if (weightUnit == "lbs") {
      final lbs = weight! / 0.453592;
      return "${lbs.toStringAsFixed(0)} lbs";
    }
    return "";
  }
}
