import 'dart:async';

import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/shared/link_picker.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
  }

  /// A project with [titles] as ready notes, oldest first (so the list shows
  /// them newest first). Returns the notes in the given order.
  Future<List<Note>> seed(
    WidgetTester tester,
    FikraDatabase db,
    List<String> titles, {
    List<String>? texts,
    AppLocalizations? l10n,
  }) async {
    await pumpUntil(tester, find.text((l10n ?? ar).welcomeStartWriting));
    final notes = await pumpFuture(tester, () async {
      final repo = LocalNotesRepository(db);
      final p = await LocalProjectsRepository(db).create('project');
      return [
        for (final (i, t) in titles.indexed)
          await repo.create(
            projectId: p.id,
            title: t,
            text: texts?[i] ?? 'text of $t',
            source: NoteSource.text,
            createdAt: DateTime(2026, 11, 1 + i),
          ),
      ];
    });
    for (final n in notes) {
      await pumpFuture(tester, () => LocalNotesRepository(db).markReady(n.id));
    }
    await pumpUntil(tester, find.text(titles.last));
    return notes;
  }

  Future<void> open(WidgetTester tester, Note note) async {
    tester.element(find.byType(Scaffold).last).push('/note/${note.id}');
    // The section has loaded and its switch-in has finished.
    await pumpUntil(
      tester,
      find.byWidgetPredicate((w) => w.key == const ValueKey('links-list') || w.key == const ValueKey('links-empty')),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tapKey(tester, 'link-to-note');
    await pumpUntil(tester, find.byKey(const ValueKey('link-confirm')));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Waits for [finder], then lets the sheet or dialog finish opening.
  Future<void> settle(WidgetTester tester, Finder finder) async {
    await pumpUntil(tester, finder);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder field(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));
  Future<List<NoteLink>> rows(WidgetTester tester, FikraDatabase db) =>
      pumpFuture(tester, () => db.select(db.noteLinks).get());
  Future<void> suggest(WidgetTester tester, FikraDatabase db, Note from, List<Note> to, {String label = 'AI reason'}) =>
      pumpFuture(
        tester,
        () => LocalNotesRepository(db).applyInsights(
          from.id,
          NoteInsights(
            title: from.title,
            concepts: const [],
            cluster: 'k',
            links: [for (final n in to) ProposedLink(targetId: n.id, label: label, strength: 0.5)],
          ),
        ),
      );
  Future<void> insert(
    WidgetTester tester,
    FikraDatabase db,
    String id,
    Note a,
    Note b,
    LinkOrigin origin,
    String label,
  ) => pumpFuture(
    tester,
    () => db
        .into(db.noteLinks)
        .insert(
          NoteLink(
            id: id,
            projectId: a.projectId,
            sourceId: a.id,
            targetId: b.id,
            label: label,
            strength: 0.4,
            origin: origin,
            dismissed: false,
          ),
        ),
  );

  fikraTest('links three notes at once with a reason, shows the rows and the count', (tester, db) async {
    phone(tester);
    final [a, b, c, d, e] = await seed(tester, db, ['A', 'B', 'C', 'D', 'E']);
    await open(tester, a);
    expect(find.text(ar.noteLinksEmpty), findsOneWidget);
    await openPicker(tester);
    // Newest first, and the open note itself isn't offered.
    expect(find.byKey(ValueKey('link-pick-${a.id}')), findsNothing);
    final ys = [e, d, c, b].map((n) => tester.getTopLeft(find.byKey(ValueKey('link-pick-${n.id}'))).dy).toList();
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text(ar.linkSelected(0)), findsOneWidget);
    for (final n in [b, c, d]) {
      await tapKey(tester, 'link-pick-${n.id}');
    }
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
    await tester.enterText(field('link-reason'), 'same lecture');
    await tester.pump();
    expect(find.text('12/80'), findsOneWidget);
    expect(find.text(ar.linkSelected(3)), findsOneWidget);
    await tapKey(tester, 'link-confirm');
    await pumpUntil(tester, find.text(ar.notesLinked(3)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('link-confirm')), findsNothing);

    final links = await rows(tester, db);
    expect(links, hasLength(3));
    expect(links.every((l) => l.origin == LinkOrigin.user && l.sourceId == a.id && l.label == 'same lecture'), isTrue);
    expect(links.map((l) => l.targetId).toSet(), {b.id, c.id, d.id});
    for (final n in [b, c, d]) {
      expect(find.byKey(ValueKey('link-options-${n.id}')), findsOneWidget);
    }
    expect(find.byKey(ValueKey('note-link-${e.id}')), findsNothing);
    expect(find.text('same lecture'), findsNWidgets(3));
    expect(find.text(ar.noteLinksEmpty), findsNothing);
  });

  fikraTest('search filters; your links cannot be picked; a suggestion can and becomes yours', (tester, db) async {
    phone(tester);
    final handle = tester.ensureSemantics();
    final [a, b, c, d] = await seed(
      tester,
      db,
      ['A', 'Linked', 'Suggested note', 'Networks'],
      texts: ['x', 'y', 'z', 'TCP and UDP'],
    );
    await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id]));
    await suggest(tester, db, a, [c]);
    await open(tester, a);
    expect(find.byKey(ValueKey('link-accept-${c.id}')), findsOneWidget);
    await openPicker(tester);

    final linkedRow = find.byKey(ValueKey('link-pick-${b.id}'));
    expect(find.descendant(of: linkedRow, matching: find.text(ar.alreadyLinked)), findsOneWidget);
    await tester.tap(linkedRow);
    await tester.pump();
    expect(find.text(ar.linkSelected(0)), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(ValueKey('link-pick-${c.id}')), matching: find.text(ar.linkSuggestedTag)),
      findsOneWidget,
    );

    // By body text, case-insensitively, as the user types.
    await tester.enterText(field('link-search'), 'udp');
    await tester.pump();
    expect(find.byKey(ValueKey('link-pick-${d.id}')), findsOneWidget);
    expect(find.byKey(ValueKey('link-pick-${b.id}')), findsNothing);
    expect(find.byKey(ValueKey('link-pick-${c.id}')), findsNothing);
    // By title.
    await tester.enterText(field('link-search'), 'sugg');
    await tester.pump();
    expect(find.byKey(ValueKey('link-pick-${c.id}')), findsOneWidget);
    expect(find.byKey(ValueKey('link-pick-${d.id}')), findsNothing);
    await tapKey(tester, 'link-pick-${c.id}');
    expect(
      tester.getSemantics(
        find.descendant(of: find.byKey(ValueKey('link-pick-${c.id}')), matching: find.byType(Pressable)),
      ),
      isSemantics(hasCheckedState: true, isChecked: true, label: ar.linkRowA11y(c.title, ar.linkSuggestedTag)),
    );
    await tester.enterText(field('link-search'), 'nothing like this');
    await tester.pump();
    expect(find.text(ar.noResultsTitle), findsOneWidget);
    // Picks survive filtering.
    expect(find.text(ar.linkSelected(1)), findsOneWidget);
    await tapKey(tester, 'link-confirm');
    await pumpUntil(tester, find.text(ar.notesLinked(1)));

    final pair = (await rows(tester, db)).where((l) => {l.sourceId, l.targetId}.containsAll({a.id, c.id})).toList();
    expect(pair, hasLength(1));
    expect(pair.single.origin, LinkOrigin.user);
    await pumpUntil(tester, find.byKey(ValueKey('link-options-${c.id}')));
    expect(find.byKey(ValueKey('link-accept-${c.id}')), findsNothing);
    handle.dispose();
  });

  fikraTest('edit the reason, clear it, and remove only after confirming', (tester, db) async {
    phone(tester);
    final [a, b] = await seed(tester, db, ['A', 'B']);
    final id = (await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id], label: 'old'))).single;
    await open(tester, a);
    Future<String> label() async => (await rows(tester, db)).singleWhere((l) => l.id == id).label;

    await tapKey(tester, 'link-options-${b.id}');
    await settle(tester, find.text(ar.editLinkReason));
    await tester.tap(find.text(ar.editLinkReason));
    await settle(tester, find.byKey(const ValueKey('link-reason-save')));
    expect(tester.widget<TextField>(field('link-reason')).controller!.text, 'old');
    expect(find.text('3/80'), findsOneWidget);
    await tester.enterText(field('link-reason'), 'new reason');
    await tester.tap(find.byKey(const ValueKey('link-reason-save')));
    await pumpUntil(tester, find.text('new reason').hitTestable());
    expect(await label(), 'new reason');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('link-reason-save')), findsNothing);

    // An empty reason is allowed and removes it.
    await tapKey(tester, 'link-options-${b.id}');
    await settle(tester, find.text(ar.editLinkReason));
    await tester.tap(find.text(ar.editLinkReason));
    await settle(tester, find.byKey(const ValueKey('link-reason-save')));
    await tester.enterText(field('link-reason'), '');
    await tester.tap(find.byKey(const ValueKey('link-reason-save')));
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (await label() != '' && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(await label(), '');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('new reason'), findsNothing);
    expect(find.byKey(ValueKey('note-link-${b.id}')), findsOneWidget);

    // Remove: cancel keeps the link.
    await tapKey(tester, 'link-options-${b.id}');
    await settle(tester, find.text(ar.removeLink));
    await tester.tap(find.text(ar.removeLink));
    await settle(tester, find.text(ar.removeLinkTitle));
    expect(find.text(ar.removeLinkBody), findsOneWidget);
    await tester.tap(find.text(ar.cancel).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect((await rows(tester, db)).single.dismissed, isFalse);
    // Still in the options sheet: confirm this time.
    await tester.tap(find.text(ar.removeLink));
    await settle(tester, find.text(ar.removeLinkTitle));
    await tester.tap(find.text(ar.removeLinkConfirm));
    await pumpUntil(tester, find.text(ar.linkRemoved));
    final removed = (await rows(tester, db)).single;
    expect(removed.dismissed, isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(ValueKey('note-link-${b.id}')), findsNothing);
    expect(find.text(ar.noteLinksEmpty), findsOneWidget);
  });

  late _SpyLinks spy;
  fikraTest(
    'accept makes a suggestion yours; reject hides it for good; double taps run once',
    linksRepository: (db) => spy = _SpyLinks(db),
    (tester, db) async {
      phone(tester);
      final [a, b, c] = await seed(tester, db, ['A', 'B', 'C']);
      await suggest(tester, db, a, [b, c]);
      await open(tester, a);
      expect(find.text(ar.linkSuggestedTag), findsNWidgets(2));

      final accept = find.byKey(ValueKey('link-accept-${b.id}'));
      await tester.ensureVisible(accept);
      await tester.pump();
      await tester.tap(accept);
      await tester.tap(accept);
      await pumpUntil(tester, find.byKey(ValueKey('link-options-${b.id}')));
      expect(spy.calls.where((c) => c == 'acceptPair'), hasLength(1));
      final ab = (await rows(tester, db)).singleWhere((l) => l.targetId == b.id);
      expect(ab.origin, LinkOrigin.user);
      expect(find.text(ar.linkSuggestedTag), findsOneWidget);

      final reject = find.byKey(ValueKey('link-reject-${c.id}'));
      await tester.tap(reject);
      await tester.tap(reject);
      await tester.pump();
      // No confirmation for a rejection.
      expect(find.text(ar.removeLinkTitle), findsNothing);
      final end = DateTime.now().add(const Duration(seconds: 5));
      while (find.byKey(ValueKey('note-link-${c.id}')).evaluate().isNotEmpty && DateTime.now().isBefore(end)) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(ValueKey('note-link-${c.id}')), findsNothing);
      expect(spy.calls.where((c) => c == 'dismissPair'), hasLength(1));

      // A new analysis (from either note) proposing the pair again doesn't bring it back.
      await suggest(tester, db, a, [c]);
      await suggest(tester, db, c, [a]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(ValueKey('note-link-${c.id}')), findsNothing);
      expect(find.byKey(ValueKey('link-options-${b.id}')), findsOneWidget);
    },
  );

  for (final accept in [true, false]) {
    late _SpyLinks undoSpy;
    fikraTest(
      'details ${accept ? 'accept' : 'reject'} shows Undo; Undo brings the suggestion back',
      linksRepository: (db) => undoSpy = _SpyLinks(db),
      (tester, db) async {
        phone(tester);
        final [a, b] = await seed(tester, db, ['A', 'B']);
        await suggest(tester, db, a, [b]);
        await open(tester, a);
        final before = await rows(tester, db);
        await tapKey(tester, '${accept ? 'link-accept' : 'link-reject'}-${b.id}');
        final toast = find.text(accept ? ar.linksAdded(1) : ar.linkSuggestionRejected);
        await pumpUntil(tester, toast);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(ValueKey('link-accept-${b.id}')), findsNothing);
        await tester.tap(find.text(ar.undo));
        await pumpUntil(tester, find.byKey(ValueKey('link-accept-${b.id}')));
        await tester.pump(const Duration(milliseconds: 500));
        expect(undoSpy.calls.where((c) => c == 'undoPair'), hasLength(1));
        expect(await rows(tester, db), unorderedEquals(before));
        // Enabled again: a new accept goes through.
        await tapKey(tester, 'link-accept-${b.id}');
        await pumpUntil(tester, find.byKey(ValueKey('link-options-${b.id}')));
        expect(undoSpy.calls.where((c) => c == 'acceptPair'), hasLength(accept ? 2 : 1));
        await tester.pump(const Duration(seconds: 7));
      },
    );
  }

  fikraTest(
    'a user link survives editing the text and a re-analysis that proposes other links',
    aiService: _Ai((note, notes) async {
      final other = notes.firstWhere((n) => n.title == 'C');
      return NoteInsights(
        title: note.title,
        concepts: const ['topic'],
        cluster: 'k',
        links: [ProposedLink(targetId: other.id, label: 'AI reason', strength: 0.9)],
      );
    }),
    (tester, db) async {
      phone(tester);
      final [a, b, _] = await seed(tester, db, ['A', 'B', 'C']);
      await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id], label: 'mine'));
      await open(tester, a);
      final container = ProviderScope.containerOf(tester.element(find.byType(NoteDetailsScreen)));
      await pumpFuture(tester, () => LocalNotesRepository(db).edit(a.id, title: 'A', text: 'completely new text'));
      final edited = await pumpFuture(tester, () => LocalNotesRepository(db).watchNote(a.id).first);
      await pumpFuture(tester, () => container.read(noteProcessorProvider).process(edited!));
      await pumpUntil(tester, find.text('AI reason'));
      expect(find.text('mine'), findsOneWidget);
      expect(find.byKey(ValueKey('link-options-${b.id}')), findsOneWidget);
      final user = (await rows(tester, db)).where((l) => l.origin == LinkOrigin.user);
      expect(user.single.targetId, b.id);
      expect(user.single.label, 'mine');
    },
  );

  fikraTest('legacy rows for one pair show one row, preferring your link', (tester, db) async {
    phone(tester);
    final [a, b, c] = await seed(tester, db, ['A', 'B', 'C']);
    await insert(tester, db, 'ab-ai', a, b, LinkOrigin.ai, 'old suggestion');
    await insert(tester, db, 'ba-user', b, a, LinkOrigin.user, 'mine');
    await insert(tester, db, 'ac-ai', a, c, LinkOrigin.ai, 'first suggestion');
    await insert(tester, db, 'ca-ai', c, a, LinkOrigin.ai, 'second suggestion');
    await open(tester, a);
    expect(find.byKey(ValueKey('open-link-${b.id}')), findsOneWidget);
    expect(find.byKey(ValueKey('link-options-${b.id}')), findsOneWidget);
    expect(find.text('mine'), findsOneWidget);
    expect(find.text('old suggestion'), findsNothing);
    expect(find.byKey(ValueKey('open-link-${c.id}')), findsOneWidget);
    expect(find.text('first suggestion'), findsOneWidget);
    expect(find.text('second suggestion'), findsNothing);
  });

  fikraTest('a link shows on both notes, and its row opens the other note', (tester, db) async {
    phone(tester);
    final [a, b] = await seed(tester, db, ['A', 'B']);
    await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id], label: 'why'));
    await open(tester, b);
    expect(find.byKey(ValueKey('link-options-${a.id}')), findsOneWidget);
    // A second tap a frame later, while the push runs, doesn't stack another page.
    final row = tester.getCenter(find.byKey(ValueKey('open-link-${a.id}')));
    await tester.tapAt(row);
    await tester.tapAt(row);
    await pumpUntil(tester, find.byKey(ValueKey('link-options-${b.id}')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(NoteDetailsScreen, skipOffstage: false), findsNWidgets(2));
    expect(find.text('why'), findsOneWidget);
  });

  fikraTest(
    'confirm runs once on a double tap and creates no duplicates',
    linksRepository: (db) => spy = _SpyLinks(db),
    (tester, db) async {
      phone(tester);
      final [a, b] = await seed(tester, db, ['A', 'B']);
      await open(tester, a);
      await openPicker(tester);
      await tapKey(tester, 'link-pick-${b.id}');
      final confirm = find.byKey(const ValueKey('link-confirm'));
      await tester.tap(confirm);
      await tester.tap(confirm);
      await pumpUntil(tester, find.text(ar.notesLinked(1)));
      expect(spy.calls.where((c) => c == 'link'), hasLength(1));
      expect(await rows(tester, db), hasLength(1));
    },
  );

  fikraTest(
    'a failed link keeps the sheet open with the picks',
    linksRepository: (db) => spy = _SpyLinks(db, failLinking: true),
    (tester, db) async {
      phone(tester);
      final [a, b, c] = await seed(tester, db, ['A', 'B', 'C']);
      await open(tester, a);
      await openPicker(tester);
      await tapKey(tester, 'link-pick-${b.id}');
      await tapKey(tester, 'link-pick-${c.id}');
      await tester.enterText(field('link-reason'), 'kept');
      await tapKey(tester, 'link-confirm');
      await pumpUntil(tester, find.text(ar.linkFailed));
      expect(find.text(ar.linkSelected(2)), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
      expect(tester.widget<TextField>(field('link-reason')).controller!.text, 'kept');
      expect(await rows(tester, db), isEmpty);
      // Trying again works and clears the message.
      spy.failLinking = false;
      await tapKey(tester, 'link-confirm');
      await pumpUntil(tester, find.text(ar.notesLinked(2)));
      expect(await rows(tester, db), hasLength(2));
    },
  );

  fikraTest('editing a link removed meanwhile just closes, without an error', (tester, db) async {
    phone(tester);
    final [a, b] = await seed(tester, db, ['A', 'B']);
    final id = (await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id]))).single;
    await open(tester, a);
    await tapKey(tester, 'link-options-${b.id}');
    await settle(tester, find.text(ar.editLinkReason));
    await tester.tap(find.text(ar.editLinkReason));
    await settle(tester, find.byKey(const ValueKey('link-reason-save')));
    await pumpFuture(tester, () => LocalLinksRepository(db).removeLink(id));
    await tester.enterText(field('link-reason'), 'too late');
    await tester.tap(find.byKey(const ValueKey('link-reason-save')));
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (find.byKey(const ValueKey('link-reason-save')).evaluate().isNotEmpty && DateTime.now().isBefore(end)) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('link-reason-save')), findsNothing);
    expect(find.text(ar.linkUpdateFailed), findsNothing);
    expect(find.text(ar.genericError), findsNothing);
    expect(find.byKey(ValueKey('note-link-${b.id}')), findsNothing);
  });

  fikraTest('empty section and a project with no other notes', (tester, db) async {
    phone(tester);
    final [a] = await seed(tester, db, ['Alone']);
    await open(tester, a);
    expect(find.text(ar.noteLinksHeader), findsOneWidget);
    expect(find.text(ar.noteLinksEmpty), findsOneWidget);
    await openPicker(tester);
    expect(find.text(ar.linkPickerEmpty), findsOneWidget);
    expect(find.text(ar.linkSelected(0)), findsOneWidget);
  });

  fikraTest('controls are 48 dp targets and follow the reading direction (English)', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final [a, b, c, d] = await seed(tester, db, ['A', 'B', 'C', 'D'], l10n: en);
    await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id], label: 'why'));
    await suggest(tester, db, a, [c]);
    // A suggestion with no reason has the shortest row.
    await insert(tester, db, 'no-reason', d, a, LinkOrigin.ai, '');
    await open(tester, a);
    expect(Directionality.of(tester.element(find.text(en.noteLinksHeader))), TextDirection.ltr);
    for (final key in [
      'link-options-${b.id}',
      'link-accept-${c.id}',
      'link-reject-${c.id}',
      'open-link-${b.id}',
      'open-link-${c.id}',
      'open-link-${d.id}',
      'link-to-note',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
    }
    final title = tester.getCenter(find.text('B'));
    expect(tester.getCenter(find.byKey(ValueKey('link-options-${b.id}'))).dx, greaterThan(title.dx));
    expect(
      tester.getCenter(find.byKey(ValueKey('link-accept-${c.id}'))).dx,
      lessThan(tester.getCenter(find.byKey(ValueKey('link-reject-${c.id}'))).dx),
    );
    await openPicker(tester);
    expect(tester.getSize(find.byKey(ValueKey('link-pick-${b.id}'))).height, greaterThanOrEqualTo(48));
  });

  fikraTest('rows read right to left in Arabic', (tester, db) async {
    phone(tester);
    final [a, b, c] = await seed(tester, db, ['A', 'B', 'C']);
    await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id]));
    await suggest(tester, db, a, [c]);
    await open(tester, a);
    expect(Directionality.of(tester.element(find.text(ar.noteLinksHeader))), TextDirection.rtl);
    final title = tester.getCenter(find.text('B'));
    expect(tester.getCenter(find.byKey(ValueKey('link-options-${b.id}'))).dx, lessThan(title.dx));
    expect(
      tester.getCenter(find.byKey(ValueKey('link-accept-${c.id}'))).dx,
      greaterThan(tester.getCenter(find.byKey(ValueKey('link-reject-${c.id}'))).dx),
    );
  });

  Future<void> waitGone(WidgetTester tester, Finder finder) async {
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (finder.evaluate().isNotEmpty && DateTime.now().isBefore(end)) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(finder, findsNothing);
  }

  /// Taps the scrim above the open sheet, closing it.
  Future<void> dismissSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(195, 20));
    await tester.pump();
  }

  fikraTest('closing the picker while linking keeps the note page open', linksRepository: (db) => spy = _SpyLinks(db), (
    tester,
    db,
  ) async {
    phone(tester);
    final [a, b] = await seed(tester, db, ['A', 'B']);
    await open(tester, a);
    await openPicker(tester);
    await tapKey(tester, 'link-pick-${b.id}');
    spy.gate = Completer<void>();
    await tapKey(tester, 'link-confirm');
    await dismissSheet(tester);
    spy.gate!.complete();
    await pumpUntil(tester, find.byKey(ValueKey('link-options-${b.id}')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(NoteDetailsScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('link-confirm')), findsNothing);
    expect(await rows(tester, db), hasLength(1));
  });

  fikraTest(
    'closing the reason sheet while saving keeps the note page open',
    linksRepository: (db) => spy = _SpyLinks(db),
    (tester, db) async {
      phone(tester);
      final [a, b] = await seed(tester, db, ['A', 'B']);
      await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [b.id], label: 'old'));
      await open(tester, a);
      await tapKey(tester, 'link-options-${b.id}');
      await settle(tester, find.text(ar.editLinkReason));
      await tester.tap(find.text(ar.editLinkReason));
      await settle(tester, find.byKey(const ValueKey('link-reason-save')));
      await tester.enterText(field('link-reason'), 'new');
      spy.gate = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('link-reason-save')));
      await tester.pump();
      await dismissSheet(tester);
      spy.gate!.complete();
      await pumpUntil(tester, find.text('new'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(NoteDetailsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('link-to-note')), findsOneWidget);
    },
  );

  fikraTest('confirming a removal after the note page went away does not touch it', (tester, db) async {
    phone(tester);
    final [a, b] = await seed(tester, db, ['A', 'B']);
    await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(b.id, [a.id]));
    await open(tester, a);
    await tapKey(tester, 'link-options-${b.id}');
    await settle(tester, find.text(ar.removeLink));
    await tester.tap(find.text(ar.removeLink));
    await settle(tester, find.text(ar.removeLinkTitle));
    // The note is deleted meanwhile: its links section is disposed under the sheet.
    await pumpFuture(tester, () => LocalNotesRepository(db).delete(a.id));
    await pumpUntil(tester, find.text(ar.noteNotFoundTitle));
    expect(find.byKey(const ValueKey('link-to-note')), findsNothing);
    await tester.tap(find.text(ar.removeLinkConfirm));
    await waitGone(tester, find.text(ar.removeLink));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.text(ar.linkUpdateFailed), findsNothing);
  });

  fikraTest(
    'accept still works when a re-analysis replaced the suggestion row meanwhile',
    linksRepository: (db) => spy = _SpyLinks(db),
    (tester, db) async {
      phone(tester);
      final [a, b] = await seed(tester, db, ['A', 'B']);
      await suggest(tester, db, a, [b]);
      final shown = (await rows(tester, db)).single.id;
      await open(tester, a);
      final accept = find.byKey(ValueKey('link-accept-${b.id}'));
      await tester.ensureVisible(accept);
      await tester.pump();
      // The re-analysis is already writing when the tap lands on the old row.
      final reanalysis = LocalNotesRepository(db).applyInsights(
        a.id,
        NoteInsights(
          title: 'A',
          concepts: const [],
          cluster: 'k',
          links: [ProposedLink(targetId: b.id, label: 'AI reason', strength: 0.5)],
        ),
      );
      await tester.tap(accept);
      await pumpFuture(tester, () => reanalysis);
      await pumpUntil(tester, find.byKey(ValueKey('link-options-${b.id}')));
      final row = (await rows(tester, db)).single;
      expect(row.id, isNot(shown));
      expect(row.origin, LinkOrigin.user);
    },
  );

  fikraTest(
    'a short screen with the keyboard open scrolls the whole picker instead of overflowing',
    linksRepository: (db) => spy = _SpyLinks(db, failLinking: true),
    (tester, db) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(390 * 3, 560 * 3);
      addTearDown(tester.view.reset);
      final [a, b] = await seed(tester, db, ['A', 'B']);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await open(tester, a);
      await openPicker(tester);
      await tapKey(tester, 'link-pick-${b.id}');
      await tapKey(tester, 'link-confirm');
      await pumpUntil(tester, find.text(ar.linkFailed));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      // Everything stays reachable: the confirm button scrolls into view and works.
      final confirm = find.byKey(const ValueKey('link-confirm'));
      await tester.ensureVisible(confirm);
      await tester.pump();
      expect(confirm.hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.byKey(ValueKey('link-pick-${b.id}')));
      await tester.pump();
      expect(find.byKey(ValueKey('link-pick-${b.id}')).hitTestable(), findsOneWidget);
    },
  );

  fikraTest('a reason ending in an emoji is stored exactly as the field shows it', (tester, db) async {
    phone(tester);
    final [a, b] = await seed(tester, db, ['A', 'B']);
    await open(tester, a);
    await openPicker(tester);
    await tapKey(tester, 'link-pick-${b.id}');
    // One letter too many: the field keeps 79 letters and the emoji.
    await tester.enterText(field('link-reason'), '${'a' * 79}😀z');
    await tester.pump();
    final shown = tester.widget<TextField>(field('link-reason')).controller!.text;
    expect(shown, '${'a' * 79}😀');
    expect(find.text('80/80'), findsOneWidget);
    await tapKey(tester, 'link-confirm');
    await pumpUntil(tester, find.text(ar.notesLinked(1)));
    expect((await rows(tester, db)).single.label, shown);
  });

  fikraTest('the tall picker keeps its button above the bottom safe area', (tester, db) async {
    phone(tester);
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    final [a, _] = await seed(tester, db, ['A', 'B']);
    await open(tester, a);
    await openPicker(tester);
    expect(tester.getRect(find.byKey(const ValueKey('link-confirm'))).bottom, lessThanOrEqualTo(844 - 34));
  });

  fikraTest('typing in the search only filters; the lists are rebuilt only when the data changes', (tester, db) async {
    phone(tester);
    final [a, b, c] = await seed(tester, db, ['A', 'Bee', 'Cat']);
    await open(tester, a);
    await openPicker(tester);
    final before = LinkPickerSheet.derivations;
    for (final query in ['c', 'ca', 'cat', 'ca', '']) {
      await tester.enterText(field('link-search'), query);
      await tester.pump();
    }
    expect(find.byKey(ValueKey('link-pick-${b.id}')), findsOneWidget);
    expect(LinkPickerSheet.derivations, before);
    await pumpFuture(tester, () => LocalLinksRepository(db).linkNotes(a.id, [c.id]));
    await pumpUntil(tester, find.text(ar.alreadyLinked));
    expect(LinkPickerSheet.derivations, greaterThan(before));
  });
}

