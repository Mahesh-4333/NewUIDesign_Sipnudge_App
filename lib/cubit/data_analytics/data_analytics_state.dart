part of 'data_analytics_cubit.dart';

class DataAnalyticsState {
  final bool isMonthlySelected;
  final bool isCalendarExpanded;
  final int selectedYear;
  final int?
      selectedMonth; // Nullable, as it might not be needed in yearly view

  const DataAnalyticsState({
    required this.isMonthlySelected,
    required this.isCalendarExpanded,
    required this.selectedYear,
    this.selectedMonth,
  });

  // The initial state definition
  factory DataAnalyticsState.initial() {
    final now = DateTime.now();
    return DataAnalyticsState(
      isMonthlySelected: true, // Defaulting to Monthly
      isCalendarExpanded: true, // Calendar open by default
      selectedYear: now.year,
      selectedMonth: now.month,
    );
  }

  // The magic of copyWith: update only what you need, keep the rest.
  DataAnalyticsState copyWith({
    bool? isMonthlySelected,
    bool? isCalendarExpanded,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return DataAnalyticsState(
      isMonthlySelected: isMonthlySelected ?? this.isMonthlySelected,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}
