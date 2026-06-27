import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/aim_test/core/aim_geometry.dart';
import 'package:reaction_time_test/features/aim_test/core/target_manager.dart';
import 'package:reaction_time_test/features/aim_test/core/sensitivity.dart';

void main() {
  group('AimTargetManager', () {
    test('center crosshair hit records raw and calibrated kill time', () {
      final manager = AimTargetManager(
        config: const AimTestConfig(totalTargetCount: 2),
        spawner: SequenceTargetSpawner(const [Vec3(0, 0, 10), Vec3(3, 0, 10)]),
      );

      manager.start(nowMs: 1000);

      final result = manager.handleShot(
        nowMs: 1250,
        camera: ViewAngles.zero,
        viewport: const AimViewport(width: 800, height: 600),
        estimatedRenderDelayMs: 16,
        estimatedInputDelayMs: 8,
      );

      expect(result.hit, isTrue);
      expect(result.rawKillTimeMs, 250);
      expect(result.calibratedKillTimeMs, 226);
      expect(manager.state.hits, 1);
      expect(manager.state.misses, 0);
      expect(manager.state.activeTargets.single.position, const Vec3(3, 0, 10));
    });

    test('empty shot counts toward error rate without consuming target', () {
      final manager = AimTargetManager(
        config: const AimTestConfig(totalTargetCount: 1),
        spawner: SequenceTargetSpawner(const [Vec3(3, 0, 10)]),
      );

      manager.start(nowMs: 1000);
      final result = manager.handleShot(
        nowMs: 1100,
        camera: ViewAngles.zero,
        viewport: const AimViewport(width: 800, height: 600),
      );

      expect(result.hit, isFalse);
      expect(manager.state.hits, 0);
      expect(manager.state.misses, 1);
      expect(manager.state.totalShots, 1);
      expect(manager.state.activeTargets.length, 1);
      expect(manager.summary.hitRate, 0);
      expect(manager.summary.errorRate, 1);
    });

    test('shot can use an explicit aim point for touch aim', () {
      final viewport = const AimViewport(width: 800, height: 600);
      final manager = AimTargetManager(
        config: const AimTestConfig(totalTargetCount: 1),
        spawner: SequenceTargetSpawner(const [Vec3(3, 0, 10)]),
      );

      manager.start(nowMs: 1000);
      final projected = manager
          .projectedTargets(camera: ViewAngles.zero, viewport: viewport)
          .single;

      expect(projected.contains(viewport.centerX, viewport.centerY), isFalse);

      final result = manager.handleShot(
        nowMs: 1120,
        camera: ViewAngles.zero,
        viewport: viewport,
        aimX: projected.centerX,
        aimY: projected.centerY,
      );

      expect(result.hit, isTrue);
      expect(manager.state.hits, 1);
      expect(manager.state.phase, AimSessionPhase.completed);
    });

    test('advance keeps targets alive until they are hit', () {
      final manager = AimTargetManager(
        config: const AimTestConfig(
          totalTargetCount: 3,
          targetLifetimeMs: 1500,
        ),
        spawner: SequenceTargetSpawner(const [
          Vec3(0, 0, 10),
          Vec3(1, 0, 10),
          Vec3(2, 0, 10),
        ]),
      );

      manager.start(nowMs: 0);
      manager.advance(nowMs: 60000);

      expect(manager.state.timedOutTargets, 0);
      expect(manager.state.activeTargets.single.position, const Vec3(0, 0, 10));
      expect(manager.state.phase, AimSessionPhase.running);
    });

    test('count-based session completes only after configured hits', () {
      final manager = AimTargetManager(
        config: const AimTestConfig(totalTargetCount: 1, targetLifetimeMs: 100),
        spawner: SequenceTargetSpawner(const [Vec3(0, 0, 10)]),
      );

      manager.start(nowMs: 0);
      manager.advance(nowMs: 60000);
      expect(manager.state.phase, AimSessionPhase.running);

      manager.handleShot(
        nowMs: 60100,
        camera: ViewAngles.zero,
        viewport: const AimViewport(width: 800, height: 600),
      );

      expect(manager.state.phase, AimSessionPhase.completed);
      expect(manager.state.activeTargets, isEmpty);
      expect(manager.summary.timedOutTargets, 0);
      expect(manager.summary.hitRate, 1);
    });

    test('count config follows spec presets and custom range', () {
      final spec = AimTestConfig.count(
        targetCount: 15,
        targetMode: AimTargetMode.multi,
        activeTargetCount: 3,
        targetSize: AimTargetSizePreset.small,
      );
      final clamped = AimTestConfig.count(targetCount: 240);

      expect(spec.evaluationMode, AimEvaluationMode.count);
      expect(spec.totalTargetCount, 15);
      expect(spec.activeTargetCount, 3);
      expect(
        spec.targetRadiusMeters,
        lessThan(AimTestConfig.mediumRadiusMeters),
      );
      expect(clamped.totalTargetCount, 120);
      expect(spec.targetLifetimeMs, 0);
    });

    test(
      'time-based session completes when the configured duration elapses',
      () {
        final manager = AimTargetManager(
          config: AimTestConfig.timed(durationSeconds: 10),
          spawner: SequenceTargetSpawner(const [
            Vec3(0, 0, 10),
            Vec3(1, 0, 10),
          ]),
        );

        manager.start(nowMs: 0);
        manager.advance(nowMs: 9999);
        expect(manager.state.phase, AimSessionPhase.running);

        manager.advance(nowMs: 10000);

        expect(manager.state.phase, AimSessionPhase.completed);
        expect(manager.state.activeTargets, isEmpty);
        expect(manager.summary.killsPerSecond, 0);
        expect(manager.summary.killsPerMinute, 0);
      },
    );

    test('multi target mode maintains configured active targets', () {
      final manager = AimTargetManager(
        config: AimTestConfig.count(
          targetCount: 5,
          targetMode: AimTargetMode.multi,
          activeTargetCount: 3,
        ),
        spawner: SequenceTargetSpawner(const [
          Vec3(-2, 0, 10),
          Vec3(0, 0, 10),
          Vec3(2, 0, 10),
          Vec3(3, 0, 10),
        ]),
      );

      manager.start(nowMs: 0);

      expect(manager.state.activeTargets.length, 3);
    });
  });
}
