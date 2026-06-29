import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final scoreServiceProvider = Provider<ScoreService>((ref) {
  return ScoreService(ref.watch(dioProvider));
});

final myScoreHistoryProvider = FutureProvider.autoDispose<MyScoreHistory>((
  ref,
) {
  return ref.watch(scoreServiceProvider).fetchMyScores();
});

final class MyScoreSummary {
  const MyScoreSummary({
    required this.totalTests,
    required this.reactionTests,
    required this.averageReactionTime,
    required this.bestReactionTime,
    required this.aimTests,
    required this.averageKillTime,
    required this.bestKillTime,
  });

  final int totalTests;
  final int reactionTests;
  final int? averageReactionTime;
  final int? bestReactionTime;
  final int aimTests;
  final int? averageKillTime;
  final int? bestKillTime;

  factory MyScoreSummary.fromJson(Map<String, Object?> json) {
    return MyScoreSummary(
      totalTests: json['totalTests'] as int,
      reactionTests: json['reactionTests'] as int,
      averageReactionTime: json['averageReactionTime'] as int?,
      bestReactionTime: json['bestReactionTime'] as int?,
      aimTests: json['aimTests'] as int,
      averageKillTime: json['averageKillTime'] as int?,
      bestKillTime: json['bestKillTime'] as int?,
    );
  }
}

final class MyScoreItem {
  const MyScoreItem({
    required this.id,
    required this.testType,
    required this.roundCount,
    required this.calibratedTime,
    required this.rawTime,
    required this.avgKillTime,
    required this.bestTime,
    required this.isValid,
    required this.leaderboardEligible,
    required this.leaderboardQualified,
    required this.leaderboardAnonymous,
    required this.qualityScore,
    required this.createdAt,
  });

  final String id;
  final String testType;
  final int? roundCount;
  final int? calibratedTime;
  final int? rawTime;
  final int? avgKillTime;
  final int? bestTime;
  final bool isValid;
  final bool leaderboardEligible;
  final bool leaderboardQualified;
  final bool leaderboardAnonymous;
  final int qualityScore;
  final DateTime createdAt;

