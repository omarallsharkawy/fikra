import 'package:flutter/material.dart';

import '../motion/page_transitions.dart';
import 'tokens.dart';

ThemeData buildFikraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = dark ? FikraPalette.dark : FikraPalette.light;
  final text = FikraText(colors);
  final scheme = dark
      ? ColorScheme.dark(
          primary: colors.accent,
          onPrimary: colors.textPrimary,
          secondary: colors.accentLight,
          surface: colors.screen,
          onSurface: colors.textPrimary,
          error: colors.danger,
        )
      : ColorScheme.light(
          primary: colors.accent,
          onPrimary: colors.textOnSelected,
          secondary: colors.accentLight,
          onSecondary: colors.textOnSelected,
          surface: colors.screen,
          onSurface: colors.textPrimary,
          error: colors.danger,
          onError: colors.textOnSelected,
          outline: colors.border,
          scrim: colors.scrim,
        );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [colors],
    fontFamily: FikraText.family,
    fontFamilyFallback: const ['Roboto'],
    scaffoldBackgroundColor: colors.screen,
    canvasColor: colors.screen,
    // Plasma: no ripples, press feedback is a spring scale instead.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accentLight,
      selectionColor: colors.selection,
      selectionHandleColor: colors.accentLight,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.glassHighlight,
      contentTextStyle: text.body,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FikraRadius.md),
        side: BorderSide(color: colors.border, width: FikraSpace.hairline),
      ),
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
