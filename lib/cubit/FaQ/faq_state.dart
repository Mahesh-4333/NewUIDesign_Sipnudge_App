// faq_state.dart
import 'package:equatable/equatable.dart';

class FaqState extends Equatable {
  final String selectedCategory;
  final Map<String, List<bool>> isExpandedMap;
  final String searchQuery;
  final List<Map<String, String>> filteredFaqs; // 👈 change type

  const FaqState({
    this.selectedCategory = 'General',
    this.isExpandedMap = const {},
    this.searchQuery = '',
    this.filteredFaqs = const [],
  });

  FaqState copyWith({
    String? selectedCategory,
    Map<String, List<bool>>? isExpandedMap,
    String? searchQuery,
    List<Map<String, String>>? filteredFaqs,
  }) {
    return FaqState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isExpandedMap: isExpandedMap ?? this.isExpandedMap,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredFaqs: filteredFaqs ?? this.filteredFaqs,
    );
  }

  @override
  List<Object?> get props => [
        selectedCategory,
        isExpandedMap,
        searchQuery,
        filteredFaqs,
      ];
}
