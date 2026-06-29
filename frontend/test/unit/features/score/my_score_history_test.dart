import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/score/services/score_service.dart';

void main() {
  test('parses the current user score summary and recent items', () {
    final history = MyScoreHistory.fromJson({
      'summary': <String, Object?>{
        'totalTests': 2,
        'reactionTests': 1,
        'averageReactionTime': 218,
        'bestReactionTime': 218,
        'aimTests': 1,
        'averageKillTime': 310,
        'bestKillTime': 280,
      },
      'items': <Object?>[
        <String, Object?>{
          'id': '2',
          'testType': 'aim',
          'roundCount': null,
          'calibratedTime': null,
          'rawTime': null,
          'avgKillTime': 310,
          'bestTime': 280,
          'isValid': true,
          'leaderboardEligible': false,
          'qualityScore': 88,
          'createdAt': '2026-06-29T01:00:00.000Z',
        },
      ],
    });

    expect(history.summary.totalTests, 2);
    expect(history.summary.averageReactionTime, 218);
    expect(history.items.single.testType, 'aim');
    expect(history.items.single.avgKillTime, 310);
  });
}
