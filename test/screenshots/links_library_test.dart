@Tags(['screenshots'])
library;

import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/links_library_fixture.dart';
import '../support/selection_fixture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      fikraTest(
        'links library (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        tags: 'screenshots',
        (tester, db) async {
          phone(tester);
          final l10n = lookupAppLocalizations(locale);
          final notes = await seedLibrary(tester, db, l10n: l10n, localizedContent: true);
          final prefix = '${locale.languageCode}/${brightness.name}';
          await saveScreenshot(tester, '$prefix/70_links_browse');
          await tester.tap(find.byKey(const ValueKey('group-filter-parent')));
          await tester.pumpAndSettle();
          await saveScreenshot(tester, '$prefix/71_links_filtered');
          await tester.tap(find.byKey(const ValueKey('group-filter-parent')));
          await tester.pumpAndSettle();
          await librarySegment(tester, 1);
          await saveScreenshot(tester, '$prefix/72_links_suggestions');
          await librarySegment(tester, 0);
          await openNoteConnections(tester, notes, 5);
          await saveScreenshot(tester, '$prefix/73_note_connections');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('links-open-graph')));
          await pumpUntil(tester, find.byType(InteractiveViewer));
          await saveScreenshot(tester, '$prefix/74_links_graph_option');
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await pumpFuture(
            tester,
            () => (db.delete(db.noteLinks)..where((l) => l.origin.equalsValue(LinkOrigin.ai))).go(),
          );
          await librarySegment(tester, 1);
          await pumpUntil(tester, find.text(l10n.linksSuggestionsEmpty));
          await saveScreenshot(tester, '$prefix/75_links_suggestions_empty');
        },
      );
    }
  }
}
