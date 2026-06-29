import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_links.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';

class AimDesktopClientNotice extends StatelessWidget {
  const AimDesktopClientNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return Semantics(
      container: true,
      label: '击杀时间测试需要桌面客户端',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.x12,
            height: AppSpacing.x12,
            decoration: BoxDecoration(
              color: extension.accentMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.mouse_outlined, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            '击杀时间测试需要桌面客户端',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            '为了稳定锁定鼠标、进入全屏并保持计时精度，Web 端不提供击杀时间测试。',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: extension.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: extension.bgMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: extension.borderMuted),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_outlined, color: colors.primary),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Text(
                      '这是浏览器的安全限制：requestFullscreen() 会消耗瞬时用户激活，因此不能依赖全屏完成后的异步回调直接锁定鼠标。桌面客户端不受这一浏览器激活链限制。',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Text('选择桌面版本', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.x4),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppSpacing.x10 * 16;
              const windows = _DesktopDownloadOption(
                icon: Icons.window_outlined,
                title: 'Windows',
                subtitle: 'Windows 10/11 · x64 安装包',
                buttonLabel: '下载 Windows .exe',
                url: AppLinks.windowsInstaller,
                primary: true,
              );
              const macos = _DesktopDownloadOption(
                icon: Icons.laptop_mac_outlined,
                title: 'macOS',
                subtitle: 'macOS 12+ · DMG 安装包',
                buttonLabel: '下载 macOS .dmg',
                url: AppLinks.macosInstaller,
              );

              if (!wide) {
                return const Column(
                  children: [
                    windows,
                    SizedBox(height: AppSpacing.x4),
                    macos,
                  ],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: windows),
                  SizedBox(width: AppSpacing.x4),
                  Expanded(child: macos),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopDownloadOption extends StatelessWidget {
  const _DesktopDownloadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.url,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String url;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    final action = primary
        ? FilledButton.icon(
            onPressed: () => _openInstaller(context, url),
            icon: const Icon(Icons.download_outlined),
            label: Text(buttonLabel),
          )
        : OutlinedButton.icon(
            onPressed: () => _openInstaller(context, url),
            icon: const Icon(Icons.download_outlined),
            label: Text(buttonLabel),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSpacing.x8),
            const SizedBox(height: AppSpacing.x4),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x1),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: extension.textSecondary),
            ),
            const SizedBox(height: AppSpacing.x5),
            action,
          ],
        ),
      ),
    );
  }
}

Future<void> _openInstaller(BuildContext context, String url) async {
  final launched = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.platformDefault,
  );
  if (!context.mounted || launched) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('暂时无法打开下载链接')));
}
