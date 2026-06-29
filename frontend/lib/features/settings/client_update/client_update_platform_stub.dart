import 'client_update_manifest.dart';
import 'client_update_platform_base.dart';

ClientUpdatePlatform createClientUpdatePlatform() =>
    const UnsupportedClientUpdatePlatform();

final class UnsupportedClientUpdatePlatform implements ClientUpdatePlatform {
  const UnsupportedClientUpdatePlatform();

  @override
  bool get isSupported => false;

  @override
  Future<ClientUpdateArtifact> download({
    required ClientUpdateManifest manifest,
    required ClientUpdateProgress onProgress,
  }) {
    throw UnsupportedError('Client updates are only available on Windows.');
  }

  @override
  Future<ClientUpdateArtifact?> findVerifiedArtifact(
    ClientUpdateManifest manifest,
  ) async => null;

  @override
  Future<bool> hasPartialDownload(ClientUpdateManifest manifest) async => false;

  @override
  Future<bool> launchInstaller(ClientUpdateArtifact artifact) async => false;
}
