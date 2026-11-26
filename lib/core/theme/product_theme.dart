import 'package:flutter/material.dart';

import 'fikra_theme.dart';
import 'tokens.dart';

/// Presentation from the approved HTML reference. Legacy demo keeps its theme.
ThemeData buildProductTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = (dark ? FikraPalette.dark : FikraPalette.light).copyWith(
    canvas: Color(dark ? 0xff101114 : 0xffeef0f2),
    surface: Color(dark ? 0xff1a1c21 : 0xffffffff),
    chip: Color(dark ? 0xff1a1c21 : 0xffffffff),
    line: Color(dark ? 0xff2b2e35 : 0xffcbd0d6),
    textPrimary: Color(dark ? 0xffeef0f2 : 0xff101114),
    textSecondary: Color(dark ? 0xffa7adb5 : 0xff4a525c),
    brandLime: const Color(0xffc6f04a),
    onBrandLime: const Color(0xff101114),
    brandBlue: const Color(0xff2547e8),
    onBrandBlue: const Color(0xffeef0f2),
    brandPurple: const Color(0xff5f31c4),
    onBrandPurple: const Color(0xffeef0f2),
    brandSlate: const Color(0xff55606d),
    onBrandSlate: const Color(0xffeef0f2),
    accent: Color(dark ? 0xffc6f04a : 0xff4a6a00),
    onAccent: Color(dark ? 0xff101114 : 0xffffffff),
  );
  final theme = buildFikraTheme(brightness, palette: colors);
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color, width: width),
  );
  return theme.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(colors.line),
      enabledBorder: border(colors.line),
      disabledBorder: border(colors.line),
      focusedBorder: border(colors.accent, 2),
      errorBorder: border(colors.danger),
      focusedErrorBorder: border(colors.danger, 2),
      labelStyle: FikraText(colors).caption,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.line),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
