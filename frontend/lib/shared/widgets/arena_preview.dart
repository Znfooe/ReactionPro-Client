import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';

class ArenaPreview extends StatelessWidget {
  const ArenaPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return RepaintBoundary(
      child: Container(
        height: AppSpacing.x10 * 8,
        decoration: BoxDecoration(
          color: extension.bgMuted,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: extension.borderMuted),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _ArenaPreviewPainter(
            primary: colors.primary,
            surface: colors.surfaceContainer,
            border: extension.borderMuted,
            muted: extension.textTertiary,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ArenaPreviewPainter extends CustomPainter {
  const _ArenaPreviewPainter({
    required this.primary,
    required this.surface,
    required this.border,
    required this.muted,
  });

  final Color primary;
  final Color surface;
  final Color border;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = border.withValues(alpha: 0.52)
      ..strokeWidth = 1;
    final horizonPaint = Paint()
      ..color = primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final targetPaint = Paint()..color = AppColors.testTargetColor;
    final targetMutedPaint = Paint()
      ..color = AppColors.testTargetColor.withValues(alpha: 0.78);
    final surfacePaint = Paint()..color = surface;
    final waitPaint = Paint()
      ..color = AppColors.testWaitBg.withValues(alpha: 0.18);
    final crosshairPaint = Paint()
      ..color = primary
      ..strokeWidth = AppSpacing.x1 / 2
      ..strokeCap = StrokeCap.square;
    final ghostPaint = Paint()
      ..color = muted.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.x1 / 4;

    final center = Offset(size.width * 0.52, size.height * 0.48);
    final gridStep = AppSpacing.x8;

    for (var x = -size.width; x < size.width * 2; x += gridStep) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(size.width / 2, size.height * 0.44),
        gridPaint,
      );
    }
    for (var y = size.height * 0.52; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final horizon = Path()
      ..moveTo(0, size.height * 0.44)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.36,
        size.width * 0.74,
        size.height * 0.52,
        size.width,
        size.height * 0.42,
      );
    canvas.drawPath(horizon, horizonPaint);

    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.30),
      AppSpacing.x10,
      waitPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.34),
      AppSpacing.x6,
      targetPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.70),
      AppSpacing.x4,
      targetMutedPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.66),
      AppSpacing.x3,
      surfacePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.66),
      AppSpacing.x3,
      ghostPaint,
    );

    final gap = AppSpacing.x2;
    final arm = AppSpacing.x5;
    canvas.drawLine(
      center.translate(-gap - arm, 0),
      center.translate(-gap, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center.translate(gap, 0),
      center.translate(gap + arm, 0),
      crosshairPaint,
    );
    canvas.drawLine(
      center.translate(0, -gap - arm),
      center.translate(0, -gap),
      crosshairPaint,
    );
    canvas.drawLine(
      center.translate(0, gap),
      center.translate(0, gap + arm),
      crosshairPaint,
    );
    canvas.drawCircle(center, AppSpacing.x1 / 2, crosshairPaint);

    final ringRect = Rect.fromCircle(center: center, radius: AppSpacing.x10);
    canvas.drawArc(ringRect, -math.pi / 3, math.pi * 1.35, false, ghostPaint);
  }

  @override
  bool shouldRepaint(covariant _ArenaPreviewPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.surface != surface ||
        oldDelegate.border != border ||
        oldDelegate.muted != muted;
  }
}
