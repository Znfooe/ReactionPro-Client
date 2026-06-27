import 'dart:async';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/precision/precision_timing.dart';
import '../core/calibration.dart';
import '../core/timing_engine.dart';
import '../data/calibration_offset_store.dart';

typedef CancelScheduledTask = void Function();

abstract interface class ReactionPhaseScheduler {
  CancelScheduledTask schedule(Duration delay, void Function() callback);
}

abstract interface class ReactionDelayGenerator {
  Duration nextDelay({required int minSeconds, required int maxSeconds});
}

abstract interface class ReactionRenderFrameClock {
  void afterNextFrame(void Function(double timestampMs) callback);
}

const reactionMinSignalDelaySecondsLimit = 1;
const reactionMaxSignalDelaySecondsLimit = 60;
const reactionMinSignalDelaySpanSeconds = 5;
const reactionDefaultSignalMinDelaySeconds = 3;
const reactionDefaultSignalMaxDelaySeconds = 12;

final class FlutterReactionRenderFrameClock
    implements ReactionRenderFrameClock {
  const FlutterReactionRenderFrameClock({
    this.timer = const BrowserPerformanceTimer(),
  });

  final PerformanceTimer timer;

  @override
  void afterNextFrame(void Function(double timestampMs) callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback(timer.now());
    });
  }
}

final class TimerReactionScheduler implements ReactionPhaseScheduler {
  const TimerReactionScheduler();

  @override
  CancelScheduledTask schedule(Duration delay, void Function() callback) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }
}

final class RandomReactionDelayGenerator implements ReactionDelayGenerator {
  RandomReactionDelayGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Duration nextDelay({required int minSeconds, required int maxSeconds}) {
    final minMs = Duration(seconds: minSeconds).inMilliseconds;
    final maxMs = Duration(seconds: maxSeconds).inMilliseconds;
    return Duration(milliseconds: minMs + _random.nextInt(maxMs - minMs + 1));
  }
}

enum ReactionTestPhase {
  idle,
  waiting,
  signal,
  clicked,
  falseStart,
  timeout,
  result,
  completed,
}

final class ReactionRoundResult {
  const ReactionRoundResult({
    required this.roundNumber,
    required this.rawReactionTimeMs,
    required this.estimatedRenderDelayMs,
    required this.estimatedInputDelayMs,
    required this.calibratedReactionTimeMs,
    required this.leaderboardEligible,
    required this.qualityScore,
    required this.qualityFlags,
  });

  final int roundNumber;
  final int rawReactionTimeMs;
  final int estimatedRenderDelayMs;
  final int estimatedInputDelayMs;
  final int calibratedReactionTimeMs;
  final bool leaderboardEligible;
  final int qualityScore;
  final List<String> qualityFlags;

  int get hardwareLatencyEstimateMs =>
      estimatedRenderDelayMs + estimatedInputDelayMs;
}

final class ReactionSessionSummary {
  const ReactionSessionSummary({
    required this.averageReactionTimeMs,
    required this.bestReactionTimeMs,
    required this.worstReactionTimeMs,
    required this.standardDeviationMs,
    this.trimmedMeanMs,
  });

  final double averageReactionTimeMs;
  final int bestReactionTimeMs;
  final int worstReactionTimeMs;
  final double standardDeviationMs;
  final double? trimmedMeanMs;
}

final class ReactionTestState {
  const ReactionTestState({
    this.phase = ReactionTestPhase.idle,
    this.selectedRoundCount = 5,
    this.results = const <ReactionRoundResult>[],
    this.currentResult,
    this.summary,
    this.calibrationOffsetMs = 0,
    this.signalMinDelaySeconds = reactionDefaultSignalMinDelaySeconds,
    this.signalMaxDelaySeconds = reactionDefaultSignalMaxDelaySeconds,
  });

  final ReactionTestPhase phase;
  final int selectedRoundCount;
  final List<ReactionRoundResult> results;
  final ReactionRoundResult? currentResult;
  final ReactionSessionSummary? summary;
  final double calibrationOffsetMs;
  final int signalMinDelaySeconds;
  final int signalMaxDelaySeconds;

  int get completedRoundCount => results.length;

