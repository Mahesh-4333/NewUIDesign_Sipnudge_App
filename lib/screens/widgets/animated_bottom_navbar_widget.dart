import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  const AnimatedBottomNavBar({super.key});

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with TickerProviderStateMixin {
  int? pressedIndex;

  late List<AnimationController> _pressControllers;
  late List<Animation<double>> _scaleAnimations;
  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;
  late List<Animation<double>> _shadowBlurAnimations;
  late List<Animation<Offset>> _shadowOffsetAnimations;

  static const List<dynamic> _icons = [
    "assets/images/home_ic.svg",
    "assets/images/analysis_ic.svg",
    "assets/images/trophy_ic.svg",
    "assets/images/settings_ic.svg"
  ];

  static const List<String> _labels = [
    AppStrings.home,
    AppStrings.analysis,
    'Goals',
    AppStrings.setting,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pressControllers = List.generate(
      _icons.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );

    _shadowBlurAnimations = _pressControllers.map((controller) {
      return Tween<double>(
        begin: AppDimensions.dim5.r,
        end: AppDimensions.dim2.r,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _shadowOffsetAnimations = _pressControllers.map((controller) {
      return Tween<Offset>(
        begin: Offset(AppDimensions.dim4.w, AppDimensions.dim4.h),
        end: Offset(AppDimensions.dim1.w, AppDimensions.dim1.h),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _scaleAnimations = _pressControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeOutBack,
    ));

    _selectionController.value = 1.0;
  }

  @override
  void dispose() {
    for (var controller in _pressControllers) {
      controller.dispose();
    }
    _selectionController.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    setState(() {
      pressedIndex = index;
    });
    _pressControllers[index].forward();
  }

  void _onTapUp(int index) {
    _pressControllers[index].reverse().then((_) {
      if (pressedIndex == index) {
        setState(() {
          pressedIndex = null;
        });
      }
    });
  }

  void _onTapCancel() {
    if (pressedIndex != null) {
      _pressControllers[pressedIndex!].reverse().then((_) {
        setState(() {
          pressedIndex = null;
        });
      });
    }
  }

  void _onTap(int index, BottomNavCubit cubit, int currentIndex) {
    if (currentIndex != index) {
      cubit.selectTabByIndex(index);
      _selectionController.reset();
      _selectionController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavCubit, BottomNavState>(
      builder: (context, state) {
        final cubit = context.read<BottomNavCubit>();
        final currentIndex = state.selectedIndex;

        return !state.isVisible
            ? SizedBox.shrink()
            : Container(
                width: AppDimensions.dim408.w,
                height: AppDimensions.dim88.h,
                padding: EdgeInsets.symmetric(
                  vertical: AppDimensions.dim14.h,
                  horizontal: AppDimensions.dim20.w,
                ),
                decoration: BoxDecoration(
                  //color: const Color(0xffffffff),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.white, AppColors.bottomnavbar]),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: AppDimensions.dim30.r,
                      spreadRadius: AppDimensions.dim2.r,
                      color: Colors.white.withOpacity(.09),
                      offset:
                          Offset(AppDimensions.dim4.w, AppDimensions.dim4.h),
                    )
                  ],
                  border: GradientBoxBorder(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.greywith80, Color(0xFF3F3F3F)],
                    ),
                    width: AppDimensions.dim1.w,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.dim90.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _icons.length,
                    (index) {
                      final isSelected = currentIndex == index;
                      return GestureDetector(
                        onTapDown: (_) => _onTapDown(index),
                        onTapUp: (_) => _onTapUp(index),
                        onTapCancel: _onTapCancel,
                        onTap: () => _onTap(index, cubit, currentIndex),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _pressControllers[index],
                            if (isSelected) _selectionController,
                          ]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimations[index].value,
                              child: isSelected
                                  ? _buildSelectedContainer(index)
                                  : _buildUnselectedItem(index),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
      },
    );
  }

  Widget _buildSelectedContainer(int index) {
    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _selectionAnimation.value),
          child: Opacity(
            opacity: (0.3 + (0.7 * _selectionAnimation.value)).clamp(0.0, 1.0),
            child: Container(
              width: AppDimensions.dim82.w,
              height: AppDimensions.dim60.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0XFF2B2536),
                boxShadow: [
                  BoxShadow(
                    blurRadius: _shadowBlurAnimations[index].value,
                    color: Colors.black.withOpacity(
                      (.25 * _selectionAnimation.value).clamp(0.0, 0.25),
                    ),
                    offset: _shadowOffsetAnimations[index].value,
                  ),
                  // BoxShadow(
                  //   blurRadius:
                  //       (AppDimensions.dim5.r * _selectionAnimation.value)
                  //           .clamp(0.0, AppDimensions.dim5.r),
                  //   color: Colors.black.withOpacity(
                  //       (.5 * _selectionAnimation.value).clamp(0.0, 0.5)),
                  //   offset: Offset(
                  //     (AppDimensions.dim5.w * _selectionAnimation.value)
                  //         .clamp(0.0, AppDimensions.dim5.w),
                  //     (AppDimensions.dim5.h * _selectionAnimation.value)
                  //         .clamp(0.0, AppDimensions.dim5.h),
                  //   ),
                  // )
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.navbarSelectedItemGradientStart,
                    AppColors.navbarSelectedItemGradientEnd,
                  ],
                ),
                // gradient: LinearGradient(
                //   begin: Alignment.topCenter,
                //   end: Alignment.bottomCenter,
                //   colors: [
                //     AppColors.navbarSelectedItemGradientStart,
                //     AppColors.navbarSelectedItemGradientEnd,
                //   ],
                // ),
                border: GradientBoxBorder(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.greywith80,
                      Color(0xFF3F3F3F),
                    ],
                  ),
                  width: AppDimensions.dim1.w,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.dim48.r),
              ),
              child: _buildNavBarItem(index, true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnselectedItem(int index) {
    return Container(
      width: AppDimensions.dim82.w,
      height: AppDimensions.dim60.h,
      alignment: Alignment.center,
      child: _buildNavBarItem(index, false),
    );
  }

  Widget _buildNavBarItem(int index, bool isSelected) {
    return SizedBox(
      width: AppDimensions.dim82.w,
      height: AppDimensions.dim60.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            _icons[index],
            color: AppColors.darkgray,
          ),
          Text(
            _labels[index],
            style: TextStyle(
              color: AppColors.darkgray,
              fontFamily: AppFontStyles.lexendFontFamily,
              fontSize: AppFontStyles.fontSize_12,
              fontVariations: isSelected
                  ? [AppFontStyles.regularFontVariation]
                  : [
                      AppFontStyles.lightFontWeightVariation,
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
