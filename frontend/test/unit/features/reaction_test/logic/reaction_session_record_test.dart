import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_session_record.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_test_controller.dart';

void main() {
  group('ReactionSessionRecord', () {
    test('完成回合组应快照全部逐回合数据与延迟汇总', () {
      const rounds = [
        ReactionRoundResult(
          roundNumber: 1,
          rawReactionTimeMs: 240,
          estimatedRenderDelayMs: 16,
          estimatedInputDelayMs: 8,
          calibratedReactionTimeMs: 216,
          leaderboardEligible: true,
          qualityScore: 96,
          qualityFlags: [],
        ),
        ReactionRoundResult(
          roundNumber: 2,
          rawReactionTimeMs: 280,
          estimatedRenderDelayMs: 20,
          estimatedInputDelayMs: 10,
          calibratedReactionTimeMs: 250,
          leaderboardEligible: false,
          qualityScore: 82,
          qualityFlags: ['frame_jitter'],
        ),
      ];
      const state = ReactionTestState(
        phase: ReactionTestPhase.completed,
        selectedRoundCount: 2,
        results: rounds,
        summary: ReactionSessionSummary(
          averageReactionTimeMs: 233,
          bestReactionTimeMs: 216,
          worstReactionTimeMs: 250,
          standardDeviationMs: 17,
        ),
        calibrationOffsetMs: 9,
        signalMinDelaySeconds: 2,
        signalMaxDelaySeconds: 7,
      );
      final completedAt = DateTime.utc(2026, 6, 27, 8, 30);

      final record = ReactionSessionRecord.fromCompletedState(
        state,
        completedAt: completedAt,
      );

      expect(record.completedAt, completedAt);
      expect(record.rounds, rounds);
      expect(record.averageRawReactionTimeMs, 260);
      expect(record.averageCalibratedReactionTimeMs, 233);
      expect(record.averageEstimatedRenderDelayMs, 18);
      expect(record.averageEstimatedInputDelayMs, 9);
      expect(record.averageHardwareLatencyEstimateMs, 27);
      expect(record.leaderboardEligible, isFalse);
      expect(record.qualityScore, 82);
      expect(record.qualityFlags, ['frame_jitter']);
      expect(record.signalMinDelaySeconds, 2);
      expect(record.signalMaxDelaySeconds, 7);
      expect(record.calibrationOffsetMs, 9);
    });

    test('未完成的回合组不能生成历史记录', () {
      expect(
        () => ReactionSessionRecord.fromCompletedState(
          const ReactionTestState(),
          completedAt: DateTime.utc(2026),
        ),
        throwsStateError,
      );
    });
  });
}
