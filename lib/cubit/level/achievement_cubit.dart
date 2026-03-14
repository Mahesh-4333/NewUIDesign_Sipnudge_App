import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import '../../helpers/database_helper.dart';
import 'achievement_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementCubit extends Cubit<AchievementState> {
  final DatabaseHelper dbHelper;

  AchievementCubit(this.dbHelper,
      {int initialLevel = 0, double initialGoal = 0.0})
      : super(AchievementState(
          currentLevel: initialLevel,
          lastNotifiedLevel: initialLevel,
          waterGoalDaily: initialGoal,
        ));

  Future<void> init() async {
    final cachedLevel = await SharedPrefsHelper.getLastLevelUpDate() ?? 0;

    final goal = await SharedPrefsHelper.getUserGoal() ?? 0;

    Fluttertoast.showToast(msg: "${cachedLevel} ");

    emit(state.copyWith(
      currentLevel: cachedLevel,
      lastNotifiedLevel: cachedLevel,
      waterGoalDaily: goal.toDouble(),
      isLoading: false,
    ));
  }

  Future<void> syncAndCalculate() async {
    emit(state.copyWith(isLoading: true));

    try {
      final goal = await SharedPrefsHelper.getUserGoal() ?? 0;

      final allDays = await dbHelper.getHydrationSummariesForRange();

      final perfectDaysCount = allDays.where((day) {
        return day.consumed >= goal.toDouble() && goal.toDouble() > 0;
      }).length;

      await SharedPrefsHelper.setLastLevelUpDate(perfectDaysCount);

      emit(state.copyWith(
        currentLevel: perfectDaysCount,
        waterGoalDaily: goal.toDouble(),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void markLevelAsNotified() {
    emit(state.copyWith(lastNotifiedLevel: state.currentLevel));
  }
}
