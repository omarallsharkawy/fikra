import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

Size measure(String text, TextStyle style, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  test('Arabic glyphs keep the existing Noto shaping at every bundled Arabic weight', () {
    for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
      final style = FikraText(FikraPalette.light).body.copyWith(fontWeight: weight);
      for (final text in ['ملاحظاتي', 'وأفكاري', 'العربية']) {
        final fallback = measure(text, style, TextDirection.rtl);
        final original = measure(text, style.copyWith(fontFamily: 'NotoSansArabic'), TextDirection.rtl);
        // Spaces/punctuation and line height may use Inter metrics; the joined
        // Arabic glyphs must retain Noto's original shaping advances.
        expect(fallback.width, closeTo(original.width, 0.01));
        expect(fallback.width, greaterThan(20));
      }
    }
  });

  test('English uses bundled Inter metrics in both Material themes', () {
    for (final brightness in Brightness.values) {
      final style = buildFikraTheme(brightness).textTheme.bodyMedium!.copyWith(fontSize: 24);
      const text = 'FIKRAH — Capture your ideas';
      final actual = measure(text, style, TextDirection.ltr);
      final inter = measure(text, style.copyWith(fontFamily: 'Inter'), TextDirection.ltr);
      final roboto = measure(text, style.copyWith(fontFamily: 'Roboto'), TextDirection.ltr);
      expect(actual, inter);
      expect((actual.width - roboto.width).abs(), greaterThan(1));
    }
  });
}
