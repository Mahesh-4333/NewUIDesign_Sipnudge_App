class CommonHelper {
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static String getMonthNameFromZeroIndex(int index) {
    if (index < 0 || index > 11) {
      return 'Invalid Month';
    }
    return _months[index];
  }
}
