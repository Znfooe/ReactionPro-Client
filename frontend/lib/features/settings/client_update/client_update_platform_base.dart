import 'client_update_manifest.dart';

typedef ClientUpdateProgress = void Function(int receivedBytes, int totalBytes);

final class ClientUpdateArtifact {
  const ClientUpdateArtifact({required this.path, required this.version});

  final String path;
  final String version;
}

abstract interface class ClientUpdatePlatform {
  bool get isSupported;

  Future<ClientUpdateArtifact?> findVerifiedArtifact(
    ClientUpdateManifest manifest,
  );

  Future<bool> hasPartialDownload(ClientUpdateManifest manifest);

  Future<ClientUpdateArtifact> download({
    required ClientUpdateManifest manifest,
    required ClientUpdateProgress onProgress,
  });

  Future<bool> launchInstaller(ClientUpdateArtifact artifact);
}

final class ClientUpdateIntegrityException implements Exception {
  const ClientUpdateIntegrityException();
}
