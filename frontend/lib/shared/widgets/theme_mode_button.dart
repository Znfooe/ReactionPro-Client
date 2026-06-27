import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_mode_provider.dart';

class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return IconButton(
      tooltip: '主题：${themeModeLabel(mode)}',
      onPressed: () {
        ref.read(themeModeProvider.notifier).state = nextThemeMode(mode);
      },
      icon: Icon(_iconFor(mode)),
    );
  }

  IconData _iconFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };
  }
}
