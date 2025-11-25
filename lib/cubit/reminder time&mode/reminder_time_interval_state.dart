import 'package:equatable/equatable.dart';

abstract class TimeIntervalState extends Equatable {
  const TimeIntervalState();

  @override
  List<Object> get props => [];
}

class TimeIntervalInitial extends TimeIntervalState {
  final String interval;

  const TimeIntervalInitial(this.interval);

  @override
  List<Object> get props => [interval];
}

class TimeIntervalUpdated extends TimeIntervalState {
  final String interval;

  const TimeIntervalUpdated(this.interval);

  @override
  List<Object> get props => [interval];
}
