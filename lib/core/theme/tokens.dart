import 'package:flutter/material.dart';

/// Semantic colors. Dark preserves the original FIKRA tokens exactly.
/// Light follows Plasma One's neutral surfaces and alpha-black labels, with
/// darker accent/status labels for AA contrast. Hex literals use AARRGGBB.
@immutable
class FikraPalette extends ThemeExtension<FikraPalette> {
  const FikraPalette({
    required this.canvas,
    required this.screen,
    required this.glass,
    required this.glassHighlight,
    required this.pressed,
    required this.scrim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBodyMuted,
    required this.textPlaceholder,
    required this.textMeta,
    required this.textOnLight,
    required this.textLink,
    required this.border,
    required this.borderGraph,
    required this.borderFocus,
    required this.accent,
    required this.accentLight,
    required this.selectedStart,
    required this.selectedEnd,
    required this.graphEdge,
    required this.danger,
    required this.dangerBg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.screenGradient,
    required this.glassGradient,
    required this.selectedGradient,
    required this.primaryGradient,
    required this.sendGradient,
    required this.textOnSelected,
    required this.textOnSend,
    required this.selection,
  });

  final Color canvas;
  final Color screen;
  final Color glass;
  final Color glassHighlight;
  final Color pressed;
  final Color scrim;
  final Color textPrimary;
  final Color textSecondary;
  final Color textBodyMuted;
  final Color textPlaceholder;
  final Color textMeta;

  /// Inverse label for the primary button (the legacy name is retained).
  final Color textOnLight;
  final Color textLink;
  final Color border;
  final Color borderGraph;
  final Color borderFocus;
  final Color accent;
  final Color accentLight;
  final Color selectedStart;
  final Color selectedEnd;
  final Color graphEdge;
  final Color danger;
  final Color dangerBg;
  final Color success;
  final Color successBg;
  final Color warning;
  final LinearGradient screenGradient;
  final LinearGradient glassGradient;
  final LinearGradient selectedGradient;
  final LinearGradient primaryGradient;
  final LinearGradient sendGradient;

  /// Foreground on the retained blue selected surfaces.
  final Color textOnSelected;

  /// Dark foreground on the bright blue send gradient in either theme.
  final Color textOnSend;
  final Color selection;

