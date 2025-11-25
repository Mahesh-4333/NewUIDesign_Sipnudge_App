import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'filter_state.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit()
      : super(
          FilterState(
            currentInterval: FilterInterval.weekly,
            currentDate: DateTime.now(),
            selectedDate: DateTime.now(),
            lastSelectedDates: {
              FilterInterval.weekly: DateTime.now(),
              FilterInterval.monthly: DateTime.now(),
              FilterInterval.yearly: DateTime.now(),
            },
          ),
        );

  void setInterval(FilterInterval interval) {
    final now = DateTime.now();
    final lastSelectedDates =
        Map<FilterInterval, DateTime>.from(state.lastSelectedDates);
    lastSelectedDates[state.currentInterval] = state.currentDate;

    DateTime newDate = lastSelectedDates[interval]!;

    switch (interval) {
      case FilterInterval.yearly:
        newDate = DateTime(newDate.year > now.year ? now.year : newDate.year);
        break;
      case FilterInterval.monthly:
        newDate = state.currentInterval == FilterInterval.yearly
            ? DateTime(newDate.year, 1)
            : DateTime(newDate.year, newDate.month);

        final nowMonth = DateTime(now.year, now.month);
        if (newDate.isAfter(nowMonth)) {
          newDate = nowMonth;
        }
        break;
      case FilterInterval.weekly:
        if (state.currentInterval == FilterInterval.yearly) {
          newDate = DateTime(newDate.year, 1, 1);
        } else if (state.currentInterval == FilterInterval.monthly) {
          newDate = DateTime(newDate.year, newDate.month, 1);
        }

        final nowWeekStart = now.subtract(Duration(days: now.weekday % 7));
        final selectedWeekStart =
            newDate.subtract(Duration(days: newDate.weekday % 7));
        if (selectedWeekStart.isAfter(nowWeekStart)) {
          newDate = now;
        }
        break;
    }

    lastSelectedDates[interval] = newDate;

    emit(state.copyWith(
      currentInterval: interval,
      currentDate: newDate,
      lastSelectedDates: lastSelectedDates,
    ));
  }

  bool canNavigateForward() {
    final current = state.currentDate;
    if (state.currentInterval == FilterInterval.weekly) {
      final endOfThisWeek = DateTime.now();
      return current.isBefore(endOfThisWeek);
    } else {
      final now = DateTime.now();
      return current.year < now.year || current.month < now.month;
    }
  }

  bool canNavigateBackward() {
    return true;
  }

  void navigateDate(bool forward) {
    DateTime newDate;
    final now = DateTime.now();

    switch (state.currentInterval) {
      case FilterInterval.weekly:
        newDate = forward
            ? state.currentDate.add(Duration(days: 7))
            : state.currentDate.subtract(Duration(days: 7));
        final newWeekStart =
            newDate.subtract(Duration(days: newDate.weekday % 7));
        final nowWeekStart = now.subtract(Duration(days: now.weekday % 7));
        if (newWeekStart.isAfter(nowWeekStart)) return;
        break;

      case FilterInterval.monthly:
        newDate = DateTime(
            state.currentDate.year,
            forward
                ? state.currentDate.month + 1
                : state.currentDate.month - 1);
        if (newDate.isAfter(DateTime(now.year, now.month))) return;
        break;

      case FilterInterval.yearly:
        newDate = DateTime(
            forward ? state.currentDate.year + 1 : state.currentDate.year - 1);
        if (newDate.year > now.year) return;
        break;
    }

    final lastSelectedDates =
        Map<FilterInterval, DateTime>.from(state.lastSelectedDates);
    lastSelectedDates[state.currentInterval] = newDate;

    emit(state.copyWith(
        currentDate: newDate, lastSelectedDates: lastSelectedDates));
  }

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  void changeInterval(FilterInterval interval) {
    emit(state.copyWith(currentInterval: interval));
  }
}
