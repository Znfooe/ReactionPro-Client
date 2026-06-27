import 'package:flutter/material.dart';

import 'app_colors.dart';

enum SplashColorRole { background, line, outline, textStart, textEnd }

final class SplashAppearance {
  const SplashAppearance({
    required this.presetId,
    required this.background,
    required this.line,
    required this.outline,
    required this.textStart,
    required this.textEnd,
  });

  static const sakura = SplashAppearance(
    presetId: 'sakura',
    background: AppColors.splashBackground,
    line: AppColors.splashLine,
    outline: AppColors.splashOutline,
    textStart: AppColors.splashTextStart,
    textEnd: AppColors.splashTextEnd,
  );

  static const monochrome = SplashAppearance(
    presetId: 'monochrome',
    background: AppColors.gray950,
    line: AppColors.gray50,
    outline: AppColors.gray500,
    textStart: AppColors.gray50,
    textEnd: AppColors.gray300,
  );

  static const sky = SplashAppearance(
    presetId: 'sky',
    background: AppColors.splashSkyBackground,
    line: AppColors.blue500,
    outline: AppColors.blue200,
    textStart: AppColors.blue700,
    textEnd: AppColors.blue300,
  );

  static const mint = SplashAppearance(
    presetId: 'mint',
    background: AppColors.splashMintBackground,
    line: AppColors.green500,
    outline: AppColors.green200,
    textStart: AppColors.green700,
    textEnd: AppColors.green300,
  );

  final String presetId;
  final Color background;
  final Color line;
  final Color outline;
  final Color textStart;
  final Color textEnd;

  SplashAppearance copyWith({
    String? presetId,
    Color? background,
    Color? line,
    Color? outline,
    Color? textStart,
    Color? textEnd,
  }) {
    return SplashAppearance(
      presetId: presetId ?? this.presetId,
      background: background ?? this.background,
      line: line ?? this.line,
      outline: outline ?? this.outline,
      textStart: textStart ?? this.textStart,
      textEnd: textEnd ?? this.textEnd,
    );
  }

  SplashAppearance withColor(SplashColorRole role, Color color) {
    return switch (role) {
      SplashColorRole.background => copyWith(
        presetId: 'custom',
        background: color,
      ),
      SplashColorRole.line => copyWith(presetId: 'custom', line: color),
      SplashColorRole.outline => copyWith(presetId: 'custom', outline: color),
      SplashColorRole.textStart => copyWith(
        presetId: 'custom',
        textStart: color,
      ),
      SplashColorRole.textEnd => copyWith(presetId: 'custom', textEnd: color),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'presetId': presetId,
      'background': background.toARGB32(),
      'line': line.toARGB32(),
      'outline': outline.toARGB32(),
      'textStart': textStart.toARGB32(),
      'textEnd': textEnd.toARGB32(),
    };
  }

  factory SplashAppearance.fromJson(Map<String, Object?> json) {
    return SplashAppearance(
      presetId: json['presetId'] as String? ?? 'custom',
      background: Color((json['background'] as num).toInt()),
      line: Color((json['line'] as num).toInt()),
      outline: Color((json['outline'] as num).toInt()),
      textStart: Color((json['textStart'] as num).toInt()),
      textEnd: Color((json['textEnd'] as num).toInt()),
    );
  }
}

final class SplashAppearancePreset {
  const SplashAppearancePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.appearance,
  });

  final String id;
  final String label;
  final String description;
  final SplashAppearance appearance;
}

const splashAppearancePresets = [
  SplashAppearancePreset(
    id: 'sky',
    label: '蓝天白云',
    description: '清亮天蓝与浅云白背景',
    appearance: SplashAppearance.sky,
  ),
  SplashAppearancePreset(
    id: 'sakura',
    label: '樱花暖橙',
    description: '当前品牌配色，柔和而有温度',
    appearance: SplashAppearance.sakura,
  ),
  SplashAppearancePreset(
    id: 'monochrome',
    label: '黑白系',
    description: '高对比黑底与冷白线稿',
    appearance: SplashAppearance.monochrome,
  ),
  SplashAppearancePreset(
    id: 'mint',
    label: '薄荷绿',
    description: '低饱和清新绿，视觉更轻盈',
    appearance: SplashAppearance.mint,
  ),
];
