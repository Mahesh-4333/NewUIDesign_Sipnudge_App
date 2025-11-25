import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'bottom_nav_state.dart';

class BottomNavCubit extends Cubit<BottomNavState> {
  BottomNavCubit() : super(const BottomNavState());

  void selectTab(BottomNavTab tab) {
    if (state.selectedTab != tab && !state.isLoading) {
      emit(state.copyWith(
        selectedTab: tab,
        previousTab: state.selectedTab,
      ));
    }
  }

  void selectTabByIndex(int index) {
    final tab = BottomNavTab.fromIndex(index);
    selectTab(tab);
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void goToPreviousTab() {
    if (state.hasPreviousTab) {
      final previousTab = state.previousTab!;
      emit(state.copyWith(
        selectedTab: previousTab,
        previousTab: null,
      ));
    }
  }

  void resetToHome() {
    if (state.selectedTab != BottomNavTab.home) {
      emit(state.copyWith(
        selectedTab: BottomNavTab.home,
        previousTab: state.selectedTab,
      ));
    }
  }

  bool isTabSelected(BottomNavTab tab) {
    return state.selectedTab == tab;
  }

  bool isIndexSelected(int index) {
    return state.selectedIndex == index;
  }

  List<BottomNavTab> get availableTabs => BottomNavTab.values;

  BottomNavTab get currentTab => state.selectedTab;
  int get currentIndex => state.selectedIndex;
  String get currentLabel => state.selectedLabel;
}
