import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/constants/app_enums.dart';

import 'reminder_state.dart';

class ReminderIntervalCubit extends Cubit<ReminderIntervalState> {
  ReminderIntervalCubit()
      : super(
          ReminderIntervalState(
            interval: ReminderInterval.hourly,
            slots: _generateSlots(ReminderInterval.hourly),
          ),
        );

  static Map<String, bool> _generateSlots(ReminderInterval i) {
    final map = <String, bool>{};
    final step = i.minutes;
    TimeOfDay t = const TimeOfDay(hour: 0, minute: 0);

    while (true) {
      final key = _key(t);
      map[key] = false;
      final next = t.hour * 60 + t.minute + step;
      if (next >= 24 * 60) break;
      t = _fromMinutes(next);
    }
    return map;
  }

  void setInterval(ReminderInterval interval) {
    final old = state.slots;
    final next = _generateSlots(interval);
    for (final k in next.keys) {
      if (old.containsKey(k)) next[k] = old[k]!;
    }
    emit(state.copyWith(interval: interval, slots: next));
  }

  void toggle(String key, bool value) {
    final copy = Map<String, bool>.from(state.slots)..[key] = value;
    emit(state.copyWith(slots: copy));
  }

  List<TimeOfDay> enabledTimes() {
    return state.slots.entries
        .where((e) => e.value)
        .map((e) => _parseKey(e.key))
        .toList();
  }

  // helpers
  static String _key(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _parseKey(String k) {
    final parts = k.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static TimeOfDay _fromMinutes(int total) =>
      TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
}
