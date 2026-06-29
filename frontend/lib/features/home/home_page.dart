import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/arena_preview.dart';
import '../../shared/widgets/feature_card.dart';
import '../../shared/widgets/status_pill.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      activeRoute: AppRoutes.home,
      child: const _HeroSection(),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        if (wide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _HomeIntro()),
              SizedBox(width: AppSpacing.x8),
              Expanded(flex: 2, child: ArenaPreview()),
            ],
          );
        }

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomeIntro(),
            SizedBox(height: AppSpacing.x8),
            ArenaPreview(),
          ],
        );
      },
    );
  }
}

class _HomeIntro extends StatelessWidget {
  const _HomeIntro();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final wideCards = MediaQuery.sizeOf(context).width >= 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            StatusPill(label: '校准反应时间', color: colors.primary),
            StatusPill(label: 'CS2 灵敏度', color: extension.colorSuccess),
          ],
        ),
        const SizedBox(height: AppSpacing.x6),
        Text('ReactionPro', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: AppSpacing.x4),
        Text(
          '反应力与击杀时间测试',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: extension.textSecondary),
        ),
        const SizedBox(height: AppSpacing.x4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            '从校准反应时间到准星灵敏度模拟，把测试做准，把体验做顺，把页面做得更有记忆点。',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: extension.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.x8),
        Wrap(
          spacing: AppSpacing.x4,
          runSpacing: AppSpacing.x4,
          children: [
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.reactionTest),
              icon: const Icon(Icons.speed_outlined),
              label: const Text('开始反应力测试'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.aimTest),
              icon: const Icon(Icons.my_location_outlined),
              label: const Text('开始击杀时间测试'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x10),
        GridView.count(
          crossAxisCount: wideCards ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.x4,
          mainAxisSpacing: AppSpacing.x4,
          childAspectRatio: wideCards ? 1.55 : 1.85,
          children: const [
            FeatureCard(
              route: AppRoutes.reactionTest,
              icon: Icons.bolt_outlined,
              title: '反应力测试',
              primaryMetric: '等待期 / 信号期 / 抢跑',
              secondaryMetric: '5 / 10 / 15 回合',
            ),
            FeatureCard(
              route: AppRoutes.aimTest,
              icon: Icons.center_focus_strong_outlined,
              title: '击杀时间测试',
              primaryMetric: '准星 / 目标球 / 空枪',
              secondaryMetric: 'Canvas 渲染器',
            ),
            FeatureCard(
              route: AppRoutes.leaderboard,
              icon: Icons.leaderboard_outlined,
              title: '排行榜',
              primaryMetric: '分项榜 + 总榜',
              secondaryMetric: 'Top 50',
            ),
            FeatureCard(
              route: AppRoutes.profile,
              icon: Icons.person_outline,
              title: '个人中心',
              primaryMetric: '历史成绩',
              secondaryMetric: '主站用户',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        Wrap(
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: [
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.login_outlined),
              label: const Text('登录'),
            ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.register),
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('注册'),
            ),
          ],
        ),
      ],
    );
  }
}
