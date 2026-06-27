import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

final class CrosshairStyle {
  const CrosshairStyle({
    this.length = 18,
    this.thickness = 2,
    this.gap = 7,
    this.color = AppColors.testCrosshairDefault,
    this.dot = true,
    this.dotSize = 3,
    this.outline = true,
    this.outlineThickness = 2,
    this.outlineColor = Colors.black,
    this.tStyle = false,
    this.dynamicSpread = false,
  });

  final double length;
  final double thickness;
  final double gap;
  final Color color;
  final bool dot;
  final double dotSize;
  final bool outline;
  final double outlineThickness;
  final Color outlineColor;
  final bool tStyle;
  final bool dynamicSpread;

  CrosshairStyle copyWith({
    double? length,
    double? thickness,
    double? gap,
    Color? color,
    bool? dot,
    double? dotSize,
    bool? outline,
    double? outlineThickness,
    Color? outlineColor,
    bool? tStyle,
    bool? dynamicSpread,
  }) {
    return CrosshairStyle(
      length: length ?? this.length,
      thickness: thickness ?? this.thickness,
      gap: gap ?? this.gap,
      color: color ?? this.color,
      dot: dot ?? this.dot,
      dotSize: dotSize ?? this.dotSize,
      outline: outline ?? this.outline,
      outlineThickness: outlineThickness ?? this.outlineThickness,
      outlineColor: outlineColor ?? this.outlineColor,
      tStyle: tStyle ?? this.tStyle,
      dynamicSpread: dynamicSpread ?? this.dynamicSpread,
    );
  }
}

class Crosshair extends StatelessWidget {
  const Crosshair({
    required this.style,
    this.dynamicSpreadPx = 0,
    this.centerOffset = Offset.zero,
    super.key,
  });

  final CrosshairStyle style;
  final double dynamicSpreadPx;
  final Offset centerOffset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CrosshairPainter(style, dynamicSpreadPx, centerOffset),
        child: const SizedBox.expand(),
      ),
    );
  }
}

final class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter(this.style, this.dynamicSpreadPx, this.centerOffset);

  final CrosshairStyle style;
  final double dynamicSpreadPx;
  final Offset centerOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + centerOffset;
    if (style.outline) {
      _drawLines(
        canvas,
        center,
        Paint()
          ..color = style.outlineColor.withValues(alpha: 0.82)
          ..strokeWidth = style.thickness + style.outlineThickness * 2
          ..strokeCap = StrokeCap.square,
        drawDot: style.dot,
        dotSize: style.dotSize + style.outlineThickness * 2,
      );
    }
    _drawLines(
      canvas,
      center,
      Paint()
        ..color = style.color
        ..strokeWidth = style.thickness
        ..strokeCap = StrokeCap.square,
      drawDot: style.dot,
      dotSize: style.dotSize,
    );
  }

  void _drawLines(
    Canvas canvas,
    Offset center,
    Paint paint, {
    required bool drawDot,
    required double dotSize,
  }) {
    final gap = style.gap + (style.dynamicSpread ? dynamicSpreadPx : 0);
    canvas.drawLine(
      center.translate(-gap - style.length, 0),
      center.translate(-gap, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(gap, 0),
      center.translate(gap + style.length, 0),
      paint,
    );
    if (!style.tStyle) {
      canvas.drawLine(
        center.translate(0, -gap - style.length),
        center.translate(0, -gap),
        paint,
      );
    }
    canvas.drawLine(
      center.translate(0, gap),
      center.translate(0, gap + style.length),
      paint,
    );
    if (drawDot) {
      canvas.drawCircle(center, dotSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.dynamicSpreadPx != dynamicSpreadPx ||
        oldDelegate.centerOffset != centerOffset;
  }
}
