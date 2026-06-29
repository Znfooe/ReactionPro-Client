import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/core/theme/app_theme.dart';
import 'package:reaction_time_test/features/score/services/score_service.dart';
import 'package:reaction_time_test/features/score/widgets/score_submit_panel.dart';

void main() {
  testWidgets('提交成功后应立即显示提交完成', (tester) async {
    final submittedScore = ValueNotifier<SubmittedScore?>(null);
    addTearDown(submittedScore.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ValueListenableBuilder<SubmittedScore?>(
            valueListenable: submittedScore,
            builder: (context, value, child) {
              return ScoreSubmitPanel(
                completed: true,
                authenticated: true,
                submitting: false,
                submittedScore: value,
                onSubmit: () {},
                onLogin: () {},
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('成绩尚未提交'), findsOneWidget);

    submittedScore.value = SubmittedScore(
      id: 'score-1',
      testType: 'reaction',
      category: 'reaction_5',
      isValid: true,
      leaderboardEligible: false,
      leaderboardAnonymous: false,
      qualityScore: 96,
      qualityFlags: const [],
      createdAt: DateTime.utc(2026, 6, 29),
    );
    await tester.pump();

    expect(find.text('提交完成'), findsOneWidget);
  });
}
