import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pearl semantic colours and static material parameters. Hexes are AARRGGBB.
@immutable
class FikraPalette extends ThemeExtension<FikraPalette> {
  const FikraPalette({
    required this.canvas,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.line,
    required this.chip,
    required this.selected,
    required this.shadow,
    required this.rim,
    required this.highlight,
    required this.lensRim,
    required this.lensNeutral,
    required this.bloomCool,
    required this.bloomWarm,
    required this.spectrumCool,
    required this.spectrumWarm,
    required this.spectrumSage,
    required this.addTop,
    required this.graphEdge,
    required this.borderGraph,
    required this.danger,
    required this.dangerBg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.scrim,
    required this.selection,
    required this.groupBlue,
    required this.groupSage,
    required this.groupSand,
    required this.groupGray,
    required this.bloomCoolAlpha,
    required this.bloomWarmAlpha,
    required this.rimAlpha,
    required this.highlightAlpha,
    required this.shadowAlpha,
    required this.contactAlpha,
    required this.frameShadowAlpha,
    required this.washAlpha,
    required this.specularAlpha,
    required this.spectrumAlpha,
    required this.lensRimAlpha,
    required this.lensSheenAlpha,
    required this.lensHighlightAlpha,
    required this.lensInnerAlpha,
    required this.lensShadowAlpha,
    required this.glassBackingAlpha,
  });

  final Color canvas;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color line;
  final Color chip;
  final Color selected;
  final Color shadow;
  final Color rim;
  final Color highlight;
  final Color lensRim;
  final Color lensNeutral;
  final Color bloomCool;
  final Color bloomWarm;
  final Color spectrumCool;
  final Color spectrumWarm;
  final Color spectrumSage;
  final Color addTop;
  final Color graphEdge;
  final Color borderGraph;
  final Color danger;
  final Color dangerBg;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color scrim;
  final Color selection;

  /// Note-group markers (stored ids 0..3): calm, distinct hues; 3:1 on
  /// surface and canvas.
  final Color groupBlue;
  final Color groupSage;
  final Color groupSand;
  final Color groupGray;
  final double bloomCoolAlpha;
  final double bloomWarmAlpha;
  final double rimAlpha;
  final double highlightAlpha;
  final double shadowAlpha;
  final double contactAlpha;
  final double frameShadowAlpha;
  final double washAlpha;
  final double specularAlpha;
  final double spectrumAlpha;
  final double lensRimAlpha;
  final double lensSheenAlpha;
  final double lensHighlightAlpha;
  final double lensInnerAlpha;
  final double lensShadowAlpha;
  final double glassBackingAlpha;

  static const lensTintAlpha = 0.20;
  static const lensSpectrumGain = 1.15;

