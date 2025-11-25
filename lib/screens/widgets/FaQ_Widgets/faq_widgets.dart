// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:hydrify/constants/app_dimensions.dart';
// import 'package:hydrify/constants/app_font_styles.dart';
// import 'package:hydrify/constants/app_strings.dart';

// /// Search Bar
// class SearchBarWidget extends StatelessWidget {
//   final TextEditingController controller;
//   final ValueChanged<String> onChanged;

//   const SearchBarWidget({
//     super.key,
//     required this.controller,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(AppDimensions.dim8),
//       child: TextField(
//         controller: controller,
//         onChanged: onChanged,
//         decoration: InputDecoration(
//           hintText: AppStrings.searchquestions,
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(AppDimensions.radius_12.r),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Category Chips
// class CategoryChipsWidget extends StatelessWidget {
//   final List<String> categories;
//   final String selectedCategory;
//   final ValueChanged<String> onCategorySelected;

//   const CategoryChipsWidget({
//     super.key,
//     required this.categories,
//     required this.selectedCategory,
//     required this.onCategorySelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: AppDimensions.dim50.h,
//       child: ListView.separated(
//         padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim8.w),
//         scrollDirection: Axis.horizontal,
//         itemCount: categories.length,
//         separatorBuilder: (_, __) => SizedBox(width: AppDimensions.dim6.w),
//         itemBuilder: (context, index) {
//           final category = categories[index];
//           final isSelected = category == selectedCategory;

//           return ChoiceChip(
//             label: Text(category),
//             selected: isSelected,
//             onSelected: (_) => onCategorySelected(category),
//           );
//         },
//       ),
//     );
//   }
// }

// /// FAQ List
// class FaqListWidget extends StatelessWidget {
//   final List<Map<String, String>> faqs;
//   final List<bool> isExpandedList;
//   final Function(int) onToggleExpansion;

//   const FaqListWidget({
//     super.key,
//     required this.faqs,
//     required this.isExpandedList,
//     required this.onToggleExpansion,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(AppDimensions.dim8),
//       itemCount: faqs.length,
//       itemBuilder: (context, index) {
//         final faq = faqs[index];
//         final isExpanded = isExpandedList[index];

//         return Card(
//           margin: EdgeInsets.symmetric(vertical: AppDimensions.dim6.h),
//           child: ExpansionTile(
//             title: Text(
//               faq[AppStrings.question]!,
//               style: TextStyle(
//                 fontVariations: [
//                   FontVariation('wght', AppFontStyles.boldFontVariation.value),
//                 ],
//               ),
//             ),
//             initiallyExpanded: isExpanded,
//             onExpansionChanged: (_) => onToggleExpansion(index),
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(AppDimensions.dim12),
//                 child: Text(faq[AppStrings.answer]!),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// /// Bottom Nav
// class CustomBottomNavBar extends StatelessWidget {
//   final String activeTab;
//   final ValueChanged<String> onTabSelected;

//   const CustomBottomNavBar({
//     super.key,
//     required this.activeTab,
//     required this.onTabSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final tabs = [AppStrings.home, AppStrings.faq, AppStrings.setting];

//     return SizedBox.shrink();

//     // return BottomNavigationBar(
//     //   currentIndex: tabs.indexOf(activeTab),
//     //   items: const [
//     //     BottomNavigationBarItem(icon: Icon(Icons.home), label: AppStrings.home),
//     //     BottomNavigationBarItem(icon: Icon(Icons.help), label: AppStrings.faq),
//     //     BottomNavigationBarItem(
//     //       icon: Icon(Icons.settings),
//     //       label: AppStrings.setting,
//     //     ),
//     //   ],
//     //   onTap: (index) => onTabSelected(tabs[index]),
//     // );
//   }
// }

//===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';

/// Search Bar
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.dim8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: AppStrings.searchquestions,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius_12.r),
          ),
        ),
      ),
    );
  }
}

/// Category Chips
class CategoryChipsWidget extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChipsWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.dim50.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim8.w),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: AppDimensions.dim6.w),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

/// FAQ List
class FaqListWidget extends StatelessWidget {
  final List<Map<String, String>> faqs;
  final List<bool> isExpandedList;
  final Function(int) onToggleExpansion;

  const FaqListWidget({
    super.key,
    required this.faqs,
    required this.isExpandedList,
    required this.onToggleExpansion,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.dim8),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        final isExpanded = isExpandedList[index];

        return Card(
          margin: EdgeInsets.symmetric(vertical: AppDimensions.dim6.h),
          child: ExpansionTile(
            title: Text(
              faq[AppStrings.question]!,
              style: TextStyle(
                fontVariations: [
                  FontVariation('wght', AppFontStyles.boldFontVariation.value),
                ],
              ),
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (_) => onToggleExpansion(index),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.dim12),
                child: Text(faq[AppStrings.answer]!),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom Nav
// class CustomBottomNavBar extends StatelessWidget {
//   final String activeTab;
//   final ValueChanged<String> onTabSelected;

//   const CustomBottomNavBar({
//     super.key,
//     required this.activeTab,
//     required this.onTabSelected,
//   });

@override
Widget build(BuildContext context) {
  //final tabs = [AppStrings.home, AppStrings.faq, AppStrings.setting];

  return SizedBox.shrink();

  // return BottomNavigationBar(
  //   currentIndex: tabs.indexOf(activeTab),
  //   items: const [
  //     BottomNavigationBarItem(icon: Icon(Icons.home), label: AppStrings.home),
  //     BottomNavigationBarItem(icon: Icon(Icons.help), label: AppStrings.faq),
  //     BottomNavigationBarItem(
  //       icon: Icon(Icons.settings),
  //       label: AppStrings.setting,
  //     ),
  //   ],
  //   onTap: (index) => onTabSelected(tabs[index]),
  // );
}
// }
