import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import 'client_update_controller.dart';

class ClientUpdateBanner extends ConsumerWidget {
  const ClientUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientUpdateControllerProvider);
    if (!_isVisible(state.phase)) {
      return const SizedBox.shrink();
    }
    final extension = AppThemeExtension.of(context);
    final controller = ref.read(clientUpdateControllerProvider.notifier);
    final downloading = state.phase == ClientUpdatePhase.downloading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      color: extension.accentMuted,
      child: Row(
        children: [
          Icon(
            downloading ? Icons.downloading_outlined : Icons.system_update_alt,
            size: AppSpacing.x6,
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(state),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (downloading) ...[
                  const SizedBox(height: AppSpacing.x2),
                  LinearProgressIndicator(value: state.progress),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          if (state.phase == ClientUpdatePhase.available)
            FilledButton.tonal(
              onPressed: controller.downloadUpdate,
              child: const Text('后台更新'),
            ),
          if (state.phase == ClientUpdatePhase.readyToInstall)
            FilledButton(
              onPressed: controller.installUpdate,
              child: const Text('重启并安装'),
            ),
        ],
      ),
    );
  }

  bool _isVisible(ClientUpdatePhase phase) {
    return phase == ClientUpdatePhase.available ||
        phase == ClientUpdatePhase.downloading ||
        phase == ClientUpdatePhase.readyToInstall ||
        phase == ClientUpdatePhase.installing;
  }

  String _title(ClientUpdateState state) {
    return switch (state.phase) {
      ClientUpdatePhase.available =>
        '发现 ReactionPro ${state.manifest?.version}',
      ClientUpdatePhase.downloading =>
        state.progress == null
            ? '正在后台下载更新'
            : '正在后台下载 ${(state.progress! * 100).round()}%',
      ClientUpdatePhase.readyToInstall => '新版本已准备好，当前版本仍可继续使用',
      ClientUpdatePhase.installing => '正在启动安全安装流程',
      _ => '',
    };
  }
}
