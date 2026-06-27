import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../web/location_redirect_stub.dart'
    if (dart.library.html) '../../web/location_redirect.dart';
import 'models/auth_state.dart';
import 'providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go(AppRoutes.home);
      }
    });

    final authState = ref.watch(authProvider);
    final loading = authState.isLoading;

    return AppPageScaffold(
      activeRoute: AppRoutes.login,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.x10 * 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x6),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('登录', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.x6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        authState.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.x6),
                    FilledButton.icon(
                      onPressed: loading ? null : _submit,
                      icon: loading
                          ? const SizedBox(
                              width: AppSpacing.x4,
                              height: AppSpacing.x4,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_outlined),
                      label: Text(loading ? '登录中' : '登录'),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    OutlinedButton.icon(
                      onPressed: loading ? null : () => _startOAuth('github'),
                      icon: const Icon(Icons.code_outlined),
                      label: const Text('GitHub 登录'),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    OutlinedButton.icon(
                      onPressed: loading ? null : () => _startOAuth('google'),
                      icon: const Icon(Icons.g_mobiledata_outlined),
                      label: const Text('Google 登录'),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: const Text('注册账号'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      return '请输入有效邮箱';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) {
      return '密码至少 8 位';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _startOAuth(String provider) {
    try {
      redirectTo(ref.read(authServiceProvider).oauthStartUrl(provider));
      return;
    } catch (_) {
      // Fall through to the local fallback message.
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OAuth 登录将在后端回调配置后启用')),
    );
  }
}
