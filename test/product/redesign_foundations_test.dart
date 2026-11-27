import 'dart:io';

import 'package:fikra/core/theme/product_theme.dart';
import 'package:fikra/core/theme/redesign_tokens.dart';
import 'package:fikra/core/widgets/redesign_widgets.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;

void main() {
  setUpAll(loadAppFonts);
  test('semantic theme backgrounds follow the unmodified HTML in both modes', () {
    final html = File('design/fikrah-ui.html').readAsStringSync();
    for (final (dark, bg, surface, text) in [
      (false, 'f6f6f9', 'ffffff', '14151a'),
      (true, '0f1015', '1a1b22', 'f2f2f6'),
    ]) {
      final c = RdColors(dark);
      for (final value in [bg, surface == 'ffffff' ? 'fff' : surface, text]) {
        expect(html, contains('#$value'));
      }
      expect(c.bg, Color(int.parse('ff$bg', radix: 16)));
      expect(c.surface, Color(int.parse('ff$surface', radix: 16)));
      expect(c.text, Color(int.parse('ff$text', radix: 16)));
    }
  });
  test('content follows its first strong direction and interpolated names are isolated', () {
    expect(rdDirection('مرحبا Inter'), TextDirection.rtl);
    expect(rdDirection('Inter مرحبا'), TextDirection.ltr);
    expect(rdDirection('', TextDirection.rtl), TextDirection.rtl);
    expect(rdIsolate('علاء'), '\u2068علاء\u2069');
  });
  for (final language in ['ar', 'en']) {
    testWidgets('shared controls remain reachable at 2x text ($language)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildProductTheme(Brightness.light),
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Column(
                  children: [
                    RdButton(c.l10n.rdSave, onPressed: () => presses++),
                    RdButton(c.l10n.rdSave, key: const ValueKey('disabled')),
                    RdChip(c.l10n.rdAll, onPressed: () => presses++),
                    RdIconButton('plus', label: c.l10n.rdAddt, onPressed: () => presses++),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final finder in [find.byType(RdButton).first, find.byType(RdChip), find.byType(RdIconButton)]) {
        final size = tester.getSize(finder);
        expect(size.height, greaterThanOrEqualTo(44));
        await tester.tap(finder);
      }
      await tester.tap(find.byKey(const ValueKey('disabled')));
      expect(presses, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