  factory MyScoreItem.fromJson(Map<String, Object?> json) {
    return MyScoreItem(
      id: json['id'] as String,
      testType: json['testType'] as String,
      roundCount: json['roundCount'] as int?,
      calibratedTime: json['calibratedTime'] as int?,
      rawTime: json['rawTime'] as int?,
      avgKillTime: json['avgKillTime'] as int?,
      bestTime: json['bestTime'] as int?,
      isValid: json['isValid'] as bool,
      leaderboardEligible: json['leaderboardEligible'] as bool,
      leaderboardQualified: json['leaderboardQualified'] as bool? ?? false,
      leaderboardAnonymous: json['leaderboardAnonymous'] as bool? ?? false,
      qualityScore: json['qualityScore'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

final class MyScoreHistory {
  const MyScoreHistory({required this.summary, required this.items});

  final MyScoreSummary summary;
  final List<MyScoreItem> items;

  factory MyScoreHistory.fromJson(Map<String, Object?> json) {
    final summary = json['summary'];
    final items = json['items'];
    if (summary is! Map<String, Object?> || items is! List<Object?>) {
      throw const FormatException('Invalid score history response data.');
    }
    return MyScoreHistory(
      summary: MyScoreSummary.fromJson(summary),
      items: [
        for (final item in items)
          if (item is Map<String, Object?>) MyScoreItem.fromJson(item),
      ],
    );
  }
}

final class SubmittedScore {
  const SubmittedScore({
    required this.id,
    required this.testType,
    required this.category,
    required this.isValid,
    required this.leaderboardEligible,
    required this.leaderboardAnonymous,
    required this.qualityScore,
    required this.qualityFlags,
    required this.createdAt,
  });

  final String id;
  final String testType;
  final String category;
  final bool isValid;
  final bool leaderboardEligible;
  final bool leaderboardAnonymous;
  final int qualityScore;
  final List<String> qualityFlags;
  final DateTime createdAt;

  factory SubmittedScore.fromJson(Map<String, Object?> json) {
    return SubmittedScore(
      id: json['id'] as String,
      testType: json['testType'] as String,
      category: json['category'] as String,
      isValid: json['isValid'] as bool,
      leaderboardEligible: json['leaderboardEligible'] as bool,
      leaderboardAnonymous: json['leaderboardAnonymous'] as bool? ?? false,
      qualityScore: json['qualityScore'] as int,
      qualityFlags: [
        for (final flag in (json['qualityFlags'] as List<Object?>? ?? const []))
          if (flag is String) flag,
      ],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

final class ScoreService {
  const ScoreService(this._dio);

  final Dio _dio;

  Future<MyScoreHistory> fetchMyScores({int limit = 50}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/scores/me',
      queryParameters: {'limit': limit},
    );
    return MyScoreHistory.fromJson(_unwrapData(response.data));
  }

  Future<SubmittedScore> submitReactionScore({
    required int roundCount,
    required int rawTime,
    required int calibratedTime,
    required int estimatedRenderDelay,
    required int estimatedInputDelay,
    required bool leaderboardEligible,
    required int qualityScore,
    required List<String> qualityFlags,
    Map<String, Object?>? precisionData,
    List<Map<String, Object?>>? perRoundData,
  }) {
    final payload = <String, Object?>{
      'testType': 'reaction',
      'roundCount': roundCount,
      'rawTime': rawTime,
      'calibratedTime': calibratedTime,
      'estimatedRenderDelay': estimatedRenderDelay,
      'estimatedInputDelay': estimatedInputDelay,
      'leaderboardEligible': leaderboardEligible,
      'qualityScore': qualityScore,
      'qualityFlags': qualityFlags,
    };
    if (precisionData != null) {
      payload['precisionData'] = precisionData;
    }
    if (perRoundData != null) {
      payload['perRoundData'] = perRoundData;
    }
    return _submit(payload);
  }

  Future<SubmittedScore> submitAimScore({
    required String aimMode,
    required String evalMode,
    required String targetBehavior,
    required int avgKillTime,
    required double hitRate,
    required double errorRate,
    required int totalKills,
    required int totalShots,
    required bool leaderboardEligible,
    required int qualityScore,
    required List<String> qualityFlags,
    int? targetCount,
    int? duration,
    String? targetSize,
    String? targetSpeed,
    String? directionMode,
    int? multiTargetCount,
    int? bestTime,
    int? worstTime,
    int? trimmedMean,
    double? sensitivity,
    double? mYaw,
    double? mPitch,
    int? dpi,
    Map<String, Object?>? precisionData,
    List<Map<String, Object?>>? perRoundData,
  }) {
    final payload = <String, Object?>{
      'testType': 'aim',
      'aimMode': aimMode,
      'evalMode': evalMode,
      'targetBehavior': targetBehavior,
      'avgKillTime': avgKillTime,
      'hitRate': hitRate,
      'errorRate': errorRate,
      'totalKills': totalKills,
      'totalShots': totalShots,
      'leaderboardEligible': leaderboardEligible,
      'qualityScore': qualityScore,
      'qualityFlags': qualityFlags,
    };
    if (targetCount != null) {
      payload['targetCount'] = targetCount;
    }
    if (duration != null) {
      payload['duration'] = duration;
    }
    if (targetSize != null) {
      payload['targetSize'] = targetSize;
    }
    if (targetSpeed != null) {
      payload['targetSpeed'] = targetSpeed;
    }
    if (directionMode != null) {
      payload['directionMode'] = directionMode;
    }
    if (multiTargetCount != null) {
      payload['multiTargetCount'] = multiTargetCount;
    }
    if (sensitivity != null) {
      payload['sensitivity'] = sensitivity;
    }
    if (mYaw != null) {
      payload['mYaw'] = mYaw;
    }
    if (mPitch != null) {
      payload['mPitch'] = mPitch;
    }
    if (dpi != null) {
      payload['dpi'] = dpi;
    }
    if (bestTime != null) {
      payload['bestTime'] = bestTime;
    }
    if (worstTime != null) {
      payload['worstTime'] = worstTime;
    }
    if (trimmedMean != null) {
      payload['trimmedMean'] = trimmedMean;
    }
    if (precisionData != null) {
      payload['precisionData'] = precisionData;
    }
    if (perRoundData != null) {
      payload['perRoundData'] = perRoundData;
    }
    return _submit(payload);
  }

  Future<SubmittedScore> publishToLeaderboard({
    required String scoreId,
    required bool anonymous,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/scores/$scoreId/leaderboard',
      data: {'anonymous': anonymous},
    );
    final data = _unwrapData(response.data);
    final score = data['score'];
    if (score is Map<String, Object?>) {
      return SubmittedScore.fromJson(score);
    }
    throw const FormatException('Invalid score response data.');
  }

  Future<SubmittedScore> _submit(Map<String, Object?> payload) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/scores',
      data: payload,
    );
    final data = _unwrapData(response.data);
    final score = data['score'];
    if (score is Map<String, Object?>) {
      return SubmittedScore.fromJson(score);
    }
    throw const FormatException('Invalid score response data.');
  }

  Map<String, Object?> _unwrapData(Map<String, Object?>? body) {
    final data = body?['data'];
    if (data is Map<String, Object?>) {
      return data;
    }
    throw const FormatException('Invalid API response data.');
  }
}
