import '../../../web/performance_now_stub.dart'
    if (dart.library.html) '../../../web/performance_now.dart';
import '../../../core/precision/precision_timing.dart';

abstract interface class PerformanceTimer {
  double now();
}

final class BrowserPerformanceTimer implements PerformanceTimer {
  const BrowserPerformanceTimer();

  @override
  double now() => performanceNow();
}

final class LatencyCompensation {
  const LatencyCompensation({
    required this.estimatedRenderDelayMs,
    required this.estimatedInputDelayMs,
  });

  static const zero = LatencyCompensation(
    estimatedRenderDelayMs: 0,
    estimatedInputDelayMs: 0,
  );

  final double estimatedRenderDelayMs;
  final double estimatedInputDelayMs;

  double get hardwareLatencyEstimateMs =>
      estimatedRenderDelayMs + estimatedInputDelayMs;
}

final class ReactionTimingResult {
  const ReactionTimingResult({
    required this.rawReactionTimeMs,
    required this.estimatedRenderDelayMs,
    required this.estimatedInputDelayMs,
    required this.calibratedReactionTimeMs,
  });

  final int rawReactionTimeMs;
  final int estimatedRenderDelayMs;
  final int estimatedInputDelayMs;
  final int calibratedReactionTimeMs;

  int get hardwareLatencyEstimateMs =>
      estimatedRenderDelayMs + estimatedInputDelayMs;
}

final class TimingEngine {
  TimingEngine({required this.timer});

  final PerformanceTimer timer;
  double? _signalRequestedAt;
  double? _signalShownAt;

  bool get hasSignalShown => _signalShownAt != null;

  RenderPresentationTiming? get signalPresentationTiming {
    final signalRequestedAt = _signalRequestedAt;
    final signalShownAt = _signalShownAt;
    if (signalRequestedAt == null || signalShownAt == null) {
      return null;
    }
    return RenderPresentationTiming(
      requestedAtMs: signalRequestedAt,
      presentedAtMs: signalShownAt,
    );
  }

  void markSignalRequested() {
    _signalRequestedAt = timer.now();
    _signalShownAt = null;
  }

  void markSignalShown() {
    _signalShownAt = timer.now();
  }

  void markSignalShownAt(double timestampMs) {
    _signalShownAt = timestampMs;
  }

  ReactionTimingResult completeReaction({
    LatencyCompensation compensation = LatencyCompensation.zero,
    InputEventTiming? inputTiming,
  }) {
    final signalShownAt = _signalShownAt;
    if (signalShownAt == null) {
      throw StateError('信号期尚未开始');
    }

    final clickAt = inputTiming?.effectiveTimestampMs ?? timer.now();
    final rawReactionTimeMs = (clickAt - signalShownAt).clamp(
      0,
      double.infinity,
    );
    final calibratedReactionTimeMs =
        (rawReactionTimeMs - compensation.hardwareLatencyEstimateMs).clamp(
          0,
          double.infinity,
        );

    return ReactionTimingResult(
      rawReactionTimeMs: rawReactionTimeMs.round(),
      estimatedRenderDelayMs: compensation.estimatedRenderDelayMs.round(),
      estimatedInputDelayMs: compensation.estimatedInputDelayMs.round(),
      calibratedReactionTimeMs: calibratedReactionTimeMs.round(),
    );
  }
}
