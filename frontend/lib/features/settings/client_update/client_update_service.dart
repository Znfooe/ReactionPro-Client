import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'client_update_manifest.dart';

final clientUpdateServiceProvider = Provider<ClientUpdateService>((ref) {
  return ClientUpdateService(ref.watch(dioProvider));
});

final class ClientUpdateService {
  const ClientUpdateService(this._dio);

  final Dio _dio;

  Future<ClientUpdateManifest> fetchWindowsManifest() async {
    final response = await _dio.get<Map<String, Object?>>(
      '/client-releases/windows',
      options: Options(extra: const {'skipAuthRefresh': true}),
    );
    final data = response.data?['data'];
    if (data is! Map<String, Object?>) {
      throw const FormatException('Invalid Windows update manifest.');
    }
    return ClientUpdateManifest.fromJson(data);
  }
}
