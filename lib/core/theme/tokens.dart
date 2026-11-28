import 'dart:math' as math;

import 'package:flutter/material.dart';

/// FIKRA brand and semantic colours plus static material parameters. Hexes are AARRGGBB.
@immutable
class FikraPalette extends ThemeExtension<FikraPalette> {
  const FikraPalette({
    required this.canvas,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.brandLime,
    required this.onBrandLime,
    required this.brandLimeFg,
    required this.brandLimeTint,
    required this.brandBlue,
    required this.onBrandBlue,
    required this.brandBlueFg,
    required this.brandBlueTint,
    required this.brandPurple,
    required this.onBrandPurple,
    required this.brandPurpleFg,
    required this.brandPurpleTint,
    required this.brandSlate,
    required this.onBrandSlate,
    required this.brandSlateFg,
    required this.brandSlateTint,
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

  /// Brand fills, ink on fills, surface-safe foregrounds, and translucent badge tints.
  final Color brandLime;
  final Color onBrandLime;
  final Color brandLimeFg;
  final Color brandLimeTint;
  final Color brandBlue;
  final Color onBrandBlue;
  final Color brandBlueFg;
  final Color brandBlueTint;
  final Color brandPurple;
  final Color onBrandPurple;
  final Color brandPurpleFg;
  final Color brandPurpleTint;
  final Color brandSlate;
  final Color onBrandSlate;
  final Color brandSlateFg;
  final Color brandSlateTint;

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

  /// Note-group markers (stored ids 0..3): distinct hues; >= 3:1 on surface and canvas.
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

  /// CSS 145deg: down and right, in the brand accent hue.
  LinearGradient get addGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    transform: const PearlGradientAngle(145),
    colors: [addTop, accent],
  );

  static const light = FikraPalette(
    canvas: Color(0xFFF5F5F2),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF14181F),
    textSecondary: Color(0xFF525B68),
    accent: Color(0xFF446200),
    onAccent: Color(0xFFFFFFFF),
    brandLime: Color(0xFFC8F04A),
    onBrandLime: Color(0xFF111214),
    brandLimeFg: Color(0xFF446200),
    brandLimeTint: Color(0x26C8F04A),
    brandBlue: Color(0xFF2448E6),
    onBrandBlue: Color(0xFFFFFFFF),
    brandBlueFg: Color(0xFF1E40D8),
    brandBlueTint: Color(0x212448E6),
    brandPurple: Color(0xFF6336D6),
    onBrandPurple: Color(0xFFFFFFFF),
    brandPurpleFg: Color(0xFF562AC2),
    brandPurpleTint: Color(0x216336D6),
    brandSlate: Color(0xFF3B4252),
    onBrandSlate: Color(0xFFFFFFFF),
    brandSlateFg: Color(0xFF3B4252),
    brandSlateTint: Color(0x213B4252),
    line: Color(0xFFDCDFE4),
    chip: Color(0xFFECEEEB),
    selected: Color(0xFFEEF6D4),
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
    addTop: Color(0xFF4E7000),
    graphEdge: Color(0xFF7A8390),
    borderGraph: Color(0xFFB8BFC9),
    danger: Color(0xFFB3261E),
    dangerBg: Color(0xFFFCE8E6),
    success: Color(0xFF1B6E3A),
    successBg: Color(0xFFE6F4EA),
    warning: Color(0xFF8A5300),
    warningBg: Color(0xFFFFF3DC),
    scrim: Color(0x33000000),
    selection: Color(0x33446200),
    groupBlue: Color(0xFF2448E6),
    groupSage: Color(0xFF2E7D52),
    groupSand: Color(0xFFA66B12),
    groupGray: Color(0xFF6B7380),
    bloomCoolAlpha: 0,
    bloomWarmAlpha: 0,
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
    canvas: Color(0xFF0E1013),
    surface: Color(0xFF171A20),
    textPrimary: Color(0xFFF3F5F7),
    textSecondary: Color(0xFFA1AAB8),
    accent: Color(0xFFC8F04A),
    onAccent: Color(0xFF111214),
    brandLime: Color(0xFFC8F04A),
    onBrandLime: Color(0xFF111214),
    brandLimeFg: Color(0xFFC8F04A),
    brandLimeTint: Color(0x24C8F04A),
    brandBlue: Color(0xFF2448E6),
    onBrandBlue: Color(0xFFFFFFFF),
    brandBlueFg: Color(0xFF7A9BFF),
    brandBlueTint: Color(0x292448E6),
    brandPurple: Color(0xFF6336D6),
    onBrandPurple: Color(0xFFFFFFFF),
    brandPurpleFg: Color(0xFFB294FF),
    brandPurpleTint: Color(0x296336D6),
    brandSlate: Color(0xFF3B4252),
    onBrandSlate: Color(0xFFFFFFFF),
    brandSlateFg: Color(0xFFB4BFCE),
    brandSlateTint: Color(0x2994A3B8),
    line: Color(0xFF2E3440),
    chip: Color(0xFF22262F),
    selected: Color(0xFF242B1A),
    shadow: Color(0xFF000000),
    rim: Color(0xFFF4F7F5),
    highlight: Color(0xFFFFFFFF),
    lensRim: Color(0xFFF4F7F5),
    lensNeutral: Color(0xFF4E565B),
    bloomCool: Color(0xFF94ACB8),
    bloomWarm: Color(0xFFB8AD97),
    spectrumCool: Color(0xFFA8BECD),
    spectrumWarm: Color(0xFFD3C9B6),
    spectrumSage: Color(0xFFC4D2CA),
    addTop: Color(0xFFD8F76A),
    graphEdge: Color(0xFF8A94A6),
    borderGraph: Color(0xFF454E5E),
    danger: Color(0xFFF28B82),
    dangerBg: Color(0xFF3A1E1E),
    success: Color(0xFF81E6A5),
    successBg: Color(0xFF172E22),
    warning: Color(0xFFF5C969),
    warningBg: Color(0xFF332915),
    scrim: Color(0x99000000),
    selection: Color(0x44C8F04A),
    groupBlue: Color(0xFF7A9BFF),
    groupSage: Color(0xFF6DD59C),
    groupSand: Color(0xFFF0C265),
    groupGray: Color(0xFF8E99AB),
    bloomCoolAlpha: 0,
    bloomWarmAlpha: 0,
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
    Color? brandLime,
    Color? onBrandLime,
    Color? brandLimeFg,
    Color? brandLimeTint,
    Color? brandBlue,
    Color? onBrandBlue,
    Color? brandBlueFg,
    Color? brandBlueTint,
    Color? brandPurple,
    Color? onBrandPurple,
    Color? brandPurpleFg,
    Color? brandPurpleTint,
    Color? brandSlate,
    Color? onBrandSlate,
    Color? brandSlateFg,
    Color? brandSlateTint,
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
    brandLime: brandLime ?? this.brandLime,
    onBrandLime: onBrandLime ?? this.onBrandLime,
    brandLimeFg: brandLimeFg ?? this.brandLimeFg,
    brandLimeTint: brandLimeTint ?? this.brandLimeTint,
    brandBlue: brandBlue ?? this.brandBlue,
    onBrandBlue: onBrandBlue ?? this.onBrandBlue,
    brandBlueFg: brandBlueFg ?? this.brandBlueFg,
    brandBlueTint: brandBlueTint ?? this.brandBlueTint,
    brandPurple: brandPurple ?? this.brandPurple,
    onBrandPurple: onBrandPurple ?? this.onBrandPurple,
    brandPurpleFg: brandPurpleFg ?? this.brandPurpleFg,
    brandPurpleTint: brandPurpleTint ?? this.brandPurpleTint,
    brandSlate: brandSlate ?? this.brandSlate,
    onBrandSlate: onBrandSlate ?? this.onBrandSlate,
    brandSlateFg: brandSlateFg ?? this.brandSlateFg,
    brandSlateTint: brandSlateTint ?? this.brandSlateTint,
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
      brandLime: Color.lerp(brandLime, other.brandLime, t)!,
      onBrandLime: Color.lerp(onBrandLime, other.onBrandLime, t)!,
      brandLimeFg: Color.lerp(brandLimeFg, other.brandLimeFg, t)!,
      brandLimeTint: Color.lerp(brandLimeTint, other.brandLimeTint, t)!,
      brandBlue: Color.lerp(brandBlue, other.brandBlue, t)!,
      onBrandBlue: Color.lerp(onBrandBlue, other.onBrandBlue, t)!,
      brandBlueFg: Color.lerp(brandBlueFg, other.brandBlueFg, t)!,
      brandBlueTint: Color.lerp(brandBlueTint, other.brandBlueTint, t)!,
      brandPurple: Color.lerp(brandPurple, other.brandPurple, t)!,
      onBrandPurple: Color.lerp(onBrandPurple, other.onBrandPurple, t)!,
      brandPurpleFg: Color.lerp(brandPurpleFg, other.brandPurpleFg, t)!,
      brandPurpleTint: Color.lerp(brandPurpleTint, other.brandPurpleTint, t)!,
      brandSlate: Color.lerp(brandSlate, other.brandSlate, t)!,
      onBrandSlate: Color.lerp(onBrandSlate, other.onBrandSlate, t)!,
      brandSlateFg: Color.lerp(brandSlateFg, other.brandSlateFg, t)!,
      brandSlateTint: Color.lerp(brandSlateTint, other.brandSlateTint, t)!,
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
  static const sm = 16.0;
  static const md = 18.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;
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

/// Brand typography. Arabic text gets zero letter spacing (tracking breaks letter joining).
class FikraText {
  const FikraText(this.colors);
  final FikraPalette colors;
  static const family = 'Inter';
  static const fallbacks = ['NotoSansArabic', 'Roboto'];
  static const _base = TextStyle(
    fontFamily: family,
    // Inter supplies Latin; preserve the existing Arabic face for Arabic glyphs.
    fontFamilyFallback: fallbacks,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  TextStyle get title =>
      _base.copyWith(color: colors.textPrimary, fontSize: 26, fontWeight: FontWeight.w600, height: 1.2);
  TextStyle get cardTitle =>
      _base.copyWith(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.35);
  TextStyle get cardTitleSmall =>
      _base.copyWith(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);
  TextStyle get section => _base.copyWith(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600);
  TextStyle get bodyLarge => _base.copyWith(color: colors.textPrimary, fontSize: 17);
  TextStyle get answer => _base.copyWith(color: colors.textPrimary, fontSize: 16);
  TextStyle get body => _base.copyWith(color: colors.textPrimary, fontSize: 16);
  TextStyle get field => _base.copyWith(color: colors.textPrimary, fontSize: 16, height: 1.4);
  TextStyle get caption => _base.copyWith(fontSize: 14, height: 1.4, color: colors.textSecondary);
  TextStyle get nav => _base.copyWith(color: colors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500);
  TextStyle get button =>
      _base.copyWith(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);
  TextStyle get chip => _base.copyWith(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500);
  TextStyle get meta => _base.copyWith(fontSize: 12.5, height: 1.4, color: colors.textSecondary);
}