  bool get canConfigure =>
      phase == ReactionTestPhase.idle || phase == ReactionTestPhase.completed;

  int get currentRoundNumber {
    if (results.length >= selectedRoundCount) {
      return selectedRoundCount;
    }
    return results.length + 1;
  }

  ReactionTestState copyWith({
    ReactionTestPhase? phase,
    int? selectedRoundCount,
    List<ReactionRoundResult>? results,
    ReactionRoundResult? currentResult,
    bool clearCurrentResult = false,
    ReactionSessionSummary? summary,
    bool clearSummary = false,
    double? calibrationOffsetMs,
    int? signalMinDelaySeconds,
    int? signalMaxDelaySeconds,
  }) {
    return ReactionTestState(
      phase: phase ?? this.phase,
      selectedRoundCount: selectedRoundCount ?? this.selectedRoundCount,
      results: results ?? this.results,
      currentResult: clearCurrentResult
          ? null
          : currentResult ?? this.currentResult,
      summary: clearSummary ? null : summary ?? this.summary,
      calibrationOffsetMs: calibrationOffsetMs ?? this.calibrationOffsetMs,
      signalMinDelaySeconds:
          signalMinDelaySeconds ?? this.signalMinDelaySeconds,
      signalMaxDelaySeconds:
          signalMaxDelaySeconds ?? this.signalMaxDelaySeconds,
    );
  }
}

final reactionTestControllerProvider =
    StateNotifierProvider.autoDispose<
      ReactionTestController,
      ReactionTestState
    >((ref) {
      return ReactionTestController(
        timingEngine: TimingEngine(timer: const BrowserPerformanceTimer()),
        scheduler: const TimerReactionScheduler(),
        delayGenerator: RandomReactionDelayGenerator(),
        frameClock: const FlutterReactionRenderFrameClock(),
        qualityPolicy: const PrecisionQualityPolicy(),
      );
    });

final calibrationServiceProvider = Provider<CalibrationService>((ref) {
  return const CalibrationService();
});

final calibrationOffsetStoreProvider = Provider<CalibrationOffsetStore>((ref) {
  return const BrowserCalibrationOffsetStore();
});

final class ReactionTestController extends StateNotifier<ReactionTestState> {
  ReactionTestController({
    required this.timingEngine,
    required this.scheduler,
    required this.delayGenerator,
    required this.frameClock,
    required this.qualityPolicy,
  }) : super(const ReactionTestState());

  static const signalTimeout = Duration(seconds: 2);
  static const falseStartThresholdMs = 100;
  static const validRoundCounts = {5, 10, 15};
  static const minSignalDelaySeconds = reactionMinSignalDelaySecondsLimit;
  static const maxSignalDelaySeconds = reactionMaxSignalDelaySecondsLimit;
  static const minSignalDelaySpanSeconds = reactionMinSignalDelaySpanSeconds;

  final TimingEngine timingEngine;
  final ReactionPhaseScheduler scheduler;
  final ReactionDelayGenerator delayGenerator;
  final ReactionRenderFrameClock frameClock;
  final PrecisionQualityPolicy qualityPolicy;
  CancelScheduledTask? _cancelSignalTask;
  CancelScheduledTask? _cancelTimeoutTask;
  FrameQualitySnapshot _latestFrameQuality = const FrameQualitySnapshot.empty();

  void selectRoundCount(int roundCount) {
    if (!validRoundCounts.contains(roundCount)) {
      throw ArgumentError.value(roundCount, 'roundCount', '仅支持 5/10/15 回合');
    }

    if (!state.canConfigure) {
      throw StateError('测试进行中不能切换回合数');
    }

    state = state.copyWith(selectedRoundCount: roundCount);
  }

  void setSignalDelayRange({required int minSeconds, required int maxSeconds}) {
    if (!state.canConfigure) {
      throw StateError('测试进行中不能切换信号出现时间');
    }

    final normalized = normalizeSignalDelayRange(
      minSeconds: minSeconds,
      maxSeconds: maxSeconds,
    );
    state = state.copyWith(
      signalMinDelaySeconds: normalized.minSeconds,
      signalMaxDelaySeconds: normalized.maxSeconds,
    );
  }

