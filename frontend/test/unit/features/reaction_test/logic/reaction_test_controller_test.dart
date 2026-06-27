import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/core/precision/precision_timing.dart';
import 'package:reaction_time_test/features/reaction_test/core/timing_engine.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_test_controller.dart';

final class FakePerformanceTimer implements PerformanceTimer {
  FakePerformanceTimer(this._now);

  double _now;

  void setNow(double value) {
    _now = value;
  }

  @override
  double now() => _now;
}

final class NoopReactionScheduler implements ReactionPhaseScheduler {
  @override
  CancelScheduledTask schedule(Duration delay, void Function() callback) {
    return () {};
  }
}

final class FixedDelayGenerator implements ReactionDelayGenerator {
  const FixedDelayGenerator(this.delay);

  final Duration delay;

  @override
  Duration nextDelay({required int minSeconds, required int maxSeconds}) =>
      delay;
}

final class ImmediateFrameClock implements ReactionRenderFrameClock {
  const ImmediateFrameClock(this.timer);

  final PerformanceTimer timer;

  @override
  void afterNextFrame(void Function(double timestampMs) callback) {
    callback(timer.now());
  }
}

ReactionTestController buildController(FakePerformanceTimer timer) {
  return ReactionTestController(
    timingEngine: TimingEngine(timer: timer),
    scheduler: NoopReactionScheduler(),
    delayGenerator: const FixedDelayGenerator(Duration(seconds: 3)),
    frameClock: ImmediateFrameClock(timer),
    qualityPolicy: const PrecisionQualityPolicy(minimumFrameSamples: 0),
  );
}

void main() {
  group('ReactionTestController', () {
    test('等待期点击应判定为抢跑且不消耗回合数', () {
      final controller = buildController(FakePerformanceTimer(1000));

      controller.startSession();
      controller.tapArena();

      expect(controller.state.phase, ReactionTestPhase.falseStart);
      expect(controller.state.completedRoundCount, 0);
      expect(controller.state.results, isEmpty);
      expect(controller.state.currentRoundNumber, 1);
    });

    test('信号出现时间范围至少保持 5 秒跨度', () {
      final controller = buildController(FakePerformanceTimer(1000));

      controller.setSignalDelayRange(minSeconds: 3, maxSeconds: 5);

      expect(controller.state.signalMinDelaySeconds, 3);
      expect(controller.state.signalMaxDelaySeconds, 8);
    });

    test('信号期点击应记录本回合原始反应时间与校准反应时间', () {
      final timer = FakePerformanceTimer(1000);
      final controller = buildController(timer);

      controller.setCalibrationOffset(24);
      controller.startSession();
      controller.enterSignalPhase();
      timer.setNow(1250);
      controller.tapArena();

      expect(controller.state.phase, ReactionTestPhase.result);
      expect(controller.state.completedRoundCount, 1);
      expect(controller.state.currentResult?.rawReactionTimeMs, 250);
      expect(controller.state.currentResult?.estimatedInputDelayMs, 24);
      expect(controller.state.currentResult?.calibratedReactionTimeMs, 226);
    });

    test('信号期 100ms 内点击应判定为抢跑', () {
      final timer = FakePerformanceTimer(1000);
      final controller = buildController(timer);

      controller.startSession();
      controller.enterSignalPhase();
      timer.setNow(1099);
      controller.tapArena();

      expect(controller.state.phase, ReactionTestPhase.falseStart);
      expect(controller.state.completedRoundCount, 0);
      expect(controller.state.results, isEmpty);
    });

    test('信号期超过 2 秒应进入超时且不消耗回合数', () {
      final controller = buildController(FakePerformanceTimer(1000));

      controller.startSession();
      controller.enterSignalPhase();
      controller.timeoutSignal();

      expect(controller.state.phase, ReactionTestPhase.timeout);
      expect(controller.state.completedRoundCount, 0);
      expect(controller.state.results, isEmpty);
    });

    test('完成回合组后应生成平均最优最差与标准差总结', () {
      final timer = FakePerformanceTimer(1000);
      final controller = buildController(timer);

      controller.startSession();
      for (final rawMs in [200, 240, 220, 260, 280]) {
        controller.enterSignalPhase();
        timer.setNow(timer.now() + rawMs);
        controller.tapArena();
        controller.continueAfterResult();
      }

      expect(controller.state.phase, ReactionTestPhase.completed);
      expect(controller.state.summary?.averageReactionTimeMs, 240);
      expect(controller.state.summary?.bestReactionTimeMs, 200);
      expect(controller.state.summary?.worstReactionTimeMs, 280);
      expect(
        controller.state.summary?.standardDeviationMs,
        closeTo(28.28, 0.01),
      );
      expect(controller.state.summary?.trimmedMeanMs, isNull);
    });

    test('15 回合组应生成去极值平均', () {
      final timer = FakePerformanceTimer(1000);
      final controller = buildController(timer);

      controller.selectRoundCount(15);
      controller.startSession();
      for (final rawMs in [
        180,
        190,
        200,
        210,
        220,
        230,
        240,
        250,
        260,
        270,
        280,
        290,
        300,
        310,
        320,
      ]) {
        controller.enterSignalPhase();
        timer.setNow(timer.now() + rawMs);
        controller.tapArena();
        controller.continueAfterResult();
      }

      expect(controller.state.phase, ReactionTestPhase.completed);
      expect(controller.state.summary?.trimmedMeanMs, 250);
    });
  });
}
