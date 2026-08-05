part of 'bottom_nav_cubit.dart';

enum BottomNavTab {
  home(0, 'Home'),
  log(1, 'Log'),
  analysis(2, 'Insights'),
  reports(3, 'Goals'),
  settings(4, 'Settings');

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
    this.isVisible = true,
  });

  final BottomNavTab selectedTab;
  final bool isLoading;
  final BottomNavTab? previousTab;
  final bool isVisible;
  int get selectedIndex => selectedTab.index;
  String get selectedLabel => selectedTab.label;
  bool get hasPreviousTab => previousTab != null;

  BottomNavState copyWith({
    BottomNavTab? selectedTab,
    bool? isLoading,
    BottomNavTab? previousTab,
    bool? isVisible, // Add to copyWith
  }) {
    return BottomNavState(
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      previousTab: previousTab ?? this.previousTab,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object?> get props => [selectedTab, isLoading, previousTab, isVisible];

  @override
  String toString() {
    return 'BottomNavState('
        'selectedTab: $selectedTab, '
        'isLoading: $isLoading, '
        'previousTab: $previousTab'
        ')';
  }
}
