import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.bgMuted,
    required this.bgOverlay,
    required this.textSecondary,
    required this.textTertiary,
    required this.accentHover,
    required this.accentActive,
    required this.accentMuted,
    required this.accentText,
    required this.colorSuccess,
    required this.colorSuccessMuted,
    required this.colorSuccessText,
    required this.colorWarning,
    required this.colorWarningMuted,
    required this.colorWarningText,
    required this.colorErrorMuted,
    required this.colorErrorText,
    required this.borderDefault,
    required this.borderMuted,
    required this.borderAccent,
  });

  final Color bgMuted;
  final Color bgOverlay;
  final Color textSecondary;
  final Color textTertiary;
  final Color accentHover;
  final Color accentActive;
  final Color accentMuted;
  final Color accentText;
  final Color colorSuccess;
  final Color colorSuccessMuted;
  final Color colorSuccessText;
  final Color colorWarning;
  final Color colorWarningMuted;
  final Color colorWarningText;
  final Color colorErrorMuted;
  final Color colorErrorText;
  final Color borderDefault;
  final Color borderMuted;
  final Color borderAccent;

  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>()!;
  }

  @override
  AppThemeExtension copyWith({
    Color? bgMuted,
    Color? bgOverlay,
    Color? textSecondary,
    Color? textTertiary,
    Color? accentHover,
    Color? accentActive,
    Color? accentMuted,
    Color? accentText,
    Color? colorSuccess,
    Color? colorSuccessMuted,
    Color? colorSuccessText,
    Color? colorWarning,
    Color? colorWarningMuted,
    Color? colorWarningText,
    Color? colorErrorMuted,
    Color? colorErrorText,
    Color? borderDefault,
    Color? borderMuted,
    Color? borderAccent,
  }) {
    return AppThemeExtension(
      bgMuted: bgMuted ?? this.bgMuted,
      bgOverlay: bgOverlay ?? this.bgOverlay,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accentHover: accentHover ?? this.accentHover,
      accentActive: accentActive ?? this.accentActive,
      accentMuted: accentMuted ?? this.accentMuted,
      accentText: accentText ?? this.accentText,
      colorSuccess: colorSuccess ?? this.colorSuccess,
      colorSuccessMuted: colorSuccessMuted ?? this.colorSuccessMuted,
      colorSuccessText: colorSuccessText ?? this.colorSuccessText,
      colorWarning: colorWarning ?? this.colorWarning,
      colorWarningMuted: colorWarningMuted ?? this.colorWarningMuted,
      colorWarningText: colorWarningText ?? this.colorWarningText,
      colorErrorMuted: colorErrorMuted ?? this.colorErrorMuted,
      colorErrorText: colorErrorText ?? this.colorErrorText,
      borderDefault: borderDefault ?? this.borderDefault,
      borderMuted: borderMuted ?? this.borderMuted,
      borderAccent: borderAccent ?? this.borderAccent,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      bgMuted: Color.lerp(bgMuted, other.bgMuted, t)!,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentActive: Color.lerp(accentActive, other.accentActive, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      colorSuccess: Color.lerp(colorSuccess, other.colorSuccess, t)!,
      colorSuccessMuted: Color.lerp(
        colorSuccessMuted,
        other.colorSuccessMuted,
        t,
      )!,
      colorSuccessText: Color.lerp(
        colorSuccessText,
        other.colorSuccessText,
        t,
      )!,
      colorWarning: Color.lerp(colorWarning, other.colorWarning, t)!,
      colorWarningMuted: Color.lerp(
        colorWarningMuted,
        other.colorWarningMuted,
        t,
      )!,
      colorWarningText: Color.lerp(
        colorWarningText,
        other.colorWarningText,
        t,
      )!,
      colorErrorMuted: Color.lerp(colorErrorMuted, other.colorErrorMuted, t)!,
      colorErrorText: Color.lerp(colorErrorText, other.colorErrorText, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderMuted: Color.lerp(borderMuted, other.borderMuted, t)!,
      borderAccent: Color.lerp(borderAccent, other.borderAccent, t)!,
    );
  }
}
