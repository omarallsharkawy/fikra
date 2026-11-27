import 'package:flutter/material.dart';

import '../motion/page_transitions.dart';
import 'tokens.dart';

ThemeData buildFikraTheme(Brightness brightness, {FikraPalette? palette}) {
  final dark = brightness == Brightness.dark;
  final colors = palette ?? (dark ? FikraPalette.dark : FikraPalette.light);
  final text = FikraText(colors);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    secondary: colors.brandBlue,
    onSecondary: colors.onBrandBlue,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    error: colors.danger,
    onError: colors.dangerBg,
    primaryContainer: colors.selected,
    onPrimaryContainer: colors.accent,
    secondaryContainer: colors.chip,
    onSecondaryContainer: colors.textPrimary,
    tertiary: colors.brandPurple,
    onTertiary: colors.onBrandPurple,
    tertiaryContainer: colors.chip,
    onTertiaryContainer: colors.textPrimary,
    errorContainer: colors.dangerBg,
    onErrorContainer: colors.danger,
    surfaceTint: Colors.transparent,
    outline: colors.line,
    scrim: colors.scrim,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [colors],
    fontFamily: FikraText.family,
    fontFamilyFallback: FikraText.fallbacks,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.canvas,
    // Plasma: no ripples, press feedback is a spring scale instead.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accent,
      selectionColor: colors.selection,
      selectionHandleColor: colors.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.surface,
      contentTextStyle: text.body,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(top: 5, bottom: 12),
      shape: const StadiumBorder(),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent, elevation: 0),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBarrierColor: colors.scrim,
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FikraPageTransitionsBuilder()}),
  );
}
