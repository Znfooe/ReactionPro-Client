import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/core/precision/precision_timing.dart';

void main() {
  group('InputEventTiming', () {
    test(
      'uses browser event timestamp when it shares the performance clock',
      () {
        const timing = InputEventTiming(
          eventTimestampMs: 1000,
          handledAtMs: 1006,
        );

        expect(timing.effectiveTimestampMs, 1000);
        expect(timing.handlerDelayMs, 6);
      },
    );

    test(
      'falls back to handler time when event timestamp is not comparable',
      () {
        const timing = InputEventTiming(
          eventTimestampMs: 100000,
          handledAtMs: 1000,
        );

        expect(timing.effectiveTimestampMs, 1000);
        expect(timing.handlerDelayMs, isNull);
      },
    );
  });

  group('FrameQualityMonitor', () {
    test('summarizes frame interval and dropped frame evidence', () {
      final monitor = FrameQualityMonitor()..reset(nowMs: 0);

      monitor
        ..recordFrame(16)
        ..recordFrame(32)
        ..recordFrame(82);

      final snapshot = monitor.snapshot();

      expect(snapshot.sampleCount, 3);
      expect(snapshot.averageFrameIntervalMs, closeTo(27.33, 0.01));
      expect(snapshot.maxFrameIntervalMs, 50);
      expect(snapshot.droppedFrameCount, 1);
    });
  });

  group('PrecisionQualityPolicy', () {
    test('accepts clean timing evidence for leaderboard', () {
      const policy = PrecisionQualityPolicy(minimumFrameSamples: 2);
      final evidence = policy.evaluate(
        renderTiming: const RenderPresentationTiming(
          requestedAtMs: 100,
          presentedAtMs: 108,
        ),
        inputTiming: const InputEventTiming(
          eventTimestampMs: 350,
          handledAtMs: 354,
        ),
        frameQuality: const FrameQualitySnapshot(
          sampleCount: 2,
          averageFrameIntervalMs: 16,
          maxFrameIntervalMs: 17,
          droppedFrameCount: 0,
          estimatedRefreshRateHz: 62.5,
        ),
      );

      expect(evidence.leaderboardEligible, isTrue);
      expect(evidence.qualityScore, 100);
      expect(evidence.flags, isEmpty);
      expect(evidence.droppedFrameRate, 0);
    });

    test('tolerates occasional dropped frames below five percent', () {
      const policy = PrecisionQualityPolicy(minimumFrameSamples: 2);
      final evidence = policy.evaluate(
        renderTiming: const RenderPresentationTiming(
          requestedAtMs: 100,
          presentedAtMs: 108,
        ),
        inputTiming: const InputEventTiming(
          eventTimestampMs: 350,
          handledAtMs: 354,
        ),
        frameQuality: const FrameQualitySnapshot(
          sampleCount: 100,
          averageFrameIntervalMs: 16.8,
          maxFrameIntervalMs: 50,
          droppedFrameCount: 4,
          estimatedRefreshRateHz: 59.5,
        ),
      );

      expect(evidence.leaderboardEligible, isTrue);
      expect(evidence.qualityScore, 100);
      expect(evidence.flags, isEmpty);
      expect(evidence.droppedFrameRate, closeTo(0.04, 0.0001));
    });

    test('rejects sustained frame drops and severe frame stalls', () {
      const policy = PrecisionQualityPolicy(minimumFrameSamples: 2);
      final evidence = policy.evaluate(
        renderTiming: const RenderPresentationTiming(
          requestedAtMs: 100,
          presentedAtMs: 108,
        ),
        inputTiming: const InputEventTiming(
          eventTimestampMs: 350,
          handledAtMs: 354,
        ),
        frameQuality: const FrameQualitySnapshot(
          sampleCount: 100,
          averageFrameIntervalMs: 19,
          maxFrameIntervalMs: 120,
          droppedFrameCount: 6,
          estimatedRefreshRateHz: 52.6,
        ),
      );

      expect(evidence.leaderboardEligible, isFalse);
      expect(evidence.flags, contains('frame_interval_high'));
      expect(evidence.flags, contains('dropped_frames'));
    });

    test('rejects scores with missing render evidence and dropped frames', () {
      const policy = PrecisionQualityPolicy(minimumFrameSamples: 2);
      final evidence = policy.evaluate(
        inputTiming: const InputEventTiming(
          eventTimestampMs: 350,
          handledAtMs: 390,
        ),
        frameQuality: const FrameQualitySnapshot(
          sampleCount: 2,
          averageFrameIntervalMs: 24,
          maxFrameIntervalMs: 52,
          droppedFrameCount: 1,
          estimatedRefreshRateHz: 41.6,
        ),
      );

      expect(evidence.leaderboardEligible, isFalse);
      expect(evidence.flags, contains('render_timestamp_missing'));
      expect(evidence.flags, contains('input_handler_delay_high'));
      expect(evidence.flags, contains('dropped_frames'));
    });
  });
}
