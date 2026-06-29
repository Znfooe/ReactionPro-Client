import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/models/auth_state.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/score/services/score_service.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/status_pill.dart';
import '../leaderboard/services/leaderboard_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  String? _syncedUserId;
  bool _saving = false;
  bool _deleting = false;
  final Set<String> _publishingScoreIds = {};

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final user = authState.user;
    final scoreHistory = user == null
        ? null
        : ref.watch(myScoreHistoryProvider);

    if (user != null && user.id != _syncedUserId) {
      _syncedUserId = user.id;
      _displayNameController.text = user.displayName;
      _avatarUrlController.text = user.avatarUrl ?? '';
    }

    return AppPageScaffold(
      activeRoute: AppRoutes.profile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('个人中心', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              StatusPill(label: '主站用户', color: colors.primary),
              StatusPill(label: '历史成绩', color: extension.colorSuccess),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          if (authState.status == AuthStatus.loading)
            const Center(child: CircularProgressIndicator())
          else if (user == null)
            _UnauthenticatedProfile(onLogin: () => context.go(AppRoutes.login))
          else
            _AuthenticatedProfile(
              formKey: _formKey,
              user: user,
              maskedEmail: _maskEmail(user.email),
              displayNameController: _displayNameController,
              avatarUrlController: _avatarUrlController,
              saving: _saving,
              deleting: _deleting,
              scoreHistory: scoreHistory!,
              publishingScoreIds: _publishingScoreIds,
              onRetryScores: () => ref.invalidate(myScoreHistoryProvider),
              onPublishScore: (score) => _confirmPublishScore(user, score),
              onSave: _saveProfile,
              onLogout: () => ref.read(authProvider.notifier).logout(),
              onDelete: _confirmDeleteAccount,
            ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            displayName: _displayNameController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('资料已更新')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('资料更新失败')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text('账号注销后当前登录状态会失效，个人资料将不再公开显示。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('注销'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        context.go(AppRoutes.home);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('账号已注销')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('账号注销失败')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  Future<void> _confirmPublishScore(SiteUser user, MyScoreItem score) async {
    if (!score.leaderboardQualified || score.leaderboardEligible) {
      return;
    }
    final anonymous = await showDialog<bool>(
      context: context,
      builder: (context) => _LeaderboardVisibilityDialog(user: user),
    );
    if (anonymous == null || !mounted) {
      return;
    }

    setState(() {
      _publishingScoreIds.add(score.id);
    });
    try {
      await ref
          .read(scoreServiceProvider)
          .publishToLeaderboard(scoreId: score.id, anonymous: anonymous);
      ref.invalidate(myScoreHistoryProvider);
      ref.invalidate(leaderboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(anonymous ? '已匿名提交到排行榜' : '已实名提交到排行榜')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('排行榜提交失败，请稍后重试')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _publishingScoreIds.remove(score.id);
        });
      }
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.isEmpty) {
      return email;
    }
    final first = parts.first.substring(0, 1);
    return '$first***@${parts.last}';
  }
}

