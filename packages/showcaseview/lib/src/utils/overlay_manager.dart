/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/linked_showcase_data_model.dart';
import '../showcase/showcase.dart';
import '../showcase/showcase_controller.dart';
import '../showcase/showcase_service.dart';
import '../showcase/showcase_view.dart';
import 'extensions.dart';

/// A singleton manager class responsible for displaying and controlling
/// overlays in the ShowcaseView.
///
/// This class manages the creation, display, and removal of overlays used by
/// the showcase system. It coordinates with [ShowcaseView] to control
/// overlay visibility and maintains the current showcase scope.
class OverlayManager {
  /// Private constructor for singleton implementation
  OverlayManager._();

  /// Singleton instance of the manager
  static final _instance = OverlayManager._();

  /// Public accessor for the singleton instance
  static OverlayManager get instance => _instance;

  /// The overlay state where entries will be inserted
  OverlayState? overlayState;

  /// Current overlay entry being displayed
  OverlayEntry? _overlayEntry;

  /// Flag to determine if overlay should be shown
  var _shouldShow = false;

  /// The current showcase scope identifier
  String get _currentScope => ShowcaseService.instance.currentScope;

  /// Returns whether an overlay is currently being displayed
  bool get _isShowing => _overlayEntry != null;

  /// Updates the overlay visibility based on the provided showcase view.
  ///
  /// This method is called from showcase widgets to control overlay visibility.
  /// If the scope has changed, it will dispose the previous overlay.
  ///
  /// * [show] - Whether to show or hide the overlay.
  /// * [scope] - The new scope to be set as current.
  void update({
    required bool show,
    required String scope,
  }) {
    if (_currentScope != scope) {
      ShowcaseService.instance.updateCurrentScope(scope);
    }
    _shouldShow = show;
    _sync();
  }

  /// Updates the overlay state reference used by the manager
  ///
  /// This method allows setting or updating the [OverlayState] that will be
  /// used for inserting overlay entries.
  ///
  /// * [overlayState] - The new overlay state to use, can be null
  void updateState(OverlayState? overlayState) =>
      this.overlayState = overlayState;

  /// Disposes the overlay for the specified scope.
  ///
  /// Hides the overlay if it's currently showing and matches the provided
  /// scope.
  ///
  /// * [scope] - The scope to dispose overlays for
  void dispose({required String scope}) {
    if (!_isShowing || _currentScope != scope) return;
    _hide();
  }

  /// Shows the overlay using the provided builder.
  ///
  /// Creates a new overlay entry if none exists, otherwise rebuilds the
  /// existing one.
  void _show(WidgetBuilder overlayBuilder) {
    if (_overlayEntry != null) {
      // Rebuild overlay.
      _rebuild();
      return;
    }
    // Create the overlay.
    _overlayEntry = OverlayEntry(builder: overlayBuilder);
    overlayState?.insert(_overlayEntry!);
  }

  /// Removes and clears the current overlay entry.
  void _hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Synchronizes the overlay visibility with the showcase manager state.
  ///
  /// Shows or hides the overlay based on the [_shouldShow] flag.
  void _sync() {
    if (_isShowing && !_shouldShow) {
      _hide();
    } else if (!_isShowing && _shouldShow) {
      _show(_getBuilder);
    } else {
      _rebuild();
    }
  }

