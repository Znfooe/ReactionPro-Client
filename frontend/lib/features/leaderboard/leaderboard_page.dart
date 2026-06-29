import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/onboarding_tutorial.dart';
import '../../shared/widgets/status_pill.dart';
import 'services/leaderboard_service.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  String _category = _categories.first.id;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final query = LeaderboardQuery(category: _category);
    final leaderboard = ref.watch(leaderboardProvider(query));
    final selectedCategory = _categories.firstWhere(
      (category) => category.id == _category,
    );

    return AppPageScaffold(
      activeRoute: AppRoutes.leaderboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('排行榜', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              StatusPill(label: '严肃成绩', color: colors.primary),
              StatusPill(label: '质量门禁', color: extension.colorSuccess),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 880;
              final table = _LeaderboardTable(
                leaderboard: leaderboard,
                category: selectedCategory,
              );
              final detail = _LeaderboardDetail(
                category: selectedCategory,
                selectedCategory: _category,
                onCategoryChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 65, child: table),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(flex: 35, child: detail),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  detail,
                  const SizedBox(height: AppSpacing.x8),
                  table,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  const _LeaderboardTable({required this.leaderboard, required this.category});

  final AsyncValue<LeaderboardResult> leaderboard;
  final _LeaderboardCategory category;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: leaderboard.when(
          data: (data) => _LeaderboardRows(result: data, category: category),
          loading: () => const SizedBox(
            height: AppSpacing.x10 * 5,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => SizedBox(
            height: AppSpacing.x10 * 5,
            child: Center(
              child: Text(
                '排行榜加载失败',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRows extends StatelessWidget {
  const _LeaderboardRows({required this.result, required this.category});

  final LeaderboardResult result;
  final _LeaderboardCategory category;

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return SizedBox(
        height: AppSpacing.x10 * 5,
        child: Center(
          child: Text('暂无入榜成绩', style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return Column(
      children: [
        const _LeaderboardRow(
          rank: '#',
          user: '主站用户',
          score: '成绩',
          header: true,
        ),
        const Divider(),
        for (final row in result.items)
          _LeaderboardRow(
            rank: '${row.rank}',
            user: row.displayName,
            avatarUrl: row.avatarUrl,
            anonymous: row.anonymous,
            score: '${row.scoreValue} ms',
            subtitle: category.shortLabel,
          ),
      ],
    );
  }
}

class _LeaderboardDetail extends StatelessWidget {
  const _LeaderboardDetail({
    required this.category,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final _LeaderboardCategory category;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('排行榜分类', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.x4),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final option in _categories)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: selectedCategory == option.id,
                    onSelected: (_) => onCategoryChanged(option.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x6),
            _DetailMetric(label: '当前分类', value: category.label),
            _DetailMetric(label: '排名依据', value: category.metricLabel),
            _DetailMetric(label: '成绩来源', value: '严肃成绩'),
            const SizedBox(height: AppSpacing.x4),
            OutlinedButton.icon(
              onPressed: () => showOnboardingTutorial(context, initialStep: 3),
              icon: const Icon(Icons.help_outline),
              label: const Text('如何提交成绩'),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              'Top 50',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: extension.accentText),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.user,
    required this.score,
    this.avatarUrl,
    this.anonymous = false,
    this.subtitle,
    this.header = false,
  });

  final String rank;
  final String user;
  final String score;
  final String? avatarUrl;
  final bool anonymous;
  final String? subtitle;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    final labelStyle = header
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.x10,
            child: Text(
              rank,
              style: AppTypography.mono(
                fontSize: header ? AppTypography.textXs : AppTypography.textLg,
                lineHeight: header
                    ? AppTypography.lineXs
                    : AppTypography.lineLg,
                fontWeight: header
                    ? AppTypography.fontWeightSemibold
                    : AppTypography.fontWeightBold,
                color: header
                    ? extension.textTertiary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (!header) ...[
            CircleAvatar(
              radius: AppSpacing.x4,
              foregroundImage: avatarUrl == null
                  ? null
                  : NetworkImage(avatarUrl!),
              child: avatarUrl == null
                  ? Icon(
                      anonymous
                          ? Icons.visibility_off_outlined
                          : Icons.person_outline,
                      size: AppSpacing.x4,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user, style: labelStyle),
                if (subtitle != null && !header)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: extension.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            score,
            textAlign: TextAlign.right,
            style: AppTypography.mono(
              fontSize: header ? AppTypography.textXs : AppTypography.textSm,
              lineHeight: header ? AppTypography.lineXs : AppTypography.lineSm,
              fontWeight: AppTypography.fontWeightSemibold,
              color: header
                  ? extension.textTertiary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.mono(
              fontSize: AppTypography.textSm,
              lineHeight: AppTypography.lineSm,
              fontWeight: AppTypography.fontWeightSemibold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCategory {
  const _LeaderboardCategory({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.metricLabel,
  });

  final String id;
  final String label;
  final String shortLabel;
  final String metricLabel;
}

const _categories = [
  _LeaderboardCategory(
    id: 'reaction_5',
    label: '反应力 5 回合',
    shortLabel: '反应力',
    metricLabel: '校准反应时间',
  ),
  _LeaderboardCategory(
    id: 'reaction_10',
    label: '反应力 10 回合',
    shortLabel: '反应力',
    metricLabel: '校准反应时间',
  ),
  _LeaderboardCategory(
    id: 'reaction_15',
    label: '反应力 15 回合',
    shortLabel: '反应力',
    metricLabel: '校准反应时间',
  ),
  _LeaderboardCategory(
    id: 'aim_single_count_static',
    label: '单目标静态',
    shortLabel: '击杀时间',
    metricLabel: '平均击杀时间',
  ),
  _LeaderboardCategory(
    id: 'aim_multi_count_static',
    label: '多目标静态',
    shortLabel: '击杀时间',
    metricLabel: '平均击杀时间',
  ),
];
