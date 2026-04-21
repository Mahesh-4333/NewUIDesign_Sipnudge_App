import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
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

  // Track the liquid glass drag and slide transition
  bool _isDragging = false;
  bool _wasDragged = false;
  double? _dragLeft;
  int? _currentIndex;
  int? _previousIndex;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late AnimationController _dragScaleController;
  late AnimationController _bounceController;
  double? _startLeft;
  double? _targetLeft;
  double? _initialDragLeft;

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

    _scaleAnimations = _pressControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
      value: 1.0, // Start completed so initial state shows resting buttons
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve:
          Curves.easeOutBack, // Smooth fluid travel with a soft settle bounce
    );

    _dragScaleController = AnimationController(
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (var controller in _pressControllers) {
      controller.dispose();
    }
    _slideController.dispose();
    _dragScaleController.dispose();
    _bounceController.dispose();
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
    }
  }

  void _onDragStart(int index) {
    if (index != _currentIndex) return;
    _dragScaleController.animateTo(1.0,
        duration: const Duration(milliseconds: 400),
        curve: const ElasticOutCurve(0.6));
    _bounceController.repeat(reverse: true);
    setState(() {
      _isDragging = true;
      _dragLeft = _getGlassLeftOffset(_currentIndex!);
      _initialDragLeft = _dragLeft;
      _slideController.stop(); // Intercept any ongoing slide
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragLeft = _dragLeft! + details.delta.dx;
      double minLeft = _getGlassLeftOffset(0);
      double maxLeft = _getGlassLeftOffset(_icons.length - 1);
      _dragLeft = _dragLeft!.clamp(minLeft, maxLeft);
    });
  }

  void _onDragEnd(DragEndDetails details, BottomNavCubit cubit) {
    if (!_isDragging) return;
    _dragScaleController.animateTo(0.0,
        duration: const Duration(milliseconds: 400),
        curve: const ElasticOutCurve(0.6));
    _bounceController.stop();
    _bounceController.reset();

    // Nearest neighbour algorithm to find dropped tab
    int nearestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < _icons.length; i++) {
      double dist = (_getGlassLeftOffset(i) - _dragLeft!).abs();
      if (dist < minDistance) {
        minDistance = dist;
        nearestIndex = i;
      }
    }

    setState(() {
      _isDragging = false;
      _wasDragged = true;
      _previousIndex = _currentIndex;
      _startLeft = _dragLeft;
      _targetLeft = _getGlassLeftOffset(nearestIndex);

      if (nearestIndex != _currentIndex) {
        cubit.selectTabByIndex(nearestIndex);
      } else {
        // Did not traverse far enough; snap back to current
        _slideController.forward(from: 0.0);
      }
    });
  }

  double _getButtonOpacity(int index, double progress) {
    if (_isDragging)
      return 0.0; // Hide rigid selected button while held/dragged

    if (progress >= 1.0) {
      return index == _currentIndex ? 1.0 : 0.0;
    }
    if (index == _currentIndex) {
      // Crossfade in the destination button only during the last 30% of the slide
      if (progress < 0.7) return 0.0;
      return (progress - 0.7) / 0.3;
    } else if (index == _previousIndex) {
      // Crossfade out the origin button only during the first 30% of the slide
      if (progress > 0.3) return 0.0;
      return 1.0 - (progress / 0.3);
    }
    return 0.0; // Unselected buttons
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BottomNavCubit, BottomNavState>(
      listener: (context, state) {
        if (_currentIndex != state.selectedIndex) {
          _previousIndex = _currentIndex ?? state.selectedIndex;
          _currentIndex = state.selectedIndex;

          // Compute exact current physical sliding position if interrupted mid-slide
          if (_wasDragged) {
            _wasDragged = false;
          } else if (_startLeft != null && _slideController.isAnimating) {
            _startLeft = _startLeft! +
                ((_targetLeft! - _startLeft!) * _slideAnimation.value);
          } else {
            _startLeft = _getGlassLeftOffset(_previousIndex!);
          }

          _targetLeft = _getGlassLeftOffset(_currentIndex!);
          _slideController.forward(from: 0.0);
        }
      },
      builder: (context, state) {
        final cubit = context.read<BottomNavCubit>();

        // Init values safely on first frame
        _currentIndex ??= state.selectedIndex;
        _targetLeft ??= _getGlassLeftOffset(_currentIndex!);
        _startLeft ??= _targetLeft;

        return !state.isVisible
            ? SizedBox.shrink()
            : AnimatedBuilder(
                animation: Listenable.merge(
                    [_slideAnimation, _dragScaleController, _bounceController]),
                builder: (context, child) {
                  double slideProgress = _slideAnimation.value;
                  double bounceValue =
                      _isDragging ? _bounceController.value : 0.0;
                  // shrinks to 0.85 when grabbed, with a +/- 0.05 bounce
                  double dragScale = 1.3 -
                      (_dragScaleController.value *
                          (0.04 + (bounceValue * 0.06)));
                  double currentLeft = _isDragging
                      ? _dragLeft!
                      : _startLeft! +
                          ((_targetLeft! - _startLeft!) * slideProgress);

                  // Clamp progress so optical effects don't flash wildly during the physical bounce overshoot
                  double clampedProgress = slideProgress.clamp(0.0, 1.0);

                  // Intense liquid distortion while dragging or sliding
                  double currentDistortion =
                      _isDragging ? 5.0 : sin(clampedProgress * 3.14159) * 5.0;
                  // Subtle liquid bulging
                  double currentMagnification = _isDragging
                      ? 1.2
                      : 1.0 + (sin(clampedProgress * 3.14159) * 0.4);

                  double barScale = 1.0 - (_dragScaleController.value * 0.05);

                  return Transform.scale(
                    scale: barScale,
                    child: Container(
                      width: AppDimensions.dim408.w,
                      height: AppDimensions.dim88.h,
                      decoration: BoxDecoration(
                        boxShadow: [
                          // BoxShadow(
                          //   blurRadius: AppDimensions.dim30.r,
                          //   spreadRadius: AppDimensions.dim2.r,
                          //   // color: Colors.white.withOpacity(.09),
                          //   offset: Offset(
                          //       AppDimensions.dim4.w, AppDimensions.dim4.h),
                          // )
                        ],
                        borderRadius:
                            BorderRadius.circular(AppDimensions.dim90.r),
                        border: GradientBoxBorder(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.greywith80, Color(0xFF3F3F3F)],
                          ),
                          width: AppDimensions.dim1.w,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.dim90.r),
                        child: Stack(
                          children: [
                            LiquidGlassView(
                              useSync: false,
                              pixelRatio: 1.7,
                              backgroundWidget: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.white,
                                      AppColors.bottomnavbar
                                    ],
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: AppDimensions.dim14.h,
                                  horizontal: AppDimensions.dim20.w,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    _icons.length,
                                    (index) {
                                      return Container(
                                        width: AppDimensions.dim82.w,
                                        height: AppDimensions.dim60.h,
                                        alignment: Alignment.center,
                                        child: AnimatedBuilder(
                                          animation: _pressControllers[index],
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale:
                                                  _scaleAnimations[index].value,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  // Always render the unselected base component
                                                  _buildNavBarItem(
                                                      index, false),
                                                  // Fade the original selected button over top seamlessly
                                                  Opacity(
                                                    opacity: _getButtonOpacity(
                                                        index, slideProgress),
                                                    child:
                                                        _buildSelectedOriginal(
                                                            index),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              children: [
                                // Mount the liquid chunk into UI tree primarily when transitioning
                                if (_isDragging ||
                                    (slideProgress > 0.0 &&
                                        slideProgress < 1.0))
                                  LiquidGlass(
                                    width: AppDimensions.dim82.w * dragScale,
                                    height: AppDimensions.dim60.h * dragScale,
                                    magnification: currentMagnification,
                                    distortion: 0.1,
                                    position: LiquidGlassOffsetPosition(
                                      left: currentLeft +
                                          AppDimensions.dim20.w +
                                          ((AppDimensions.dim82.w -
                                                  (AppDimensions.dim82.w *
                                                      dragScale)) /
                                              2),
                                      top: AppDimensions.dim14.h +
                                          ((AppDimensions.dim60.h -
                                                  (AppDimensions.dim60.h *
                                                      dragScale)) /
                                              2),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.dim48.r),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Transparent touch interception layer over the view
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.dim14.h,
                                horizontal: AppDimensions.dim20.w,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  _icons.length,
                                  (index) => GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (_) => _onTapDown(index),
                                    onTapUp: (_) => _onTapUp(index),
                                    onTapCancel: _onTapCancel,
                                    onTap: () =>
                                        _onTap(index, cubit, _currentIndex!),
                                    onLongPress: () => _onDragStart(index),
                                    onLongPressMoveUpdate: (details) {
                                      if (_isDragging) {
                                        setState(() {
                                          _dragLeft = (_initialDragLeft ??
                                                  0.0) +
                                              details.localOffsetFromOrigin.dx;
                                          double minLeft =
                                              _getGlassLeftOffset(0);
                                          double maxLeft = _getGlassLeftOffset(
                                              _icons.length - 1);
                                          _dragLeft = _dragLeft!
                                              .clamp(minLeft, maxLeft);
                                        });
                                      }
                                    },
                                    onLongPressEnd: (details) =>
                                        _onDragEnd(DragEndDetails(), cubit),
                                    onLongPressUp: () =>
                                        _onDragEnd(DragEndDetails(), cubit),
                                    onHorizontalDragStart: (_) =>
                                        _onDragStart(index),
                                    onHorizontalDragUpdate: (details) =>
                                        _onDragUpdate(details),
                                    onHorizontalDragEnd: (details) =>
                                        _onDragEnd(details, cubit),
                                    child: SizedBox(
                                      width: AppDimensions.dim82.w,
                                      height: AppDimensions.dim60.h,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
      },
    );
  }

  // Purana wala button code for the resting highlighted state
  Widget _buildSelectedOriginal(int index) {
    return Container(
      width: AppDimensions.dim82.w,
      height: AppDimensions.dim60.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.dim48.r),
        boxShadow: [
          BoxShadow(
            blurRadius: AppDimensions.dim10.r,
            spreadRadius: AppDimensions.dim2.r,
            color: Colors.black.withValues(alpha: 0.1),
            offset: Offset(AppDimensions.dim2.w, AppDimensions.dim4.h),
          ),
        ],
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navbarSelectedItemGradientStart,
              AppColors.navbarSelectedItemGradientEnd,
            ]),
        border: GradientBoxBorder(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.greywith80,
            ],
          ),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: _buildNavBarItem(index, true),
    );
  }

  double _getGlassLeftOffset(int currentIndex) {
    double itemWidth = AppDimensions.dim82.w;
    double totalWidth = AppDimensions.dim408.w;
    double paddingHorizontal = AppDimensions.dim20.w;
    double gap = (totalWidth - (paddingHorizontal * 2) - (itemWidth * 4)) / 3;
    return currentIndex * (itemWidth + gap);
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
