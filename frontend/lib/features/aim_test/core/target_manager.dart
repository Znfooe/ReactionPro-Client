import 'dart:math' as math;

import '../../../core/precision/precision_timing.dart';
import '../../reaction_test/core/timing_engine.dart';
import 'aim_geometry.dart';
import 'scene_projection.dart';
import 'sensitivity.dart';

enum AimSessionPhase { idle, running, completed }

enum AimTestMode { evaluation, targetSequence }

enum AimDifficulty { easy, normal, hard }

enum AimEvaluationMode { count, timed }

enum AimTargetMode { single, multi }

enum AimTargetBehavior { static, moving }

enum AimMovementPattern { bounce, random }

enum AimTargetSizePreset { small, medium, large, custom }

final class AimTestConfig {
  const AimTestConfig({
    this.evaluationMode = AimEvaluationMode.count,
    this.mode = AimTestMode.evaluation,
    this.difficulty = AimDifficulty.normal,
    this.totalTargetCount = 10,
    this.durationSeconds = 20,
    this.targetMode = AimTargetMode.single,
    this.activeTargetCount = 1,
    this.targetBehavior = AimTargetBehavior.static,
    this.movementPattern = AimMovementPattern.bounce,
    this.movementSpeedMetersPerSecond = mediumMovementSpeedMetersPerSecond,
    this.targetSize = AimTargetSizePreset.medium,
    this.targetRadiusMeters = mediumRadiusMeters,
    this.targetRadiusPx = mediumRadiusPx,
    this.targetLifetimeMs = 0,
    this.spawnFadeInMs = 150,
    this.minTargetDistanceMeters = 6,
    this.maxTargetDistanceMeters = 15,
    this.horizontalSpreadMeters = 4.4,
    this.verticalSpreadMeters = 2.4,
  });

  factory AimTestConfig.count({
    int targetCount = 10,
    AimTargetMode targetMode = AimTargetMode.single,
    int activeTargetCount = 1,
    AimTargetBehavior targetBehavior = AimTargetBehavior.static,
    AimMovementPattern movementPattern = AimMovementPattern.bounce,
    double movementSpeedMetersPerSecond = mediumMovementSpeedMetersPerSecond,
    AimTargetSizePreset targetSize = AimTargetSizePreset.medium,
    double customRadiusMeters = mediumRadiusMeters,
    double customRadiusPx = mediumRadiusPx,
  }) {
    return AimTestConfig(
      evaluationMode: AimEvaluationMode.count,
      totalTargetCount: normalizeCount(targetCount),
      durationSeconds: 0,
      targetMode: targetMode,
      activeTargetCount: normalizeActiveTargetCount(
        targetMode,
        activeTargetCount,
      ),
      targetBehavior: targetBehavior,
      movementPattern: movementPattern,
      movementSpeedMetersPerSecond: movementSpeedMetersPerSecond,
      targetSize: targetSize,
      targetRadiusMeters: radiusForSize(
        targetSize,
        customRadiusMeters: customRadiusMeters,
      ),
      targetRadiusPx: radiusPxForSize(
        targetSize,
        customRadiusPx: customRadiusPx,
      ),
    );
  }

  factory AimTestConfig.timed({
    int durationSeconds = 20,
    AimTargetMode targetMode = AimTargetMode.single,
    int activeTargetCount = 1,
    AimTargetBehavior targetBehavior = AimTargetBehavior.static,
    AimMovementPattern movementPattern = AimMovementPattern.bounce,
    double movementSpeedMetersPerSecond = mediumMovementSpeedMetersPerSecond,
    AimTargetSizePreset targetSize = AimTargetSizePreset.medium,
    double customRadiusMeters = mediumRadiusMeters,
    double customRadiusPx = mediumRadiusPx,
  }) {
    return AimTestConfig(
      evaluationMode: AimEvaluationMode.timed,
      totalTargetCount: 0,
      durationSeconds: normalizeDurationSeconds(durationSeconds),
      targetMode: targetMode,
      activeTargetCount: normalizeActiveTargetCount(
        targetMode,
        activeTargetCount,
      ),
      targetBehavior: targetBehavior,
      movementPattern: movementPattern,
      movementSpeedMetersPerSecond: movementSpeedMetersPerSecond,
      targetSize: targetSize,
      targetRadiusMeters: radiusForSize(
        targetSize,
        customRadiusMeters: customRadiusMeters,
      ),
      targetRadiusPx: radiusPxForSize(
        targetSize,
        customRadiusPx: customRadiusPx,
      ),
    );
  }

