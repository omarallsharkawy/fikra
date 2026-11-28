import 'package:fikra/app/tab_bar/product_navigation.dart';
import 'package:fikra/core/theme/product_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pearl_contrast_test.dart' show contrast;
import '../support/app_harness.dart' show loadAppFonts;

void main() {
  setUpAll(loadAppFonts);
  test('saved content uses its writing direction independently of UI language', () {
    expect(productContentDirection('An English note.'), TextDirection.ltr);
    expect(productContentDirection('هذه ملاحظة عربية.'), TextDirection.rtl);
  });
  for (final brightness in Brightness.values) {
    test('reference $brightness reading and colored surfaces meet AA', () {
      final c = buildProductTheme(brightness).extension<FikraPalette>()!;
      for (final pair in [
        (c.textPrimary, c.canvas),
        (c.textPrimary, c.surface),
        (c.textSecondary, c.canvas),
        (c.textSecondary, c.surface),
        (c.onBrandBlue, c.brandBlue),
        (c.onBrandPurple, c.brandPurple),
        (c.onBrandLime, c.brandLime),
        (c.onBrandSlate, c.brandSlate),
        (c.accent, c.surface),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    });
  }
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('central capture, selection and large-text navigation (${locale.languageCode})', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final calls = <(int, bool)>[];
      Widget host({bool hidden = false}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildProductTheme(Brightness.dark),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ProductNavigation(branch: 1, hidden: hidden, onSelect: (b, r) => calls.add((b, r))),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final add = tester.getCenter(find.byKey(const ValueKey('nav-add')));
      expect(add.dx, closeTo(180, .5));
      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.tap(find.byKey(const ValueKey('nav-add')));
      expect(calls, [(1, true), (2, false), (0, false)]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(hidden: true));
      expect(find.byKey(const ValueKey('nav-add')), findsNothing);
      expect(find.byKey(const ValueKey('nav-0')), findsNothing);
    });
  }
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('editing direction follows live content and explicit direction stays fixed ($locale)', (tester) async {
      Widget host({TextDirection? direction}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildProductTheme(Brightness.dark),
        home: Scaffold(
          body: ProductTextInput(value: '', onChanged: (_) {}, label: 'Content', textDirection: direction),
        ),
      );
      await tester.pumpWidget(host());
      await tester.enterText(find.byType(TextField), 'فكرة عربية');
      await tester.pump();
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.rtl);
      expect(field.controller!.selection.baseOffset, 'فكرة عربية'.length);
      await tester.enterText(find.byType(TextField), 'English thought');
      await tester.pump();
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);
      expect(field.controller!.text, 'English thought');
      await tester.pumpWidget(host(direction: TextDirection.ltr));
      await tester.enterText(find.byType(TextField), 'نص');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).textDirection, TextDirection.ltr);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('password visibility preserves entered value and controller updates', (tester) async {
    var password = 'fixture-only';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: buildProductTheme(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) => ProductTextInput(
              value: password,
              label: 'Password',
              obscure: true,
              onChanged: (value) => update(() => password = value),
            ),
          ),
        ),
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    await tester.enterText(find.byType(TextField), 'fixture-updated');
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(password, 'fixture-updated');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, password);
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
  });
}
