enum ReminderInterval {
  thirty(minutes: 30, label: 'Every 30 min'),
  hourly(minutes: 60, label: 'Every 1 hour'),
  twoHourly(minutes: 120, label: 'Every 2 hours');

  const ReminderInterval({required this.minutes, required this.label});
  final int minutes;
  final String label;
}
