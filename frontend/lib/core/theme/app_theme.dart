import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_extension.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static final light = _buildTheme(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.blue600,
      onPrimary: Colors.white,
      secondary: AppColors.gray700,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF111111),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Colors.white,
      error: AppColors.red600,
      onError: Colors.white,
    ),
    extension: const AppThemeExtension(
      bgMuted: Color(0xFFF0F0F0),
      bgOverlay: Color(0x80000000),
      textSecondary: Color(0xFF555555),
      textTertiary: Color(0xFF888888),
      accentHover: AppColors.blue700,
      accentActive: AppColors.blue800,
      accentMuted: AppColors.blue50,
      accentText: AppColors.blue700,
      colorSuccess: AppColors.green700,
      colorSuccessMuted: AppColors.green100,
      colorSuccessText: AppColors.green800,
      colorWarning: AppColors.orange700,
      colorWarningMuted: AppColors.orange50,
      colorWarningText: AppColors.orange800,
      colorErrorMuted: AppColors.red50,
      colorErrorText: AppColors.red800,
      borderDefault: Color(0xFFD4D4D4),
      borderMuted: Color(0xFFE8E8E8),
      borderAccent: AppColors.blue300,
    ),
  );

  static final dark = _buildTheme(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.blue400,
      onPrimary: Color(0xFF111111),
      secondary: AppColors.gray300,
      onSecondary: AppColors.gray950,
      surface: AppColors.gray950,
      onSurface: Color(0xFFF5F5F5),
      surfaceContainer: Color(0xFF141414),
      surfaceContainerHigh: Color(0xFF1C1C1C),
      error: AppColors.red400,
      onError: AppColors.gray950,
    ),
    extension: const AppThemeExtension(
      bgMuted: Color(0xFF1A1A1A),
      bgOverlay: Color(0xB3000000),
      textSecondary: Color(0xFFA3A3A3),
      textTertiary: Color(0xFF737373),
      accentHover: AppColors.blue300,
      accentActive: AppColors.blue500,
      accentMuted: Color(0x2660A5FA),
      accentText: AppColors.blue300,
      colorSuccess: AppColors.green400,
      colorSuccessMuted: Color(0x264ADE80),
      colorSuccessText: AppColors.green200,
      colorWarning: AppColors.orange400,
      colorWarningMuted: Color(0x26FB923C),
      colorWarningText: AppColors.orange200,
      colorErrorMuted: Color(0x26F87171),
      colorErrorText: AppColors.red200,
      borderDefault: Color(0xFF3A3A3A),
      borderMuted: Color(0xFF2A2A2A),
      borderAccent: AppColors.blue600,
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppThemeExtension extension,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontSans,
      fontFamilyFallback: AppTypography.fontFallback,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[extension],
    );

    return base.copyWith(
      textTheme: _textTheme(colorScheme, extension),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontFamily: AppTypography.fontSans,
          fontFamilyFallback: AppTypography.fontFallback,
          fontSize: AppTypography.textXl,
          fontWeight: AppTypography.fontWeightBold,
          height: AppTypography.lineXl / AppTypography.textXl,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: extension.borderMuted),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: extension.borderMuted,
        thickness: 1,
        space: AppSpacing.x6,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, AppSpacing.x10)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          ),
          textStyle: WidgetStatePropertyAll(
            _buttonTextStyle(AppTypography.textBase),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return extension.accentActive;
            }
            if (states.contains(WidgetState.hovered)) {
              return extension.accentHover;
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, AppSpacing.x10)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          ),
          textStyle: WidgetStatePropertyAll(
            _buttonTextStyle(AppTypography.textSm),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: extension.borderDefault),
          ),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            _buttonTextStyle(AppTypography.textSm),
          ),
          foregroundColor: WidgetStatePropertyAll(extension.textSecondary),
          overlayColor: WidgetStatePropertyAll(extension.accentMuted),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: TextStyle(
          color: extension.textTertiary,
          fontSize: AppTypography.textBase,
          height: AppTypography.lineBase / AppTypography.textBase,
        ),
        labelStyle: TextStyle(
          color: extension.textSecondary,
          fontSize: AppTypography.textSm,
          fontWeight: AppTypography.fontWeightMedium,
          height: AppTypography.lineSm / AppTypography.textSm,
        ),
        border: _outlineBorder(extension.borderDefault),
        enabledBorder: _outlineBorder(extension.borderDefault),
        focusedBorder: _outlineBorder(colorScheme.primary),
        errorBorder: _outlineBorder(colorScheme.error),
        focusedErrorBorder: _outlineBorder(colorScheme.error),
      ),
    );
  }

  static TextTheme _textTheme(
    ColorScheme colorScheme,
    AppThemeExtension extension,
  ) {
    TextStyle sans(
      double size,
      double lineHeight,
      FontWeight weight,
      Color color,
    ) {
      return TextStyle(
        color: color,
        fontFamily: AppTypography.fontSans,
        fontFamilyFallback: AppTypography.fontFallback,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        letterSpacing: 0,
      );
    }

    return TextTheme(
      displayLarge: sans(
        AppTypography.text5xl,
        AppTypography.line5xl,
        AppTypography.fontWeightBold,
        colorScheme.onSurface,
      ),
      headlineLarge: sans(
        AppTypography.text4xl,
        AppTypography.line4xl,
        AppTypography.fontWeightBold,
        colorScheme.onSurface,
      ),
      headlineMedium: sans(
        AppTypography.text3xl,
        AppTypography.line3xl,
        AppTypography.fontWeightBold,
        colorScheme.onSurface,
      ),
      titleLarge: sans(
        AppTypography.textXl,
        AppTypography.lineXl,
        AppTypography.fontWeightSemibold,
        colorScheme.onSurface,
      ),
      titleMedium: sans(
        AppTypography.textLg,
        AppTypography.lineLg,
        AppTypography.fontWeightSemibold,
        colorScheme.onSurface,
      ),
      bodyLarge: sans(
        AppTypography.textBase,
        AppTypography.lineBase,
        AppTypography.fontWeightNormal,
        colorScheme.onSurface,
      ),
      bodyMedium: sans(
        AppTypography.textSm,
        AppTypography.lineSm,
        AppTypography.fontWeightNormal,
        extension.textSecondary,
      ),
      labelLarge: sans(
        AppTypography.textBase,
        AppTypography.lineBase,
        AppTypography.fontWeightSemibold,
        colorScheme.onSurface,
      ),
      labelMedium: sans(
        AppTypography.textSm,
        AppTypography.lineSm,
        AppTypography.fontWeightMedium,
        extension.textSecondary,
      ),
      labelSmall: sans(
        AppTypography.textXs,
        AppTypography.lineXs,
        AppTypography.fontWeightMedium,
        extension.textTertiary,
      ),
    );
  }

  static TextStyle _buttonTextStyle(double size) {
    return TextStyle(
      fontFamily: AppTypography.fontSans,
      fontFamilyFallback: AppTypography.fontFallback,
      fontSize: size,
      fontWeight: AppTypography.fontWeightSemibold,
      height: AppTypography.lineSm / AppTypography.textSm,
      letterSpacing: 0,
    );
  }

  static OutlineInputBorder _outlineBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
  }
}
