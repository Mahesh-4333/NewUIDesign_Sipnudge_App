import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

part 'data_analytics_state.dart';

class DataAnalyticsCubit extends Cubit<DataAnalyticsState> {
  final ApiService _apiService = ApiService();

  DataAnalyticsCubit() : super(DataAnalyticsState.initial()) {
    fetchAnalytics();
  }

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
    fetchAnalytics();
  }

  void toggleCalendar() {
    emit(state.copyWith(
      isCalendarExpanded: !state.isCalendarExpanded,
    ));
  }

  void selectMonth(int monthIndex) {
    emit(state.copyWith(selectedMonth: monthIndex + 1));
    fetchAnalytics();
  }

  void changeYear(int yearDelta) {
    final currentYear = DateTime.now().year;
    final newYear = state.selectedYear + yearDelta;

    if (newYear <= currentYear) {
      emit(state.copyWith(selectedYear: newYear));
      fetchAnalytics();
    }
  }

  Future<void> fetchAnalytics() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        emit(state.copyWith(isLoading: false, error: 'User not logged in'));
        return;
      }
      
      final data = await _apiService.getAnalytics(
        userId, 
        state.selectedYear, 
        month: state.isMonthlySelected ? state.selectedMonth : null
      );
      
      emit(state.copyWith(isLoading: false, analyticsData: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
