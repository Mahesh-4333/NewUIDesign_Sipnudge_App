part of 'calendar_cubit.dart';

enum CalendarStatus { initial, loading, loaded, error }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final DateTime selectedDate;
  final DateTime displayedMonth;
  final List<ScheduleTimelineItem> dailySchedule;

  // 1. ADD THIS NEW PROPERTY
  final List<GoogleEvent> selectedDayEvents;

  final bool isSyncing;
  final String? errorMessage;
  final Set<HydrationSlot> unsilencedSlots;

  const CalendarState({
    this.status = CalendarStatus.initial,
    required this.selectedDate,
    required this.displayedMonth,
    this.dailySchedule = const [],

    // 2. ADD TO CONSTRUCTOR (Default to empty list)
    this.selectedDayEvents = const [],
    this.isSyncing = false,
    this.errorMessage,
    this.unsilencedSlots = const {},
  });

  CalendarState copyWith({
    CalendarStatus? status,
    DateTime? selectedDate,
    DateTime? displayedMonthNYear,
    List<ScheduleTimelineItem>? dailySchedule,

    // 3. ADD TO COPYWITH
    List<GoogleEvent>? selectedDayEvents,
    bool? isSyncing,
    String? errorMessage,
    Set<HydrationSlot>? unsilencedSlots,
  }) {
    return CalendarState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      displayedMonth: displayedMonthNYear ?? this.displayedMonth,
      dailySchedule: dailySchedule ?? this.dailySchedule,

      // 4. MAP TO COPYWITH
      selectedDayEvents: selectedDayEvents ?? this.selectedDayEvents,

      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
      unsilencedSlots: unsilencedSlots ?? this.unsilencedSlots,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedDate,
        displayedMonth,
        dailySchedule,
        selectedDayEvents, // 5. ADD TO PROPS FOR EQUATABLE
        isSyncing,
        errorMessage,
        unsilencedSlots,
      ];
}
