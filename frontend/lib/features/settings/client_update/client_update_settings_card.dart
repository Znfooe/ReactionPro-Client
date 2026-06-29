import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import 'client_update_controller.dart';

class ClientUpdateSettingsCard extends ConsumerStatefulWidget {
  const ClientUpdateSettingsCard({super.key});

  @override
  ConsumerState<ClientUpdateSettingsCard> createState() =>
      _ClientUpdateSettingsCardState();
}

class _ClientUpdateSettingsCardState
    extends ConsumerState<ClientUpdateSettingsCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      ref.read(clientUpdateControllerProvider.notifier).initialize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientUpdateControllerProvider);
    final controller = ref.read(clientUpdateControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final busy =
        state.phase == ClientUpdatePhase.checking ||
        state.phase == ClientUpdatePhase.downloading ||
        state.phase == ClientUpdatePhase.installing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: extension.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.x10,
                height: AppSpacing.x10,
                decoration: BoxDecoration(
                  color: extension.accentMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.system_update_alt),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '版本与更新',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      '当前版本 ${state.currentVersionLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: AppSpacing.x4),
            LinearProgressIndicator(
              value: state.phase == ClientUpdatePhase.downloading
                  ? state.progress
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          Text(
            _statusText(state),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: state.phase == ClientUpdatePhase.error
                  ? colors.error
                  : extension.textSecondary,
            ),
          ),
          if (!busy && state.phase != ClientUpdatePhase.unsupported) ...[
            const SizedBox(height: AppSpacing.x4),
            Align(
              alignment: Alignment.centerRight,
              child: _UpdateAction(state: state, controller: controller),
            ),
          ],
          if (state.manifest?.releaseNotes.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.x4),
            Text('更新说明', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.x2),
            Text(
              state.manifest!.releaseNotes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(ClientUpdateState state) {
    if (state.phase == ClientUpdatePhase.unsupported) {
      return '后台更新仅在 Windows 客户端中提供。';
    }
    if (state.phase == ClientUpdatePhase.downloading &&
        state.progress != null) {
      return '已下载 ${(state.progress! * 100).round()}%，下载期间可继续使用全部功能。';
    }
    return state.message ?? '每次启动 Windows 客户端时会自动检查更新。';
  }
}

class _UpdateAction extends StatelessWidget {
  const _UpdateAction({required this.state, required this.controller});

  final ClientUpdateState state;
  final ClientUpdateController controller;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      ClientUpdatePhase.available => FilledButton.tonal(
        onPressed: controller.downloadUpdate,
        child: const Text('后台更新'),
      ),
      ClientUpdatePhase.readyToInstall => FilledButton(
        onPressed: controller.installUpdate,
        child: const Text('重启并安装'),
      ),
      ClientUpdatePhase.checking ||
      ClientUpdatePhase.downloading ||
      ClientUpdatePhase.installing => const SizedBox.shrink(),
      ClientUpdatePhase.unsupported => const SizedBox.shrink(),
      _ => OutlinedButton(
        onPressed: controller.checkForUpdates,
        child: const Text('检查更新'),
      ),
    };
  }
}
