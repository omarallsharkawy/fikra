import 'package:flutter/material.dart';

/// Design tokens mirrored from the Figma variables (FIKRA Color / FIKRA Layout).
/// Dark only, like the design. Names follow the Figma variable names.
abstract final class FikraColors {
  static const canvas = Color(0xFF111111); // bg/canvas
  static const screen = Color(0xFF151515); // bg/screen
  static const glass = Color(0xFF232323); // surface/glass
  static const glassHighlight = Color(0xFF2D2D2D); // surface/glass-highlight
  static const pressed = Color(0x0FFFFFFF); // surface/pressed
  static const scrim = Color(0x99000000); // surface/scrim (60%)

  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xB3FFFFFF); // 70%
  static const textBodyMuted = Color(0xC2FFFFFF); // 76%
  static const textPlaceholder = Color(0xA3FFFFFF); // 64%
  static const textMeta = Color(0x80FFFFFF); // 50%
  static const textOnLight = Color(0xFF151515);
  static const textLink = Color(0xFF78C7FF);

  static const border = Color(0x24FFFFFF); // 14%
  static const borderGraph = Color(0x3AFFFFFF); // 23%
  static const borderFocus = Color(0xFF49AAFF);

  static const accent = Color(0xFF0088FF);
  static const accentLight = Color(0xFF49AAFF);
  static const selectedStart = Color(0xFF167FC8);
  static const selectedEnd = Color(0xFF00569A);
  static const graphEdge = Color(0xFF2E9CDF);

  static const danger = Color(0xFFFF6B6B);
  static const dangerBg = Color(0x29FF6B6B);
  static const success = Color(0xFF3DD68C);
  static const successBg = Color(0x293DD68C);
  static const warning = Color(0xFFFFB547);

  static const screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1D1D1D), Color(0xFF151515), Color(0xFF1B1B1B)],
    stops: [0, 0.5, 1],
  );
  static const glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF232323), Color(0xFF292929)],
    stops: [0, 0.6, 1],
  );
  static const selectedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [selectedStart, selectedEnd],
  );
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAFAFA), Color(0xFFE8E8E8)],
  );
  static const sendGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accentLight, accent],
  );
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
abstract final class FikraText {
  static const family = 'NotoSansArabic';
  static const _base = TextStyle(
    fontFamily: family,
    height: 1.5,
    color: FikraColors.textPrimary,
    fontWeight: FontWeight.w400,
  );

  static final title = _base.copyWith(fontSize: 26);
  static final cardTitle = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700);
  static final cardTitleSmall = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w700);
  static final section = _base.copyWith(fontSize: 17);
  static final bodyLarge = _base.copyWith(fontSize: 18);
  static final answer = _base.copyWith(fontSize: 17);
  static final body = _base.copyWith(fontSize: 16);
  static final field = _base.copyWith(fontSize: 15);
  static final caption = _base.copyWith(fontSize: 12.5, color: FikraColors.textBodyMuted);
  static final nav = _base.copyWith(fontSize: 13);
  static final button = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700);
  static final chip = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500);
  static final meta = _base.copyWith(fontSize: 11, color: FikraColors.textMeta);
}