  /// Creates and returns the overlay widget structure.
  ///
  /// Builds a stack with background and tooltip widgets based on active
  /// controllers.
  Widget _getBuilder(BuildContext context) {
    if (!context.mounted || !(_overlayEntry?.mounted ?? true)) {
      return const SizedBox.shrink();
    }

    final showcaseView = ShowcaseView.getNamed(_currentScope);
    final controllers = ShowcaseService.instance
            .getControllers(
              scope: showcaseView.scope,
            )[showcaseView.getActiveShowcaseKey]
            ?.values
            .toList() ??
        <ShowcaseController>[];

    if (controllers.isEmpty) return const SizedBox.shrink();

    final currentShowcaseKey = showcaseView.getActiveShowcaseKey;

    late final ShowcaseController firstController;
    late final Showcase firstShowcaseConfig;
    final controllerLength = controllers.length;
    for (var i = 0; i < controllerLength; i++) {
      final controller = controllers[i];
      if (i == 0) {
        firstController = controller;
        firstShowcaseConfig = firstController.config;
      }
      if (controller.key == currentShowcaseKey) {
        controller.updateControllerData();
      }
    }

    final backgroundContainer = ColoredBox(
      color: (firstController.showcaseView.overlayColor ??
              firstShowcaseConfig.overlayColor)
          .reduceOpacity(
        (firstController.showcaseView.overlayOpacity ??
            firstShowcaseConfig.overlayOpacity),
      ),
      child: const Align(),
    );

    final scale = firstController.config.overlayScale ??
        firstController.showcaseView.overlayScale;
    final targetCenter = firstController.linkedShowcaseDataModel?.rect.center;

    Widget blurredBackground = firstController.blur <= 0.2
        ? backgroundContainer
        : BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: firstController.blur,
              sigmaY: firstController.blur,
            ),
            child: backgroundContainer,
          );

    Widget clipPathChild;
    if (targetCenter != null) {
      final linkedData = _getLinkedShowcasesData(controllers).firstOrNull;
      final targetRect = linkedData?.rect;
      final padding = linkedData?.overlayPadding ?? EdgeInsets.zero;
      final isCircle = linkedData?.isCircle ?? false;
      
      final borderRadius = (linkedData?.radius != null)
          ? (linkedData!.radius!.topLeft.x)
          : 8.0;

      final targetRectWithPadding = targetRect != null
          ? Rect.fromLTRB(
              targetRect.left - padding.left,
              targetRect.top - padding.top,
              targetRect.right + padding.right,
              targetRect.bottom + padding.bottom,
            )
          : Rect.fromCenter(center: targetCenter, width: 50, height: 50);

      clipPathChild = SoftElongatedMask(
        targetRect: targetRectWithPadding,
        isCircle: isCircle,
        borderRadius: borderRadius,
        fadeWidth: linkedData?.overlayFadeWidth ?? 12.5,
        scale: scale,
        targetCenter: targetCenter,
        child: blurredBackground,
      );
    } else {
      clipPathChild = blurredBackground;
    }

    final overlayChild = Stack(
      // This key is used to force rebuild the overlay when needed.
      // this key enables `_overlayEntry?.markNeedsBuild();` to detect that
      // output of the builder has changed.
      key: ValueKey(firstController.id),
      children: [
        GestureDetector(
          onTap: firstController.handleBarrierTap,
          child: clipPathChild,
        ),
        ...controllers.expand((object) => object.tooltipWidgets),
      ],
    );

    final inheritedData = firstController.inheritedData;

    // Wrap the child with captured themes to maintain the original context's
    // theme. Captured themes are used as to cover cases where there are
    // multiple themes in the widget tree.
    final themedChild = inheritedData.capturedThemes.wrap(overlayChild);

    // Wrap with other inherited widgets to maintain showcase's context's
    // inherited values.
    return Directionality(
      textDirection: inheritedData.textDirection,
      child: MediaQuery(
        data: inheritedData.mediaQuery,
        child: DefaultTextStyle(
          style: inheritedData.textStyle,
          child: themedChild,
        ),
      ),
    );
  }

  /// Extracts and returns linked showcase data from controllers.
  ///
  /// Filters out null data and collects valid linked showcase information.
  List<LinkedShowcaseDataModel> _getLinkedShowcasesData(
    List<ShowcaseController> controllers,
  ) {
    final controllerLength = controllers.length;
    return [
      for (var i = 0; i < controllerLength; i++)
        if (controllers[i].linkedShowcaseDataModel case final model?) model,
    ];
  }

  /// Forces the overlay entry to rebuild
  void _rebuild() => _overlayEntry?.markNeedsBuild();
}

class SoftElongatedMask extends SingleChildRenderObjectWidget {
  final Rect targetRect;
  final bool isCircle;
  final double borderRadius;
  final double fadeWidth;
  final double? scale;
  final Offset? targetCenter;

