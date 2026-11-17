import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/connections/note_connections_screen.dart';
import 'package:fikra/features/connections/suggestion_card.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/links_library_fixture.dart';
import 'support/selection_fixture.dart';

Finder get connectionsScroll => find.descendant(
  of: find.byType(NoteConnectionsScreen),
  matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
);

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest(
      'connections, options, picker, full note, branch back and graph (${locale.languageCode})',
      locale: locale,
      (tester, db) async {
        phone(tester);
        final l10n = locale.languageCode == 'ar' ? arL10n : enL10n;
        final notes = await seedLibrary(tester, db, l10n: l10n);
        await openNoteConnections(tester, notes, 5);
        expect(find.text(l10n.linksConfirmed), findsOneWidget);
        expect(find.byKey(ValueKey('connection-${notes[4].id}')), findsOneWidget);
        expect(find.byType(SuggestionCard), findsOneWidget);
        expect(find.byKey(const ValueKey('floating-tab-bar')), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('connection-options-${notes[4].id}')));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text(l10n.editLinkReason), findsOneWidget);
        expect(find.text(l10n.removeLink), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.longPress(find.byKey(ValueKey('connection-${notes[4].id}')));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text(l10n.editLinkReason), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('connections-link-picker')));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('link-search')), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('connections-note')));
        await tester.pumpAndSettle();
        expect(find.byType(NoteDetailsScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('connection-${notes[4].id}')));
        await tester.pumpAndSettle();
        expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[4].id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[5].id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('links-open-graph')));
        await tester.pumpAndSettle();
        expect(find.byType(LinksScreen), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('links-segment-0')), findsOneWidget);
      },
    );
  }

  for (final move in [false, true]) {
    fikraTest('connections pops when its note is ${move ? 'moved' : 'deleted'}', (tester, db) async {
      phone(tester);
      final notes = await seedLibrary(tester, db);
      await openNoteConnections(tester, notes, 5);
      await pumpFuture(tester, () async {
        if (move) {
          final other = (await db.select(db.projects).get()).singleWhere((p) => p.id != notes[5].projectId);
          await LocalNotesRepository(db).moveNotes([notes[5].id], other.id);
        } else {
          await LocalNotesRepository(db).delete(notes[5].id);
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(NoteConnectionsScreen), findsNothing);
      expect(find.byKey(const ValueKey('links-segment-0')), findsOneWidget);
    });
  }

  fikraTest('invalid background connections cannot pop a newer full note route', (tester, db) async {
    phone(tester);
    final notes = await seedLibrary(tester, db);
    await openNoteConnections(tester, notes, 5);
    final context = tester.element(find.byType(NoteConnectionsScreen));
    context.push('/note/${notes[4].id}', extra: notes[4]);
    await tester.pumpAndSettle();
    await pumpFuture(tester, () => LocalNotesRepository(db).delete(notes[5].id));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(NoteConnectionsScreen), findsNothing);
  });

  fikraTest('a suggestion row for the page\'s own note does not push the same page again', (tester, db) async {
    phone(tester);
    final notes = await seedLibrary(tester, db);
    await openNoteConnections(tester, notes, 5);
    final card = tester.widget<SuggestionCard>(find.byType(SuggestionCard));
    final self = find.byKey(ValueKey('suggestion-note-${card.entry.link.id}-${notes[5].id}'));
    await tester.scrollUntilVisible(self, 200, scrollable: connectionsScroll);
    await tester.pumpAndSettle();
    await tester.tap(self);
    await tester.pumpAndSettle();
    expect(find.byType(NoteConnectionsScreen, skipOffstage: false), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('suggestion-note-${card.entry.link.id}-${notes[2].id}')));
    await tester.pumpAndSettle();
    expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[2].id);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[5].id);
  });
}
