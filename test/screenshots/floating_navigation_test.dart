// flutter test test/screenshots/floating_navigation_test.dart --run-skipped -t screenshots
@Tags(['screenshots'])
library;

import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/selection_fixture.dart';
import 'graph_navigation_test.dart' show saveWithKeyboard;

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      fikraTest(
        'floating navigation ${locale.languageCode} ${brightness.name}',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        tags: 'screenshots',
        (tester, db) async {
          phone(tester);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          final l10n = lookupAppLocalizations(locale);
          final (_, _, notes) = await seedNotes(
            tester,
            db,
            List.generate(35, (i) => locale.languageCode == 'ar' ? 'فكرة رقم ${i + 1}' : 'Idea ${i + 1}'),
            l10n: l10n,
          );
          Future<void> capture(String name) =>
              saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/floating_$name');
          await capture('home');
          final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
          addTearDown(pointer.removePointer);
          await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)));
          await tester.pump();
          // No release: the lens remains frozen over Links during capture's pump.
          await capture('mid_slide_links');
          await pointer.up();
          await tester.pumpAndSettle();
          await tester.tap(Tabs.addButton);
          await tester.pumpAndSettle();
          await capture('add_selected');
          final title = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField)).at(0);
          await tester.tap(title);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
          await tester.pumpAndSettle();
          await saveWithKeyboard(
            tester,
            '${locale.languageCode}/${brightness.name}/floating_keyboard',
            inset: 300,
            dark: brightness == Brightness.dark,
          );
          tester.view.viewInsets = const FakeViewPadding();
          tester.testTextInput.hide();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.tap(Tabs.finder(Tabs.notes));
          await tester.pumpAndSettle();
          final scrollable = find.descendant(
            of: find.byType(NotesScreen),
            matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
          );
          await tester.scrollUntilVisible(find.byKey(ValueKey(notes[0].id)), 500, scrollable: scrollable);
          final position = tester.state<ScrollableState>(scrollable).position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          await capture('notes_bottom');
        },
      );
    }
  }
}
