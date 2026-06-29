import 'reaction_test_controller.dart';

final class ReactionSessionRecord {
  const ReactionSessionRecord._({
    required this.completedAt,
    required this.selectedRoundCount,
    required this.rounds,
    required this.summary,
    required this.calibrationOffsetMs,
    required this.signalMinDelaySeconds,
    required this.signalMaxDelaySeconds,
  });

  factory ReactionSessionRecord.fromCompletedState(
    ReactionTestState state, {
    required DateTime completedAt,
  }) {
    final summary = state.summary;
    if (state.phase != ReactionTestPhase.completed ||
        summary == null ||
        state.results.isEmpty) {
      throw StateError('只有已完成的回合组可以生成历史记录');
    }

    return ReactionSessionRecord._(
      completedAt: completedAt,
      selectedRoundCount: state.selectedRoundCount,
      rounds: List<ReactionRoundResult>.unmodifiable(state.results),
      summary: summary,
      calibrationOffsetMs: state.calibrationOffsetMs,
      signalMinDelaySeconds: state.signalMinDelaySeconds,
      signalMaxDelaySeconds: state.signalMaxDelaySeconds,
    );
  }

  final DateTime completedAt;
  final int selectedRoundCount;
  final List<ReactionRoundResult> rounds;
  final ReactionSessionSummary summary;
  final double calibrationOffsetMs;
  final int signalMinDelaySeconds;
  final int signalMaxDelaySeconds;

  double get averageRawReactionTimeMs =>
      _average(rounds.map((round) => round.rawReactionTimeMs));

  double get averageCalibratedReactionTimeMs =>
      _average(rounds.map((round) => round.calibratedReactionTimeMs));

  double get averageEstimatedRenderDelayMs =>
      _average(rounds.map((round) => round.estimatedRenderDelayMs));

  double get averageEstimatedInputDelayMs =>
      _average(rounds.map((round) => round.estimatedInputDelayMs));

  double get averageHardwareLatencyEstimateMs =>
      _average(rounds.map((round) => round.hardwareLatencyEstimateMs));

  int get totalFrameSampleCount =>
      rounds.fold(0, (total, round) => total + round.frameSampleCount);

  int get totalDroppedFrameCount =>
      rounds.fold(0, (total, round) => total + round.droppedFrameCount);

  double get droppedFrameRate {
    final sampleCount = totalFrameSampleCount;
    return sampleCount == 0 ? 0 : totalDroppedFrameCount / sampleCount;
  }

  bool get leaderboardEligible =>
      rounds.every((round) => round.leaderboardEligible);

  int get qualityScore => rounds
      .map((round) => round.qualityScore)
      .reduce((left, right) => left < right ? left : right);

  List<String> get qualityFlags => List<String>.unmodifiable({
    for (final round in rounds) ...round.qualityFlags,
  });

  static double _average(Iterable<int> values) {
    final list = values.toList(growable: false);
    return list.reduce((left, right) => left + right) / list.length;
  }
}
