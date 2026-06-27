import 'dart:math' as math;

final class InputEventTiming {
  const InputEventTiming({required this.handledAtMs, this.eventTimestampMs});

  final double handledAtMs;
  final double? eventTimestampMs;

  double get effectiveTimestampMs {
    final eventTimestampMs = this.eventTimestampMs;
    if (eventTimestampMs == null) {
      return handledAtMs;
    }
    final deltaMs = handledAtMs - eventTimestampMs;
    if (deltaMs < -1000 || deltaMs > 1000) {
      return handledAtMs;
    }
    return eventTimestampMs;
  }

  double? get handlerDelayMs {
    final eventTimestampMs = this.eventTimestampMs;
    if (eventTimestampMs == null) {
      return null;
    }
    final deltaMs = handledAtMs - eventTimestampMs;
    if (deltaMs < -1000 || deltaMs > 1000) {
      return null;
    }
    return math.max(0, deltaMs);
  }
}

final class RenderPresentationTiming {
  const RenderPresentationTiming({
    required this.requestedAtMs,
    required this.presentedAtMs,
  });

  final double requestedAtMs;
  final double presentedAtMs;

  double get renderDelayMs => math.max(0, presentedAtMs - requestedAtMs);
}

final class FrameQualitySnapshot {
  const FrameQualitySnapshot({
    required this.sampleCount,
    required this.averageFrameIntervalMs,
    required this.maxFrameIntervalMs,
    required this.droppedFrameCount,
    required this.estimatedRefreshRateHz,
  });

  const FrameQualitySnapshot.empty()
    : sampleCount = 0,
      averageFrameIntervalMs = 0,
      maxFrameIntervalMs = 0,
      droppedFrameCount = 0,
      estimatedRefreshRateHz = 0;

  final int sampleCount;
  final double averageFrameIntervalMs;
  final double maxFrameIntervalMs;
  final int droppedFrameCount;
  final double estimatedRefreshRateHz;
}

final class FrameQualityMonitor {
  FrameQualityMonitor({this.dropThresholdMs = 34});

  final double dropThresholdMs;
  final List<double> _intervals = <double>[];
  double? _lastFrameAtMs;

  void reset({double? nowMs}) {
    _intervals.clear();
    _lastFrameAtMs = nowMs;
  }

  void recordFrame(double nowMs) {
    final lastFrameAtMs = _lastFrameAtMs;
    if (lastFrameAtMs != null) {
      final interval = nowMs - lastFrameAtMs;
      if (interval > 0 && interval < 1000) {
        _intervals.add(interval);
      }
    }
    _lastFrameAtMs = nowMs;
  }

  FrameQualitySnapshot snapshot() {
    if (_intervals.isEmpty) {
      return const FrameQualitySnapshot.empty();
    }
    final sum = _intervals.reduce((a, b) => a + b);
    final average = sum / _intervals.length;
    final maxInterval = _intervals.reduce(math.max);
    final droppedFrames = _intervals
        .where((interval) => interval >= dropThresholdMs)
        .length;
    return FrameQualitySnapshot(
      sampleCount: _intervals.length,
      averageFrameIntervalMs: average,
      maxFrameIntervalMs: maxInterval,
      droppedFrameCount: droppedFrames,
      estimatedRefreshRateHz: average <= 0 ? 0 : 1000 / average,
    );
  }
}

final class ScorePrecisionEvidence {
  const ScorePrecisionEvidence({
    required this.leaderboardEligible,
    required this.qualityScore,
    required this.flags,
    this.renderDelayMs,
    this.inputHandlerDelayMs,
    this.averageFrameIntervalMs,
    this.maxFrameIntervalMs,
    this.droppedFrameCount,
    this.estimatedRefreshRateHz,
  });

  final bool leaderboardEligible;
  final int qualityScore;
  final List<String> flags;
  final double? renderDelayMs;
  final double? inputHandlerDelayMs;
  final double? averageFrameIntervalMs;
  final double? maxFrameIntervalMs;
  final int? droppedFrameCount;
  final double? estimatedRefreshRateHz;

  Map<String, Object?> toJson() {
    return {
      'leaderboardEligible': leaderboardEligible,
      'qualityScore': qualityScore,
      'flags': flags,
      'renderDelayMs': renderDelayMs,
      'inputHandlerDelayMs': inputHandlerDelayMs,
      'averageFrameIntervalMs': averageFrameIntervalMs,
      'maxFrameIntervalMs': maxFrameIntervalMs,
      'droppedFrameCount': droppedFrameCount,
      'estimatedRefreshRateHz': estimatedRefreshRateHz,
    };
  }
}

final class PrecisionQualityPolicy {
  const PrecisionQualityPolicy({
    this.maxRenderDelayMs = 25,
    this.maxInputHandlerDelayMs = 16,
    this.maxFrameIntervalMs = 34,
    this.maxDroppedFrameCount = 0,
    this.minimumFrameSamples = 30,
  });

  final double maxRenderDelayMs;
  final double maxInputHandlerDelayMs;
  final double maxFrameIntervalMs;
  final int maxDroppedFrameCount;
  final int minimumFrameSamples;

  ScorePrecisionEvidence evaluate({
    RenderPresentationTiming? renderTiming,
    InputEventTiming? inputTiming,
    FrameQualitySnapshot frameQuality = const FrameQualitySnapshot.empty(),
    bool requiresPointerLock = false,
    bool pointerLocked = false,
  }) {
    final flags = <String>[];
    final renderDelayMs = renderTiming?.renderDelayMs;
    final inputHandlerDelayMs = inputTiming?.handlerDelayMs;

    if (renderTiming == null) {
      flags.add('render_timestamp_missing');
    } else if (renderDelayMs! > maxRenderDelayMs) {
      flags.add('render_delay_high');
    }

    if (inputTiming == null) {
      flags.add('input_timestamp_missing');
    } else if (inputHandlerDelayMs == null) {
      flags.add('input_timestamp_untrusted');
    } else if (inputHandlerDelayMs > maxInputHandlerDelayMs) {
      flags.add('input_handler_delay_high');
    }

    if (frameQuality.sampleCount < minimumFrameSamples) {
      flags.add('frame_samples_insufficient');
    }
    if (frameQuality.maxFrameIntervalMs > maxFrameIntervalMs) {
      flags.add('frame_interval_high');
    }
    if (frameQuality.droppedFrameCount > maxDroppedFrameCount) {
      flags.add('dropped_frames');
    }
    if (requiresPointerLock && !pointerLocked) {
      flags.add('pointer_lock_missing');
    }

    final qualityScore = math.max(0, 100 - flags.length * 18);
    return ScorePrecisionEvidence(
      leaderboardEligible: flags.isEmpty,
      qualityScore: qualityScore,
      flags: List.unmodifiable(flags),
      renderDelayMs: renderDelayMs,
      inputHandlerDelayMs: inputHandlerDelayMs,
      averageFrameIntervalMs: frameQuality.sampleCount == 0
          ? null
          : frameQuality.averageFrameIntervalMs,
      maxFrameIntervalMs: frameQuality.sampleCount == 0
          ? null
          : frameQuality.maxFrameIntervalMs,
      droppedFrameCount: frameQuality.sampleCount == 0
          ? null
          : frameQuality.droppedFrameCount,
      estimatedRefreshRateHz: frameQuality.sampleCount == 0
          ? null
          : frameQuality.estimatedRefreshRateHz,
    );
  }
}
