import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import 'models/auth_state.dart';
import 'providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      activeRoute: AppRoutes.register,
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
                    Text('注册', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.x6),
                    TextFormField(
                      controller: _displayNameController,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: '显示名称',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _validateDisplayName,
                    ),
                    const SizedBox(height: AppSpacing.x4),
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
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: '确认密码',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: _validateConfirmPassword,
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
                          : const Icon(Icons.person_add_alt_outlined),
                      label: Text(loading ? '注册中' : '注册'),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('已有账号'),
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

  String? _validateDisplayName(String? value) {
    final displayName = value?.trim() ?? '';
    if (displayName.length < 2 || displayName.length > 50) {
      return '显示名称需为 2-50 个字符';
    }
    return null;
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
    final password = value ?? '';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    if (password.length < 8 || !hasLetter || !hasNumber) {
      return '密码至少 8 位，且包含字母和数字';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
        );
  }
}
