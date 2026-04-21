import 'package:equatable/equatable.dart';
import 'package:hydrify/models/google_event.dart';
import 'package:hydrify/models/hydration_entry.dart';

class ScheduleTimelineItem extends Equatable {
  final HydrationEntry entry;
  final List<GoogleEvent> overlappingEvents;

  const ScheduleTimelineItem({
    required this.entry,
    required this.overlappingEvents,
  });

  @override
  List<Object?> get props => [entry, overlappingEvents];
}
