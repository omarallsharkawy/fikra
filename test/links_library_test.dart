import "dart:async";
import "dart:ui" show Tristate;

import 'package:fikra/core/format.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/library_cards.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/features/connections/suggestion_card.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/links_library_fixture.dart';
import 'support/selection_fixture.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);
    fikraTest('Browse chips, search both lists, sort, count and semantics (${locale.languageCode})', locale: locale, (
      tester,
      db,
    ) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      try {
        final notes = await seedLibrary(tester, db, l10n: l10n);
        expect(find.byType(LinksLibraryScreen), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(LinksLibraryScreen))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        final browse = tester.getSemantics(find.byKey(const ValueKey('links-segment-1')));
        expect(browse.flagsCollection.isButton, isTrue);
        expect(browse.flagsCollection.isSelected, Tristate.isTrue);
        expect(
          tester.getSemantics(find.byKey(const ValueKey('links-segment-2'))).label,
          l10n.linksSuggestionsCountA11y(3),
        );
        expect(find.text(l10n.linksSuggestionsCount(3)), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('group-filter-parent')));
        await tester.pumpAndSettle();
        expect(find.byType(BrowseNoteCard), findsNWidgets(2));
        expect(find.byKey(const ValueKey('group-filter-child')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('group-filter-child')));
        await tester.pumpAndSettle();
        expect(find.byType(BrowseNoteCard), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('group-filter-child')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('browse-${notes[5].id}')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('topic-filter-Ideas')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('browse-${notes[1].id}')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('topic-filter-Ideas')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('links-search')), 'NOTE 5');
        await tester.pump();
        // Debounced like Notes: nothing filters before 180 ms.
        expect(find.byKey(ValueKey('browse-${notes[4].id}')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.byType(BrowseNoteCard), findsOneWidget);
        await librarySegment(tester, 1);
        expect(find.byType(SuggestionCard), findsOneWidget);
        final pair = pairKey(notes[2].id, notes[5].id);
        expect(
          find.bySemanticsLabel(l10n.acceptLinkA11y('${Fmt.isolate('Note 2')} · ${Fmt.isolate('Note 5')}')),
          findsOneWidget,
        );
        expect(find.byKey(ValueKey('reject-$pair')), findsOneWidget);
        await tester.enterText(find.byKey(const ValueKey('links-search')), 'missing');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.text(l10n.noResultsTitle), findsOneWidget);
        expect(find.text(l10n.noResultsBody('missing')), findsOneWidget);
        await tester.enterText(find.byKey(const ValueKey('links-search')), '');
        await librarySegment(tester, 0);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('links-sort')));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('links-sort-oldest')));
        await tester.pumpAndSettle();
        final cards = tester.widgetList<BrowseNoteCard>(find.byType(BrowseNoteCard)).toList();
        expect(cards[0].entry.note.id, notes[0].id);
        await tester.tap(find.byKey(const ValueKey('links-sort')));
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('links-sort-mostLinks')));
        await tester.pumpAndSettle();
        expect(tester.widgetList<BrowseNoteCard>(find.byType(BrowseNoteCard)).elementAt(0).entry.note.id, notes[4].id);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final fail in [false, true]) {
    late LibrarySpy spy;
    fikraTest(
      'pair actions guard double taps and ${fail ? 'keep failures' : 'remove successes'}',
      linksRepository: (db) => spy = LibrarySpy(db),
      (tester, db) async {
        phone(tester);
        final notes = await seedLibrary(tester, db);
        await librarySegment(tester, 1);
        for (final accept in [true, false]) {
          final gate = spy.gate = Completer<void>();
          addTearDown(() {
            if (!gate.isCompleted) gate.complete();
          });
          spy.fail = fail;
          final pair = pairKey(notes[0].id, notes[3].id);
          final second = pairKey(notes[1].id, notes[4].id);
          final target = find.byKey(ValueKey('${accept ? 'accept' : 'reject'}-${accept || fail ? pair : second}'));
          await tester.scrollUntilVisible(target, 200, scrollable: libraryScroll);
          await Scrollable.ensureVisible(tester.element(target), alignment: .5);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.tap(target);
          expect(accept ? spy.accepts : spy.rejects, 1);
          gate.complete();
          await pumpFuture(tester, () => spy.pending!);
          await tester.pumpAndSettle();
          if (fail) {
            expect(target, findsOneWidget);
            expect(find.text(arL10n.linkUpdateFailed), findsOneWidget);
          } else {
            expect(target, findsNothing);
            expect(find.text('${arL10n.linksSuggestions} ${accept ? 2 : 1}'), findsOneWidget);
          }
        }
      },
    );
  }

  fikraTest('segments and both scroll offsets survive tab switches; last row clears floating controls', (
    tester,
    db,
  ) async {
    phone(tester);
    final semantics = tester.ensureSemantics();
    try {
      final notes = await seedLibrary(tester, db, count: 45);
      final tail = find.byKey(ValueKey('browse-${notes[0].id}'));
      await tester.scrollUntilVisible(tail, 500, scrollable: libraryScroll);
      final browse = tester.state<ScrollableState>(libraryScroll).position;
      browse.jumpTo(browse.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(tail).dy, lessThan(tester.getTopLeft(Tabs.addButton).dy));
      final offset = browse.pixels;
      await librarySegment(tester, 1);
      final suggestions = tester.state<ScrollableState>(libraryScroll).position;
      suggestions.jumpTo(suggestions.maxScrollExtent);
      await tester.pumpAndSettle();
      final suggestionOffset = suggestions.pixels;
      await tester.tap(Tabs.finder(Tabs.notes));
      await tester.pumpAndSettle();
      await tester.tap(Tabs.finder(Tabs.links));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(const ValueKey('links-segment-2'))).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(suggestions.pixels, suggestionOffset);
      await librarySegment(tester, 0);
      expect(browse.pixels, offset);
    } finally {
      semantics.dispose();
    }
  });
  late LibrarySpy sharedSpy;
  fikraTest(
    'a pending pair stays locked on a second connections presentation',
    linksRepository: (db) => sharedSpy = LibrarySpy(db),
    (tester, db) async {
      phone(tester);
      final notes = await seedLibrary(tester, db);
      await librarySegment(tester, 1);
      final pair = pairKey(notes[0].id, notes[3].id);
      final accept = find.byKey(ValueKey('accept-$pair'));
      await tester.scrollUntilVisible(accept, 200, scrollable: libraryScroll);
      await Scrollable.ensureVisible(tester.element(accept), alignment: .5);
      await tester.pumpAndSettle();
      final gate = sharedSpy.gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.tap(accept);
      await tester.pump();
      final presentation = tester.widget<SuggestionCard>(
        find.byWidgetPredicate((w) => w is SuggestionCard && pairKey(w.entry.a.id, w.entry.b.id) == pair),
      );
      await tester.tap(find.byKey(ValueKey('suggestion-note-${presentation.entry.link.id}-${notes[0].id}')));
      await tester.pumpAndSettle();
      final second = tester.widget<TextButton>(find.byKey(ValueKey('accept-$pair')));
      expect(second.onPressed, isNull);
      expect(sharedSpy.accepts, 1);
      gate.complete();
      await pumpFuture(tester, () => sharedSpy.pending!);
      await tester.pumpAndSettle();
    },
  );

  fikraTest('chip-only empty state, live group chip, sort semantics, Map segment label and no zero count', (
    tester,
    db,
  ) async {
    phone(tester);
    final semantics = tester.ensureSemantics();
    try {
      final notes = await seedLibrary(tester, db);
      final map = tester.getSemantics(find.byKey(const ValueKey('links-segment-0')));
      expect(map.label, arL10n.linksMap);
      await pumpFuture(
        tester,
        () => db
            .into(db.noteGroups)
            .insert(
              NoteGroup(
                id: 'empty',
                projectId: notes[0].projectId,
                name: 'Empty',
                position: 2,
                createdAt: DateTime(2026),
              ),
            ),
      );
      await pumpUntil(tester, find.byKey(const ValueKey('group-filter-empty')));
      await tester.tap(find.byKey(const ValueKey('group-filter-empty')));
      await tester.pumpAndSettle();
      for (final segment in [0, 1]) {
        await librarySegment(tester, segment);
        expect(find.text(arL10n.noResultsTitle), findsOneWidget);
        expect(find.text(arL10n.linksFilterEmptyBody), findsOneWidget);
        expect(find.text(arL10n.noResultsBody('')), findsNothing);
      }
      await librarySegment(tester, 0);
      // Deleting the selected group clears the chip from the live groups list.
      await pumpFuture(tester, () => (db.delete(db.noteGroups)..where((g) => g.id.equals('empty'))).go());
      await tester.pumpAndSettle();
      expect(find.text(arL10n.linksFilterEmptyBody), findsNothing);
      expect(find.byKey(ValueKey('browse-${notes[5].id}')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('links-sort')));
      await tester.pump();
      await tester.pumpAndSettle();
      for (final order in LinksSort.values) {
        expect(
          tester
              .getSemantics(
                find.descendant(of: find.byKey(ValueKey('links-sort-${order.name}')), matching: find.byType(Pressable)),
              )
              .flagsCollection
              .isSelected,
          order == LinksSort.newest ? Tristate.isTrue : Tristate.isFalse,
        );
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await pumpFuture(tester, () => (db.delete(db.noteLinks)..where((l) => l.origin.equalsValue(LinkOrigin.ai))).go());
      await tester.pumpAndSettle();
      expect(find.text(arL10n.linksSuggestions), findsOneWidget);
      expect(tester.getSemantics(find.byKey(const ValueKey('links-segment-2'))).label, arL10n.linksSuggestions);
    } finally {
      semantics.dispose();
    }
  });

  for (final accept in [true, false]) {
    late LibrarySpy undoSpy;
    fikraTest(
      '${accept ? 'accept' : 'reject'} shows Undo; Undo brings the suggestion back enabled',
      linksRepository: (db) => undoSpy = LibrarySpy(db),
      (tester, db) async {
        phone(tester);
        final notes = await seedLibrary(tester, db);
        await librarySegment(tester, 1);
        final pair = pairKey(notes[0].id, notes[3].id);
        final button = find.byKey(ValueKey('${accept ? 'accept' : 'reject'}-$pair'));
        await tester.scrollUntilVisible(button, 200, scrollable: libraryScroll);
        await Scrollable.ensureVisible(tester.element(button), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(button, findsNothing);
        expect(find.text(accept ? arL10n.linksAdded(1) : arL10n.linkSuggestionRejected), findsOneWidget);
        await tester.tap(find.text(arL10n.undo));
        await pumpFuture(tester, () => undoSpy.pending!);
        await tester.pumpAndSettle();
        expect(undoSpy.undos, 1);
        await tester.scrollUntilVisible(button, 200, scrollable: libraryScroll);
        await tester.pumpAndSettle();
        expect(tester.widget<TextButton>(button).onPressed, isNotNull);
        expect(find.text('${arL10n.linksSuggestions} 3'), findsOneWidget);
      },
    );
  }

  late LibrarySpy blockSpy;
  fikraTest(
    'a second accept/reject while an Undo runs does nothing',
    linksRepository: (db) => blockSpy = LibrarySpy(db),
    (tester, db) async {
      phone(tester);
      final notes = await seedLibrary(tester, db);
      await librarySegment(tester, 1);
      final first = find.byKey(ValueKey('accept-${pairKey(notes[0].id, notes[3].id)}'));
      final second = find.byKey(ValueKey('reject-${pairKey(notes[1].id, notes[4].id)}'));
      await tester.scrollUntilVisible(first, 200, scrollable: libraryScroll);
      await Scrollable.ensureVisible(tester.element(first), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(first);
      await tester.pumpAndSettle();
      final gate = blockSpy.undoGate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.tap(find.text(arL10n.undo));
      await tester.pump();
      await tester.scrollUntilVisible(second, 200, scrollable: libraryScroll);
      await tester.pumpAndSettle();
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(blockSpy.rejects, 0);
      // Not left locked: the row stays and works once the Undo is done.
      expect(tester.widget<TextButton>(second).onPressed, isNotNull);
      gate.complete();
      await pumpFuture(tester, () => blockSpy.pending!);
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      await tester.tap(second);
      await pumpFuture(tester, () => blockSpy.pending!);
      await tester.pumpAndSettle();
      expect(blockSpy.rejects, 1);
      expect(second, findsNothing);
    },
  );
}
