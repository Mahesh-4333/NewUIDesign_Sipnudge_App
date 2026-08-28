import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';

class LeaderboardBadgeController {
  _LeaderboardAchievementBadgeState? _state;

  void _attach(_LeaderboardAchievementBadgeState state) {
    _state = state;
  }

  void _detach(_LeaderboardAchievementBadgeState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  void triggerLevelUpBoost() {
    _state?._triggerLevelUpBoost();
  }
}

class LeaderboardAchievementBadge extends StatefulWidget {
  const LeaderboardAchievementBadge({
    super.key,
    required this.level,
    this.width = 320,
    this.controller,
    this.normalRotationDuration = const Duration(seconds: 36),
    this.boostRotationDuration = const Duration(seconds: 1),
    this.boostDuration = const Duration(seconds: 4),
    this.leafDuration = const Duration(milliseconds: 6000),
    this.glowDuration = const Duration(milliseconds: 4200),
    this.backgroundBreathDuration = const Duration(milliseconds: 3800),
    this.backgroundScaleMin = 0.97,
    this.backgroundScaleMax = 1.03,
    this.backgroundOpacityMin = 0.2,
    this.backgroundOpacityMax = 0.7,
    this.backgroundAssetPath = AssetsPath.asc,
    this.leavesLeftAssetPath = AssetsPath.badge_leaves_left,
    this.leavesRightAssetPath = AssetsPath.badge_leaves_right,
    this.ringAssetPath = AssetsPath.badge_ring,
    this.coreAssetPath = AssetsPath.badge_core,
    this.enableFloating = true,
  });

  final String level;
  final double width;
  final LeaderboardBadgeController? controller;
  final Duration normalRotationDuration;
  final Duration boostRotationDuration;
  final Duration boostDuration;
  final Duration leafDuration;
  final Duration glowDuration;
  final Duration backgroundBreathDuration;
  final double backgroundScaleMin;
  final double backgroundScaleMax;
  final double backgroundOpacityMin;
  final double backgroundOpacityMax;
  final String backgroundAssetPath;
  final String leavesLeftAssetPath;
  final String leavesRightAssetPath;
  final String ringAssetPath;
  final String coreAssetPath;
  final bool enableFloating;

  @override
  State<LeaderboardAchievementBadge> createState() =>
      _LeaderboardAchievementBadgeState();
}

class _LeaderboardAchievementBadgeState
    extends State<LeaderboardAchievementBadge> with TickerProviderStateMixin {
  static const double _sourceWidth = 344;
  static const double _sourceHeight = 341;
  static const double _badgeCenterX = 171.512;
  static const double _badgeCenterY = 153.21;
  static const Alignment _badgeCenterAlignment = Alignment(
    (_badgeCenterX / (_sourceWidth / 2)) - 1,
    (_badgeCenterY / (_sourceHeight / 2)) - 1,
  );

  late final AnimationController _rotationController;
  late final AnimationController _leafController;
  late final AnimationController _glowController;
  late final AnimationController _backgroundBreathController;

  Timer? _boostResetTimer;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: widget.normalRotationDuration,
    )..repeat();

    _leafController = AnimationController(
      vsync: this,
      duration: widget.leafDuration,
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: widget.glowDuration,
    )..repeat(reverse: true);

    _backgroundBreathController = AnimationController(
      vsync: this,
      duration: widget.backgroundBreathDuration,
    )..repeat(reverse: true);

    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant LeaderboardAchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    _boostResetTimer?.cancel();
    widget.controller?._detach(this);
    _rotationController.dispose();
    _leafController.dispose();
    _glowController.dispose();
    _backgroundBreathController.dispose();
    super.dispose();
  }

  void _triggerLevelUpBoost() {
    _boostResetTimer?.cancel();

    _rotationController
      ..stop()
      ..duration = widget.boostRotationDuration
      ..repeat();

    _glowController.stop();
    unawaited(
      _glowController.forward(from: 0).whenComplete(() {
        if (!mounted) {
          return;
        }
        _glowController.repeat(reverse: true);
      }),
    );

    _boostResetTimer = Timer(widget.boostDuration, () {
      if (!mounted) {
        return;
      }
      _rotationController
        ..stop()
        ..duration = widget.normalRotationDuration
        ..repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: _sourceWidth / _sourceHeight,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotationController,
            _leafController,
            _glowController,
            _backgroundBreathController,
          ]),
          builder: (context, _) {
            final leafWave = sin(_leafController.value * 2 * pi) * 0.028;
            final glowScale = lerpDouble(0.985, 1.015, _glowController.value)!;
            final glowOpacity = lerpDouble(0.35, 0.6, _glowController.value)!;
            final backgroundScale = lerpDouble(
              widget.backgroundScaleMin,
              widget.backgroundScaleMax,
              _backgroundBreathController.value,
            )!;
            final backgroundOpacity = lerpDouble(
              widget.backgroundOpacityMin,
              widget.backgroundOpacityMax,
              _backgroundBreathController.value,
            )!;
            final floatingOffset = widget.enableFloating
                ? sin(_glowController.value * 2 * pi) * 1.4
                : 0.0;

            return Transform.translate(
              offset: Offset(0, floatingOffset),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  _buildPulseAura(glowScale, glowOpacity),
                  _buildBreathingBackground(backgroundScale, backgroundOpacity),
                  _buildLeafLayer(
                    assetPath: widget.leavesLeftAssetPath,
                    angle: leafWave,
                    pivot: const Alignment(0.02, 0.27),
                  ),
                  _buildLeafLayer(
                    assetPath: widget.leavesRightAssetPath,
                    angle: -leafWave,
                    pivot: const Alignment(-0.02, 0.27),
                  ),
                  Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    alignment: _badgeCenterAlignment,
                    child: _alignedLayerPNG(widget.ringAssetPath),
                  ),
                  _alignedLayer(widget.coreAssetPath),
                  Align(
                    alignment: _badgeCenterAlignment,
                    child: FractionallySizedBox(
                      widthFactor: 0.35,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF16446F),
                            Color(0xFF2569A9),
                            Color(0xFF59ADFB),
                          ],
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          widget.level,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: widget.width * 0.18,
                            fontVariations: [
                              AppFontStyles.extraBoldFontVariation
                            ],
                            fontFamily: AppFontStyles.poppinsFamily,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _svgLayer(String assetPath) {
    return SvgPicture.asset(
      assetPath,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }

  Widget _buildLeafLayer({
    required String assetPath,
    required double angle,
    required Alignment pivot,
  }) {
    final leafLayer = ColorFiltered(
      colorFilter: ColorFilter.mode(const Color(0x22FFBF66), BlendMode.srcATop),
      child: _svgLayer(assetPath),
    );

    return Transform.rotate(angle: angle, alignment: pivot, child: leafLayer);
  }

  Widget _buildBreathingBackground(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      alignment: _badgeCenterAlignment,
      child: Opacity(
        opacity: opacity,
        child: _alignedLayer(widget.backgroundAssetPath),
      ),
    );
  }

  Widget _alignedLayer(String assetPath) {
    return SizedBox.expand(
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.fill,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _alignedLayerPNG(String assetPath) {
    return SizedBox.expand(
      child: Image.asset(
        assetPath,
        fit: BoxFit.fill,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildPulseAura(double scale, double opacity) {
    return Align(
      alignment: _badgeCenterAlignment,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity * 0.4,
          child: Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x4DFFE2A8),
                  Color(0x26B6D8FF),
                  Colors.transparent,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3AFFD69A),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