  factory AimTestConfig.preset({
    AimTestMode mode = AimTestMode.evaluation,
    AimDifficulty difficulty = AimDifficulty.normal,
    int? totalTargetCount,
  }) {
    return switch (difficulty) {
      AimDifficulty.easy => AimTestConfig(
        mode: mode,
        difficulty: difficulty,
        totalTargetCount: totalTargetCount ?? 15,
        activeTargetCount: 1,
        targetRadiusMeters: 0.55,
        targetLifetimeMs: 0,
        minTargetDistanceMeters: 5,
        maxTargetDistanceMeters: 11,
        horizontalSpreadMeters: 3.6,
        verticalSpreadMeters: 1.8,
      ),
      AimDifficulty.normal => AimTestConfig(
        mode: mode,
        difficulty: difficulty,
        totalTargetCount: totalTargetCount ?? 30,
        activeTargetCount: 1,
        targetRadiusMeters: 0.45,
        targetLifetimeMs: 0,
        minTargetDistanceMeters: 6,
        maxTargetDistanceMeters: 15,
        horizontalSpreadMeters: 4.4,
        verticalSpreadMeters: 2.4,
      ),
      AimDifficulty.hard => AimTestConfig(
        mode: mode,
        difficulty: difficulty,
        totalTargetCount: totalTargetCount ?? 45,
        activeTargetCount: mode == AimTestMode.evaluation ? 2 : 1,
        targetRadiusMeters: 0.34,
        targetLifetimeMs: 0,
        minTargetDistanceMeters: 8,
        maxTargetDistanceMeters: 18,
        horizontalSpreadMeters: 5.4,
        verticalSpreadMeters: 3,
      ),
    };
  }

  static const smallRadiusMeters = 0.32;
  static const mediumRadiusMeters = 0.45;
  static const largeRadiusMeters = 0.62;
  static const smallRadiusPx = 16.0;
  static const mediumRadiusPx = 24.0;
  static const largeRadiusPx = 32.0;
  static const slowMovementSpeedMetersPerSecond = 0.8;
  static const mediumMovementSpeedMetersPerSecond = 1.6;
  static const fastMovementSpeedMetersPerSecond = 2.8;

  static int normalizeCount(int value) => value.clamp(1, 120).toInt();

  static int normalizeDurationSeconds(int value) => value.clamp(1, 120).toInt();

  static int normalizeActiveTargetCount(AimTargetMode mode, int value) {
    if (mode == AimTargetMode.single) {
      return 1;
    }
    return value.clamp(2, 120).toInt();
  }

  static double radiusForSize(
    AimTargetSizePreset targetSize, {
    double customRadiusMeters = mediumRadiusMeters,
  }) {
    return switch (targetSize) {
      AimTargetSizePreset.small => smallRadiusMeters,
      AimTargetSizePreset.medium => mediumRadiusMeters,
      AimTargetSizePreset.large => largeRadiusMeters,
      AimTargetSizePreset.custom => customRadiusMeters.clamp(0.16, 1.2),
    };
  }

  static double radiusPxForSize(
    AimTargetSizePreset targetSize, {
    double customRadiusPx = mediumRadiusPx,
  }) {
    return switch (targetSize) {
      AimTargetSizePreset.small => smallRadiusPx,
      AimTargetSizePreset.medium => mediumRadiusPx,
      AimTargetSizePreset.large => largeRadiusPx,
      AimTargetSizePreset.custom => customRadiusPx.clamp(8, 80),
    };
  }

  final AimEvaluationMode evaluationMode;
  final AimTestMode mode;
  final AimDifficulty difficulty;
  final int totalTargetCount;
  final int durationSeconds;
  final AimTargetMode targetMode;
  final int activeTargetCount;
  final AimTargetBehavior targetBehavior;
  final AimMovementPattern movementPattern;
  final double movementSpeedMetersPerSecond;
  final AimTargetSizePreset targetSize;
  final double targetRadiusMeters;
  final double targetRadiusPx;
  final double targetLifetimeMs;
  final double spawnFadeInMs;
  final double minTargetDistanceMeters;
  final double maxTargetDistanceMeters;
  final double horizontalSpreadMeters;
  final double verticalSpreadMeters;
}

