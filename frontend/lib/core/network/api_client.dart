import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/token_storage.dart';
import '../config/env.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);
  dio.interceptors.add(AuthInterceptor(dio: dio, tokenStorage: tokenStorage));
  return dio;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const SecureTokenStorage();
});

final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final shouldSkipRefresh =
        requestOptions.extra['skipAuthRefresh'] == true ||
        requestOptions.extra['hasRetriedAuthRefresh'] == true;

    if (err.response?.statusCode != 401 || shouldSkipRefresh) {
      handler.next(err);
      return;
    }

    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final refreshClient = Dio(dio.options);
      final refreshResult = await AuthService(refreshClient).refresh(refreshToken);
      await tokenStorage.saveTokens(
        accessToken: refreshResult.accessToken,
        refreshToken: refreshToken,
      );

      final retryOptions = Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer ${refreshResult.accessToken}',
        },
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        extra: {
          ...requestOptions.extra,
          'hasRetriedAuthRefresh': true,
        },
      );
      final retryResponse = await dio.request<Object?>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: retryOptions,
      );
      handler.resolve(retryResponse);
    } catch (_) {
      await tokenStorage.clearTokens();
      handler.next(err);
    }
  }
}