class _UnauthenticatedProfile extends StatelessWidget {
  const _UnauthenticatedProfile({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请先登录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x4),
            FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_outlined),
              label: const Text('登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedProfile extends StatelessWidget {
  const _AuthenticatedProfile({
    required this.formKey,
    required this.user,
    required this.maskedEmail,
    required this.displayNameController,
    required this.avatarUrlController,
    required this.saving,
    required this.deleting,
    required this.scoreHistory,
    required this.publishingScoreIds,
    required this.onRetryScores,
    required this.onPublishScore,
    required this.onSave,
    required this.onLogout,
    required this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final SiteUser user;
  final String maskedEmail;
  final TextEditingController displayNameController;
  final TextEditingController avatarUrlController;
  final bool saving;
  final bool deleting;
  final AsyncValue<MyScoreHistory> scoreHistory;
  final Set<String> publishingScoreIds;
  final VoidCallback onRetryScores;
  final ValueChanged<MyScoreItem> onPublishScore;
  final VoidCallback onSave;
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final busy = saving || deleting;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < AppSpacing.x10 * 14;
                final identity = _ProfileIdentity(
                  user: user,
                  maskedEmail: maskedEmail,
                  avatarBackgroundColor: extension.accentMuted,
                  avatarIconColor: colors.primary,
                );
                final logoutButton = OutlinedButton.icon(
                  onPressed: busy ? null : onLogout,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('退出'),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: AppSpacing.x4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: logoutButton,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: AppSpacing.x4),
                    logoutButton,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.x8),
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('资料编辑', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.x4),
                  TextFormField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: '显示名',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: _validateDisplayName,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TextFormField(
                    controller: avatarUrlController,
                    decoration: const InputDecoration(
                      labelText: '头像 URL',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    validator: _validateAvatarUrl,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Wrap(
                    spacing: AppSpacing.x3,
                    runSpacing: AppSpacing.x3,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : onSave,
                        icon: saving
                            ? const SizedBox(
                                width: AppSpacing.x4,
                                height: AppSpacing.x4,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(saving ? '保存中' : '保存资料'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : onDelete,
                        icon: deleting
                            ? const SizedBox(
                                width: AppSpacing.x4,
                                height: AppSpacing.x4,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: Text(deleting ? '注销中' : '注销账号'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            _ProfileScoreHistory(
              history: scoreHistory,
              publishingScoreIds: publishingScoreIds,
              onRetry: onRetryScores,
              onPublishScore: onPublishScore,
            ),
          ],
        ),
      ),
    );
  }

  String? _validateDisplayName(String? value) {
    final displayName = value?.trim() ?? '';
    if (displayName.length < 2 || displayName.length > 50) {
      return '显示名需要 2-50 个字符';
    }
    return null;
  }

  String? _validateAvatarUrl(String? value) {
    final avatarUrl = value?.trim() ?? '';
    if (avatarUrl.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(avatarUrl);
    if (uri == null ||
        !uri.hasAbsolutePath ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return '请输入有效的头像 URL';
    }
    return null;
  }
}

class _ProfileScoreHistory extends StatelessWidget {
  const _ProfileScoreHistory({
    required this.history,
    required this.publishingScoreIds,
    required this.onRetry,
    required this.onPublishScore,
  });

  final AsyncValue<MyScoreHistory> history;
  final Set<String> publishingScoreIds;
  final VoidCallback onRetry;
  final ValueChanged<MyScoreItem> onPublishScore;

  @override
  Widget build(BuildContext context) {
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: [
              const Expanded(child: Text('成绩同步失败，请检查网络后重试。')),
              const SizedBox(width: AppSpacing.x3),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      data: (scoreHistory) => _ProfileScoreHistoryContent(
        scoreHistory: scoreHistory,
        publishingScoreIds: publishingScoreIds,
        onPublishScore: onPublishScore,
      ),
    );
  }
}

class _ProfileScoreHistoryContent extends StatelessWidget {
  const _ProfileScoreHistoryContent({
    required this.scoreHistory,
    required this.publishingScoreIds,
    required this.onPublishScore,
  });

  final MyScoreHistory scoreHistory;
  final Set<String> publishingScoreIds;
  final ValueChanged<MyScoreItem> onPublishScore;

  @override
  Widget build(BuildContext context) {
    final summary = scoreHistory.summary;
    final recentItems = scoreHistory.items.take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('成绩摘要', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x4),
        Wrap(
          spacing: AppSpacing.x4,
          runSpacing: AppSpacing.x4,
          children: [
            _ProfileMetric(label: '总测试次数', value: '${summary.totalTests}'),
            _ProfileMetric(
              label: '平均反应时间',
              value: _milliseconds(summary.averageReactionTime),
            ),
            _ProfileMetric(
              label: '最佳反应成绩',
              value: _milliseconds(summary.bestReactionTime),
            ),
            if (summary.aimTests > 0) ...[
              _ProfileMetric(
                label: '平均击杀时间',
                value: _milliseconds(summary.averageKillTime),
              ),
              _ProfileMetric(
                label: '最佳击杀成绩',
                value: _milliseconds(summary.bestKillTime),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        Text('最近成绩', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x3),
        if (recentItems.isEmpty)
          Text(
            '完成一次测试后，成绩会自动同步到这里。',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentItems.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) => _ProfileScoreRow(
              score: recentItems[index],
              publishing: publishingScoreIds.contains(recentItems[index].id),
              onPublish: () => onPublishScore(recentItems[index]),
            ),
          ),
      ],
    );
  }

  static String _milliseconds(int? value) =>
      value == null ? '-- ms' : '$value ms';
}

class _ProfileScoreRow extends StatelessWidget {
  const _ProfileScoreRow({
    required this.score,
    required this.publishing,
    required this.onPublish,
  });

  final MyScoreItem score;
  final bool publishing;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final reaction = score.testType == 'reaction';
    final primaryValue = reaction ? score.calibratedTime : score.avgKillTime;
    final details = Row(
      children: [
        Icon(
          reaction ? Icons.bolt_outlined : Icons.center_focus_strong_outlined,
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${reaction ? '反应力测试' : '击杀时间测试'} · ${primaryValue ?? '--'} ms',
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                '${_formatDate(score.createdAt)} · 质量分 ${score.qualityScore}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );

    final action = _buildAction(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppSpacing.x10 * 18;
        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: AppSpacing.x3),
                action,
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
          child: Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: AppSpacing.x4),
              action,
            ],
          ),
        );
      },
    );
  }

  Widget _buildAction(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    if (!score.isValid) {
      return Text(
        '无效成绩',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: extension.colorErrorText),
      );
    }
    if (score.leaderboardEligible) {
      return StatusPill(
        label: score.leaderboardAnonymous ? '匿名入榜' : '实名入榜',
        color: extension.colorSuccess,
      );
    }
    if (!score.leaderboardQualified) {
      return Tooltip(
        message: '质量分需达到 90 且没有质量标记',
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock_outline),
          label: const Text('质量未达标'),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: publishing ? null : onPublish,
      icon: publishing
          ? const SizedBox.square(
              dimension: AppSpacing.x4,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.leaderboard_outlined),
      label: Text(publishing ? '提交中' : '提交到排行榜'),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

class _LeaderboardVisibilityDialog extends StatelessWidget {
  const _LeaderboardVisibilityDialog({required this.user});

  final SiteUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('提交到排行榜'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.x10 * 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '选择这次成绩在排行榜中的展示方式。提交后该成绩会参与对应分类排名。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x4),
            _LeaderboardVisibilityOption(
              icon: CircleAvatar(
                foregroundImage: user.avatarUrl == null
                    ? null
                    : NetworkImage(user.avatarUrl!),
                child: user.avatarUrl == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              title: user.displayName,
              description: '显示当前头像和名称',
              onTap: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.x3),
            _LeaderboardVisibilityOption(
              icon: const CircleAvatar(
                child: Icon(Icons.visibility_off_outlined),
              ),
              title: '匿名玩家',
              description: '隐藏头像、名称和用户标识',
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _LeaderboardVisibilityOption extends StatelessWidget {
  const _LeaderboardVisibilityOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: extension.borderMuted),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: extension.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.user,
    required this.maskedEmail,
    required this.avatarBackgroundColor,
    required this.avatarIconColor,
  });

  final SiteUser user;
  final String maskedEmail;
  final Color avatarBackgroundColor;
  final Color avatarIconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: AppSpacing.x8,
          backgroundColor: avatarBackgroundColor,
          foregroundImage: user.avatarUrl == null
              ? null
              : NetworkImage(user.avatarUrl!),
          child: user.avatarUrl == null
              ? Icon(Icons.person_outline, color: avatarIconColor)
              : null,
        ),
        const SizedBox(width: AppSpacing.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                maskedEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                '注册时间 ${user.createdAt}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);

    return Container(
      width: AppSpacing.x10 * 5,
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: extension.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.mono(
              fontSize: AppTypography.text2xl,
              lineHeight: AppTypography.line2xl,
              fontWeight: AppTypography.fontWeightSemibold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