final class AimTarget {
  const AimTarget({
    required this.id,
    required this.position,
    required this.radiusMeters,
    required this.spawnedAtMs,
    this.screenRadiusPx,
    this.velocityMetersPerSecond = const Vec3(0, 0, 0),
    this.presentedAtMs,
  });

  final String id;
  final Vec3 position;
  final double radiusMeters;
  final double spawnedAtMs;
  final double? screenRadiusPx;
  final Vec3 velocityMetersPerSecond;
  final double? presentedAtMs;

  AimTarget copyWith({
    Vec3? position,
    Vec3? velocityMetersPerSecond,
    double? presentedAtMs,
  }) {
    return AimTarget(
      id: id,
      position: position ?? this.position,
      radiusMeters: radiusMeters,
      spawnedAtMs: spawnedAtMs,
      screenRadiusPx: screenRadiusPx,
      velocityMetersPerSecond:
          velocityMetersPerSecond ?? this.velocityMetersPerSecond,
      presentedAtMs: presentedAtMs ?? this.presentedAtMs,
    );
  }
}

final class AimShotResult {
  const AimShotResult({
    required this.hit,
    this.targetId,
    this.rawKillTimeMs,
    this.calibratedKillTimeMs,
  });

  final bool hit;
  final String? targetId;
  final int? rawKillTimeMs;
  final int? calibratedKillTimeMs;
}

final class AimRoundResult {
  const AimRoundResult({
    required this.targetId,
    required this.rawKillTimeMs,
    required this.calibratedKillTimeMs,
    required this.estimatedRenderDelayMs,
    required this.estimatedInputDelayMs,
    required this.leaderboardEligible,
    required this.qualityScore,
    required this.qualityFlags,
  });

  final String targetId;
  final int rawKillTimeMs;
  final int calibratedKillTimeMs;
  final int estimatedRenderDelayMs;
  final int estimatedInputDelayMs;
  final bool leaderboardEligible;
  final int qualityScore;
  final List<String> qualityFlags;
}

final class AimTestState {
  const AimTestState({
    required this.phase,
    required this.startedAtMs,
    required this.activeTargets,
    required this.results,
    required this.misses,
    required this.timedOutTargets,
  });

  const AimTestState.idle()
    : this(
        phase: AimSessionPhase.idle,
        startedAtMs: null,
        activeTargets: const [],
        results: const [],
        misses: 0,
        timedOutTargets: 0,
      );

  final AimSessionPhase phase;
  final double? startedAtMs;
  final List<AimTarget> activeTargets;
  final List<AimRoundResult> results;
  final int misses;
  final int timedOutTargets;

  int get hits => results.length;
  int get totalShots => hits + misses;
  int get resolvedTargets => hits + timedOutTargets;
}

final class AimSummary {
  const AimSummary({
    required this.totalShots,
    required this.hits,
    required this.misses,
    required this.timedOutTargets,
    required this.totalTargetCount,
    required this.durationSeconds,
    required this.evaluationMode,
    required this.hitRate,
    required this.errorRate,
    required this.shotAccuracy,
    required this.killsPerSecond,
    required this.killsPerMinute,
    required this.averageKillTimeMs,
    required this.bestKillTimeMs,
    required this.worstKillTimeMs,
    required this.trimmedMeanMs,
    required this.leaderboardEligible,
    required this.qualityScore,
    required this.qualityFlags,
  });

  final int totalShots;
  final int hits;
  final int misses;
  final int timedOutTargets;
  final int totalTargetCount;
  final int durationSeconds;
  final AimEvaluationMode evaluationMode;
  final double hitRate;
  final double errorRate;
  final double shotAccuracy;
  final double? killsPerSecond;
  final double? killsPerMinute;
  final int? averageKillTimeMs;
  final int? bestKillTimeMs;
  final int? worstKillTimeMs;
  final int? trimmedMeanMs;
  final bool leaderboardEligible;
  final int qualityScore;
  final List<String> qualityFlags;
}

abstract interface class AimTargetSpawner {
  Vec3 nextPosition(int index);
}

