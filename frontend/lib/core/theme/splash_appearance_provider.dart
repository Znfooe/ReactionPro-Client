import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'splash_appearance.dart';

final splashAppearanceProvider =
    StateNotifierProvider<SplashAppearanceController, SplashAppearance>((ref) {
      return SplashAppearanceController();
    });

final class SplashAppearanceController extends StateNotifier<SplashAppearance> {
  SplashAppearanceController() : super(SplashAppearance.sky) {
    unawaited(_restore());
  }

  static const _storageKey = 'reactionpro_splash_appearance_v1';
  static const _storage = FlutterSecureStorage();
  bool _changedByUser = false;

  void selectPreset(SplashAppearancePreset preset) {
    _changedByUser = true;
    state = preset.appearance;
    unawaited(_persist());
  }

  void updateColor(SplashColorRole role, Color color) {
    _changedByUser = true;
    state = state.withColor(role, color);
    unawaited(_persist());
  }

  void reset() {
    selectPreset(splashAppearancePresets.first);
  }

  Future<void> _restore() async {
    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored == null || _changedByUser) {
        return;
      }
      final json = jsonDecode(stored);
      if (json is Map<String, Object?>) {
        state = SplashAppearance.fromJson(json);
      } else if (json is Map) {
        state = SplashAppearance.fromJson(json.cast<String, Object?>());
      }
    } catch (_) {
      // Invalid or unavailable local storage falls back to the sky preset.
    }
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _storageKey, value: jsonEncode(state.toJson()));
    } catch (_) {
      // Appearance remains usable for this session when persistence fails.
    }
  }
}
