// import 'package:flutter/material.dart';

// enum FilterInterval { weekly, monthly, yearly }

// class FilterProvider extends ChangeNotifier {
//   FilterInterval _currentInterval = FilterInterval.weekly;
//   DateTime _currentDate = DateTime.now();
//   DateTime _selectedDate = DateTime.now();

//   final Map<FilterInterval, DateTime> _lastSelectedDates = {
//     FilterInterval.weekly: DateTime.now(),
//     FilterInterval.monthly: DateTime.now(),
//     FilterInterval.yearly: DateTime.now(),
//   };

//   FilterInterval get currentInterval => _currentInterval;
//   DateTime get currentDate => _currentDate;
//   DateTime get selectedDate => _selectedDate;

//   bool canNavigateForward() {
//     final now = DateTime.now();

//     switch (_currentInterval) {
//       case FilterInterval.weekly:
//         final currentWeekStart = _currentDate.subtract(
//           Duration(days: _currentDate.weekday % 7),
//         );
//         final nowWeekStart = now.subtract(
//           Duration(days: now.weekday % 7),
//         );
//         return currentWeekStart.isBefore(nowWeekStart);

//       case FilterInterval.monthly:
//         final currentMonth = DateTime(_currentDate.year, _currentDate.month);
//         final nowMonth = DateTime(now.year, now.month);
//         return currentMonth.isBefore(nowMonth);

//       case FilterInterval.yearly:
//         return _currentDate.year < now.year;
//     }
//   }

//   void setInterval(FilterInterval interval) {
//     _lastSelectedDates[_currentInterval] = _currentDate;

//     DateTime newDate = _lastSelectedDates[interval]!;
//     final now = DateTime.now();

//     switch (interval) {
//       case FilterInterval.yearly:
//         _currentDate = DateTime(newDate.year);
//         if (_currentDate.year > now.year) {
//           _currentDate = DateTime(now.year);
//         }
//         break;

//       case FilterInterval.monthly:
//         if (_currentInterval == FilterInterval.yearly) {
//           _currentDate = DateTime(newDate.year, 1);
//         } else {
//           _currentDate = DateTime(newDate.year, newDate.month);
//         }

//         final currentMonth = DateTime(now.year, now.month);
//         if (_currentDate.isAfter(currentMonth)) {
//           _currentDate = DateTime(now.year, now.month);
//         }
//         break;

//       case FilterInterval.weekly:
//         if (_currentInterval == FilterInterval.yearly) {
//           _currentDate = DateTime(newDate.year, 1, 1);
//         } else if (_currentInterval == FilterInterval.monthly) {
//           _currentDate = DateTime(newDate.year, newDate.month, 1);
//         } else {
//           _currentDate = newDate;
//         }
//         // Ensure we don't exceed current week
//         final nowWeekStart = now.subtract(
//           Duration(days: now.weekday % 7),
//         );
//         final selectedWeekStart = _currentDate.subtract(
//           Duration(days: _currentDate.weekday % 7),
//         );
//         if (selectedWeekStart.isAfter(nowWeekStart)) {
//           _currentDate = now;
//         }
//         break;
//     }

//     _currentInterval = interval;
//     _lastSelectedDates[interval] = _currentDate;
//     notifyListeners();
//   }

//   void navigateDate(bool forward) {
//     DateTime newDate;
//     final now = DateTime.now();

//     switch (_currentInterval) {
//       case FilterInterval.weekly:
//         newDate = forward
//             ? _currentDate.add(const Duration(days: 7))
//             : _currentDate.subtract(const Duration(days: 7));
//         final newWeekStart = newDate.subtract(
//           Duration(days: newDate.weekday % 7),
//         );
//         final nowWeekStart = now.subtract(
//           Duration(days: now.weekday % 7),
//         );
//         if (newWeekStart.isAfter(nowWeekStart)) {
//           return;
//         }
//         break;

//       case FilterInterval.monthly:
//         newDate = DateTime(
//           _currentDate.year,
//           forward ? _currentDate.month + 1 : _currentDate.month - 1,
//         );

//         final currentMonth = DateTime(now.year, now.month);
//         if (newDate.isAfter(currentMonth)) {
//           return;
//         }
//         break;

//       case FilterInterval.yearly:
//         newDate = DateTime(
//           forward ? _currentDate.year + 1 : _currentDate.year - 1,
//         );

//         if (newDate.year > now.year) {
//           return;
//         }
//         break;
//     }

//     _currentDate = newDate;
//     _lastSelectedDates[_currentInterval] = newDate;
//     notifyListeners();
//   }

//   String getFormattedDateRange() {
//     switch (_currentInterval) {
//       case FilterInterval.weekly:
//         DateTime startOfWeek = _currentDate.subtract(
//           Duration(days: _currentDate.weekday % 7),
//         );
//         DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

//         return '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}, ${startOfWeek.year}';

//       case FilterInterval.monthly:
//         return '${_getMonthName(_currentDate.month)}, ${_currentDate.year}';

//       case FilterInterval.yearly:
//         return '${_currentDate.year}';
//     }
//   }

//   void selectDate(DateTime date) {
//     _selectedDate = date;
//     notifyListeners();
//   }

//   String _formatDate(DateTime date) {
//     return '${_getMonthName(date.month)} ${date.day}';
//   }

//   String _getMonthName(int month) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     return months[month - 1];
//   }
// }
