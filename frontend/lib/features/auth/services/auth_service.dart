import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../models/user_model.dart';

final class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final SiteUser user;
  final String accessToken;
  final String refreshToken;
}

final class AuthRefreshResult {
  const AuthRefreshResult({required this.user, required this.accessToken});

  final SiteUser user;
  final String accessToken;
}

final class AuthService {
  const AuthService(this._dio);

  final Dio _dio;

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _dio.post<Map<String, Object?>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'displayName': displayName},
    );

    return login(email: email, password: password);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = _unwrapData(response.data);

    return AuthSession(
      user: SiteUser.fromJson(data['user'] as Map<String, Object?>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  String oauthStartUrl(String provider) {
    final baseUrl = Env.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return '$baseUrl/auth/oauth/$provider';
  }

  Future<AuthSession> completeOAuthLogin(String code) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/oauth/complete',
      data: {'code': code},
      options: Options(extra: const {'skipAuthRefresh': true}),
    );
    final data = _unwrapData(response.data);

    return AuthSession(
      user: SiteUser.fromJson(data['user'] as Map<String, Object?>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<AuthRefreshResult> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: const {'skipAuthRefresh': true}),
    );
    final data = _unwrapData(response.data);

    return AuthRefreshResult(
      user: SiteUser.fromJson(data['user'] as Map<String, Object?>),
      accessToken: data['accessToken'] as String,
    );
  }

  Future<SiteUser> me() async {
    final response = await _dio.get<Map<String, Object?>>('/auth/me');
    final data = _unwrapData(response.data);
    return SiteUser.fromJson(data['user'] as Map<String, Object?>);
  }

  Future<SiteUser> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final payload = <String, Object?>{};
    if (displayName != null) {
      payload['displayName'] = displayName;
    }
    if (avatarUrl != null) {
      payload['avatarUrl'] = avatarUrl.isEmpty ? null : avatarUrl;
    }

    final response = await _dio.patch<Map<String, Object?>>(
      '/users/me',
      data: payload,
    );
    final data = _unwrapData(response.data);
    return SiteUser.fromJson(data['user'] as Map<String, Object?>);
  }

  Future<void> deleteAccount() async {
    await _dio.delete<Map<String, Object?>>('/users/me');
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<Map<String, Object?>>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      options: Options(extra: const {'skipAuthRefresh': true}),
    );
  }

  Map<String, Object?> _unwrapData(Map<String, Object?>? body) {
    final data = body?['data'];
    if (data is Map<String, Object?>) {
      return data;
    }
    throw const FormatException('Invalid API response data.');
  }
}
