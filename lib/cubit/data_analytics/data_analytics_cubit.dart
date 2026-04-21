import 'package:flutter_bloc/flutter_bloc.dart';

part 'data_analytics_state.dart';

class DataAnalyticsCubit extends Cubit<DataAnalyticsState> {
  DataAnalyticsCubit() : super(DataAnalyticsState.initial());

  // 1 & 3: Toggle Monthly/Yearly and handle Calendar collapse
  void toggleAnalyticsMode({required bool isMonthly}) {
    if (state.isMonthlySelected == isMonthly) return; // No change needed

    if (!isMonthly) {
      // Switching to Yearly: Collapse calendar automatically
      emit(state.copyWith(
        isMonthlySelected: false,
        isCalendarExpanded: false,
      ));
    } else {
      emit(state.copyWith(
        isMonthlySelected: true,
        isCalendarExpanded: true,
      ));
    }
  }

  void toggleCalendar() {
    emit(state.copyWith(
      isCalendarExpanded: !state.isCalendarExpanded,
    ));
  }

  void selectMonth(int monthIndex) {
    emit(state.copyWith(selectedMonth: monthIndex));
  }

  void changeYear(int yearDelta) {
    final currentYear = DateTime.now().year;
    final newYear = state.selectedYear + yearDelta;

    if (newYear <= currentYear) {
      emit(state.copyWith(selectedYear: newYear));
    }
  }
}
