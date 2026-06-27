import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final scoreServiceProvider = Provider<ScoreService>((ref) {
  return ScoreService(ref.watch(dioProvider));
});

final class SubmittedScore {
  const SubmittedScore({
    required this.id,
    required this.testType,
    required this.category,
    required this.isValid,
    required this.leaderboardEligible,
    required this.qualityScore,
    required this.qualityFlags,
    required this.createdAt,
  });

  final String id;
  final String testType;
  final String category;
  final bool isValid;
  final bool leaderboardEligible;
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