/// The real repository, counting calls; linking can be made to fail.
class _SpyLinks implements LinksRepository {
  _SpyLinks(FikraDatabase db, {this.failLinking = false}) : _inner = LocalLinksRepository(db);
  final LocalLinksRepository _inner;
  bool failLinking;
  final calls = <String>[];

  /// When set, linking and label edits wait for it, to act while they run.
  Completer<void>? gate;

  /// When set, a pair Undo waits for it (a slow Undo).
  Completer<void>? undoGate;

  @override
  Stream<List<NoteLink>> watchLinks(String projectId) => _inner.watchLinks(projectId);

  @override
  Future<List<String>> linkNotes(String sourceId, Iterable<String> targetIds, {String? label}) async {
    calls.add('link');
    await gate?.future;
    if (failLinking) throw Exception('disk full');
    return _inner.linkNotes(sourceId, targetIds, label: label);
  }

  @override
  Future<List<LinkChange>> linkNotesForUndo(String sourceId, Iterable<String> targetIds) =>
      _inner.linkNotesForUndo(sourceId, targetIds);

  @override
  Future<void> undoLinks(Iterable<LinkChange> changes) => _inner.undoLinks(changes);

  @override
  Future<void> updateLabel(String linkId, String? label) async {
    calls.add('label');
    await gate?.future;
    return _inner.updateLabel(linkId, label);
  }

