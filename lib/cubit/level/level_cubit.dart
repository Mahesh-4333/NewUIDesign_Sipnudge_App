import 'package:flutter_bloc/flutter_bloc.dart';
import 'level_state.dart';

class LevelCubit extends Cubit<LevelState> {
  LevelCubit() : super(LevelState.initial());

  void updateLevel(int level) {
    emit(state.copyWith(currentLevel: level));
  }

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }
}
