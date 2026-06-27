import 'package:flutter/material.dart';

class SlotRevealChar extends StatelessWidget {
  const SlotRevealChar({
    super.key,
    required this.char,
    required this.progress,
    required this.style,
    required this.lineHeight,
  });

  final String char;
  final double progress;
  final TextStyle style;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: lineHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dy = constraints.maxHeight * (1.0 - clampedProgress);
              return Transform.translate(
                offset: Offset(0, dy),
                child: Text(char, style: style),
              );
            },
          ),
        ),
      ),
    );
  }
}
