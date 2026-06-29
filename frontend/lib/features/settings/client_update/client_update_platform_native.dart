import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'client_update_manifest.dart';
import 'client_update_platform_base.dart';

ClientUpdatePlatform createClientUpdatePlatform() =>
    const NativeClientUpdatePlatform();

final class NativeClientUpdatePlatform implements ClientUpdatePlatform {
  const NativeClientUpdatePlatform();

  @override
  bool get isSupported => Platform.isWindows;

  @override
  Future<ClientUpdateArtifact?> findVerifiedArtifact(
    ClientUpdateManifest manifest,
  ) async {
    final paths = await _artifactPaths(manifest);
    if (await _isVerified(paths.complete, manifest.sha256!)) {
      return ClientUpdateArtifact(
        path: paths.complete.path,
        version: manifest.version!,
      );
    }
    if (await _isVerified(paths.partial, manifest.sha256!)) {
      if (await paths.complete.exists()) {
        await paths.complete.delete();
      }
      final complete = await paths.partial.rename(paths.complete.path);
      return ClientUpdateArtifact(
        path: complete.path,
        version: manifest.version!,
      );
    }
    return null;
  }

  @override
  Future<bool> hasPartialDownload(ClientUpdateManifest manifest) async {
    final paths = await _artifactPaths(manifest);
    return paths.partial.exists();
  }

  @override
  Future<ClientUpdateArtifact> download({
    required ClientUpdateManifest manifest,
    required ClientUpdateProgress onProgress,
  }) async {
    final existing = await findVerifiedArtifact(manifest);
    if (existing != null) {
      return existing;
    }

    final paths = await _artifactPaths(manifest);
    var receivedBytes = await paths.partial.exists()
        ? await paths.partial.length()
        : 0;
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/octet-stream'},
      ),
    );
    final response = await dio.get<ResponseBody>(
      manifest.downloadUrl!.toString(),
      options: Options(
        responseType: ResponseType.stream,
        headers: receivedBytes > 0 ? {'Range': 'bytes=$receivedBytes-'} : null,
      ),
    );
    final canResume =
        receivedBytes > 0 && response.statusCode == HttpStatus.partialContent;
    if (!canResume) {
      receivedBytes = 0;
    }
    final remainingBytes = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    final totalBytes = remainingBytes == null
        ? -1
        : receivedBytes + remainingBytes;
    final sink = paths.partial.openWrite(
      mode: canResume ? FileMode.append : FileMode.write,
    );

    try {
      onProgress(receivedBytes, totalBytes);
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }
    } finally {
      await sink.close();
    }

    if (!await _isVerified(paths.partial, manifest.sha256!)) {
      await paths.partial.delete();
      throw const ClientUpdateIntegrityException();
    }
    if (await paths.complete.exists()) {
      await paths.complete.delete();
    }
    final complete = await paths.partial.rename(paths.complete.path);
    return ClientUpdateArtifact(
      path: complete.path,
      version: manifest.version!,
    );
  }

  @override
  Future<bool> launchInstaller(ClientUpdateArtifact artifact) async {
    final installer = File(artifact.path);
    if (!await installer.exists()) {
      return false;
    }
    await Process.start(installer.path, const [
      '/SILENT',
      '/SUPPRESSMSGBOXES',
      '/NORESTART',
      '/NOCANCEL',
      '/CLOSEAPPLICATIONS',
    ], mode: ProcessStartMode.detached);
    return true;
  }

  Future<_ArtifactPaths> _artifactPaths(ClientUpdateManifest manifest) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}updates');
    await directory.create(recursive: true);
    final safeVersion = manifest.version!.replaceAll(
      RegExp(r'[^0-9A-Za-z.-]'),
      '_',
    );
    final basePath =
        '${directory.path}${Platform.pathSeparator}ReactionPro-Setup-x64-$safeVersion-build${manifest.buildNumber}.exe';
    return _ArtifactPaths(
      complete: File(basePath),
      partial: File('$basePath.part'),
    );
  }

  Future<bool> _isVerified(File file, String expectedSha256) async {
    if (!await file.exists()) {
      return false;
    }
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase() == expectedSha256.toLowerCase();
  }
}

final class _ArtifactPaths {
  const _ArtifactPaths({required this.complete, required this.partial});

  final File complete;
  final File partial;
}
