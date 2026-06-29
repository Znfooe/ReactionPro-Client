import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'client_update_manifest.dart';
import 'client_update_platform.dart';
import 'client_update_service.dart';

final clientUpdatePlatformProvider = Provider<ClientUpdatePlatform>((ref) {
  return createClientUpdatePlatform();
});

final clientUpdateControllerProvider =
    StateNotifierProvider<ClientUpdateController, ClientUpdateState>((ref) {
      return ClientUpdateController(
        ref.watch(clientUpdateServiceProvider),
        ref.watch(clientUpdatePlatformProvider),
      );
    });

enum ClientUpdatePhase {
  uninitialized,
  unsupported,
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  installing,
  error,
}

final class ClientUpdateState {
  const ClientUpdateState({
    this.phase = ClientUpdatePhase.uninitialized,
    this.currentVersion = '',
    this.currentBuildNumber = 0,
    this.manifest,
    this.artifact,
    this.receivedBytes = 0,
    this.totalBytes = -1,
    this.message,
  });

  static const _notProvided = Object();

  final ClientUpdatePhase phase;
  final String currentVersion;
  final int currentBuildNumber;
  final ClientUpdateManifest? manifest;
  final ClientUpdateArtifact? artifact;
  final int receivedBytes;
  final int totalBytes;
  final String? message;

  double? get progress {
    if (totalBytes <= 0) {
      return null;
    }
    return (receivedBytes / totalBytes).clamp(0, 1);
  }

  String get currentVersionLabel {
    if (currentVersion.isEmpty) {
      return '读取中';
    }
    return '$currentVersion+$currentBuildNumber';
  }

  ClientUpdateState copyWith({
    ClientUpdatePhase? phase,
    String? currentVersion,
    int? currentBuildNumber,
    Object? manifest = _notProvided,
    Object? artifact = _notProvided,
    int? receivedBytes,
    int? totalBytes,
    Object? message = _notProvided,
  }) {
    return ClientUpdateState(
      phase: phase ?? this.phase,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      manifest: identical(manifest, _notProvided)
          ? this.manifest
          : manifest as ClientUpdateManifest?,
      artifact: identical(artifact, _notProvided)
          ? this.artifact
          : artifact as ClientUpdateArtifact?,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      message: identical(message, _notProvided)
          ? this.message
          : message as String?,
    );
  }
}

final class ClientUpdateController extends StateNotifier<ClientUpdateState> {
  ClientUpdateController(this._service, this._platform)
    : super(const ClientUpdateState());

  final ClientUpdateService _service;
  final ClientUpdatePlatform _platform;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (!_platform.isSupported) {
      state = state.copyWith(phase: ClientUpdatePhase.unsupported);
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      state = state.copyWith(
        phase: ClientUpdatePhase.idle,
        currentVersion: packageInfo.version,
        currentBuildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
        message: null,
      );
      await _checkForUpdates(resumePartialDownload: true);
    } catch (_) {
      state = state.copyWith(
        phase: ClientUpdatePhase.error,
        message: '暂时无法检查更新，不影响当前版本使用。',
      );
    }
  }

  Future<void> checkForUpdates() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    if (!_platform.isSupported ||
        state.phase == ClientUpdatePhase.downloading) {
      return;
    }
    await _checkForUpdates(resumePartialDownload: false);
  }

  Future<void> _checkForUpdates({required bool resumePartialDownload}) async {
    state = state.copyWith(phase: ClientUpdatePhase.checking, message: null);
    try {
      final manifest = await _service.fetchWindowsManifest();
      if (!manifest.enabled) {
        state = state.copyWith(
          phase: ClientUpdatePhase.upToDate,
          manifest: manifest,
          artifact: null,
          message: '当前没有已发布的客户端更新。',
        );
        return;
      }
      if (!manifest.isNewerThan(
        version: state.currentVersion,
        buildNumber: state.currentBuildNumber,
      )) {
        state = state.copyWith(
          phase: ClientUpdatePhase.upToDate,
          manifest: manifest,
          artifact: null,
          message: '已是最新版本。',
        );
        return;
      }

      final artifact = await _platform.findVerifiedArtifact(manifest);
      if (artifact != null) {
        state = state.copyWith(
          phase: ClientUpdatePhase.readyToInstall,
          manifest: manifest,
          artifact: artifact,
          receivedBytes: 0,
          totalBytes: -1,
          message: '更新包已校验，可以重启安装。',
        );
        return;
      }

      state = state.copyWith(
        phase: ClientUpdatePhase.available,
        manifest: manifest,
        artifact: null,
        receivedBytes: 0,
        totalBytes: -1,
        message: '发现新版本 ${manifest.version}。',
      );
      if (resumePartialDownload &&
          await _platform.hasPartialDownload(manifest)) {
        unawaited(downloadUpdate());
      }
    } catch (_) {
      state = state.copyWith(
        phase: ClientUpdatePhase.error,
        message: '检查更新失败，请稍后重试。',
      );
    }
  }

  Future<void> downloadUpdate() async {
    final manifest = state.manifest;
    if (manifest == null ||
        !manifest.enabled ||
        manifest.version == null ||
        manifest.downloadUrl == null ||
        manifest.sha256 == null ||
        state.phase == ClientUpdatePhase.downloading) {
      return;
    }

    state = state.copyWith(
      phase: ClientUpdatePhase.downloading,
      receivedBytes: 0,
      totalBytes: -1,
      message: '正在后台下载，当前功能可继续使用。',
    );
    try {
      final artifact = await _platform.download(
        manifest: manifest,
        onProgress: (receivedBytes, totalBytes) {
          if (state.phase != ClientUpdatePhase.downloading) {
            return;
          }
          state = state.copyWith(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
          );
        },
      );
      state = state.copyWith(
        phase: ClientUpdatePhase.readyToInstall,
        artifact: artifact,
        receivedBytes: state.totalBytes > 0
            ? state.totalBytes
            : state.receivedBytes,
        message: '下载完成并通过安全校验。',
      );
    } on ClientUpdateIntegrityException {
      state = state.copyWith(
        phase: ClientUpdatePhase.error,
        artifact: null,
        message: '更新包校验失败，已删除损坏文件，请重新下载。',
      );
    } on DioException {
      state = state.copyWith(
        phase: ClientUpdatePhase.error,
        message: '下载已暂停，下次启动或重试时会从断点继续。',
      );
    } catch (_) {
      state = state.copyWith(
        phase: ClientUpdatePhase.error,
        message: '后台更新失败，当前版本未受影响。',
      );
    }
  }

  Future<void> installUpdate() async {
    final artifact = state.artifact;
    if (artifact == null || state.phase != ClientUpdatePhase.readyToInstall) {
      return;
    }
    state = state.copyWith(
      phase: ClientUpdatePhase.installing,
      message: '正在启动安装器，ReactionPro 将暂时关闭。',
    );
    try {
      final launched = await _platform.launchInstaller(artifact);
      if (!launched) {
        throw StateError('Installer is unavailable.');
      }
      state = state.copyWith(
        phase: ClientUpdatePhase.readyToInstall,
        message: '安装器已启动；若取消安装，可再次点击重启并安装。',
      );
    } catch (_) {
      state = state.copyWith(
        phase: ClientUpdatePhase.readyToInstall,
        message: '安装器启动失败，更新包仍已安全保留。',
      );
    }
  }
}
