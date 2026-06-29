import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_session_history.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_session_record.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_test_controller.dart';

void main() {
  test('keeps the newest 50 completed reaction sessions', () {
    final history = ReactionSessionHistoryNotifier();

    for (var index = 0; index < 51; index += 1) {
      history.add(_record(index));
    }

    expect(history.state, hasLength(50));
    expect(history.state.first.completedAt, DateTime.utc(2026, 1, 1, 0, 0, 50));
    expect(history.state.last.completedAt, DateTime.utc(2026, 1, 1, 0, 0, 1));
  });
}

ReactionSessionRecord _record(int index) {
  const result = ReactionRoundResult(
    roundNumber: 1,
    rawReactionTimeMs: 220,
    estimatedRenderDelayMs: 10,
    estimatedInputDelayMs: 5,
    calibratedReactionTimeMs: 205,
    leaderboardEligible: true,
    qualityScore: 100,
    qualityFlags: [],
  );
  return ReactionSessionRecord.fromCompletedState(
    const ReactionTestState(
      phase: ReactionTestPhase.completed,
      selectedRoundCount: 5,
      results: [result],
      summary: ReactionSessionSummary(
        averageReactionTimeMs: 205,
        bestReactionTimeMs: 205,
        worstReactionTimeMs: 205,
        standardDeviationMs: 0,
      ),
    ),
    completedAt: DateTime.utc(2026, 1, 1, 0, 0, index),
  );
}
