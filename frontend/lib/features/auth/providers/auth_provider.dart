import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authService: ref.watch(authServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  )..restoreSession();
});

final class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({required this.authService, required this.tokenStorage})
    : super(const AuthState.loading());

  final AuthService authService;
  final TokenStorage tokenStorage;

  Future<void> restoreSession() async {
    final accessToken = await tokenStorage.readAccessToken();
    final refreshToken = await tokenStorage.readRefreshToken();

    if (accessToken == null || refreshToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await authService.me();
      state = AuthState.authenticated(user);
    } catch (_) {
      try {
        final refreshed = await authService.refresh(refreshToken);
        await tokenStorage.saveTokens(
          accessToken: refreshed.accessToken,
          refreshToken: refreshToken,
        );
        state = AuthState.authenticated(refreshed.user);
      } catch (_) {
        await tokenStorage.clearTokens();
        state = const AuthState.unauthenticated();
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final session = await authService.login(email: email, password: password);
      await tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      state = AuthState.authenticated(session.user);
    } catch (_) {
      state = const AuthState.unauthenticated(errorMessage: '邮箱或密码错误');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState.loading();
    try {
      final session = await authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      state = AuthState.authenticated(session.user);
    } catch (_) {
      state = const AuthState.unauthenticated(errorMessage: '注册失败，请检查表单');
    }
  }

  Future<void> completeOAuthLogin(String code) async {
    state = const AuthState.loading();
    try {
      final session = await authService.completeOAuthLogin(code);
      await tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      state = AuthState.authenticated(session.user);
    } catch (_) {
      await tokenStorage.clearTokens();
      state = const AuthState.unauthenticated(errorMessage: 'OAuth 登录失败');
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String avatarUrl,
  }) async {
    final user = await authService.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    state = AuthState.authenticated(user);
  }

  Future<void> deleteAccount() async {
    await authService.deleteAccount();
    await tokenStorage.clearTokens();
    state = const AuthState.unauthenticated();
  }

  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await authService.logout(refreshToken);
      } catch (_) {
        // 本地退出优先，服务端 token 失效失败不阻塞用户离开登录态。
      }
    }

    await tokenStorage.clearTokens();
    state = const AuthState.unauthenticated();
  }
}