final class RandomTargetSpawner implements AimTargetSpawner {
  RandomTargetSpawner({
    math.Random? random,
    this.horizontalSpreadMeters = 4.4,
    this.verticalSpreadMeters = 2.4,
    this.minDistanceMeters = 6,
    this.maxDistanceMeters = 15,
  }) : _random = random ?? math.Random();

  factory RandomTargetSpawner.fromConfig(
    AimTestConfig config, {
    math.Random? random,
  }) {
    return RandomTargetSpawner(
      random: random,
      horizontalSpreadMeters: config.horizontalSpreadMeters,
      verticalSpreadMeters: config.verticalSpreadMeters,
      minDistanceMeters: config.minTargetDistanceMeters,
      maxDistanceMeters: config.maxTargetDistanceMeters,
    );
  }

  final math.Random _random;
  final double horizontalSpreadMeters;
  final double verticalSpreadMeters;
  final double minDistanceMeters;
  final double maxDistanceMeters;

  @override
  Vec3 nextPosition(int index) {
    final x = (_random.nextDouble() * 2 - 1) * horizontalSpreadMeters;
    final y = (_random.nextDouble() * 2 - 1) * verticalSpreadMeters;
    final distanceRange = maxDistanceMeters - minDistanceMeters;
    final z = minDistanceMeters + _random.nextDouble() * distanceRange;
    return Vec3(x, y, z);
  }
}

final class SequenceTargetSpawner implements AimTargetSpawner {
  SequenceTargetSpawner(this.positions);

  factory SequenceTargetSpawner.preset(AimDifficulty difficulty) {
    final positions = switch (difficulty) {
      AimDifficulty.easy => const [
        Vec3(-1.4, 0, 7),
        Vec3(1.4, 0, 7),
        Vec3(0, 0.9, 8),
        Vec3(0, -0.8, 8),
      ],
      AimDifficulty.normal => const [
        Vec3(-2.4, 0.4, 9),
        Vec3(2.2, -0.3, 10),
        Vec3(-0.8, 1.4, 11),
        Vec3(1.1, -1.3, 12),
        Vec3(0, 0, 8),
      ],
      AimDifficulty.hard => const [
        Vec3(-3.4, 1.4, 12),
        Vec3(3.1, -1.1, 14),
        Vec3(-1.8, -1.7, 16),
        Vec3(1.9, 1.7, 15),
        Vec3(0, 0, 18),
      ],
    };
    return SequenceTargetSpawner(positions);
  }

  final List<Vec3> positions;

  @override
  Vec3 nextPosition(int index) {
    return positions[index % positions.length];
  }
}

final class AimTargetManager {
  AimTargetManager({
    required this.config,
    AimTargetSpawner? spawner,
    this._projector = const CanvasSceneProjector(),
    this._qualityPolicy = const PrecisionQualityPolicy(),
  }) : _spawner = spawner ?? _defaultSpawner(config);

  final AimTestConfig config;
  final AimTargetSpawner _spawner;
  final CanvasSceneProjector _projector;
  final PrecisionQualityPolicy _qualityPolicy;

  AimTestState state = const AimTestState.idle();
  int _spawnedCount = 0;
  double _lastAdvanceMs = 0;

  static AimTargetSpawner _defaultSpawner(AimTestConfig config) {
    return switch (config.mode) {
      AimTestMode.evaluation => RandomTargetSpawner.fromConfig(config),
      AimTestMode.targetSequence => SequenceTargetSpawner.preset(
        config.difficulty,
      ),
    };
  }

  void start({required double nowMs}) {
    _spawnedCount = 0;
    _lastAdvanceMs = nowMs;
    state = AimTestState(
      phase: AimSessionPhase.running,
      startedAtMs: nowMs,
      activeTargets: _spawnInitialTargets(nowMs),
      results: const [],
      misses: 0,
      timedOutTargets: 0,
    );
  }

