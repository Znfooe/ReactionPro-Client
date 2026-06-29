import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_links.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_typography.dart';
import '../../features/settings/client_update/client_update_banner.dart';
import 'onboarding_tutorial.dart';
import 'theme_mode_button.dart';

class AppPageScaffold extends ConsumerWidget {
  const AppPageScaffold({
    super.key,
    required this.activeRoute,
    required this.child,
  });

  final String activeRoute;
  final Widget child;

  static const _navItems = <_NavItem>[
    _NavItem(AppRoutes.about, '关于作者', Icons.face_outlined),
    _NavItem(AppRoutes.reactionTest, '反应力测试', Icons.speed_outlined),
    _NavItem(AppRoutes.aimTest, '击杀时间测试', Icons.my_location_outlined),
    _NavItem(AppRoutes.leaderboard, '排行榜', Icons.leaderboard_outlined),
    _NavItem(AppRoutes.profile, '个人中心', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < AppSpacing.x10 * 36;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppSpacing.x16,
        titleSpacing: AppSpacing.x4,
        title: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.go(AppRoutes.home),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: AppSpacing.x1,
            ),
            child: Text(
              'ReactionPro',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        actions: [
          _DownloadMenu(compact: compact),
          if (compact)
            _CompactNavigation(activeRoute: activeRoute, items: _navItems)
          else
            for (final item in _navItems)
              _NavButton(item: item, activeRoute: activeRoute),
          _SettingsButton(active: activeRoute == AppRoutes.settings),
          const ThemeModeButton(),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ClientUpdateBanner(),
            Expanded(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? AppSpacing.x4 : AppSpacing.x8,
                        vertical: compact ? AppSpacing.x6 : AppSpacing.x10,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const TutorialLauncher(),
    );
  }
}

class _DownloadMenu extends StatelessWidget {
  const _DownloadMenu({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    final menu = PopupMenuButton<String>(
      tooltip: '下载客户端',
      position: PopupMenuPosition.under,
      onSelected: (url) =>
          launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: AppLinks.windowsInstaller,
          child: _DownloadMenuItem(
            icon: Icons.window_outlined,
            title: 'Windows',
            subtitle: 'Windows 10/11 · x64 安装包',
          ),
        ),
        PopupMenuItem(
          value: AppLinks.macosInstaller,
          child: _DownloadMenuItem(
            icon: Icons.laptop_mac_outlined,
            title: 'macOS',
            subtitle: 'macOS 12+ · DMG 安装包',
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.x2 : AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        child: compact
            ? const Icon(Icons.download_outlined)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_outlined, size: AppSpacing.x5),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    '下载客户端',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: extension.textSecondary,
                      fontWeight: AppTypography.fontWeightMedium,
                    ),
                  ),
                ],
              ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.x2),
      child: menu,
    );
  }
}

class _DownloadMenuItem extends StatelessWidget {
  const _DownloadMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);

    return SizedBox(
      width: AppSpacing.x10 * 4,
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.x6),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: extension.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: active ? null : () => context.go(AppRoutes.settings),
      tooltip: '设置',
      icon: const Icon(Icons.settings_outlined),
    );

    if (!active) {
      return button;
    }
    return IconButton.filledTonal(
      onPressed: null,
      tooltip: '设置',
      icon: const Icon(Icons.settings),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.activeRoute});

  final _NavItem item;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final active = item.path == activeRoute;
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.x2),
      child: TextButton.icon(
        onPressed: active ? null : () => context.go(item.path),
        icon: Icon(item.icon, size: AppSpacing.x5),
        label: Text(item.label),
        style: TextButton.styleFrom(
          foregroundColor: active ? colors.primary : extension.textSecondary,
          disabledForegroundColor: colors.primary,
          textStyle: const TextStyle(
            fontSize: AppTypography.textSm,
            fontWeight: AppTypography.fontWeightMedium,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({required this.activeRoute, required this.items});

  final String activeRoute;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '导航',
      icon: const Icon(Icons.menu_outlined),
      initialValue: activeRoute,
      onSelected: (path) => context.go(path),
      itemBuilder: (context) {
        return [
          for (final item in items)
            PopupMenuItem(
              value: item.path,
              child: Row(
                children: [
                  Icon(item.icon, size: AppSpacing.x5),
                  const SizedBox(width: AppSpacing.x2),
                  Text(item.label),
                ],
              ),
            ),
        ];
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