  @override
  Future<void> removeLink(String linkId) {
    calls.add('remove');
    return _inner.removeLink(linkId);
  }

  @override
  Future<void> acceptSuggestion(String linkId) {
    calls.add('accept');
    return _inner.acceptSuggestion(linkId);
  }

  @override
  Future<void> dismissSuggestion(String linkId) {
    calls.add('dismiss');
    return _inner.dismissSuggestion(linkId);
  }

  @override
  Future<void> acceptPair(String a, String b) {
    calls.add('acceptPair');
    return _inner.acceptPair(a, b);
  }

  @override
  Future<void> dismissPair(String a, String b) {
    calls.add('dismissPair');
    return _inner.dismissPair(a, b);
  }

  @override
  Future<PairChange?> acceptPairForUndo(String a, String b) {
    calls.add('acceptPair');
    return _inner.acceptPairForUndo(a, b);
  }

  @override
  Future<PairChange?> dismissPairForUndo(String a, String b) {
    calls.add('dismissPair');
    return _inner.dismissPairForUndo(a, b);
  }

  @override
  Future<bool> undoPairChange(PairChange change) async {
    calls.add('undoPair');
    await undoGate?.future;
    return _inner.undoPairChange(change);
  }
}

class _Ai implements AiService {
  _Ai(this.analyzeNote);
  final Future<NoteInsights> Function(Note, List<Note>) analyzeNote;

  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) => analyzeNote(note, projectNotes);

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) => throw UnimplementedError();
}