  static ({int minSeconds, int maxSeconds}) normalizeSignalDelayRange({
    required int minSeconds,
    required int maxSeconds,
  }) {
    var normalizedMin = minSeconds
        .clamp(
          reactionMinSignalDelaySecondsLimit,
          reactionMaxSignalDelaySecondsLimit -
              reactionMinSignalDelaySpanSeconds,
        )
        .toInt();
    var normalizedMax = maxSeconds
        .clamp(
          normalizedMin + reactionMinSignalDelaySpanSeconds,
          reactionMaxSignalDelaySecondsLimit,
        )
        .toInt();

    if (normalizedMax - normalizedMin < reactionMinSignalDelaySpanSeconds) {
      normalizedMin = (normalizedMax - reactionMinSignalDelaySpanSeconds)
          .clamp(
            reactionMinSignalDelaySecondsLimit,
            reactionMaxSignalDelaySecondsLimit -
                reactionMinSignalDelaySpanSeconds,
          )
          .toInt();
    }

    return (minSeconds: normalizedMin, maxSeconds: normalizedMax);
  }

  void startSession() {
    _cancelScheduledTasks();
    state = ReactionTestState(
      selectedRoundCount: state.selectedRoundCount,
      calibrationOffsetMs: state.calibrationOffsetMs,
      signalMinDelaySeconds: state.signalMinDelaySeconds,
      signalMaxDelaySeconds: state.signalMaxDelaySeconds,
      phase: ReactionTestPhase.waiting,
    );
    _scheduleSignal();
  }

  void resetSession() {
    _cancelScheduledTasks();
    state = ReactionTestState(
      selectedRoundCount: state.selectedRoundCount,
      calibrationOffsetMs: state.calibrationOffsetMs,
      signalMinDelaySeconds: state.signalMinDelaySeconds,
      signalMaxDelaySeconds: state.signalMaxDelaySeconds,
    );
  }

  void retryRound() {
    _cancelScheduledTasks();
    if (state.phase != ReactionTestPhase.falseStart &&
        state.phase != ReactionTestPhase.timeout) {
      throw StateError('当前状态不能重试回合');
    }
    state = state.copyWith(
      phase: ReactionTestPhase.waiting,
      clearCurrentResult: true,
    );
    _scheduleSignal();
  }

  void enterSignalPhase() {
    if (state.phase != ReactionTestPhase.waiting) {
      throw StateError('必须先进入等待期');
    }

    _cancelSignalTask?.call();
    _cancelSignalTask = null;
    timingEngine.markSignalRequested();
    state = state.copyWith(phase: ReactionTestPhase.signal);
    frameClock.afterNextFrame((timestampMs) {
      if (!mounted || state.phase != ReactionTestPhase.signal) {
        return;
      }
      timingEngine.markSignalShownAt(timestampMs);
      _cancelTimeoutTask = scheduler.schedule(signalTimeout, timeoutSignal);
    });
  }

  void timeoutSignal() {
    if (state.phase != ReactionTestPhase.signal) {
      return;
    }
    _cancelTimeoutTask?.call();
    _cancelTimeoutTask = null;
    state = state.copyWith(phase: ReactionTestPhase.timeout);
  }

  void tapArena({
    InputEventTiming? inputTiming,
    FrameQualitySnapshot frameQuality = const FrameQualitySnapshot.empty(),
  }) {
    _latestFrameQuality = frameQuality;
    switch (state.phase) {
      case ReactionTestPhase.idle:
      case ReactionTestPhase.completed:
        startSession();
      case ReactionTestPhase.waiting:
        _recordFalseStart();
      case ReactionTestPhase.signal:
        _completeSignalClick(inputTiming);
      case ReactionTestPhase.falseStart:
      case ReactionTestPhase.timeout:
        retryRound();
      case ReactionTestPhase.result:
        continueAfterResult();
      case ReactionTestPhase.clicked:
        break;
    }
  }