  void advance({required double nowMs}) {
    if (state.phase != AimSessionPhase.running) {
      return;
    }

    if (_timeLimitReached(nowMs)) {
      state = AimTestState(
        phase: AimSessionPhase.completed,
        startedAtMs: state.startedAtMs,
        activeTargets: const [],
        results: state.results,
        misses: state.misses,
        timedOutTargets: state.timedOutTargets,
      );
      return;
    }

    final elapsedSeconds = math.max(0, nowMs - _lastAdvanceMs) / 1000;
    _lastAdvanceMs = nowMs;
    if (config.targetBehavior != AimTargetBehavior.moving ||
        elapsedSeconds == 0) {
      return;
    }

    state = AimTestState(
      phase: state.phase,
      startedAtMs: state.startedAtMs,
      activeTargets: _advanceMovingTargets(state.activeTargets, elapsedSeconds),
      results: state.results,
      misses: state.misses,
      timedOutTargets: state.timedOutTargets,
    );
  }

  void markActiveTargetsPresented(double nowMs) {
    if (state.phase != AimSessionPhase.running) {
      return;
    }
    var changed = false;
    final targets = [
      for (final target in state.activeTargets)
        if (target.presentedAtMs == null)
          target.copyWith(presentedAtMs: nowMs)
        else
          target,
    ];
    for (var i = 0; i < state.activeTargets.length; i++) {
      changed =
          changed ||
          state.activeTargets[i].presentedAtMs != targets[i].presentedAtMs;
    }
    if (!changed) {
      return;
    }
    state = AimTestState(
      phase: state.phase,
      startedAtMs: state.startedAtMs,
      activeTargets: targets,
      results: state.results,
      misses: state.misses,
      timedOutTargets: state.timedOutTargets,
    );
  }

  AimShotResult handleShot({
    required double nowMs,
    required ViewAngles camera,
    required AimViewport viewport,
    double estimatedRenderDelayMs = 0,
    double estimatedInputDelayMs = 0,
    InputEventTiming? inputTiming,
    FrameQualitySnapshot frameQuality = const FrameQualitySnapshot.empty(),
    bool pointerLocked = false,
    double? aimX,
    double? aimY,
  }) {
    if (state.phase != AimSessionPhase.running) {
      return const AimShotResult(hit: false);
    }

    advance(nowMs: nowMs);
    if (state.phase != AimSessionPhase.running) {
      return const AimShotResult(hit: false);
    }

    final shotX = aimX ?? viewport.centerX;
    final shotY = aimY ?? viewport.centerY;
    for (final target in state.activeTargets) {
      final projected = _projector.projectTarget(
        target: target,
        camera: camera,
        viewport: viewport,
      );
      if (projected == null || !projected.visible) {
        continue;
      }
      if (!projected.contains(shotX, shotY)) {
        continue;
      }

      final presentationTiming = target.presentedAtMs == null
          ? null
          : RenderPresentationTiming(
              requestedAtMs: target.spawnedAtMs,
              presentedAtMs: target.presentedAtMs!,
            );
      final shotAtMs = inputTiming?.effectiveTimestampMs ?? nowMs;
      final shownAtMs = target.presentedAtMs ?? target.spawnedAtMs;
      final rawMs = (shotAtMs - shownAtMs).clamp(0, double.infinity);
      final quality = _qualityPolicy.evaluate(
        renderTiming: presentationTiming,
        inputTiming: inputTiming,
        frameQuality: frameQuality,
        requiresPointerLock: true,
        pointerLocked: pointerLocked,
      );
      final compensation = LatencyCompensation(
        estimatedRenderDelayMs:
            presentationTiming?.renderDelayMs ?? estimatedRenderDelayMs,
        estimatedInputDelayMs: estimatedInputDelayMs,
      );
      final resolvedRenderDelayMs =
          presentationTiming?.renderDelayMs ?? estimatedRenderDelayMs;
      final calibratedMs = (rawMs - compensation.hardwareLatencyEstimateMs)
          .clamp(0, double.infinity);
      final round = AimRoundResult(
        targetId: target.id,
        rawKillTimeMs: rawMs.round(),
        calibratedKillTimeMs: calibratedMs.round(),
        estimatedRenderDelayMs: resolvedRenderDelayMs.round(),
        estimatedInputDelayMs: estimatedInputDelayMs.round(),
        leaderboardEligible: quality.leaderboardEligible,
        qualityScore: quality.qualityScore,
        qualityFlags: quality.flags,
      );
      _recordHit(target, round, nowMs);
      return AimShotResult(
        hit: true,
        targetId: target.id,
        rawKillTimeMs: round.rawKillTimeMs,
        calibratedKillTimeMs: round.calibratedKillTimeMs,
      );
    }

    state = AimTestState(
      phase: state.phase,
      startedAtMs: state.startedAtMs,
      activeTargets: state.activeTargets,
      results: state.results,
      misses: state.misses + 1,
      timedOutTargets: state.timedOutTargets,
    );
    return const AimShotResult(hit: false);
  }

