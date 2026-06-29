import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_session_record.dart';
import 'package:reaction_time_test/features/reaction_test/logic/reaction_test_controller.dart';
import 'package:reaction_time_test/features/reaction_test/widgets/reaction_result_details.dart';
import 'package:reaction_time_test/core/theme/app_theme.dart';

void main() {
  testWidgets('反应力结果详情应展示延迟汇总与全部逐回合字段', (tester) async {
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
    final entry = ReactionSessionRecord.fromCompletedState(
      state,
      completedAt: DateTime.utc(2026, 6, 27, 8, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReactionResultDetails(entry: entry),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('延迟分解汇总'), findsOneWidget);
    expect(find.text('测试配置'), findsOneWidget);
    expect(find.text('回合趋势'), findsOneWidget);
    expect(find.text('逐回合完整数据'), findsOneWidget);
    expect(find.text('原始反应'), findsOneWidget);
    expect(find.text('渲染延迟'), findsOneWidget);
    expect(find.text('输入延迟'), findsOneWidget);
    expect(find.text('硬件延迟估算'), findsOneWidget);
    expect(find.text('校准反应'), findsOneWidget);
    expect(find.text('质量分'), findsWidgets);
    expect(find.text('质量标记'), findsWidgets);
    expect(find.text('frame_jitter'), findsWidgets);
  });

  testWidgets('历史记录未展开时应直接显示弹窗查看按钮', (tester) async {
    const round = ReactionRoundResult(
      roundNumber: 1,
      rawReactionTimeMs: 240,
      estimatedRenderDelayMs: 16,
      estimatedInputDelayMs: 8,
      calibratedReactionTimeMs: 216,
      leaderboardEligible: true,
      qualityScore: 96,
      qualityFlags: [],
    );
    const state = ReactionTestState(
      phase: ReactionTestPhase.completed,
      selectedRoundCount: 1,
      results: [round],
      summary: ReactionSessionSummary(
        averageReactionTimeMs: 216,
        bestReactionTimeMs: 216,
        worstReactionTimeMs: 216,
        standardDeviationMs: 0,
      ),
      calibrationOffsetMs: 8,
      signalMinDelaySeconds: 2,
      signalMaxDelaySeconds: 7,
    );
    final entry = ReactionSessionRecord.fromCompletedState(
      state,
      completedAt: DateTime.utc(2026, 6, 29, 0, 31),
    );
    ReactionSessionRecord? openedEntry;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReactionHistoryPanel(
            entries: [entry],
            onOpenDetails: (value) => openedEntry = value,
          ),
        ),
      ),
    );

    expect(find.text('弹窗查看'), findsOneWidget);
    expect(find.text('延迟分解汇总'), findsNothing);

    await tester.tap(find.text('弹窗查看'));
    await tester.pump();

    expect(openedEntry, same(entry));
    expect(find.text('延迟分解汇总'), findsNothing);
  });
}
