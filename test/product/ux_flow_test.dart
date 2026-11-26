import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('capture saves without scrolling while keyboard is open (${locale.languageCode}, $scale)', (
        tester,
      ) async {
        final r = await boot(tester, locale: locale, scale: scale, size: const Size(360, 800));
        await r.session.login('other@example.invalid', 'fixture-only');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
        final field = find.descendant(
          of: find.byKey(ValueKey('capture-content-${r.workspace.selectedProjectId}')),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, 'A thought with the keyboard open');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final save = find.byKey(const ValueKey('save-product-note'));
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(500));
        expect(tester.getRect(save).top, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(r.workspace.notes.single.content, 'A thought with the keyboard open');
        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        await cleanup(tester);
      });
    }
  }
  testWidgets('preview explanations stay available behind the compact information action', (tester) async {
    await boot(tester);
    await tapVisible(tester, find.byKey(const ValueKey('development-banner')));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Preview information'), findsOneWidget);
    expect(find.textContaining('no live backend'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
}
