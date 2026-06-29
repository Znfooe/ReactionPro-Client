import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/core/theme/app_theme.dart';
import 'package:reaction_time_test/features/profile/widgets/score_detail_dialog.dart';
import 'package:reaction_time_test/features/score/services/score_service.dart';

void main() {
  testWidgets('成绩详情应展示精度与逐回合数据', (tester) async {
    final detail = ScoreDetail.fromJson({
      'id': '1',
      'testType': 'reaction',
      'qualityScore': 100,
      'precisionData': {'droppedFrameRate': 0.02},
      'perRoundData': [
        {'roundNumber': 1, 'calibratedReactionTimeMs': 226},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ScoreDetailDialog(detail: Future.value(detail))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试完整数据'), findsOneWidget);
    expect(find.text('精度数据'), findsOneWidget);
    expect(find.text('逐回合数据'), findsOneWidget);
    expect(find.text('2.0%'), findsOneWidget);
    expect(find.text('回合 1'), findsOneWidget);
  });
}
