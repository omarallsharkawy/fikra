import 'package:flutter/material.dart';

/// Literal semantic values from design/fikrah-ui.html (CSS :root).
@immutable
class RdColors extends ThemeExtension<RdColors> {
  const RdColors(this.dark);
  final bool dark;
  Color get page => Color(dark ? 0xff07080b : 0xffe9e9ef);
  Color get bg => Color(dark ? 0xff0f1015 : 0xfff6f6f9);
  Color get surface => Color(dark ? 0xff1a1b22 : 0xffffffff);
  Color get surface2 => Color(dark ? 0xff242530 : 0xffeeeef4);
  Color get text => Color(dark ? 0xfff2f2f6 : 0xff14151a);
  Color get muted => Color(dark ? 0xffa0a2b2 : 0xff5f6173);
  Color get line => Color(dark ? 0xff2d2e3a : 0xffdcdce6);
  Color get lime => const Color(0xffc8f04d);
  Color get onLime => const Color(0xff14170a);
  Color get purple => Color(dark ? 0xff9b82ff : 0xff5b3fd9);
  Color get purpleSoft => Color(dark ? 0x249b82ff : 0x1a5b3fd9);
  Color get blue => Color(dark ? 0xff7ba0ff : 0xff2f5be0);
  Color get red => Color(dark ? 0xffff7b7b : 0xffc92a2a);
  Color get redSoft => Color(dark ? 0x1fff7b7b : 0x1ac92a2a);
  Color get added => Color(dark ? 0x3850c878 : 0x2e28a050);
  Color get removed => Color(dark ? 0x33ff7b7b : 0x26c92a2a);
  Color get orange => const Color(0xffe8913a);
  @override
  RdColors copyWith({bool? dark}) => RdColors(dark ?? this.dark);
  @override
  RdColors lerp(covariant RdColors? other, double t) => t < .5 ? this : other ?? this;
}

extension RedesignTheme on BuildContext {
  RdColors get rd => Theme.of(this).extension<RdColors>() ?? RdColors(Theme.of(this).brightness == Brightness.dark);
}

abstract final class RdTokens {
  static const gutter = 16.0, cardPadding = 14.0, cardRadius = 18.0, fieldRadius = 14.0;
  static const buttonHeight = 48.0, fieldHeight = 52.0, hitTarget = 44.0;
  static const sheetMotion = Duration(milliseconds: 200);
  static const undoWindow = Duration(seconds: 5);
  // Use Inter for Latin and IBM Plex Sans Arabic for Arabic glyphs.
  static const family = 'Inter';
  static const fallbacks = ['IBMPlexSansArabic', 'Noto Color Emoji'];
  static TextStyle style(
    BuildContext c, {
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.6,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallbacks,
    fontSize: size,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: weight,
    height: height,
    color: color ?? c.rd.text,
  );
}
