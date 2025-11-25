import 'package:equatable/equatable.dart';

class LevelState extends Equatable {
  final int currentLevel;
  final String title;

  const LevelState({required this.currentLevel, required this.title});

  factory LevelState.initial() {
    return const LevelState(currentLevel: 1, title: "Home");
  }

  LevelState copyWith({int? currentLevel, String? title}) {
    return LevelState(
      currentLevel: currentLevel ?? this.currentLevel,
      title: title ?? this.title,
    );
  }

  @override
  List<Object?> get props => [currentLevel, title];
}
