part of 'bottom_nav_cubit.dart';

enum BottomNavTab {
  home(0, 'Home'),
  analysis(1, 'Analysis'),
  reports(2, 'Reports'),
  settings(3, 'Settings');

  const BottomNavTab(this.position, this.label);

  final int position;
  final String label;

  static BottomNavTab fromIndex(int index) {
    return BottomNavTab.values.firstWhere(
      (tab) => tab.index == index,
      orElse: () => BottomNavTab.home,
    );
  }
}

class BottomNavState extends Equatable {
  const BottomNavState({
    this.selectedTab = BottomNavTab.home,
    this.isLoading = false,
    this.previousTab,
  });

  final BottomNavTab selectedTab;
  final bool isLoading;
  final BottomNavTab? previousTab;
  int get selectedIndex => selectedTab.index;
  String get selectedLabel => selectedTab.label;
  bool get hasPreviousTab => previousTab != null;

  BottomNavState copyWith({
    BottomNavTab? selectedTab,
    bool? isLoading,
    BottomNavTab? previousTab,
  }) {
    return BottomNavState(
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      previousTab: previousTab ?? this.previousTab,
    );
  }

  @override
  List<Object?> get props => [selectedTab, isLoading, previousTab];

  @override
  String toString() {
    return 'BottomNavState('
        'selectedTab: $selectedTab, '
        'isLoading: $isLoading, '
        'previousTab: $previousTab'
        ')';
  }
}
