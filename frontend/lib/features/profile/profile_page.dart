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
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/status_pill.dart';

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
            Wrap(
              spacing: AppSpacing.x4,
              runSpacing: AppSpacing.x4,
              children: const [
                _ProfileMetric(label: '总测试次数', value: '0'),
                _ProfileMetric(label: '平均反应时间', value: '-- ms'),
                _ProfileMetric(label: '最佳成绩', value: '-- ms'),
              ],
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
