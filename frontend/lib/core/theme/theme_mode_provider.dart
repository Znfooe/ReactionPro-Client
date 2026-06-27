import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

ThemeMode nextThemeMode(ThemeMode current) {
  return switch (current) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
}

String themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => '跟随系统',
    ThemeMode.light => '极简白',
    ThemeMode.dark => '夜间黑',
  };
}