  AimSummary get summary {
    final killTimes =
        state.results.map((result) => result.calibratedKillTimeMs).toList()
          ..sort();
    final totalShots = state.totalShots;
    final hits = state.hits;
    final misses = state.misses;
    final targetDenominator = config.evaluationMode == AimEvaluationMode.count
        ? config.totalTargetCount
        : totalShots;

    int? average;
    int? best;
    int? worst;
    int? trimmed;
    double? killsPerSecond;
    double? killsPerMinute;
    var leaderboardEligible = killTimes.isNotEmpty;
    var qualityScore = 100;
    final qualityFlags = <String>{};
    if (killTimes.isNotEmpty) {
      average = (killTimes.reduce((a, b) => a + b) / killTimes.length).round();
      best = killTimes.first;
      worst = killTimes.last;
      if (killTimes.length >= 15) {
        final trimmedValues = killTimes.sublist(1, killTimes.length - 1);
        trimmed = (trimmedValues.reduce((a, b) => a + b) / trimmedValues.length)
            .round();
      }
    }
    for (final result in state.results) {
      leaderboardEligible = leaderboardEligible && result.leaderboardEligible;
      qualityScore = math.min(qualityScore, result.qualityScore);
      qualityFlags.addAll(result.qualityFlags);
    }
    if (config.evaluationMode == AimEvaluationMode.timed) {
      killsPerSecond = config.durationSeconds == 0
          ? 0
          : hits / config.durationSeconds;
      killsPerMinute = killsPerSecond * 60;
    }

    return AimSummary(
      totalShots: totalShots,
      hits: hits,
      misses: misses,
      timedOutTargets: state.timedOutTargets,
      totalTargetCount: targetDenominator,
      durationSeconds: config.durationSeconds,
      evaluationMode: config.evaluationMode,
      hitRate: targetDenominator == 0 ? 0 : hits / targetDenominator,
      errorRate: totalShots == 0 ? 0 : misses / totalShots,
      shotAccuracy: totalShots == 0 ? 0 : hits / totalShots,
      killsPerSecond: killsPerSecond,
      killsPerMinute: killsPerMinute,
      averageKillTimeMs: average,
      bestKillTimeMs: best,
      worstKillTimeMs: worst,
      trimmedMeanMs: trimmed,
      leaderboardEligible: leaderboardEligible,
      qualityScore: killTimes.isEmpty ? 0 : qualityScore,
      qualityFlags: List.unmodifiable(qualityFlags),
    );
  }

  List<ProjectedTarget> projectedTargets({
    required ViewAngles camera,
    required AimViewport viewport,
  }) {
    final projectedTargets = <ProjectedTarget>[];
    for (final target in state.activeTargets) {
      final projected = _projector.projectTarget(
        target: target,
        camera: camera,
        viewport: viewport,
      );
      if (projected != null) {
        projectedTargets.add(projected);
      }
    }
    return projectedTargets;
  }

  double spawnProgress(AimTarget target, double nowMs) {
    if (config.spawnFadeInMs <= 0) {
      return 1;
    }
    final ageMs = nowMs - target.spawnedAtMs;
    return (ageMs / config.spawnFadeInMs).clamp(0, 1).toDouble();
  }

  double lifetimeProgress(AimTarget target, double nowMs) {
    if (config.targetLifetimeMs <= 0) {
      return 1;
    }
    final ageMs = nowMs - target.spawnedAtMs;
    return (ageMs / config.targetLifetimeMs).clamp(0, 1).toDouble();
  }

  List<AimTarget> _spawnInitialTargets(double nowMs) {
    final targets = <AimTarget>[];
    final desiredTargetCount = config.evaluationMode == AimEvaluationMode.timed
        ? config.activeTargetCount
        : math.min(config.activeTargetCount, config.totalTargetCount);
    while (targets.length < desiredTargetCount) {
      targets.add(_spawnTarget(nowMs, existingTargets: targets));
    }
    return targets;
  }

