import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/aim_test/core/aim_geometry.dart';
import 'package:reaction_time_test/features/aim_test/core/scene_projection.dart';
import 'package:reaction_time_test/features/aim_test/core/sensitivity.dart';
import 'package:reaction_time_test/features/aim_test/core/target_manager.dart';

void main() {
  group('CanvasSceneProjector', () {
    test('正前方目标球应投影到屏幕中心并具有透视半径', () {
      const projector = CanvasSceneProjector();
      const viewport = AimViewport(width: 800, height: 600);
      const target = AimTarget(
        id: 'target-1',
        position: Vec3(0, 0, 10),
        radiusMeters: 0.5,
        spawnedAtMs: 1000,
      );

      final projected = projector.projectTarget(
        target: target,
        camera: ViewAngles.zero,
        viewport: viewport,
      );

      expect(projected, isNotNull);
      expect(projected!.centerX, closeTo(400, 0.001));
      expect(projected.centerY, closeTo(300, 0.001));
      expect(projected.radiusPx, greaterThan(0));
      expect(projected.visible, isTrue);
    });

    test('指定屏幕半径时目标大小不随深度变化', () {
      const projector = CanvasSceneProjector();
      const viewport = AimViewport(width: 800, height: 600);
      const nearTarget = AimTarget(
        id: 'near-target',
        position: Vec3(0, 0, 6),
        radiusMeters: 0.5,
        screenRadiusPx: 22,
        spawnedAtMs: 1000,
      );
      const farTarget = AimTarget(
        id: 'far-target',
        position: Vec3(0, 0, 18),
        radiusMeters: 0.5,
        screenRadiusPx: 22,
        spawnedAtMs: 1000,
      );

      final nearProjected = projector.projectTarget(
        target: nearTarget,
        camera: ViewAngles.zero,
        viewport: viewport,
      );
      final farProjected = projector.projectTarget(
        target: farTarget,
        camera: ViewAngles.zero,
        viewport: viewport,
      );

      expect(nearProjected?.radiusPx, 22);
      expect(farProjected?.radiusPx, 22);
    });

    test('视角向右旋转时，正前方目标应出现在屏幕左侧', () {
      const projector = CanvasSceneProjector();
      const viewport = AimViewport(width: 800, height: 600);
      const target = AimTarget(
        id: 'target-1',
        position: Vec3(0, 0, 10),
        radiusMeters: 0.5,
        spawnedAtMs: 1000,
      );

      final projected = projector.projectTarget(
        target: target,
        camera: const ViewAngles(
          yawRadians: 10 * math.pi / 180,
          pitchRadians: 0,
        ),
        viewport: viewport,
      );

      expect(projected, isNotNull);
      expect(projected!.centerX, lessThan(400));
    });
  });
}
