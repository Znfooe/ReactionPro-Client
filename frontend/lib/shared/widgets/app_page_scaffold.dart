import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_typography.dart';
import 'onboarding_tutorial.dart';
import 'theme_mode_button.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.activeRoute,
    required this.child,
  });

  final String activeRoute;
  final Widget child;

  static const _navItems = <_NavItem>[
    _NavItem(AppRoutes.reactionTest, '反应力测试', Icons.speed_outlined),
    _NavItem(AppRoutes.aimTest, '击杀时间测试', Icons.my_location_outlined),
    _NavItem(AppRoutes.leaderboard, '排行榜', Icons.leaderboard_outlined),
    _NavItem(AppRoutes.profile, '个人中心', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < AppSpacing.x10 * 28;

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
      floatingActionButton: const TutorialLauncher(),
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
      tooltip: '外观设置',
      icon: const Icon(Icons.settings_outlined),
    );

    if (!active) {
      return button;
    }
    return IconButton.filledTonal(
      onPressed: null,
      tooltip: '外观设置',
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
