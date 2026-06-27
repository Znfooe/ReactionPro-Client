import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_motion.dart';
import '../theme/splash_appearance_provider.dart';
import '../../shared/widgets/reactionpro_pattern.dart';

class SplitCurtainRouteTransition extends ConsumerWidget {
  const SplitCurtainRouteTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  static const _closeEnd = 3 / 7;
  static const _lineThickness = 2.0;

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(splashAppearanceProvider);
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        if (animation.status == AnimationStatus.reverse) {
          return child!;
        }

        final value = animation.value;
        final closing = const Interval(
          0,
          _closeEnd,
          curve: AppCurves.defaultEase,
        ).transform(value);
        final opening = const Interval(
          _closeEnd,
          1,
          curve: AppCurves.easeOutQuint,
        ).transform(value);
        final coverage = value <= _closeEnd ? closing : 1 - opening;

        return LayoutBuilder(
          builder: (context, constraints) {
            final panelHeight = constraints.maxHeight * coverage / 2;
            final showCurtain = coverage > 0.001;

            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: value < _closeEnd ? 0 : 1, child: child),
                if (showCurtain) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: panelHeight,
                    child: ReactionProPatternSurface(
                      appearance: appearance,
                      phase: value,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: panelHeight,
                    child: ReactionProPatternSurface(
                      appearance: appearance,
                      phase: value,
                      mirrorVertically: true,
                    ),
                  ),
                  Positioned(
                    top: panelHeight,
                    left: 0,
                    right: 0,
                    child: ColoredBox(
                      color: appearance.line,
                      child: const SizedBox(height: _lineThickness),
                    ),
                  ),
                  Positioned(
                    bottom: panelHeight,
                    left: 0,
                    right: 0,
                    child: ColoredBox(
                      color: appearance.line,
                      child: const SizedBox(height: _lineThickness),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
