import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const fontSans = 'Inter';
  static const fontMono = 'JetBrainsMono';
  static const fontFallback = <String>[
    'Segoe UI',
    'PingFang SC',
    'Microsoft YaHei',
  ];
  static const monoFallback = <String>['Consolas', 'Menlo', 'monospace'];

  static const textXs = 12.0;
  static const textSm = 14.0;
  static const textBase = 16.0;
  static const textLg = 18.0;
  static const textXl = 20.0;
  static const text2xl = 24.0;
  static const text3xl = 30.0;
  static const text4xl = 36.0;
  static const text5xl = 48.0;

  static const lineXs = 16.0;
  static const lineSm = 20.0;
  static const lineBase = 24.0;
  static const lineLg = 28.0;
  static const lineXl = 28.0;
  static const line2xl = 32.0;
  static const line3xl = 36.0;
  static const line4xl = 40.0;
  static const line5xl = 56.0;

  static const fontWeightNormal = FontWeight.w400;
  static const fontWeightMedium = FontWeight.w500;
  static const fontWeightSemibold = FontWeight.w600;
  static const fontWeightBold = FontWeight.w700;

  static const splashOutlineWidth = 5.0;
  static const splashLetterSpacing = 4.0;

  static TextStyle mono({
    required double fontSize,
    required double lineHeight,
    FontWeight fontWeight = fontWeightMedium,
    Color? color,
  }) {
    return TextStyle(
      color: color,
      fontFamily: fontMono,
      fontFamilyFallback: monoFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight / fontSize,
      letterSpacing: 0,
    );
  }
}