  void continueAfterResult() {
    if (state.phase != ReactionTestPhase.result) {
      throw StateError('当前状态没有可继续的回合结果');
    }

    if (state.results.length >= state.selectedRoundCount) {
      state = state.copyWith(
        phase: ReactionTestPhase.completed,
        summary: _buildSummary(state.results, state.selectedRoundCount),
      );
      return;
    }

    state = state.copyWith(
      phase: ReactionTestPhase.waiting,
      clearCurrentResult: true,
    );
    _scheduleSignal();
  }

  void setCalibrationOffset(double calibrationOffsetMs) {
    state = state.copyWith(calibrationOffsetMs: calibrationOffsetMs);
  }

  Future<void> loadCalibrationOffset({
    required CalibrationService service,
    required CalibrationOffsetStore store,
  }) async {
    final offset = await service.loadOffset(store);
    if (offset != null && mounted) {
      setCalibrationOffset(offset);
    }
  }

  void _scheduleSignal() {
    _cancelSignalTask = scheduler.schedule(
      delayGenerator.nextDelay(
        minSeconds: state.signalMinDelaySeconds,
        maxSeconds: state.signalMaxDelaySeconds,
      ),
      enterSignalPhase,
    );
  }

  void _completeSignalClick(InputEventTiming? inputTiming) {
    if (!timingEngine.hasSignalShown) {
      return;
    }

    _cancelTimeoutTask?.call();
    _cancelTimeoutTask = null;

    final presentationTiming = timingEngine.signalPresentationTiming;
    final evidence = qualityPolicy.evaluate(
      renderTiming: presentationTiming,
      inputTiming: inputTiming,
      frameQuality: _latestFrameQuality,
    );
    final timing = timingEngine.completeReaction(
      compensation: LatencyCompensation(
        estimatedRenderDelayMs: presentationTiming?.renderDelayMs ?? 0,
        estimatedInputDelayMs: state.calibrationOffsetMs,
      ),
      inputTiming: inputTiming,
    );

    if (timing.rawReactionTimeMs < falseStartThresholdMs) {
      _recordFalseStart();
      return;
    }

    final result = ReactionRoundResult(
      roundNumber: state.currentRoundNumber,
      rawReactionTimeMs: timing.rawReactionTimeMs,
      estimatedRenderDelayMs: timing.estimatedRenderDelayMs,
      estimatedInputDelayMs: timing.estimatedInputDelayMs,
      calibratedReactionTimeMs: timing.calibratedReactionTimeMs,
      leaderboardEligible: evidence.leaderboardEligible,
      qualityScore: evidence.qualityScore,
      qualityFlags: evidence.flags,
    );
    state = state.copyWith(
      phase: ReactionTestPhase.result,
      currentResult: result,
      results: List.unmodifiable([...state.results, result]),
      clearSummary: true,
    );
  }

  void _recordFalseStart() {
    _cancelScheduledTasks();
    state = state.copyWith(
      phase: ReactionTestPhase.falseStart,
      clearCurrentResult: true,
    );
  }

  ReactionSessionSummary _buildSummary(
    List<ReactionRoundResult> results,
    int selectedRoundCount,
  ) {
    final values = results
        .map((result) => result.calibratedReactionTimeMs)
        .toList();
    final average =
        values.reduce((value, element) => value + element) / values.length;
    final best = values.reduce(min);
    final worst = values.reduce(max);
    final variance =
        values
            .map((value) => pow(value - average, 2))
            .reduce((value, element) => value + element) /
        values.length;
    final sorted = [...values]..sort();
    final trimmedMean = selectedRoundCount >= 15 && sorted.length >= 3
        ? sorted
                  .sublist(1, sorted.length - 1)
                  .reduce((value, element) => value + element) /
              (sorted.length - 2)
        : null;

    return ReactionSessionSummary(
      averageReactionTimeMs: average,
      bestReactionTimeMs: best,
      worstReactionTimeMs: worst,
      standardDeviationMs: sqrt(variance),
      trimmedMeanMs: trimmedMean,
    );
  }

  void _cancelScheduledTasks() {
    _cancelSignalTask?.call();
    _cancelSignalTask = null;
    _cancelTimeoutTask?.call();
    _cancelTimeoutTask = null;
  }

  @override
  void dispose() {
    _cancelScheduledTasks();
    super.dispose();
  }
}
