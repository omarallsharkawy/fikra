import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildFikraTheme() {
  const scheme = ColorScheme.dark(
    primary: FikraColors.accent,
    onPrimary: FikraColors.textPrimary,
    secondary: FikraColors.accentLight,
    surface: FikraColors.screen,
    onSurface: FikraColors.textPrimary,
    error: FikraColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: FikraText.family,
    scaffoldBackgroundColor: FikraColors.screen,
    canvasColor: FikraColors.screen,
    // Plasma: no ripples, press feedback is a spring scale instead.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: FikraColors.accentLight,
      selectionColor: Color(0x5549AAFF),
      selectionHandleColor: FikraColors.accentLight,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FikraColors.glassHighlight,
      contentTextStyle: FikraText.body,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FikraRadius.md),
        side: const BorderSide(color: FikraColors.border, width: FikraSpace.hairline),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent, elevation: 0),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBarrierColor: FikraColors.scrim,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: FikraColors.textPrimary, size: 22),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
