import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../core/aim_geometry.dart';
import '../core/scene_projection.dart';
import '../core/sensitivity.dart';
import '../core/target_manager.dart';

enum AimRendererMode { canvas, flutterScene }

class AimSceneRenderer extends StatelessWidget {
  const AimSceneRenderer({
    required this.manager,
    required this.camera,
    required this.nowMs,
    required this.backgroundColor,
    required this.gridColor,
    required this.gridOpacity,
    required this.gridStrokeWidth,
    required this.gridSpacingPx,
    required this.gridLineCount,
    required this.targetColor,
    required this.targetOutlineColor,
    required this.showTargetOutline,
    required this.mode,
    super.key,
  });

  final AimTargetManager manager;
  final ViewAngles camera;
  final double nowMs;
  final Color backgroundColor;
  final Color gridColor;
  final double gridOpacity;
  final double gridStrokeWidth;
  final double gridSpacingPx;
  final int gridLineCount;
  final Color targetColor;
  final Color targetOutlineColor;
  final bool showTargetOutline;
  final AimRendererMode mode;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: switch (mode) {
          AimRendererMode.canvas => AimScenePainter(
            manager: manager,
            camera: camera,
            nowMs: nowMs,
            backgroundColor: backgroundColor,
            gridColor: gridColor,
            gridOpacity: gridOpacity,
            gridStrokeWidth: gridStrokeWidth,
            gridSpacingPx: gridSpacingPx,
            gridLineCount: gridLineCount,
            targetColor: targetColor,
            targetOutlineColor: targetOutlineColor,
            showTargetOutline: showTargetOutline,
          ),
          AimRendererMode.flutterScene => FlutterSceneCompatiblePainter(
            manager: manager,
            camera: camera,
            nowMs: nowMs,
            backgroundColor: backgroundColor,
            gridColor: gridColor,
            gridOpacity: gridOpacity,
            gridStrokeWidth: gridStrokeWidth,
            gridSpacingPx: gridSpacingPx,
            gridLineCount: gridLineCount,
            targetColor: targetColor,
            targetOutlineColor: targetOutlineColor,
            showTargetOutline: showTargetOutline,
          ),
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

final class AimScenePainter extends CustomPainter {
  const AimScenePainter({
    required this.manager,
    required this.camera,
    required this.nowMs,
    required this.backgroundColor,
    required this.gridColor,
    required this.gridOpacity,
    required this.gridStrokeWidth,
    required this.gridSpacingPx,
    required this.gridLineCount,
    required this.targetColor,
    required this.targetOutlineColor,
    required this.showTargetOutline,
  });

  final AimTargetManager manager;
  final ViewAngles camera;
  final double nowMs;
  final Color backgroundColor;
  final Color gridColor;
  final double gridOpacity;
  final double gridStrokeWidth;
  final double gridSpacingPx;
  final int gridLineCount;
  final Color targetColor;
  final Color targetOutlineColor;
  final bool showTargetOutline;

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = AimViewport(width: size.width, height: size.height);
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    _drawFlatGrid(canvas, size);

    final projectedTargets = manager.projectedTargets(
      camera: camera,
      viewport: viewport,
    )..sort((a, b) => b.depth.compareTo(a.depth));

    for (final target in projectedTargets) {
      if (!target.visible) {
        continue;
      }
      _drawTarget(canvas, target);
    }
  }

  void _drawFlatGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: gridOpacity.clamp(0, 1))
      ..strokeWidth = gridStrokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final spacing = gridSpacingPx.clamp(AppSpacing.x2, size.longestSide);
    final lineCount = gridLineCount.clamp(2, 32);