  const SoftElongatedMask({
    super.key,
    required super.child,
    required this.targetRect,
    required this.isCircle,
    required this.borderRadius,
    required this.fadeWidth,
    this.scale,
    this.targetCenter,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSoftElongatedMask(
      targetRect: targetRect,
      isCircle: isCircle,
      borderRadius: borderRadius,
      fadeWidth: fadeWidth,
      scale: scale,
      targetCenter: targetCenter,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSoftElongatedMask renderObject) {
    renderObject
      ..targetRect = targetRect
      ..isCircle = isCircle
      ..borderRadius = borderRadius
      ..fadeWidth = fadeWidth
      ..scale = scale
      ..targetCenter = targetCenter;
  }
}

class RenderSoftElongatedMask extends RenderProxyBox {
  Rect _targetRect;
  bool _isCircle;
  double _borderRadius;
  double _fadeWidth;
  double? _scale;
  Offset? _targetCenter;

  RenderSoftElongatedMask({
    required Rect targetRect,
    required bool isCircle,
    required double borderRadius,
    required double fadeWidth,
    double? scale,
    Offset? targetCenter,
  })  : _targetRect = targetRect,
        _isCircle = isCircle,
        _borderRadius = borderRadius,
        _fadeWidth = fadeWidth,
        _scale = scale,
        _targetCenter = targetCenter;

  Rect get targetRect => _targetRect;
  set targetRect(Rect value) {
    if (_targetRect == value) return;
    _targetRect = value;
    markNeedsPaint();
  }

  bool get isCircle => _isCircle;
  set isCircle(bool value) {
    if (_isCircle == value) return;
    _isCircle = value;
    markNeedsPaint();
  }

  double get borderRadius => _borderRadius;
  set borderRadius(double value) {
    if (_borderRadius == value) return;
    _borderRadius = value;
    markNeedsPaint();
  }

  double get fadeWidth => _fadeWidth;
  set fadeWidth(double value) {
    if (_fadeWidth == value) return;
    _fadeWidth = value;
    markNeedsPaint();
  }

  double? get scale => _scale;
  set scale(double? value) {
    if (_scale == value) return;
    _scale = value;
    markNeedsPaint();
  }

  Offset? get targetCenter => _targetCenter;
  set targetCenter(Offset? value) {
    if (_targetCenter == value) return;
    _targetCenter = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If inside the target hole, click passes through (we return false)
    if (_isCircle) {
      final center = _targetRect.center;
      final radius = _targetRect.shortestSide / 2;
      final distance = (position - center).distance;
      if (distance <= radius) {
        return false;
      }
    } else {
      if (_targetRect.contains(position)) {
        return false;
      }
    }

    // Pass through clicks outside the scaled overlay
    final isScaled = _scale != null && _scale! > 0.0 && _scale! < 1.0 && _targetCenter != null;
    if (isScaled) {
      final tCenter = _targetCenter!;
      final shortestSide = size.shortestSide > 0 ? size.shortestSide : 1.0;

      final holeMaxDist = _isCircle
          ? (_targetRect.shortestSide / 2)
          : (_targetRect.longestSide / 2);

      const solidRingWidth = 60.0;
      const outerFadeWidth = 80.0;

      final minOuterRadius = holeMaxDist + _fadeWidth + solidRingWidth + outerFadeWidth;
      final desiredOuterRadius = _scale! * shortestSide;
      final outerRadius = desiredOuterRadius > minOuterRadius ? desiredOuterRadius : minOuterRadius;

      final distance = (position - tCenter).distance;
      if (distance > outerRadius) {
        return false;
      }
    }

    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final canvas = context.canvas;
    final bounds = offset & size;

    // 1. Save layer for compositing
    canvas.saveLayer(bounds, Paint());

    // 2. Paint child (blurred background)
    context.paintChild(child!, offset);

    // 3. Punch target hole using BlendMode.dstOut and MaskFilter.blur
    final holePaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _fadeWidth);

    if (_isCircle) {
      final center = _targetRect.center + offset;
      final radius = _targetRect.shortestSide / 2;
      canvas.drawCircle(center, radius, holePaint);
    } else {
      final adjustedRect = _targetRect.shift(offset);
      final rrect = RRect.fromRectAndRadius(adjustedRect, Radius.circular(_borderRadius));
      canvas.drawRRect(rrect, holePaint);
    }

    // 4. Apply outer scale using BlendMode.dstIn
    final isScaled = _scale != null && _scale! > 0.0 && _scale! < 1.0 && _targetCenter != null;
    if (isScaled) {
      final outerPaint = Paint()..blendMode = BlendMode.dstIn;
      final tCenter = _targetCenter! + offset;
      final shortestSide = size.shortestSide > 0 ? size.shortestSide : 1.0;

      final holeMaxDist = _isCircle
          ? (_targetRect.shortestSide / 2)
          : (_targetRect.longestSide / 2);

      const solidRingWidth = 60.0;
      const outerFadeWidth = 80.0;

      final minOuterRadius = holeMaxDist + _fadeWidth + solidRingWidth + outerFadeWidth;
      final desiredOuterRadius = _scale! * shortestSide;
      final outerRadius = desiredOuterRadius > minOuterRadius ? desiredOuterRadius : minOuterRadius;

      final stop3 = (outerRadius - outerFadeWidth) / outerRadius;

      final shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: const [
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [
          0.0,
          stop3.clamp(0.0, 1.0),
          1.0,
        ],
      ).createShader(Rect.fromCircle(center: tCenter, radius: outerRadius));

      outerPaint.shader = shader;
      canvas.drawRect(bounds, outerPaint);
    }

    canvas.restore();
  }
}
