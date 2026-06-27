import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(ref.watch(dioProvider));
});

final leaderboardProvider = FutureProvider.autoDispose
    .family<LeaderboardResult, LeaderboardQuery>((ref, query) {
      return ref.watch(leaderboardServiceProvider).fetchLeaderboard(query);
    });

final class LeaderboardQuery {
  const LeaderboardQuery({required this.category, this.limit = 50});

  final String category;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is LeaderboardQuery &&
        other.category == category &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(category, limit);
}

final class LeaderboardResult {
  const LeaderboardResult({
    required this.category,
    required this.items,
    required this.total,
  });

  final String category;
  final List<LeaderboardEntry> items;
  final int total;

  factory LeaderboardResult.fromJson(Map<String, Object?> json) {
    return LeaderboardResult(
      category: json['category'] as String,
      total: json['total'] as int,
      items: [
        for (final item in (json['items'] as List<Object?>? ?? const []))
          if (item is Map<String, Object?>) LeaderboardEntry.fromJson(item),
      ],
    );
  }
}

final class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.scoreId,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.testType,
    required this.scoreValue,
    required this.createdAt,
  });

  final int rank;
  final String scoreId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String testType;
  final int scoreValue;
  final DateTime createdAt;

  factory LeaderboardEntry.fromJson(Map<String, Object?> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      scoreId: json['scoreId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      testType: json['testType'] as String,
      scoreValue: json['scoreValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

final class LeaderboardService {
  const LeaderboardService(this._dio);

  final Dio _dio;

  Future<LeaderboardResult> fetchLeaderboard(LeaderboardQuery query) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/leaderboards',
      queryParameters: {'category': query.category, 'limit': query.limit},
    );
    final data = _unwrapData(response.data);
    return LeaderboardResult.fromJson(data);
  }

  Map<String, Object?> _unwrapData(Map<String, Object?>? body) {
    final data = body?['data'];
    if (data is Map<String, Object?>) {
      return data;
    }
    throw const FormatException('Invalid leaderboard response data.');
  }
}