  /// CSS 145deg: down and right, in the one approved accent hue.
  LinearGradient get addGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    transform: const PearlGradientAngle(145),
    colors: [addTop, accent],
  );

  static const light = FikraPalette(
    canvas: Color(0xFFF5F4F0),
    surface: Color(0xFFFEFEFC),
    textPrimary: Color(0xFF263039),
    textSecondary: Color(0xFF59636B),
    accent: Color(0xFF346789),
    onAccent: Color(0xFFFFFFFF),
    line: Color(0xFFE0E1E1),
    chip: Color(0xFFF5F5F4),
    selected: Color(0xFFECF0F2),
    shadow: Color(0xFF101719),
    rim: Color(0xFFFFFFFF),
    highlight: Color(0xFFFFFFFF),
    lensRim: Color(0xFFFFFFFF),
    lensNeutral: Color(0xFFD6D9D9),
    bloomCool: Color(0xFFB8C8D0),
    bloomWarm: Color(0xFFD9CCB6),
    spectrumCool: Color(0xFFA8BECD),
    spectrumWarm: Color(0xFFD3C9B6),
    spectrumSage: Color(0xFFC4D2CA),
    addTop: Color(0xFF3B7090),
    graphEdge: Color(0xFF8E9599),
    borderGraph: Color(0xFFB2B7B9),
    danger: Color(0xFF884C40),
    dangerBg: Color(0xFFF3E8E2),
    success: Color(0xFF41634F),
    successBg: Color(0xFFE9EFE8),
    warning: Color(0xFF746039),
    warningBg: Color(0xFFF2EDE1),
    scrim: Color(0x33000000),
    selection: Color(0x33346789),
    groupBlue: Color(0xFF5E7F96),
    groupSage: Color(0xFF6E8B78),
    groupSand: Color(0xFFA08A5C),
    groupGray: Color(0xFF878E92),
    bloomCoolAlpha: 0.1,
    bloomWarmAlpha: 0.07,
    rimAlpha: 0.76,
    highlightAlpha: 0.65,
    shadowAlpha: 0.12,
    contactAlpha: 0.05,
    frameShadowAlpha: 0.10,
    washAlpha: 0,
    specularAlpha: 0.72,
    spectrumAlpha: 0.12,
    lensRimAlpha: 0.88,
    lensSheenAlpha: 0.05,
    lensHighlightAlpha: 0.86,
    lensInnerAlpha: 0.32,
    lensShadowAlpha: 0.12,
    glassBackingAlpha: 0.90,
  );

  static const dark = FikraPalette(
    canvas: Color(0xFF20272C),
    surface: Color(0xFF2D353A),
    textPrimary: Color(0xFFF2F4F4),
    textSecondary: Color(0xFFB6C0C4),
    accent: Color(0xFFA2C1D4),
    onAccent: Color(0xFF162832),
    line: Color(0xFF495054),
    chip: Color(0xFF353D42),
    selected: Color(0xFF384248),
    shadow: Color(0xFF101719),
    rim: Color(0xFFF4F7F5),
    highlight: Color(0xFFFFFFFF),
    lensRim: Color(0xFFF4F7F5),
    lensNeutral: Color(0xFF4E565B),
    bloomCool: Color(0xFF94ACB8),
    bloomWarm: Color(0xFFB8AD97),
    spectrumCool: Color(0xFFA8BECD),
    spectrumWarm: Color(0xFFD3C9B6),
    spectrumSage: Color(0xFFC4D2CA),
    addTop: Color(0xFFACC8D8),
    graphEdge: Color(0xFF8A9498),
    borderGraph: Color(0xFF6C7579),
    danger: Color(0xFFD4ABA0),
    dangerBg: Color(0xFF40332F),
    success: Color(0xFFAAC5B2),
    successBg: Color(0xFF303E35),
    warning: Color(0xFFD1BE95),
    warningBg: Color(0xFF403A2E),
    scrim: Color(0x99000000),
    selection: Color(0x55A2C1D4),
    groupBlue: Color(0xFF8FAFC3),
    groupSage: Color(0xFF9DB8A6),
    groupSand: Color(0xFFC8B48A),
    groupGray: Color(0xFF8A9498),
    bloomCoolAlpha: 0.09,
    bloomWarmAlpha: 0.04,
    rimAlpha: 0.3,
    highlightAlpha: 0.24,
    shadowAlpha: 0.32,
    contactAlpha: 0.12,
    frameShadowAlpha: 0.28,
    washAlpha: 0,
    specularAlpha: 0.48,
    spectrumAlpha: 0.14,
    lensRimAlpha: 0.65,
    lensSheenAlpha: 0.03,
    lensHighlightAlpha: 0.64,
    lensInnerAlpha: 0.16,
    lensShadowAlpha: 0.24,
    glassBackingAlpha: 0.72,
  );

  @override
  FikraPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? line,
    Color? chip,
    Color? selected,
    Color? shadow,
    Color? rim,
    Color? highlight,
    Color? lensRim,
    Color? lensNeutral,
    Color? bloomCool,
    Color? bloomWarm,
    Color? spectrumCool,
    Color? spectrumWarm,
    Color? spectrumSage,
    Color? addTop,
    Color? graphEdge,
    Color? borderGraph,
    Color? danger,
    Color? dangerBg,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? scrim,
    Color? selection,
    Color? groupBlue,
    Color? groupSage,
    Color? groupSand,
    Color? groupGray,
    double? bloomCoolAlpha,
    double? bloomWarmAlpha,
    double? rimAlpha,
    double? highlightAlpha,
    double? shadowAlpha,
    double? contactAlpha,
    double? frameShadowAlpha,
    double? washAlpha,
    double? specularAlpha,
    double? spectrumAlpha,
    double? lensRimAlpha,
    double? lensSheenAlpha,
    double? lensHighlightAlpha,
    double? lensInnerAlpha,
    double? lensShadowAlpha,
    double? glassBackingAlpha,
  }) => FikraPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    line: line ?? this.line,
    chip: chip ?? this.chip,
    selected: selected ?? this.selected,
    shadow: shadow ?? this.shadow,
    rim: rim ?? this.rim,
    highlight: highlight ?? this.highlight,
    lensRim: lensRim ?? this.lensRim,
    lensNeutral: lensNeutral ?? this.lensNeutral,
    bloomCool: bloomCool ?? this.bloomCool,
    bloomWarm: bloomWarm ?? this.bloomWarm,
    spectrumCool: spectrumCool ?? this.spectrumCool,
    spectrumWarm: spectrumWarm ?? this.spectrumWarm,
    spectrumSage: spectrumSage ?? this.spectrumSage,
    addTop: addTop ?? this.addTop,
    graphEdge: graphEdge ?? this.graphEdge,
    borderGraph: borderGraph ?? this.borderGraph,
    danger: danger ?? this.danger,
    dangerBg: dangerBg ?? this.dangerBg,
    success: success ?? this.success,
    successBg: successBg ?? this.successBg,
    warning: warning ?? this.warning,
    warningBg: warningBg ?? this.warningBg,
    scrim: scrim ?? this.scrim,
    selection: selection ?? this.selection,
    groupBlue: groupBlue ?? this.groupBlue,
    groupSage: groupSage ?? this.groupSage,
    groupSand: groupSand ?? this.groupSand,
    groupGray: groupGray ?? this.groupGray,
    bloomCoolAlpha: bloomCoolAlpha ?? this.bloomCoolAlpha,
    bloomWarmAlpha: bloomWarmAlpha ?? this.bloomWarmAlpha,
    rimAlpha: rimAlpha ?? this.rimAlpha,
    highlightAlpha: highlightAlpha ?? this.highlightAlpha,
    shadowAlpha: shadowAlpha ?? this.shadowAlpha,
    contactAlpha: contactAlpha ?? this.contactAlpha,
    frameShadowAlpha: frameShadowAlpha ?? this.frameShadowAlpha,
    washAlpha: washAlpha ?? this.washAlpha,
    specularAlpha: specularAlpha ?? this.specularAlpha,
    spectrumAlpha: spectrumAlpha ?? this.spectrumAlpha,
    lensRimAlpha: lensRimAlpha ?? this.lensRimAlpha,
    lensSheenAlpha: lensSheenAlpha ?? this.lensSheenAlpha,
    lensHighlightAlpha: lensHighlightAlpha ?? this.lensHighlightAlpha,
    lensInnerAlpha: lensInnerAlpha ?? this.lensInnerAlpha,
    lensShadowAlpha: lensShadowAlpha ?? this.lensShadowAlpha,
    glassBackingAlpha: glassBackingAlpha ?? this.glassBackingAlpha,
  );

  @override
  FikraPalette lerp(covariant FikraPalette? other, double t) {
    if (other == null || t == 0) return this;
    if (t == 1) return other;
    return FikraPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      line: Color.lerp(line, other.line, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      rim: Color.lerp(rim, other.rim, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      lensRim: Color.lerp(lensRim, other.lensRim, t)!,
      lensNeutral: Color.lerp(lensNeutral, other.lensNeutral, t)!,
      bloomCool: Color.lerp(bloomCool, other.bloomCool, t)!,
      bloomWarm: Color.lerp(bloomWarm, other.bloomWarm, t)!,
      spectrumCool: Color.lerp(spectrumCool, other.spectrumCool, t)!,
      spectrumWarm: Color.lerp(spectrumWarm, other.spectrumWarm, t)!,
      spectrumSage: Color.lerp(spectrumSage, other.spectrumSage, t)!,
      addTop: Color.lerp(addTop, other.addTop, t)!,
      graphEdge: Color.lerp(graphEdge, other.graphEdge, t)!,
      borderGraph: Color.lerp(borderGraph, other.borderGraph, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      groupBlue: Color.lerp(groupBlue, other.groupBlue, t)!,
      groupSage: Color.lerp(groupSage, other.groupSage, t)!,
      groupSand: Color.lerp(groupSand, other.groupSand, t)!,
      groupGray: Color.lerp(groupGray, other.groupGray, t)!,
      bloomCoolAlpha: bloomCoolAlpha + (other.bloomCoolAlpha - bloomCoolAlpha) * t,
      bloomWarmAlpha: bloomWarmAlpha + (other.bloomWarmAlpha - bloomWarmAlpha) * t,
      rimAlpha: rimAlpha + (other.rimAlpha - rimAlpha) * t,
      highlightAlpha: highlightAlpha + (other.highlightAlpha - highlightAlpha) * t,
      shadowAlpha: shadowAlpha + (other.shadowAlpha - shadowAlpha) * t,
      contactAlpha: contactAlpha + (other.contactAlpha - contactAlpha) * t,
      frameShadowAlpha: frameShadowAlpha + (other.frameShadowAlpha - frameShadowAlpha) * t,
      washAlpha: washAlpha + (other.washAlpha - washAlpha) * t,
      specularAlpha: specularAlpha + (other.specularAlpha - specularAlpha) * t,
      spectrumAlpha: spectrumAlpha + (other.spectrumAlpha - spectrumAlpha) * t,
      lensRimAlpha: lensRimAlpha + (other.lensRimAlpha - lensRimAlpha) * t,
      lensSheenAlpha: lensSheenAlpha + (other.lensSheenAlpha - lensSheenAlpha) * t,
      lensHighlightAlpha: lensHighlightAlpha + (other.lensHighlightAlpha - lensHighlightAlpha) * t,
      lensInnerAlpha: lensInnerAlpha + (other.lensInnerAlpha - lensInnerAlpha) * t,
      lensShadowAlpha: lensShadowAlpha + (other.lensShadowAlpha - lensShadowAlpha) * t,
      glassBackingAlpha: glassBackingAlpha + (other.glassBackingAlpha - glassBackingAlpha) * t,
    );
  }
}

/// CSS angles operate in physical coordinates, including non-square controls.
/// A diagonal Alignment alone would change the angle with the aspect ratio.
class PearlGradientAngle extends GradientTransform {
  const PearlGradientAngle(this.degrees);
  final double degrees;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    if (bounds.width == 0) return Matrix4.identity();
    final angle = (degrees - 90) * math.pi / 180;
    final length = (bounds.width * math.cos(angle)).abs() + (bounds.height * math.sin(angle)).abs();
    final centre = bounds.center;
    return Matrix4.translationValues(centre.dx, centre.dy, 0)
      ..rotateZ(angle)
      ..scaleByDouble(length / bounds.width, 1, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
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
  TextStyle get caption => _base.copyWith(fontSize: 12.5, color: colors.textSecondary);
  TextStyle get nav => _base.copyWith(color: colors.textPrimary, fontSize: 13);
  TextStyle get button => _base.copyWith(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700);
  TextStyle get chip => _base.copyWith(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500);
  TextStyle get meta => _base.copyWith(fontSize: 11, color: colors.textSecondary);
}
