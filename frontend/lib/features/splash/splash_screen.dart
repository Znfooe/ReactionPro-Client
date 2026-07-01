import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/splash_appearance.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/reactionpro_pattern.dart';
import 'slot_reveal_char.dart';

enum SplashPhase { loading, collapsing, expanding, completed }

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.loadingFuture,
    required this.appearance,
    required this.child,
  });

  final Future<void> loadingFuture;
  final SplashAppearance appearance;
  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _text = 'ZNFOOE 2026';
  static const _fontFamilies = [
    'CangErYuMoW01',
    'CangErYuMoW02',
    'CangErYuMoW03',
    'CangErYuMoW04',
    'CangErYuMoW05',
  ];
  static const _loopDuration = AppDurations.splashLoop;
  static const _collapseDuration = AppDurations.splashCollapse;
  static const _expandDuration = AppDurations.splashExpand;
  static const _charDelayStep = Duration(milliseconds: 80);
  static const _charDuration = Duration(milliseconds: 400);
  static const _lineHeight = AppTypography.splashRevealLineHeight;
  static const _lineThickness = 2.0;
  static const _spaceWidth = AppTypography.text5xl * 0.4;

  late final AnimationController _controller;
  late final String _fontFamily;
  SplashPhase _phase = SplashPhase.loading;
  bool _loadingComplete = false;

  @override
  void initState() {
    super.initState();
    _fontFamily = _fontFamilies[Random().nextInt(_fontFamilies.length)];
    _controller = AnimationController(vsync: this, duration: _loopDuration);
    _startLoadingLoop();
    widget.loadingFuture.then<void>(
      (_) => _loadingComplete = true,
      onError: (_) => _loadingComplete = true,
    );
  }

  void _startLoadingLoop() {
    _controller.forward(from: 0).then((_) {
      if (!mounted || _phase != SplashPhase.loading) {
        return;
      }
      if (_loadingComplete) {
        _startCollapse();
        return;
      }
      _startLoadingLoop();
    });
  }

  void _startCollapse() {
    setState(() => _phase = SplashPhase.collapsing);
    _controller.duration = _collapseDuration;
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        _startExpand();
      }
    });
  }

  void _startExpand() {
    setState(() => _phase = SplashPhase.expanding);
    _controller.duration = _expandDuration;
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _phase = SplashPhase.completed);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_phase != SplashPhase.completed) _buildAnimationLayer(context),
      ],
    );
  }

  Widget _buildAnimationLayer(BuildContext context) {
    return switch (_phase) {
      SplashPhase.loading => _buildLoadingAnimation(context),
      SplashPhase.collapsing => _buildCollapseAnimation(context),
      SplashPhase.expanding => _buildExpandAnimation(context),
      SplashPhase.completed => const SizedBox.shrink(),
    };
  }

  Widget _buildLoadingAnimation(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ReactionProPatternSurface(
              appearance: widget.appearance,
              phase: _controller.value,
            );
          },
        ),
        Center(
          child: Semantics(
            label: _text,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final scale = _loadingScale(t);
                final opacity = _loadingOpacity(t);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: _buildSlotRevealText(context, t),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapseAnimation(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = AppCurves.defaultEase.transform(_controller.value);
        final scaleY = (1.0 - progress).clamp(0.001, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 1 - progress * 0.48,
              child: ReactionProPatternSurface(
                appearance: widget.appearance,
                phase: progress,
              ),
            ),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1.0 - progress,
                    child: Transform.scale(
                      scaleX: 1,
                      scaleY: scaleY,
                      child: _buildStaticSplashText(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandAnimation(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = AppCurves.easeOutQuint.transform(_controller.value);
        final openingHeight =
            _lineThickness + (screenSize.height - _lineThickness) * progress;
        final panelHeight = ((screenSize.height - openingHeight) / 2).clamp(
          0.0,
          screenSize.height / 2,
        );

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: panelHeight,
              child: ReactionProPatternSurface(
                appearance: widget.appearance,
                phase: progress,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: panelHeight,
              child: ReactionProPatternSurface(
                appearance: widget.appearance,
                phase: progress,
                mirrorVertically: true,
              ),
            ),
            if (progress < 1)
              Positioned(
                top: panelHeight,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: widget.appearance.line,
                  child: const SizedBox(height: _lineThickness),
                ),
              ),
            if (progress < 1)
              Positioned(
                bottom: panelHeight,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: widget.appearance.line,
                  child: const SizedBox(height: _lineThickness),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSlotRevealText(BuildContext context, double t) {
    final fillStyle = _splashTextStyle();
    final strokeStyle = _splashStrokeTextStyle();
    final chars = _text.split('');

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _buildSlotRevealRow(chars, t, strokeStyle),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [widget.appearance.textStart, widget.appearance.textEnd],
          ).createShader(bounds),
          child: _buildSlotRevealRow(chars, t, fillStyle),
        ),
      ],
    );
  }

  Widget _buildSlotRevealRow(List<String> chars, double t, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          if (chars[i] == ' ')
            const SizedBox(width: _spaceWidth)
          else
            SlotRevealChar(
              char: chars[i],
              progress: _charProgress(index: i, controllerValue: t),
              style: style,
              lineHeight: _lineHeight,
            ),
      ],
    );
  }

  Widget _buildStaticSplashText() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          _text,
          style: _splashStrokeTextStyle(),
          textAlign: TextAlign.center,
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [widget.appearance.textStart, widget.appearance.textEnd],
          ).createShader(bounds),
          child: Text(
            _text,
            style: _splashTextStyle(),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  TextStyle _splashTextStyle() {
    return TextStyle(
      color: Colors.white,
      fontFamily: _fontFamily,
      fontFamilyFallback: AppTypography.fontFallback,
      fontSize: AppTypography.text5xl,
      fontWeight: AppTypography.fontWeightBold,
      height: AppTypography.line5xl / AppTypography.text5xl,
      letterSpacing: AppTypography.splashLetterSpacing,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
      decorationThickness: 0,
    );
  }

  TextStyle _splashStrokeTextStyle() {
    return _splashTextStyle().copyWith(
      foreground: ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = AppTypography.splashOutlineWidth
        ..strokeJoin = ui.StrokeJoin.round
        ..color = widget.appearance.outline,
    );
  }

  double _charProgress({required int index, required double controllerValue}) {
    final delayMs = index * _charDelayStep.inMilliseconds;
    final durationMs = _charDuration.inMilliseconds;
    final totalMs = _loopDuration.inMilliseconds;
    final begin = (delayMs / totalMs).clamp(0.0, 0.5);
    final end = ((delayMs + durationMs) / totalMs).clamp(0.0, 0.5);
    final interval = Interval(begin, end, curve: AppCurves.easeOutQuint);
    return interval.transform(controllerValue);
  }

  double _loadingScale(double t) {
    if (t < 0.667) {
      return 1;
    }
    if (t < 0.833) {
      final localT = (t - 0.667) / (0.833 - 0.667);
      return 1 - 0.2 * AppCurves.defaultEase.transform(localT);
    }
    return 0.8;
  }

  double _loadingOpacity(double t) {
    if (t < 0.833) {
      return 1;
    }
    final localT = (t - 0.833) / (1 - 0.833);
    return 1 - AppCurves.easeIn.transform(localT);
  }
}
