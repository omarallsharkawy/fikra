import 'package:flutter/material.dart';

import 'fikra_theme.dart';
import 'tokens.dart';
import 'redesign_tokens.dart';

ThemeData buildProductTheme(Brightness brightness) {
  final c = RdColors(brightness == Brightness.dark);
  final colors = (c.dark ? FikraPalette.dark : FikraPalette.light).copyWith(
    canvas: c.bg,
    surface: c.surface,
    chip: c.surface2,
    line: c.line,
    textPrimary: c.text,
    textSecondary: c.muted,
    brandLime: c.lime,
    onBrandLime: c.onLime,
    brandLimeFg: c.onLime,
    brandLimeTint: c.lime,
    brandBlue: c.blue,
    brandBlueFg: c.blue,
    brandBlueTint: c.purpleSoft,
    onBrandBlue: c.text,
    brandPurple: c.purple,
    brandPurpleFg: c.purple,
    brandPurpleTint: c.purpleSoft,
    onBrandPurple: Colors.white,
    accent: c.lime,
    onAccent: c.onLime,
    danger: c.red,
    dangerBg: c.redSoft,
    selected: c.lime,
    scrim: const Color(0x80000000),
    graphEdge: c.line,
    selection: c.purpleSoft,
  );
  final theme = buildFikraTheme(brightness, palette: colors);
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );
  return theme.copyWith(
    extensions: [colors, c],
    textTheme: theme.textTheme.apply(fontFamily: RdTokens.family, fontFamilyFallback: RdTokens.fallbacks),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: RdTokens.family, fontFamilyFallback: RdTokens.fallbacks),
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    iconTheme: IconThemeData(size: 22, color: c.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
      border: border(c.line),
      enabledBorder: border(c.line),
      focusedBorder: border(c.blue),
      errorBorder: border(c.red),
      focusedErrorBorder: border(c.red),
      labelStyle: TextStyle(color: c.muted),
      floatingLabelStyle: TextStyle(color: c.blue),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.blue,
      selectionColor: c.purpleSoft,
      selectionHandleColor: c.blue,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.blue, minimumSize: const Size(44, 44)),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      contentTextStyle: TextStyle(fontFamily: RdTokens.family, fontSize: 15, color: c.bg, height: 1.6),
      actionTextColor: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(bottom: 84),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBarrierColor: const Color(0x80000000),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
  );
}