  AimTarget _spawnTarget(
    double nowMs, {
    List<AimTarget> existingTargets = const [],
  }) {
    final index = _spawnedCount++;
    var position = _spawner.nextPosition(index);
    for (var attempt = 0; attempt < 10; attempt++) {
      if (_hasEnoughSpacing(position, existingTargets)) {
        break;
      }
      position = _spawner.nextPosition(index + attempt + 1);
    }
    return AimTarget(
      id: 'target-$index',
      position: position,
      radiusMeters: config.targetRadiusMeters,
      screenRadiusPx: config.targetRadiusPx,
      spawnedAtMs: nowMs,
      velocityMetersPerSecond: _velocityForTarget(index),
    );
  }

  void _recordHit(AimTarget hitTarget, AimRoundResult round, double nowMs) {
    final results = [...state.results, round];
    var activeTargets = [
      for (final target in state.activeTargets)
        if (target.id != hitTarget.id) target,
    ];
    var phase = AimSessionPhase.running;

    if (config.evaluationMode == AimEvaluationMode.count &&
        results.length >= config.totalTargetCount) {
      phase = AimSessionPhase.completed;
      activeTargets = const [];
    } else {
      activeTargets = _fillTargets(activeTargets, nowMs);
    }

    state = AimTestState(
      phase: phase,
      startedAtMs: state.startedAtMs,
      activeTargets: activeTargets,
      results: results,
      misses: state.misses,
      timedOutTargets: state.timedOutTargets,
    );
  }

  List<AimTarget> _fillTargets(List<AimTarget> currentTargets, double nowMs) {
    final targets = [...currentTargets];
    while (targets.length < config.activeTargetCount &&
        (config.evaluationMode == AimEvaluationMode.timed ||
            _spawnedCount < config.totalTargetCount)) {
      targets.add(_spawnTarget(nowMs, existingTargets: targets));
    }
    return targets;
  }

  bool _timeLimitReached(double nowMs) {
    if (config.evaluationMode != AimEvaluationMode.timed) {
      return false;
    }
    final startedAtMs = state.startedAtMs;
    if (startedAtMs == null) {
      return false;
    }
    return nowMs - startedAtMs >= config.durationSeconds * 1000;
  }

  bool _hasEnoughSpacing(Vec3 position, List<AimTarget> existingTargets) {
    final minDistance = config.targetRadiusMeters * 2 * 1.5;
    return existingTargets.every(
      (target) => target.position.distanceTo(position) >= minDistance,
    );
  }

  Vec3 _velocityForTarget(int index) {
    if (config.targetBehavior != AimTargetBehavior.moving) {
      return const Vec3(0, 0, 0);
    }
    final angle = index * math.pi * 0.37 + math.pi / 5;
    final speed = config.movementSpeedMetersPerSecond;
    return Vec3(math.cos(angle) * speed, math.sin(angle) * speed, 0);
  }

  List<AimTarget> _advanceMovingTargets(
    List<AimTarget> targets,
    double elapsedSeconds,
  ) {
    return [
      for (final target in targets)
        _advanceMovingTarget(target, elapsedSeconds),
    ];
  }

  AimTarget _advanceMovingTarget(AimTarget target, double elapsedSeconds) {
    final next =
        target.position + target.velocityMetersPerSecond * elapsedSeconds;
    var x = next.x;
    var y = next.y;
    var velocity = target.velocityMetersPerSecond;

    if (x.abs() > config.horizontalSpreadMeters) {
      x = x.clamp(
        -config.horizontalSpreadMeters,
        config.horizontalSpreadMeters,
      );
      velocity = Vec3(-velocity.x, velocity.y, velocity.z);
    }
    if (y.abs() > config.verticalSpreadMeters) {
      y = y.clamp(-config.verticalSpreadMeters, config.verticalSpreadMeters);
      velocity = Vec3(velocity.x, -velocity.y, velocity.z);
    }

    if (config.movementPattern == AimMovementPattern.random) {
      final seed = (target.id.hashCode + next.x * 1000 + next.y * 1000).round();
      if (seed % 19 == 0) {
        velocity = Vec3(-velocity.y, velocity.x, velocity.z);
      }
    }

    return target.copyWith(
      position: Vec3(x, y, target.position.z),
      velocityMetersPerSecond: velocity,
    );
  }
}
