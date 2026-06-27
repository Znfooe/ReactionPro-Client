import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/splash_appearance.dart';

class ReactionProPatternSurface extends StatelessWidget {
  const ReactionProPatternSurface({
    super.key,
    required this.appearance,
    this.phase = 0,
    this.mirrorVertically = false,
  });

  final SplashAppearance appearance;
  final double phase;
  final bool mirrorVertically;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: appearance.background,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ReactionProPatternPainter(
            phase: phase,
            mirrorVertically: mirrorVertically,
            appearance: appearance,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

final class _ReactionProPatternPainter extends CustomPainter {
  const _ReactionProPatternPainter({
    required this.phase,
    required this.mirrorVertically,
    required this.appearance,
  });

  static const _tileSize = AppSpacing.x10 * 4;
  static const _outerRadius = AppSpacing.x12;
  static const _innerRadius = AppSpacing.x6;
  static const _reticleGap = AppSpacing.x2;
  static const _reticleLength = AppSpacing.x5;

  final double phase;
  final bool mirrorVertically;
  final SplashAppearance appearance;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (mirrorVertically) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }

    final loopPhase = phase % 1;
    final drift = _tileSize * loopPhase;
    canvas.translate(drift - _tileSize, drift - _tileSize);

    final primaryPaint = Paint()
      ..color = appearance.line.withValues(alpha: 0.22)
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke;
    final secondaryPaint = Paint()
      ..color = appearance.outline.withValues(alpha: 0.30)
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke;

    final columns = (size.width / _tileSize).ceil() + 2;
    final rows = (size.height / _tileSize).ceil() + 2;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        _drawTile(
          canvas,
          Offset(column * _tileSize, row * _tileSize),
          primaryPaint,
          secondaryPaint,
          alternate: (row + column).isOdd,
        );
      }
    }
    canvas.restore();
  }

  void _drawTile(
    Canvas canvas,
    Offset origin,
    Paint primaryPaint,
    Paint secondaryPaint, {
    required bool alternate,
  }) {
    final center = origin + const Offset(_tileSize / 2, _tileSize / 2);
    final outerDiamond = Path()
      ..moveTo(center.dx, center.dy - _outerRadius)
      ..lineTo(center.dx + _outerRadius, center.dy)
      ..lineTo(center.dx, center.dy + _outerRadius)
      ..lineTo(center.dx - _outerRadius, center.dy)
      ..close();
    canvas.drawPath(outerDiamond, primaryPaint);

    final innerDiamond = Path()
      ..moveTo(center.dx, center.dy - _innerRadius)
      ..lineTo(center.dx + _innerRadius, center.dy)
      ..lineTo(center.dx, center.dy + _innerRadius)
      ..lineTo(center.dx - _innerRadius, center.dy)
      ..close();
    canvas.drawPath(innerDiamond, secondaryPaint);

    _drawReticle(canvas, center, primaryPaint);
    _drawChevrons(canvas, center, secondaryPaint, alternate: alternate);
    _drawCornerBrackets(canvas, origin, primaryPaint, alternate: alternate);
  }

  void _drawReticle(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(
      center.translate(-_reticleLength, 0),
      center.translate(-_reticleGap, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(_reticleGap, 0),
      center.translate(_reticleLength, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -_reticleLength),
      center.translate(0, -_reticleGap),
      paint,
    );
    canvas.drawLine(
      center.translate(0, _reticleGap),
      center.translate(0, _reticleLength),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: AppSpacing.x2,
        height: AppSpacing.x2,
      ),
      paint,
    );
  }

  void _drawChevrons(
    Canvas canvas,
    Offset center,
    Paint paint, {
    required bool alternate,
  }) {
    final direction = alternate ? -1.0 : 1.0;
    final upper = Path()
      ..moveTo(center.dx - AppSpacing.x8, center.dy - AppSpacing.x10)
      ..lineTo(center.dx, center.dy - AppSpacing.x16)
      ..lineTo(center.dx + AppSpacing.x8, center.dy - AppSpacing.x10);
    final lower = Path()
      ..moveTo(center.dx - AppSpacing.x8, center.dy + AppSpacing.x10)
      ..lineTo(center.dx, center.dy + AppSpacing.x16)
      ..lineTo(center.dx + AppSpacing.x8, center.dy + AppSpacing.x10);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(direction, 1);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(upper, paint);
    canvas.drawPath(lower, paint);
    canvas.restore();
  }

  void _drawCornerBrackets(
    Canvas canvas,
    Offset origin,
    Paint paint, {
    required bool alternate,
  }) {
    final inset = AppSpacing.x4;
    final length = alternate ? AppSpacing.x8 : AppSpacing.x6;
    final left = origin.dx + inset;
    final top = origin.dy + inset;
    final right = origin.dx + _tileSize - inset;
    final bottom = origin.dy + _tileSize - inset;

    canvas.drawLine(Offset(left, top), Offset(left + length, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + length), paint);
    canvas.drawLine(Offset(right, top), Offset(right - length, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + length), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + length, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - length), paint);
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right - length, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReactionProPatternPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.mirrorVertically != mirrorVertically ||
        oldDelegate.appearance != appearance;
  }
}
