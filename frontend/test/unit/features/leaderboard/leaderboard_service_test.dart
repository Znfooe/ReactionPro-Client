import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/leaderboard/services/leaderboard_service.dart';

void main() {
  test('匿名榜单项不应包含用户标识和头像', () {
    final result = LeaderboardResult.fromJson({
      'category': 'reaction_5',
      'total': 1,
      'items': <Object?>[
        <String, Object?>{
          'rank': 1,
          'scoreId': 'score-1',
          'userId': null,
          'displayName': '匿名玩家',
          'avatarUrl': null,
          'anonymous': true,
          'testType': 'reaction',
          'scoreValue': 226,
          'createdAt': '2026-06-29T08:00:00.000Z',
        },
      ],
    });

    final entry = result.items.single;
    expect(entry.userId, isNull);
    expect(entry.displayName, '匿名玩家');
    expect(entry.avatarUrl, isNull);
    expect(entry.anonymous, isTrue);
  });
}
