part of 'filter_cubit.dart';

enum FilterInterval { weekly, monthly, yearly }

class FilterState extends Equatable {
  final FilterInterval currentInterval;
  final DateTime currentDate;
  final DateTime selectedDate;
  final Map<FilterInterval, DateTime> lastSelectedDates;

  const FilterState({
    required this.currentInterval,
    required this.currentDate,
    required this.selectedDate,
    required this.lastSelectedDates,
  });

  bool get canNavigateForward {
    final now = DateTime.now();

    switch (currentInterval) {
      case FilterInterval.weekly:
        final currentWeekStart =
            currentDate.subtract(Duration(days: currentDate.weekday % 7));
        final nowWeekStart = now.subtract(Duration(days: now.weekday % 7));
        return currentWeekStart.isBefore(nowWeekStart);
      case FilterInterval.monthly:
        return DateTime(currentDate.year, currentDate.month)
            .isBefore(DateTime(now.year, now.month));
      case FilterInterval.yearly:
        return currentDate.year < now.year;
    }
  }

  String getFormattedDateRange() {
    switch (currentInterval) {
      case FilterInterval.weekly:
        final startOfWeek =
            currentDate.subtract(Duration(days: currentDate.weekday % 7));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}, ${startOfWeek.year}';
      case FilterInterval.monthly:
        return '${_getMonthName(currentDate.month)}, ${currentDate.year}';
      case FilterInterval.yearly:
        return '${currentDate.year}';
    }
  }

  String _formatDate(DateTime date) =>
      '${_getMonthName(date.month)} ${date.day}';

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  FilterState copyWith({
    FilterInterval? currentInterval,
    DateTime? currentDate,
    DateTime? selectedDate,
    Map<FilterInterval, DateTime>? lastSelectedDates,
  }) {
    return FilterState(
      currentInterval: currentInterval ?? this.currentInterval,
      currentDate: currentDate ?? this.currentDate,
      selectedDate: selectedDate ?? this.selectedDate,
      lastSelectedDates: lastSelectedDates ?? this.lastSelectedDates,
    );
  }

  @override
  List<Object?> get props =>
      [currentInterval, currentDate, selectedDate, lastSelectedDates];
}