    for (var i = -lineCount; i <= lineCount; i++) {
      final x = center.dx + i * spacing;
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      final y = center.dy + i * spacing;
      if (y >= 0 && y <= size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  void _drawTarget(Canvas canvas, ProjectedTarget projected) {
    final center = Offset(projected.centerX, projected.centerY);
    final spawnProgress = Curves.easeOut.transform(
      manager.spawnProgress(projected.target, nowMs),
    );
    final lifetimeProgress = manager.lifetimeProgress(projected.target, nowMs);
    final radius = projected.radiusPx * (0.82 + spawnProgress * 0.18);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22 * spawnProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final targetPaint = Paint()
      ..color = targetColor.withValues(alpha: spawnProgress);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * spawnProgress)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = targetOutlineColor.withValues(alpha: 0.82 * spawnProgress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final lifetimePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.62 * spawnProgress)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center.translate(0, radius * 0.16),
      radius * 1.05,
      shadowPaint,
    );
    canvas.drawCircle(center, radius, targetPaint);
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.30),
      radius * 0.24,
      highlightPaint,
    );
    if (showTargetOutline) {
      canvas.drawCircle(center, radius, borderPaint);
    }
    if (lifetimeProgress < 1) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + AppSpacing.x1),
        -math.pi / 2,
        math.pi * 2 * (1 - lifetimeProgress),
        false,
        lifetimePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AimScenePainter oldDelegate) {
    return oldDelegate.manager.state != manager.state ||
        oldDelegate.camera != camera ||
        oldDelegate.nowMs != nowMs ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.gridOpacity != gridOpacity ||
        oldDelegate.gridStrokeWidth != gridStrokeWidth ||
        oldDelegate.gridSpacingPx != gridSpacingPx ||
        oldDelegate.gridLineCount != gridLineCount ||
        oldDelegate.targetColor != targetColor ||
        oldDelegate.targetOutlineColor != targetOutlineColor ||
        oldDelegate.showTargetOutline != showTargetOutline;
  }
}

final class FlutterSceneCompatiblePainter extends AimScenePainter {
  const FlutterSceneCompatiblePainter({
    required super.manager,
    required super.camera,
    required super.nowMs,
    required super.backgroundColor,
    required super.gridColor,
    required super.gridOpacity,
    required super.gridStrokeWidth,
    required super.gridSpacingPx,
    required super.gridLineCount,
    required super.targetColor,
    required super.targetOutlineColor,
    required super.showTargetOutline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = AimViewport(width: size.width, height: size.height);
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          backgroundColor,
          Color.alphaBlend(
            gridColor.withValues(alpha: (gridOpacity * 0.72).clamp(0, 1)),
            backgroundColor,
          ),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    _drawDepthRoom(canvas, size);

    final projectedTargets = manager.projectedTargets(
      camera: camera,
      viewport: viewport,
    )..sort((a, b) => b.depth.compareTo(a.depth));

    for (final target in projectedTargets) {
      if (target.visible) {
        _drawVolumetricTarget(canvas, target);
      }
    }
  }

  void _drawDepthRoom(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final paint = Paint()
      ..color = gridColor.withValues(alpha: gridOpacity.clamp(0, 1))
      ..strokeWidth = gridStrokeWidth;
    final lineCount = gridLineCount.clamp(2, 32);
    for (var i = 1; i <= lineCount; i++) {
      final scale = i / lineCount;
      final width = size.width * (0.12 + scale * 0.82);
      final height = size.height * (0.08 + scale * 0.62);
      final rect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );
      canvas.drawRect(rect, paint);
    }
    for (var i = -lineCount; i <= lineCount; i++) {
      final x = center.dx + i * gridSpacingPx - camera.yawRadians * 80;
      canvas.drawLine(Offset(x, 0), center, paint);
      canvas.drawLine(center, Offset(x, size.height), paint);
    }
  }

  void _drawVolumetricTarget(Canvas canvas, ProjectedTarget projected) {
    final center = Offset(projected.centerX, projected.centerY);
    final spawnProgress = Curves.easeOutCubic.transform(
      manager.spawnProgress(projected.target, nowMs),
    );
    final radius = projected.radiusPx * (0.78 + spawnProgress * 0.22);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28 * spawnProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.34, -0.42),
        radius: 0.9,
        colors: [
          Color.alphaBlend(
            Colors.white.withValues(alpha: 0.44),
            targetColor,
          ).withValues(alpha: spawnProgress),
          targetColor.withValues(alpha: spawnProgress),
          Color.alphaBlend(
            Colors.black.withValues(alpha: 0.34),
            targetColor,
          ).withValues(alpha: spawnProgress),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    final rimPaint = Paint()
      ..color = targetOutlineColor.withValues(alpha: 0.74 * spawnProgress)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.72),
        width: radius * 1.72,
        height: radius * 0.32,
      ),
      shadowPaint,
    );
    canvas.drawCircle(center, radius, spherePaint);
    if (showTargetOutline) {
      canvas.drawCircle(center, radius, rimPaint);
    }
    canvas.drawCircle(
      center.translate(-radius * 0.26, -radius * 0.30),
      radius * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.46 * spawnProgress),
    );
  }
}
