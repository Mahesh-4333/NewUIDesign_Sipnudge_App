import 'package:equatable/equatable.dart';

class GoogleEvent extends Equatable {
  final String id;
  final String title;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;

  const GoogleEvent({
    required this.id,
    required this.title,
    this.location,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [id, title, location, startTime, endTime];
}
