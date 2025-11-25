part of 'bottle_data_cubit.dart';

class BottleDataState extends Equatable {
  final double volume;
  final int volumePercent;
  final int currentPage;
  final int battery;
  final List<BottleData> currentPageData;

  const BottleDataState({
    required this.volume,
    required this.volumePercent,
    required this.battery,
    required this.currentPage,
    required this.currentPageData,
  });

  factory BottleDataState.initial() {
    return BottleDataState(
      volume: 0.0,
      volumePercent: 0,
      battery: 0,
      currentPage: 0,
      currentPageData: [],
    );
  }

  BottleDataState copyWith({
    double? volume,
    int? volumePercent,
    int? currentPage,
    List<BottleData>? currentPageData,
    int? battery,
  }) {
    return BottleDataState(
      volume: volume ?? this.volume,
      volumePercent: volumePercent ?? this.volumePercent,
      currentPage: currentPage ?? this.currentPage,
      currentPageData: currentPageData ?? this.currentPageData,
      battery: battery ?? this.battery,
    );
  }

  @override
  List<Object?> get props =>
      [volume, volumePercent, currentPage, currentPageData, battery];
}
