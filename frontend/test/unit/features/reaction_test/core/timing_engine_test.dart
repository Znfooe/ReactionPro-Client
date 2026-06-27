import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/reaction_test/core/timing_engine.dart';

final class FakePerformanceTimer implements PerformanceTimer {
  FakePerformanceTimer(this._now);

  double _now;

  void setNow(double value) {
    _now = value;
  }

  @override
  double now() => _now;
}

void main() {
  group('BrowserPerformanceTimer', () {
    test('原生平台应提供单调递增的高精度时间戳', () async {
      const timer = BrowserPerformanceTimer();

      final first = timer.now();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final second = timer.now();

      expect(first, isNonNegative);
      expect(first.isFinite, isTrue);
      expect(second, greaterThan(first));
    });
  });

  group('TimingEngine', () {
    test('校准反应时间应扣除估计渲染延迟与输入延迟', () {
      final timer = FakePerformanceTimer(1000);
      final engine = TimingEngine(timer: timer);

      engine.markSignalShown();
      timer.setNow(1250);

      final result = engine.completeReaction(
        compensation: const LatencyCompensation(
          estimatedRenderDelayMs: 16,
          estimatedInputDelayMs: 8,
        ),
      );

      expect(result.rawReactionTimeMs, 250);
      expect(result.hardwareLatencyEstimateMs, 24);
      expect(result.calibratedReactionTimeMs, 226);
    });

    test('未进入信号期时完成计时应抛出状态错误', () {
      final engine = TimingEngine(timer: FakePerformanceTimer(1000));

      expect(() => engine.completeReaction(), throwsA(isA<StateError>()));
    });

    test('校准反应时间不得为负数', () {
      final timer = FakePerformanceTimer(1000);
      final engine = TimingEngine(timer: timer);

      engine.markSignalShown();
      timer.setNow(1020);

      final result = engine.completeReaction(
        compensation: const LatencyCompensation(
          estimatedRenderDelayMs: 16,
          estimatedInputDelayMs: 8,
        ),
      );

      expect(result.rawReactionTimeMs, 20);
      expect(result.calibratedReactionTimeMs, 0);
    });
  });
}
