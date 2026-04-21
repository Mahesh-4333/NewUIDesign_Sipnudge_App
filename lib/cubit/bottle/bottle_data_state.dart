part of 'bottle_data_cubit.dart';

class BottleDataState extends Equatable {
  final double volume;
  final int volumePercent;
  final int currentPage;
  final int battery;
  final int refills;
  final List<BottleData> currentPageData;
  final DateTime? lastRefreshed;

  const BottleDataState({
    required this.volume,
    required this.volumePercent,
    required this.battery,
    required this.refills,
    required this.currentPage,
    required this.currentPageData,
    this.lastRefreshed,
  });

  factory BottleDataState.initial() {
    return BottleDataState(
      volume: 0.0,
      volumePercent: 0,
      battery: 0,
      refills: 0,
      currentPage: 0,
      currentPageData: [],
      lastRefreshed: null,
    );
  }

  BottleDataState copyWith({
    double? volume,
    int? volumePercent,
    int? currentPage,
    List<BottleData>? currentPageData,
    int? battery,
    int? refills,
    DateTime? lastRefreshed,
  }) {
    return BottleDataState(
      volume: volume ?? this.volume,
      volumePercent: volumePercent ?? this.volumePercent,
      currentPage: currentPage ?? this.currentPage,
      currentPageData: currentPageData ?? this.currentPageData,
      battery: battery ?? this.battery,
      refills: refills ?? this.refills,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }

  @override
  List<Object?> get props =>
      [volume, volumePercent, currentPage, currentPageData, battery, refills, lastRefreshed];
}
