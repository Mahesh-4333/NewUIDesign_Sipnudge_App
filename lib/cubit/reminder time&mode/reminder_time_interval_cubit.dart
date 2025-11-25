import 'package:bloc/bloc.dart';
import 'package:hydrify/cubit/reminder%20time&mode/reminder_time_interval_state.dart';

class TimeIntervalCubit extends Cubit<TimeIntervalState> {
  TimeIntervalCubit() : super(TimeIntervalInitial('30 Minutes'));

  void updateInterval() {
    if (state is TimeIntervalInitial || state is TimeIntervalUpdated) {
      String currentInterval = (state is TimeIntervalInitial)
          ? (state as TimeIntervalInitial).interval
          : (state as TimeIntervalUpdated).interval;

      String nextInterval;

      if (currentInterval == '30 Minutes') {
        nextInterval = '1 Hour';
      } else if (currentInterval == '1 Hour') {
        nextInterval = '2 Hours';
      } else {
        nextInterval = '30 Minutes';
      }

      emit(TimeIntervalUpdated(nextInterval));
    }
  }
}