  static const dark = FikraPalette(
    canvas: Color(0xFF111111),
    screen: Color(0xFF151515),
    glass: Color(0xFF232323),
    glassHighlight: Color(0xFF2D2D2D),
    pressed: Color(0x0FFFFFFF),
    scrim: Color(0x99000000),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xB3FFFFFF),
    textBodyMuted: Color(0xC2FFFFFF),
    textPlaceholder: Color(0xA3FFFFFF),
    textMeta: Color(0x80FFFFFF),
    textOnLight: Color(0xFF151515),
    textLink: Color(0xFF78C7FF),
    border: Color(0x24FFFFFF),
    borderGraph: Color(0x3AFFFFFF),
    borderFocus: Color(0xFF49AAFF),
    accent: Color(0xFF0088FF),
    accentLight: Color(0xFF49AAFF),
    selectedStart: Color(0xFF167FC8),
    selectedEnd: Color(0xFF00569A),
    graphEdge: Color(0xFF2E9CDF),
    danger: Color(0xFFFF6B6B),
    dangerBg: Color(0x29FF6B6B),
    success: Color(0xFF3DD68C),
    successBg: Color(0x293DD68C),
    warning: Color(0xFFFFB547),
    screenGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1D1D1D), Color(0xFF151515), Color(0xFF1B1B1B)],
      stops: [0, 0.5, 1],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D2D2D), Color(0xFF232323), Color(0xFF292929)],
      stops: [0, 0.6, 1],
    ),
    selectedGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF167FC8), Color(0xFF00569A)],
    ),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFAFAFA), Color(0xFFE8E8E8)],
    ),
    sendGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF49AAFF), Color(0xFF0088FF)],
    ),
    textOnSelected: Color(0xFFFAFAFA),
    textOnSend: Color(0xFF151515),
    selection: Color(0x5549AAFF),
  );

  static const light = FikraPalette(
    canvas: Color(0xFFF2F2F2),
    screen: Color(0xFFF2F2F2),
    glass: Color(0xFFFAFAFA),
    glassHighlight: Color(0xFFFFFFFF),
    pressed: Color(0x08000000),
    scrim: Color(0x33000000),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0x99000000),
    textBodyMuted: Color(0xB3000000),
    textPlaceholder: Color(0x99000000),
    textMeta: Color(0x99000000),
    textOnLight: Color(0xFFFAFAFA),
    textLink: Color(0xFF0066AD),
    border: Color(0x1A000000),
    borderGraph: Color(0x4D000000),
    borderFocus: Color(0xFF0066AD),
    accent: Color(0xFF0066AD),
    accentLight: Color(0xFF0066AD),
    selectedStart: Color(0xFF0872B5),
    selectedEnd: Color(0xFF00569A),
    graphEdge: Color(0xFF00569A),
    danger: Color(0xFFB42318),
    dangerBg: Color(0xFFFFF1EE),
    success: Color(0xFF176B36),
    successBg: Color(0xFFE2FEE4),
    warning: Color(0xFF8A5900),
    screenGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF2F2F2), Color(0xFFF2F2F2), Color(0xFFF7F7F7)],
      stops: [0, 0.5, 1],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
      stops: [0, 0.6, 1],
    ),
    selectedGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0872B5), Color(0xFF00569A)],
    ),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF171717), Color(0xFF363636)],
    ),
    sendGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF49AAFF), Color(0xFF0088FF)],
    ),
    textOnSelected: Color(0xFFFAFAFA),
    textOnSend: Color(0xFF151515),
    selection: Color(0x330066AD),
  );

  @override
  FikraPalette copyWith({
    Color? canvas,
    Color? screen,
    Color? glass,
    Color? glassHighlight,
    Color? pressed,
    Color? scrim,
    Color? textPrimary,
    Color? textSecondary,
    Color? textBodyMuted,
    Color? textPlaceholder,
    Color? textMeta,
    Color? textOnLight,
    Color? textLink,
    Color? border,
    Color? borderGraph,
    Color? borderFocus,
    Color? accent,
    Color? accentLight,
    Color? selectedStart,
    Color? selectedEnd,
    Color? graphEdge,
    Color? danger,
    Color? dangerBg,
    Color? success,
    Color? successBg,
    Color? warning,
    LinearGradient? screenGradient,
    LinearGradient? glassGradient,
    LinearGradient? selectedGradient,
    LinearGradient? primaryGradient,
    LinearGradient? sendGradient,
    Color? textOnSelected,
    Color? textOnSend,
    Color? selection,
  }) => FikraPalette(
    canvas: canvas ?? this.canvas,
    screen: screen ?? this.screen,
    glass: glass ?? this.glass,
    glassHighlight: glassHighlight ?? this.glassHighlight,
    pressed: pressed ?? this.pressed,
    scrim: scrim ?? this.scrim,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textBodyMuted: textBodyMuted ?? this.textBodyMuted,
    textPlaceholder: textPlaceholder ?? this.textPlaceholder,
    textMeta: textMeta ?? this.textMeta,
    textOnLight: textOnLight ?? this.textOnLight,
    textLink: textLink ?? this.textLink,
    border: border ?? this.border,
    borderGraph: borderGraph ?? this.borderGraph,
    borderFocus: borderFocus ?? this.borderFocus,
    accent: accent ?? this.accent,
    accentLight: accentLight ?? this.accentLight,
    selectedStart: selectedStart ?? this.selectedStart,
    selectedEnd: selectedEnd ?? this.selectedEnd,
    graphEdge: graphEdge ?? this.graphEdge,
    danger: danger ?? this.danger,
    dangerBg: dangerBg ?? this.dangerBg,
    success: success ?? this.success,
    successBg: successBg ?? this.successBg,
    warning: warning ?? this.warning,
    screenGradient: screenGradient ?? this.screenGradient,
    glassGradient: glassGradient ?? this.glassGradient,
    selectedGradient: selectedGradient ?? this.selectedGradient,
    primaryGradient: primaryGradient ?? this.primaryGradient,
    sendGradient: sendGradient ?? this.sendGradient,
    textOnSelected: textOnSelected ?? this.textOnSelected,
    textOnSend: textOnSend ?? this.textOnSend,
    selection: selection ?? this.selection,
  );

  @override
  FikraPalette lerp(covariant FikraPalette? other, double t) {
    if (other == null || t == 0) return this;
    if (t == 1) return other;
    return FikraPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      screen: Color.lerp(screen, other.screen, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textBodyMuted: Color.lerp(textBodyMuted, other.textBodyMuted, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      textMeta: Color.lerp(textMeta, other.textMeta, t)!,
      textOnLight: Color.lerp(textOnLight, other.textOnLight, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderGraph: Color.lerp(borderGraph, other.borderGraph, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      selectedStart: Color.lerp(selectedStart, other.selectedStart, t)!,
      selectedEnd: Color.lerp(selectedEnd, other.selectedEnd, t)!,
      graphEdge: Color.lerp(graphEdge, other.graphEdge, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      screenGradient: LinearGradient.lerp(screenGradient, other.screenGradient, t)!,
      glassGradient: LinearGradient.lerp(glassGradient, other.glassGradient, t)!,
      selectedGradient: LinearGradient.lerp(selectedGradient, other.selectedGradient, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      sendGradient: LinearGradient.lerp(sendGradient, other.sendGradient, t)!,
      textOnSelected: Color.lerp(textOnSelected, other.textOnSelected, t)!,
      textOnSend: Color.lerp(textOnSend, other.textOnSend, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
    );
  }
}

extension FikraThemeContext on BuildContext {
  FikraPalette get colors => Theme.of(this).extension<FikraPalette>()!;
  FikraText get text => FikraText(colors);
}

abstract final class FikraRadius {
  static const sm = 18.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 28.0;
  static const xxl = 38.0;
  static const full = 999.0;
}

abstract final class FikraSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const screen = 22.0;
  static const button = 56.0;
  static const nav = 70.0;
  static const field = 48.0;
  static const hairline = 0.6;
}

/// Text styles from the Figma text styles. Arabic text gets no letter spacing
/// (negative tracking breaks letter joining).
class FikraText {
  const FikraText(this.colors);
  final FikraPalette colors;
  static const family = 'NotoSansArabic';
  static const _base = TextStyle(
    fontFamily: family,
    // NotoSansArabic has no Latin glyphs; Latin words (TCP, FastAPI…) use
    // Roboto, which Android would pick anyway. Explicit so tests match.
    fontFamilyFallback: ['Roboto'],
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  TextStyle get title => _base.copyWith(color: colors.textPrimary, fontSize: 26);
  TextStyle get cardTitle => _base.copyWith(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700);
  TextStyle get cardTitleSmall => _base.copyWith(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700);
  TextStyle get section => _base.copyWith(color: colors.textPrimary, fontSize: 17);
  TextStyle get bodyLarge => _base.copyWith(color: colors.textPrimary, fontSize: 18);
  TextStyle get answer => _base.copyWith(color: colors.textPrimary, fontSize: 17);
  TextStyle get body => _base.copyWith(color: colors.textPrimary, fontSize: 16);
  TextStyle get field => _base.copyWith(color: colors.textPrimary, fontSize: 15);
  TextStyle get caption => _base.copyWith(fontSize: 12.5, color: colors.textBodyMuted);
  TextStyle get nav => _base.copyWith(color: colors.textPrimary, fontSize: 13);
  TextStyle get button => _base.copyWith(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700);
  TextStyle get chip => _base.copyWith(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500);
  TextStyle get meta => _base.copyWith(fontSize: 11, color: colors.textMeta);
}
