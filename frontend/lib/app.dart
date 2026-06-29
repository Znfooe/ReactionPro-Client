import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/splash_appearance_provider.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/utils/app_preloader.dart';
import 'features/splash/splash_screen.dart';
import 'features/settings/client_update/client_update_controller.dart';

class ReactionProApp extends ConsumerStatefulWidget {
  const ReactionProApp({super.key});

  @override
  ConsumerState<ReactionProApp> createState() => _ReactionProAppState();
}

class _ReactionProAppState extends ConsumerState<ReactionProApp> {
  late final Future<void> _preloadFuture;

  @override
  void initState() {
    super.initState();
    _preloadFuture = AppPreloader.preload();
    unawaited(
      Future.microtask(
        ref.read(clientUpdateControllerProvider.notifier).initialize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final splashAppearance = ref.watch(splashAppearanceProvider);

    return MaterialApp.router(
      title: 'ReactionPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return SplashScreen(
          loadingFuture: _preloadFuture,
          appearance: splashAppearance,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
