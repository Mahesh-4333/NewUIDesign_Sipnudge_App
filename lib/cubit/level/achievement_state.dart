import 'package:equatable/equatable.dart';

class AchievementState {
  final int currentLevel;
  final int lastNotifiedLevel;
  final bool isLoading;
  final double waterGoalDaily;

  AchievementState({
    this.currentLevel = 0,
    this.lastNotifiedLevel = 0,
    this.isLoading = false,
    this.waterGoalDaily = 0.0,
  });

  AchievementState copyWith({
    int? currentLevel,
    int? lastNotifiedLevel,
    bool? isLoading,
    double? waterGoalDaily,
  }) {
    return AchievementState(
        currentLevel: currentLevel ?? this.currentLevel,
        lastNotifiedLevel: lastNotifiedLevel ?? this.lastNotifiedLevel,
        isLoading: isLoading ?? this.isLoading,
        waterGoalDaily: waterGoalDaily ?? this.waterGoalDaily);
  }
}
