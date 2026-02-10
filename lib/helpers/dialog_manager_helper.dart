import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//**
///  1️⃣ Check if any modal is open
// if (DialogManager().isAnyModalOpen) {
//  print("A dialog or bottom sheet is open");
//}

// 2️⃣ Check specific modal types
//if (DialogManager().isDialogOpen) {
  // Handle open dialog
//}

//if (DialogManager().isBottomSheetOpen) {
  // Handle open bottom sheet
//}

// 3️⃣ Use tracked methods (automatically manages state)
//await DialogManager().showTrackedModalBottomSheet(
//  context: context,
//  builder: (context) => ReminderBottomSheet(),
//);

// 4️⃣ For manual tracking (if using standard showModalBottomSheet)
//DialogManager().markBottomSheetOpen();
// ... show bottom sheet ...
//DialogManager().markBottomSheetClosed();
// */


/// DialogManager is a utility to track and manage open dialogs and bottom sheets
class DialogManager {
  static final DialogManager _instance = DialogManager._internal();

  factory DialogManager() { 
    return _instance;
  }

  DialogManager._internal();

  bool _isDialogOpen = false;
  bool _isBottomSheetOpen = false;

  /// Check if any dialog is currently open
  bool get isDialogOpen => _isDialogOpen;

  /// Check if any bottom sheet is currently open
  bool get isBottomSheetOpen => _isBottomSheetOpen;

  /// Check if any modal (dialog or bottom sheet) is open
  bool get isAnyModalOpen => _isDialogOpen || _isBottomSheetOpen;

  /// Show a dialog and automatically track it
  Future<T?> showTrackedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) async {
    _isDialogOpen = true;
    try {
      final result = await showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );
      return result;
    } finally {
      _isDialogOpen = false;
    }
  }

  /// Show a bottom sheet and automatically track it
  Future<T?> showTrackedModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    String? barrierLabel,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) async {
    _isBottomSheetOpen = true;
    try {
      final result = await showModalBottomSheet<T>(
        context: context,
        builder: builder,
        backgroundColor: backgroundColor,
        barrierLabel: barrierLabel,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
      );
      return result;
    } finally {
      _isBottomSheetOpen = false;
    }
  }

  /// Show a Cupertino modal bottom sheet and automatically track it
  Future<T?> showTrackedCupertinoModalPopup<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? routeSettings,
    ImageFilter? filter,
  }) async {
    _isBottomSheetOpen = true;
    try {
      final result = await showCupertinoModalPopup<T>(
        context: context,
        builder: builder,
        routeSettings: routeSettings,
        filter: filter,
      );
      return result;
    } finally {
      _isBottomSheetOpen = false;
    }
  }

  /// Manually mark dialog as open (for custom dialogs)
  void markDialogOpen() => _isDialogOpen = true;

  /// Manually mark dialog as closed
  void markDialogClosed() => _isDialogOpen = false;

  /// Manually mark bottom sheet as open (for custom bottom sheets)
  void markBottomSheetOpen() => _isBottomSheetOpen = true;

  /// Manually mark bottom sheet as closed
  void markBottomSheetClosed() => _isBottomSheetOpen = false;

  /// Reset all tracking (use when navigating to different screens)
  void reset() {
    _isDialogOpen = false;
    _isBottomSheetOpen = false;
  }
}

/// Extension on NavigatorState to check if a dialog/bottom sheet is open
extension DialogStateExtension on NavigatorState {
  /// Alternative method using Navigator stack inspection
  /// Returns true if there's an overlay route (dialog/bottom sheet) open
  bool get hasOpenModal {
    bool hasOpenModal = false;
    popUntil((route) {
      if (route.isFirst) {
        return hasOpenModal = false; // No overlay
      }
      // Check if it's an overlay route type
      hasOpenModal = route is OverlayRoute;
      return true; // Stop checking after first route
    });
    return hasOpenModal;
  }
}
