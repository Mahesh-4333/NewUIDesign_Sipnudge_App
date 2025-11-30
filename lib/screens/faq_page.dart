import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/FaQ/faq_cubit.dart';
import 'package:hydrify/cubit/FaQ/faq_state.dart';

class FAQ_Page extends StatefulWidget {
  const FAQ_Page({super.key});

  @override
  State<FAQ_Page> createState() => _FAQ_PageState();
}

class _FAQ_PageState extends State<FAQ_Page> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => FaqCubit(), child: const _FAQPageView());
  }
}

class _FAQPageView extends StatelessWidget {
  const _FAQPageView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FaqCubit>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          AppStrings.faq,
          style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_AppBar,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                AppFontStyles.boldFontVariation,
              ]),
        ),
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            "assets/images/back_ic.svg",
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/app_background.png"), // your image path
            fit: BoxFit.cover,
          ),
          // gradient: LinearGradient(
          //   colors: [AppColors.gradientStart, AppColors.gradientEnd],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.dim20.h),
                    child: Column(
                      children: [
                        /// Header
                        // _buildHeader(context),

                        SizedBox(height: AppDimensions.dim24.h),

                        /// Search Box
                        _buildSearchBox(cubit),

                        SizedBox(height: AppDimensions.dim24.h),

                        /// Category Selector
                        _buildCategorySelector(context),

                        SizedBox(height: AppDimensions.dim24.h),

                        /// FAQ Items
                        BlocBuilder<FaqCubit, FaqState>(
                          builder: (context, state) {
                            final selectedCategory = state.selectedCategory;

                            // 🔎 If searching → show only results for selected category
                            if (state.searchQuery.isNotEmpty) {
                              final resultsForCategory = state.filteredFaqs
                                  .where((item) =>
                                      item['category'] == selectedCategory)
                                  .toList();

                              if (resultsForCategory.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: AppDimensions.dim24.w),
                                  child: Text(
                                    'No results found in "$selectedCategory".',
                                    style: TextStyle(
                                      fontFamily:
                                          AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation
                                      ],
                                      fontSize: AppFontStyles.fontSize_16.sp,
                                      color: AppColors.bluegray,
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: resultsForCategory.map((item) {
                                  final question = item['question']!;
                                  final answer = item['answer']!;

                                  return Column(
                                    children: [
                                      Container(
                                        width: AppDimensions.dim380.w,
                                        padding: EdgeInsets.all(
                                            AppDimensions.dim20.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radius_16.r),
                                          border: Border.all(
                                              color: AppColors.greywith80),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.black
                                                  .withOpacity(0.25),
                                              blurRadius:
                                                  AppDimensions.radius_4.r,
                                              offset: Offset(
                                                AppDimensions.radius_4.r,
                                                AppDimensions.radius_4.r,
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            /// Question
                                            Text(
                                              question,
                                              style: TextStyle(
                                                fontFamily: AppFontStyles
                                                    .urbanistFontFamily,
                                                fontVariations: [
                                                  AppFontStyles
                                                      .fontWeightVariation600,
                                                ],
                                                fontSize: AppFontStyles
                                                    .fontSize_18.sp,
                                                color: AppColors.bluegray,
                                              ),
                                            ),
                                            SizedBox(
                                                height: AppDimensions.dim10.h),

                                            const Divider(
                                                color: AppColors.verylightgray),
                                            SizedBox(
                                                height: AppDimensions.dim10.h),

                                            /// Answer
                                            Text(
                                              answer,
                                              style: TextStyle(
                                                fontFamily: AppFontStyles
                                                    .urbanistFontFamily,
                                                fontVariations: [
                                                  AppFontStyles
                                                      .semiBoldFontVariation,
                                                ],
                                                fontSize: AppFontStyles
                                                    .fontSize_16.sp,
                                                color: AppColors.bluegray,
                                                letterSpacing: 0.2.sp,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: AppDimensions.dim20.h),
                                    ],
                                  );
                                }).toList(),
                              );
                            }

                            // 🟦 No search: normal category + expansion behavior
                            final categoryFaqs = context
                                .read<FaqCubit>()
                                .faqData[selectedCategory]!;
                            final expandedMap =
                                state.isExpandedMap[selectedCategory]!;

                            return Column(
                              children:
                                  List.generate(categoryFaqs.length, (index) {
                                final question =
                                    categoryFaqs[index]['question']!;
                                final answer = categoryFaqs[index]['answer']!;
                                final isExpanded = expandedMap[index];

                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => context
                                          .read<FaqCubit>()
                                          .toggleExpansion(index),
                                      child: Container(
                                        width: AppDimensions.dim380.w,
                                        padding: EdgeInsets.all(
                                            AppDimensions.dim20.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radius_16.r),
                                          border: Border.all(
                                              color: AppColors.greywith80),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.black
                                                  .withOpacity(0.25),
                                              blurRadius:
                                                  AppDimensions.radius_4.r,
                                              offset: Offset(
                                                AppDimensions.radius_4.r,
                                                AppDimensions.radius_4.r,
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    question,
                                                    style: TextStyle(
                                                      fontFamily: AppFontStyles
                                                          .urbanistFontFamily,
                                                      fontVariations: [
                                                        AppFontStyles
                                                            .fontWeightVariation600,
                                                      ],
                                                      fontSize: AppFontStyles
                                                          .fontSize_18.sp,
                                                      color: AppColors.bluegray,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        AppDimensions.dim8.w),
                                              ],
                                            ),
                                            AnimatedSize(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                              child: isExpanded
                                                  ? Column(
                                                      children: [
                                                        SizedBox(
                                                            height:
                                                                AppDimensions
                                                                    .dim10.h),
                                                        const Divider(
                                                            color: AppColors
                                                                .verylightgray),
                                                        SizedBox(
                                                            height:
                                                                AppDimensions
                                                                    .dim10.h),
                                                        Text(
                                                          answer,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppFontStyles
                                                                    .urbanistFontFamily,
                                                            fontVariations: [
                                                              AppFontStyles
                                                                  .semiBoldFontVariation,
                                                            ],
                                                            fontSize:
                                                                AppFontStyles
                                                                    .fontSize_16
                                                                    .sp,
                                                            color: AppColors
                                                                .bluegray,
                                                            letterSpacing:
                                                                0.2.sp,
                                                            height: 1.5,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: AppDimensions.dim20.h),
                                  ],
                                );
                              }),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),

              /// Bottom Navigation
              // Padding(
              //     padding: EdgeInsets.only(
              //       bottom: AppDimensions.dim5.h,
              //       right: AppDimensions.dim15.w,
              //       left: AppDimensions.dim15.w,
              //     ),
              //     child: AnimatedBottomNavBar()),
            ],
          ),
        ),
      ),
    );
  }

  /// ----------------- Header -----------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppDimensions.dim50.h,
        left: AppDimensions.dim24.w,
        right: AppDimensions.dim20.w,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppDimensions.dim40.w,
            height: AppDimensions.dim40.h,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.raisinblack,
                size: AppFontStyles.fontSize_30.sp,
              ),
            ),
          ),
          SizedBox(width: AppDimensions.dim120.w),
          Text(
            'FAQ',
            style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_24.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
        ],
      ),
    );
  }

  /// ----------------- Search Box -----------------
  Widget _buildSearchBox(FaqCubit cubit) {
    return BlocBuilder<FaqCubit, FaqState>(
      builder: (context, state) {
        return Container(
          width: AppDimensions.dim380.w,
          height: AppDimensions.dim65.h,
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim20.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radius_40.r),
            border: Border.all(color: AppColors.greywith80),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.25),
                offset: Offset(
                  AppDimensions.radius_4.r,
                  AppDimensions.radius_4.r,
                ),
                blurRadius: AppDimensions.radius_4.r,
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/searchicon.png',
                width: AppDimensions.dim16.w,
                height: AppDimensions.dim16.h,
                color: AppColors.gray400,
              ),
              SizedBox(width: AppDimensions.dim12.w),
              Expanded(
                child: TextField(
                  onChanged: cubit.filterSearch,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.regularFontVariation],
                      color: AppColors.gray400,
                      fontSize: AppFontStyles.fontSize_18.sp,
                      letterSpacing: 0.2.sp,
                    ),
                    border: InputBorder.none,
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black),
                            onPressed: () => cubit.filterSearch(''),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ----------------- Category Selector -----------------
  Widget _buildCategorySelector(BuildContext context) {
    final cubit = context.read<FaqCubit>();

    return BlocBuilder<FaqCubit, FaqState>(
      builder: (context, state) {
        final categories = cubit.faqData.keys.toList();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.dim24.w),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((label) {
                final bool isSelected = state.selectedCategory == label;
                return Padding(
                  padding: EdgeInsets.only(right: AppDimensions.dim12.w),
                  child: GestureDetector(
                    onTap: () => cubit.selectCategory(label),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.dim28.w,
                        vertical: AppDimensions.dim12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.bluegray
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radius_30.r),
                        border: Border.all(
                          color: AppColors.bluegray,
                          width: AppDimensions.dim1.w,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: AppFontStyles.fontSize_16.sp,
                          color: isSelected ? AppColors.white : Colors.blueGrey,
                          //color: AppColors.bluegray,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            AppFontStyles.fontWeightVariation600,
                          ],
                          letterSpacing: 0.2.sp,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

//============================================================================

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrify/constants/app_strings.dart';
// import 'package:hydrify/cubit/FaQ/faq_cubit.dart';
// import 'package:hydrify/cubit/FaQ/faq_state.dart';
// import 'package:hydrify/screens/widgets/FaQ_Widgets/faq_widgets.dart';

// class FAQPage extends StatelessWidget {
//   const FAQPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => FaqCubit(),
//       child: BlocBuilder<FaqCubit, FaqState>(
//         builder: (context, state) {
//           final cubit = context.read<FaqCubit>();

//           return Scaffold(
//             appBar: AppBar(
//               title: const Text(AppStrings.faq),
//               centerTitle: true,
//             ),
//             body: Column(
//               children: [
//                 /// Search Bar
//                 SearchBarWidget(
//                   controller: state.searchController,
//                   onChanged: cubit.filterSearchResults,
//                 ),

//                 /// Category Chips
//                 CategoryChipsWidget(
//                   categories: state.faqData.keys.toList(),
//                   selectedCategory: state.selectedCategory,
//                   onCategorySelected: cubit.changeCategory,
//                 ),

//                 /// FAQ List
//                 Expanded(
//                   child: FaqListWidget(
//                     faqs: state.faqData[state.selectedCategory] ?? [],
//                     isExpandedList:
//                         state.isExpandedMap[state.selectedCategory] ?? [],
//                     onToggleExpansion: (index) => cubit.toggleExpansion(
//                       state.selectedCategory,
//                       index,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             /// Bottom Nav
//             bottomNavigationBar: CustomBottomNavBar(
//               activeTab: 'Home',
//               onTabSelected: cubit.updateTab,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

//============================================================================
