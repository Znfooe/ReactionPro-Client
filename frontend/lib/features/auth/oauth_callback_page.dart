import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import 'models/auth_state.dart';
import 'providers/auth_provider.dart';

class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({
    required this.code,
    super.key,
  });

  final String? code;

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  bool _started = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_completeLogin);
  }

  Future<void> _completeLogin() async {
    if (_started) {
      return;
    }
    _started = true;

    final code = widget.code;
    if (code == null || code.isEmpty) {
      setState(() {
        _localError = 'OAuth 回调缺少登录 code';
      });
      return;
    }

    await ref.read(authProvider.notifier).completeOAuthLogin(code);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go(AppRoutes.home);
      }
    });

    final authState = ref.watch(authProvider);
    final errorMessage = _localError ?? authState.errorMessage;

    return AppPageScaffold(
      activeRoute: AppRoutes.login,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.x10 * 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    errorMessage == null ? '正在完成登录' : '登录失败',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  if (errorMessage == null)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.login_outlined),
                      label: const Text('返回登录'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
