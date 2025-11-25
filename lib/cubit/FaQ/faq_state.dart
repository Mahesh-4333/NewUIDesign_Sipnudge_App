// import 'package:flutter/material.dart';

// class FaqState {
//   final String selectedCategory;
//   final Map<String, List<Map<String, String>>> faqData;
//   final Map<String, List<bool>> isExpandedMap;
//   final TextEditingController searchController;
//   final String activeTab;

//   FaqState({
//     required this.selectedCategory,
//     required this.faqData,
//     required this.isExpandedMap,
//     required this.searchController,
//     required this.activeTab,
//   });

//   FaqState copyWith({
//     String? selectedCategory,
//     Map<String, List<Map<String, String>>>? faqData,
//     Map<String, List<bool>>? isExpandedMap,
//     TextEditingController? searchController,
//     String? activeTab,
//   }) {
//     return FaqState(
//       selectedCategory: selectedCategory ?? this.selectedCategory,
//       faqData: faqData ?? this.faqData,
//       isExpandedMap: isExpandedMap ?? this.isExpandedMap,
//       searchController: searchController ?? this.searchController,
//       activeTab: activeTab ?? this.activeTab,
//     );
//   }
// }

//============================================================================

import 'package:equatable/equatable.dart';

class FaqState extends Equatable {
  final String selectedCategory;
  final Map<String, List<bool>> isExpandedMap;
  final String searchQuery;
  final List<String> filteredFAQs;

  const FaqState({
    this.selectedCategory = 'General',
    this.isExpandedMap = const {},
    this.searchQuery = '',
    this.filteredFAQs = const [],
  });

  FaqState copyWith({
    String? selectedCategory,
    Map<String, List<bool>>? isExpandedMap,
    String? searchQuery,
    List<String>? filteredFAQs,
  }) {
    return FaqState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isExpandedMap: isExpandedMap ?? this.isExpandedMap,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredFAQs: filteredFAQs ?? this.filteredFAQs,
    );
  }

  @override
  List<Object?> get props => [
        selectedCategory,
        isExpandedMap,
        searchQuery,
        filteredFAQs,
      ];
}
