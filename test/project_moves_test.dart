import 'dart:async';

import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/format.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/ask/ask_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
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

  group('message wording', () {
    test('move confirmation counts links and suggestions with every Arabic plural form', () {
      String ar0(int u, int s) => moveNoteMessage(ar, (userLinks: u, suggestions: s));
      String en0(int u, int s) => moveNoteMessage(en, (userLinks: u, suggestions: s));
      const arHead = 'الملاحظة هتتنقل بملفاتها، وهيتشال ';
      const arTail = ' بينها وبين الملاحظات اللي هتفضل هنا.';
      expect(ar0(0, 0), 'الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال.');
      expect(en0(0, 0), 'The note moves with its files. No links will be removed.');
      expect(ar0(1, 0), '$arHeadرابط واحد$arTail');
      expect(ar0(2, 0), '$arHeadرابطين$arTail');
      expect(ar0(0, 1), '$arHeadاقتراح واحد$arTail');
      expect(ar0(0, 2), '$arHeadاقتراحين$arTail');
      expect(ar0(3, 10), '${arHead}3 روابط و10 اقتراحات$arTail');
      expect(ar0(11, 99), '${arHead}11 رابط و99 اقتراح$arTail');
      expect(ar0(100, 103), '${arHead}100 رابط و103 اقتراحات$arTail');
      expect(en0(1, 0), 'The note moves with its files. Its 1 link to notes that stay here will be removed.');
      expect(en0(0, 1), 'The note moves with its files. Its 1 suggestion to notes that stay here will be removed.');
      expect(
        en0(2, 3),
        'The note moves with its files. Its 2 links and 3 suggestions to notes that stay here will be removed.',
      );
      // The zero forms exist for completeness; messages leave zero counts out.
      expect(ar.suggestionsCount(0), 'مفيش اقتراحات');
      expect(ar.filesCount(0), 'مفيش ملفات');
      expect(en.suggestionsCount(0), 'No suggestions');
      expect(en.filesCount(0), 'No files');
    });

    test('project delete confirmation counts notes, files and links, or says the project is empty', () {
      String ar0(int n, int f, int l, {bool chat = true}) =>
          deleteProjectMessage(ar, (notes: n, files: f, links: l, chat: chat));
      String en0(int n, int f, int l, {bool chat = true}) =>
          deleteProjectMessage(en, (notes: n, files: f, links: l, chat: chat));
      const arTail = '، والمحادثة كمان. مش هتعرف ترجّعهم.';
      // No notes: the chat is mentioned only when there is one.
      expect(ar0(0, 0, 0, chat: false), 'المشروع ده فاضي، مفيهوش ملاحظات.');
      expect(en0(0, 0, 0, chat: false), 'This project is empty. It has no notes.');
      expect(ar0(0, 0, 0), 'المشروع ده مفيهوش ملاحظات، بس المحادثة اللي فيه هتتحذف. مش هتعرف ترجّعها.');
      expect(en0(0, 0, 0), "This project has no notes, but its chat will be deleted. You can't undo this.");
      expect(ar0(1, 0, 0), 'هيتحذف ملاحظة واحدة$arTail');
      expect(ar0(2, 1, 0), 'هيتحذف ملاحظتين وملف واحد$arTail');
      expect(ar0(3, 2, 1), 'هيتحذف 3 ملاحظات وملفين ورابط واحد$arTail');
      expect(ar0(11, 0, 2), 'هيتحذف 11 ملاحظة ورابطين$arTail');
      expect(ar0(100, 4, 12), 'هيتحذف 100 ملاحظة و4 ملفات و12 رابط$arTail');
      expect(en0(1, 0, 0), "This deletes 1 note, plus the chat. You can't undo this.");
      expect(en0(3, 1, 0), "This deletes 3 notes and 1 file, plus the chat. You can't undo this.");
      expect(en0(3, 2, 5), "This deletes 3 notes, 2 files and 5 links, plus the chat. You can't undo this.");
    });

    test('a mixed Latin and number project name keeps its order inside Arabic and English', () {
      /// The left edge of each part of [message] once laid out in [direction].
      List<double> lefts(String message, TextDirection direction, List<String> parts) {
        final painter = TextPainter(
          text: TextSpan(text: message, style: const TextStyle(fontSize: 14)),
          textDirection: direction,
        )..layout(maxWidth: 4000);
        final result = [
          for (final part in parts)
            painter
                .getBoxesForSelection(
                  TextSelection(baseOffset: message.indexOf(part), extentOffset: message.indexOf(part) + part.length),
                )
                .first
                .left,
        ];
        painter.dispose();
        return result;
      }

      final latin = Fmt.isolate('2026 Work');
      for (final message in [ar.moveNoteTitle(latin), ar.noteMoved(latin), ar.deleteProjectTitle(latin)]) {
        final [number, word] = lefts(message, TextDirection.rtl, ['2026', 'Work']);
        expect(number, lessThan(word), reason: message); // "2026 Work", not "Work 2026"
      }
      final arabic = Fmt.isolate('مشروع 2026');
      for (final message in [en.moveNoteTitle(arabic), en.noteMoved(arabic), en.deleteProjectTitle(arabic)]) {
        final [number, word] = lefts(message, TextDirection.ltr, ['2026', 'مشروع']);
        expect(number, lessThan(word), reason: message); // read right to left: the word first
      }
    });
  });

  /// Project P (selected) with [titles] as ready notes, and project Q with one
  /// note. Returns P, Q and P's notes in order.
  Future<(Project, Project, List<Note>)> seed(
    WidgetTester tester,
    FikraDatabase db,
    List<String> titles, {
    AppLocalizations? l10n,
    bool other = true,
  }) async {
    await pumpUntil(tester, find.text((l10n ?? ar).startNewProject));
    final (p, q, notes) = await pumpFuture(tester, () async {
      final projects = LocalProjectsRepository(db);
      final repo = LocalNotesRepository(db);
      final p = await projects.create('Study');
      final q = other ? await projects.create('Work') : null;
      if (q != null) {
        final n = await repo.create(projectId: q.id, title: 'Q note', text: 'q', source: NoteSource.text);
        await repo.markReady(n.id);
      }
      await projects.setCurrent(p.id);
      final notes = <Note>[];
      for (final (i, t) in titles.indexed) {
        final n = await repo.create(
          projectId: p.id,
          title: t,
          text: 'text of $t',
          source: i == 0 ? NoteSource.pdf : NoteSource.text,
          attachments: i == 0
              ? const [
                  AttachmentDraft(kind: AttachmentKind.pdf, path: '/private/a.pdf', name: 'a.pdf', bytes: 10),
                  AttachmentDraft(kind: AttachmentKind.voice, path: '/private/a.m4a', durationMs: 1000),
                ]
              : const [],
          createdAt: DateTime(2026, 11, 1 + i),
        );
        await repo.markReady(n.id);
        notes.add(n);
      }
      return (p, q, notes);
    });
    await pumpUntil(tester, find.text(titles.last));
    return (p, q ?? p, notes);
  }

  var edgeSequence = 0;
  Future<void> edge(
    WidgetTester tester,
    FikraDatabase db,
    Note a,
    Note b,
    LinkOrigin origin, {
    bool dismissed = false,
  }) => pumpFuture(
    tester,
    () => db
        .into(db.noteLinks)
        .insert(
          NoteLink(
            id: 'edge-${edgeSequence++}',
            projectId: a.projectId,
            sourceId: a.id,
            targetId: b.id,
            label: 'reason',
            strength: 0.5,
            origin: origin,
            dismissed: dismissed,
          ),
        ),
  );

  Future<void> open(WidgetTester tester, Note note) async {
    tester.element(find.byType(Scaffold).last).push('/note/${note.id}');
    await pumpUntil(tester, find.byType(NoteDetailsScreen));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> settle(WidgetTester tester, Finder finder) async {
    await pumpUntil(tester, finder);
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Taps the scrim above the open sheet and lets it close.
  Future<void> dismiss(WidgetTester tester) async {
    await tester.tapAt(const Offset(195, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> openOptions(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.bySemanticsLabel(l10n.options));
    await settle(tester, find.text(l10n.noteOptions));
  }

  Future<void> openPicker(WidgetTester tester, AppLocalizations l10n) async {
    await openOptions(tester, l10n);
    await tester.tap(find.byKey(const ValueKey('note-move')));
    await settle(tester, find.text(l10n.moveToProject));
  }

  Future<Note> read(WidgetTester tester, FikraDatabase db, String id) =>
      pumpFuture(tester, () => (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle());
  Future<List<NoteLink>> links(WidgetTester tester, FikraDatabase db) =>
      pumpFuture(tester, () => db.select(db.noteLinks).get());
  Future<String?> current(WidgetTester tester, FikraDatabase db) =>
      pumpFuture(tester, () => LocalProjectsRepository(db).watchCurrentId().first);

  for (final l10n in [ar, en]) {
    late _SpyNotes notesSpy;
    fikraTest(
      'moving a note with crossing links and suggestions (${l10n.localeName})',
      locale: Locale(l10n.localeName),
      notesRepository: (db) => notesSpy = _SpyNotes(db),
      aiService: _QuietAi(),
      (tester, db) async {
        phone(tester);
        final (p, q, [a, b, c, d, e, f, g]) = await seed(tester, db, ['A', 'B', 'C', 'D', 'E', 'F', 'G'], l10n: l10n);
        // Two user pairs (one with a reverse AI duplicate), three suggestion
        // pairs, a rejected one (not counted) and a link that stays.
        await edge(tester, db, a, b, LinkOrigin.user);
        await edge(tester, db, b, a, LinkOrigin.ai);
        await edge(tester, db, c, a, LinkOrigin.user);
        await edge(tester, db, a, d, LinkOrigin.ai);
        await edge(tester, db, e, a, LinkOrigin.ai);
        await edge(tester, db, a, f, LinkOrigin.ai);
        await edge(tester, db, a, g, LinkOrigin.ai, dismissed: true);
        await edge(tester, db, b, c, LinkOrigin.user);
        final attachments = await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(a.id).first);
        await open(tester, a);
        await openPicker(tester, l10n);
        // One sheet: the options sheet closed before the picker opened.
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(l10n.noteOptions), findsNothing);
        expect(find.byKey(ValueKey('project-pick-${p.id}')), findsNothing);
        expect(
          find.descendant(of: find.byKey(ValueKey('project-pick-${q.id}')), matching: find.text(l10n.notesCount(1))),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
        await settle(tester, find.text(l10n.moveNoteTitle(Fmt.isolate('Work'))));
        expect(find.byType(BottomSheet), findsNothing);
        expect(
          find.text(
            l10n.localeName == 'ar'
                ? 'الملاحظة هتتنقل بملفاتها، وهيتشال رابطين و3 اقتراحات بينها وبين الملاحظات اللي هتفضل هنا.'
                : 'The note moves with its files. Its 2 links and 3 suggestions to notes that stay here will be removed.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text(l10n.moveConfirm));
        await settle(tester, find.text(l10n.noteMoved(Fmt.isolate('Work'))));
        await pumpUntil(tester, find.byType(NotesScreen));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(NoteDetailsScreen), findsNothing);
        expect(find.byType(NotesScreen), findsOneWidget);
        expect(find.text(l10n.noteMoved(Fmt.isolate('Work'))), findsOneWidget);
        expect((await read(tester, db, a.id)).projectId, q.id);
        expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(a.id).first), attachments);
        final left = await links(tester, db);
        expect(left.where((l) => l.sourceId == a.id || l.targetId == a.id), isEmpty);
        expect(left.where((l) => l.sourceId == b.id && l.targetId == c.id), hasLength(1));
        expect(await current(tester, db), p.id);
        expect(notesSpy.moves, 1);
        await pumpUntil(tester, find.byType(NotesScreen)); // let the relink job run
        for (var i = 0; i < 20 && notesSpy.relinked.isEmpty; i++) {
          await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 10)));
        }
        expect(notesSpy.relinked, [a.id]);
        // The note left the selected project's list.
        expect(find.text('A'), findsNothing);
        expect(find.text('G'), findsOneWidget);
      },
    );
  }

  fikraTest('a move that loses nothing says so plainly and uses the primary button', aiService: _QuietAi(), (
    tester,
    db,
  ) async {
    phone(tester);
    final (_, q, [a]) = await seed(tester, db, ['A']);
    await open(tester, a);
    await openPicker(tester, ar);
    await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
    await settle(tester, find.text(ar.moveNoteBodyNoLinks));
    expect(find.text(ar.moveNoteTitle(Fmt.isolate('Work'))), findsOneWidget);
    final confirm = tester.widget<FikraButton>(find.widgetWithText(FikraButton, ar.moveConfirm));
    expect(confirm.style, FikraButtonStyle.primary);
    await tester.tap(find.text(ar.moveConfirm));
    await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
    expect((await read(tester, db, a.id)).projectId, q.id);
  });

  fikraTest('the move option is hidden when there is no other project', (tester, db) async {
    phone(tester);
    final (_, _, [a]) = await seed(tester, db, ['A'], other: false);
    await open(tester, a);
    await openOptions(tester, ar);
    expect(find.descendant(of: find.byType(BottomSheet), matching: find.text(ar.edit)), findsOneWidget);
    expect(find.text(ar.deleteNote), findsOneWidget);
    expect(find.byKey(const ValueKey('note-move')), findsNothing);
    expect(find.text(ar.moveToProject), findsNothing);
  });

  fikraTest('cancelling at the picker or at the confirmation changes nothing', (tester, db) async {
    phone(tester);
    final (p, q, [a, b]) = await seed(tester, db, ['A', 'B']);
    await edge(tester, db, a, b, LinkOrigin.user);
    await open(tester, a);

    await openPicker(tester, ar);
    await dismiss(tester);
    expect(find.byType(BottomSheet), findsNothing);

    await openPicker(tester, ar);
    await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
    await settle(tester, find.text(ar.moveNoteTitle(Fmt.isolate('Work'))));
    await tester.tap(find.text(ar.cancel).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(NoteDetailsScreen), findsOneWidget);
    expect(find.text(ar.moveNoteTitle(Fmt.isolate('Work'))), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect((await read(tester, db, a.id)).projectId, p.id);
    expect(await links(tester, db), hasLength(1));
    expect(await current(tester, db), p.id);

    // The option works again after both cancels.
    await openPicker(tester, ar);
    expect(find.byKey(ValueKey('project-pick-${q.id}')), findsOneWidget);
  });

  late _SpyNotes doubleSpy;
  fikraTest(
    // A second tap in the same frame never reaches a popped route: the
    // Navigator absorbs pointers after a pop. This checks the outcome.
    'same-frame double taps on the option, the project and confirm move once',
    notesRepository: (db) => doubleSpy = _SpyNotes(db),
    aiService: _QuietAi(),
    (tester, db) async {
      phone(tester);
      final (p, q, [a, _]) = await seed(tester, db, ['A', 'B']);
      await open(tester, a);
      await openOptions(tester, ar);
      final option = find.byKey(const ValueKey('note-move'));
      await tester.tap(option);
      await tester.tap(option, warnIfMissed: false);
      await settle(tester, find.text(ar.moveToProject));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(NoteDetailsScreen), findsOneWidget);

      final pick = find.byKey(ValueKey('project-pick-${q.id}'));
      await tester.tap(pick);
      await tester.tap(pick, warnIfMissed: false);
      await settle(tester, find.text(ar.moveConfirm));
      expect(find.byType(NoteDetailsScreen), findsOneWidget);

      final confirm = find.text(ar.moveConfirm);
      await tester.tap(confirm);
      await tester.tap(confirm, warnIfMissed: false);
      await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
      await pumpUntil(tester, find.byType(NotesScreen));
      await tester.pump(const Duration(milliseconds: 600));
      expect(doubleSpy.moves, 1);
      expect(find.byType(NoteDetailsScreen), findsNothing);
      expect(find.byType(NotesScreen), findsOneWidget);
      expect((await read(tester, db, a.id)).projectId, q.id);
      expect(await current(tester, db), p.id);
    },
  );

  late _SpyNotes gatedSpy;
  fikraTest(
    'a second move cannot start while the first is saving',
    notesRepository: (db) => gatedSpy = _SpyNotes(db),
    aiService: _QuietAi(),
    (tester, db) async {
      phone(tester);
      final (_, q, [a, _]) = await seed(tester, db, ['A', 'B']);
      await open(tester, a);
      await openPicker(tester, ar);
      await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
      await settle(tester, find.text(ar.moveConfirm));
      final gate = gatedSpy.gate = Completer<void>();
      await tester.tap(find.text(ar.moveConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(ar.moveConfirm), findsNothing);
      expect(gatedSpy.moves, 1);

      // The page is still there while the move is saving; its options (and the
      // header Edit button, and a second move) stay disabled/shut.
      await tester.tap(find.bySemanticsLabel(ar.options));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(ar.noteOptions), findsNothing);
      await tester.tap(find.byKey(const ValueKey('note-edit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(ar.editNoteTitle), findsNothing);

      gate.complete();
      await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
      await pumpUntil(tester, find.byType(NotesScreen));
      expect(gatedSpy.moves, 1);
      expect((await read(tester, db, a.id)).projectId, q.id);
    },
  );

  late _SpyNotes onTopSpy;
  fikraTest(
    'a page opened on top while the move saves stays when the move ends',
    notesRepository: (db) => onTopSpy = _SpyNotes(db),
    aiService: _QuietAi(),
    (tester, db) async {
      phone(tester);
      final (_, q, [a, b]) = await seed(tester, db, ['A', 'B']);
      await open(tester, a);
      await openPicker(tester, ar);
      await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
      await settle(tester, find.text(ar.moveConfirm));
      final gate = onTopSpy.gate = Completer<void>();
      await tester.tap(find.text(ar.moveConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      // While saving, another page is opened on top (as a link row does).
      tester.element(find.byType(NoteDetailsScreen)).push('/note/${b.id}');
      await pumpUntil(tester, find.text('text of B'));
      await tester.pump(const Duration(milliseconds: 600));

      gate.complete();
      await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
      expect((await read(tester, db, a.id)).projectId, q.id);
      // B's page is still the one on screen; nothing navigated it away.
      expect(find.text('text of B'), findsOneWidget);
      expect(find.byType(NotesScreen), findsNothing);
    },
  );

  fikraTest(
    "Back after moving a note opened from another note's link row lands on a valid screen",
    aiService: _QuietAi(),
    (tester, db) async {
      phone(tester);
      final (_, q, [a, b]) = await seed(tester, db, ['A', 'B']);
      await edge(tester, db, b, a, LinkOrigin.user);
      await open(tester, b);
      final row = find.byKey(ValueKey('open-link-${a.id}'));
      await tester.ensureVisible(row);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(row);
      await pumpUntil(tester, find.text('text of A'));
      await tester.pump(const Duration(milliseconds: 600));
      await openPicker(tester, ar);
      await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
      await settle(tester, find.text(ar.moveConfirm));
      await tester.tap(find.text(ar.moveConfirm));
      await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
      await pumpUntil(tester, find.byType(NotesScreen));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(NoteDetailsScreen), findsNothing);

      // System Back from the notes list: no stale note page comes back.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.byType(NoteDetailsScreen), findsNothing);
      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    },
  );

  fikraTest(
    'move numbers that changed while the dialog was open are shown again before moving',
    aiService: _QuietAi(),
    (tester, db) async {
      phone(tester);
      final (p, q, [a, b]) = await seed(tester, db, ['A', 'B']);
      await open(tester, a);
      await openPicker(tester, ar);
      await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
      await settle(tester, find.text(ar.moveNoteBodyNoLinks));
      // A queued analysis adds a suggestion while the dialog is open.
      await edge(tester, db, a, b, LinkOrigin.ai);
      await tester.tap(find.text(ar.moveConfirm));
      await settle(tester, find.text(moveNoteMessage(ar, (userLinks: 0, suggestions: 1))));
      expect(find.text(ar.moveNoteBodyNoLinks), findsNothing);
      expect((await read(tester, db, a.id)).projectId, p.id);
      expect(await links(tester, db), hasLength(1));

      await tester.tap(find.text(ar.moveConfirm));
      await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
      expect((await read(tester, db, a.id)).projectId, q.id);
      expect(await links(tester, db), isEmpty);
    },
  );

  fikraTest('the move leaves for the notes list even when the note was opened from Ask', aiService: _QuietAi(), (
    tester,
    db,
  ) async {
    phone(tester);
    final (_, q, [a, _]) = await seed(tester, db, ['A', 'B']);
    await tester.tap(Tabs.finder(Tabs.ask));
    await settle(tester, find.byType(AskScreen));
    await open(tester, a);
    await openPicker(tester, ar);
    await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
    await settle(tester, find.text(ar.moveConfirm));
    await tester.tap(find.text(ar.moveConfirm));
    await settle(tester, find.text(ar.noteMoved(Fmt.isolate('Work'))));
    await pumpUntil(tester, find.byType(NotesScreen));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(NoteDetailsScreen), findsNothing);
    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.byType(AskScreen), findsNothing); // offstage branch
  });

  fikraTest('a target project deleted meanwhile shows the failure and changes nothing', (tester, db) async {
    phone(tester);
    final (p, q, [a, b]) = await seed(tester, db, ['A', 'B']);
    await edge(tester, db, a, b, LinkOrigin.user);
    await open(tester, a);
    await openPicker(tester, ar);
    await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
    await settle(tester, find.text(ar.moveNoteTitle(Fmt.isolate('Work'))));
    await pumpFuture(tester, () => LocalProjectsRepository(db).delete(q.id));
    await tester.tap(find.text(ar.moveConfirm));
    await settle(tester, find.text(ar.moveNoteFailed));

    expect(find.byType(NoteDetailsScreen), findsOneWidget);
    expect(find.text(ar.noteMoved(Fmt.isolate('Work'))), findsNothing);
    expect((await read(tester, db, a.id)).projectId, p.id);
    expect(await links(tester, db), hasLength(1));
    expect(await current(tester, db), p.id);
  });

  fikraTest('a note deleted while its move is being confirmed does not throw', (tester, db) async {
    phone(tester);
    final (_, q, [a, _]) = await seed(tester, db, ['A', 'B']);
    await open(tester, a);
    await openPicker(tester, ar);
    await tester.tap(find.byKey(ValueKey('project-pick-${q.id}')));
    await settle(tester, find.text(ar.moveNoteTitle(Fmt.isolate('Work'))));
    await pumpFuture(tester, () => LocalNotesRepository(db).delete(a.id));
    await tester.tap(find.text(ar.moveConfirm));
    await settle(tester, find.text(ar.noteNotFoundTitle));
    expect(tester.takeException(), isNull);
    expect(find.text(ar.noteMoved(Fmt.isolate('Work'))), findsNothing);
    expect(find.text(ar.moveNoteFailed), findsNothing);
  });

  fikraTest('Ask: sources moved to another project or deleted render and cannot be opened', (tester, db) async {
    phone(tester);
    final (p, q, [a, b, c]) = await seed(tester, db, ['Moved', 'Deleted', 'Kept']);
    await pumpFuture(tester, () async {
      final chat = LocalChatRepository(db);
      await chat.add(projectId: p.id, role: 'user', body: 'question?');
      await chat.add(projectId: p.id, role: 'assistant', body: 'answer', sourceIds: [a.id, b.id, c.id]);
      await LocalNotesRepository(db).moveNotes([a.id], q.id);
      await LocalNotesRepository(db).delete(b.id);
    });
    await tester.tap(Tabs.finder(Tabs.ask));
    await settle(tester, find.text(ar.sources));
    expect(tester.takeException(), isNull);
    expect(find.text(ar.sourceMissing), findsNWidgets(2));
    expect(find.text('Kept'), findsOneWidget);
    expect(find.text('Moved'), findsNothing);
    expect(find.bySemanticsLabel(ar.sourceMissingA11y(1)), findsOneWidget);
    expect(find.bySemanticsLabel(ar.sourceMissingA11y(2)), findsOneWidget);
    for (final index in [1, 2]) {
      // A disabled control with no tap action for TalkBack either.
      expect(
        tester.getSemantics(find.bySemanticsLabel(ar.sourceMissingA11y(index))),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, hasTapAction: false),
      );
    }
    for (final row in find.text(ar.sourceMissing).evaluate().toList()) {
      await tester.tap(find.byWidget(row.widget));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(NoteDetailsScreen), findsNothing);
    }
    // The note that is still here opens.
    await tester.tap(find.text('Kept'));
    await settle(tester, find.byType(NoteDetailsScreen));
  });

  Future<void> openProjects(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.bySemanticsLabel(l10n.projectPillA11y('Study')).first);
    await settle(tester, find.text(l10n.projectsTitle));
  }

  fikraTest('project delete confirmation says in numbers what goes, or that the project is empty', (tester, db) async {
    phone(tester);
    final (p, q, [a, b, c]) = await seed(tester, db, ['A', 'B', 'C']);
    await edge(tester, db, a, b, LinkOrigin.user);
    await edge(tester, db, b, a, LinkOrigin.ai); // same pair
    await edge(tester, db, a, c, LinkOrigin.ai);
    await edge(tester, db, b, c, LinkOrigin.ai, dismissed: true); // rejected
    await openProjects(tester, ar);
    await tester.tap(find.bySemanticsLabel(ar.projectOptionsA11y('Study')));
    await settle(tester, find.text(ar.deleteProject));
    await tester.tap(find.text(ar.deleteProject));
    await settle(tester, find.text(ar.deleteProjectTitle(Fmt.isolate('Study'))));
    expect(find.text('هيتحذف 3 ملاحظات وملفين ورابطين، والمحادثة كمان. مش هتعرف ترجّعهم.'), findsOneWidget);
    await tester.tap(find.text(ar.cancel).last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(await pumpFuture(tester, () => db.select(db.notes).get()), hasLength(4));
    for (var i = 0; i < 2; i++) {
      await dismiss(tester); // the options, then the projects sheet
    }
    expect(find.byType(BottomSheet), findsNothing);

    // An empty project.
    await pumpFuture(tester, () async {
      await LocalProjectsRepository(db).create('Empty');
      await LocalProjectsRepository(db).setCurrent(p.id);
    });
    await tester.pump(const Duration(milliseconds: 100));
    await openProjects(tester, ar);
    await tester.tap(find.bySemanticsLabel(ar.projectOptionsA11y('Empty')));
    await settle(tester, find.text(ar.deleteProject));
    await tester.tap(find.text(ar.deleteProject).last);
    await settle(tester, find.text(ar.deleteProjectTitle(Fmt.isolate('Empty'))));
    expect(find.text(ar.deleteProjectEmptyBody), findsOneWidget);
    await tester.tap(find.text(ar.delete).last);
    await settle(tester, find.text(ar.projectDeleted));
    final names = (await pumpFuture(tester, () => db.select(db.projects).get())).map((p) => p.name);
    expect(names, unorderedEquals(['Study', 'Work']));
    expect(await current(tester, db), p.id);
    expect(q.name, 'Work');
  });

  Future<void> openDelete(WidgetTester tester, String name) async {
    await tester.tap(find.bySemanticsLabel(ar.projectOptionsA11y(name)));
    await settle(tester, find.text(ar.deleteProject));
  }

  late _SpyProjects projectsSpy;
  fikraTest(
    'a double tap on delete counts once and opens one dialog; cancel lets it open again',
    projectsRepository: (db) => projectsSpy = _SpyProjects(db),
    (tester, db) async {
      phone(tester);
      await seed(tester, db, ['A']);
      await openProjects(tester, ar);
      await openDelete(tester, 'Study');
      // A slow count: the second tap lands while the first is still counting.
      final gate = projectsSpy.gate = Completer<void>();
      await tester.tap(find.text(ar.deleteProject));
      await tester.pump();
      await tester.tap(find.text(ar.deleteProject));
      await tester.pump();
      projectsSpy.gate = null;
      gate.complete();
      await settle(tester, find.text(ar.deleteProjectTitle(Fmt.isolate('Study'))));
      expect(find.text(ar.deleteProjectTitle(Fmt.isolate('Study'))), findsOneWidget);
      expect(projectsSpy.counts, 1);
      await tester.tap(find.text(ar.cancel).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(ar.deleteProjectTitle(Fmt.isolate('Study'))), findsNothing);
      // The guard is reset after a cancel.
      await tester.tap(find.text(ar.deleteProject));
      await settle(tester, find.text(ar.deleteProjectTitle(Fmt.isolate('Study'))));
      expect(projectsSpy.counts, 2);
    },
  );

  late _SpyProjects closingSpy;
  fikraTest(
    'a delete count that returns after its sheet was dismissed opens no dialog',
    projectsRepository: (db) => closingSpy = _SpyProjects(db),
    (tester, db) async {
      phone(tester);
      await seed(tester, db, ['A']);
      await openProjects(tester, ar);
      await openDelete(tester, 'Study');
      final gate = closingSpy.gate = Completer<void>();
      await tester.tap(find.text(ar.deleteProject));
      await tester.pump();
      // Dismiss the options sheet; the count comes back while it is closing.
      await tester.tapAt(const Offset(195, 40));
      await tester.pump();
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(ar.deleteProjectTitle(Fmt.isolate('Study'))), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(await pumpFuture(tester, () => db.select(db.projects).get()), hasLength(2));
    },
  );

  fikraTest('delete numbers that changed while the dialog was open are shown again before deleting', (
    tester,
    db,
  ) async {
    phone(tester);
    final (p, _, _) = await seed(tester, db, ['A']);
    await openProjects(tester, ar);
    await openDelete(tester, 'Study');
    await tester.tap(find.text(ar.deleteProject));
    await settle(tester, find.text(deleteProjectMessage(ar, (notes: 1, files: 2, links: 0, chat: false))));
    // A note is added while the dialog is open.
    await pumpFuture(
      tester,
      () => LocalNotesRepository(db).create(projectId: p.id, title: 'late', text: 'x', source: NoteSource.text),
    );
    await tester.tap(find.text(ar.delete).last);
    await settle(tester, find.text(deleteProjectMessage(ar, (notes: 2, files: 2, links: 0, chat: false))));
    expect(await pumpFuture(tester, () => db.select(db.projects).get()), hasLength(2));

    await tester.tap(find.text(ar.delete).last);
    await settle(tester, find.text(ar.projectDeleted));
    expect((await pumpFuture(tester, () => db.select(db.projects).get())).map((p) => p.name), ['Work']);
  });

  fikraTest('deleting a project with no notes but a chat says the chat goes', (tester, db) async {
    phone(tester);
    final (p, _, _) = await seed(tester, db, ['A']);
    await pumpFuture(tester, () async {
      final empty = await LocalProjectsRepository(db).create('Asked');
      await LocalChatRepository(db).add(projectId: empty.id, role: 'user', body: 'question?');
      await LocalProjectsRepository(db).setCurrent(p.id);
    });
    await tester.pump(const Duration(milliseconds: 100));
    await openProjects(tester, ar);
    await openDelete(tester, 'Asked');
    await tester.tap(find.text(ar.deleteProject).last);
    await settle(tester, find.text(ar.deleteProjectEmptyChatBody));
    expect(find.text(ar.deleteProjectEmptyBody), findsNothing);
  });

  fikraTest('UX-16: new project closes the projects sheet first, and cancelling changes nothing', (tester, db) async {
    phone(tester);
    final (p, _, _) = await seed(tester, db, ['A']);
    await openProjects(tester, ar);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('new-project')));
    await settle(tester, find.text(ar.projectNameHint));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(ar.projectsTitle), findsNothing);
    expect(find.text(ar.newProject), findsOneWidget); // the name sheet's title
    await dismiss(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(await pumpFuture(tester, () => db.select(db.projects).get()), hasLength(2));
    expect(await current(tester, db), p.id);

    // Naming one still creates and selects it.
    await openProjects(tester, ar);
    await tester.tap(find.byKey(const ValueKey('new-project')));
    await settle(tester, find.text(ar.projectNameHint));
    await tester.enterText(find.byType(TextField).last, 'New one');
    await tester.pump();
    await tester.tap(find.text(ar.create));
    await pumpUntil(tester, find.bySemanticsLabel(ar.projectPillA11y('New one')));
    expect(await pumpFuture(tester, () => db.select(db.projects).get()), hasLength(3));
  });

  fikraTest('UX-17: the first project has its own title and example; later ones keep theirs', (tester, db) async {
    phone(tester);
    await pumpUntil(tester, find.text(ar.startNewProject));
    await tester.tap(find.text(ar.startNewProject));
    await settle(tester, find.text(ar.firstProjectTitle));
    expect(ar.firstProjectTitle, 'سمّي أول مشروع');
    expect(find.text('اسم المشروع، مثلاً: مذاكرة'), findsOneWidget);
    expect(find.text(ar.projectNameHint), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'Study');
    await tester.pump();
    await tester.tap(find.text(ar.create));
    await pumpUntil(tester, find.bySemanticsLabel(ar.projectPillA11y('Study')));
    await tester.pump(const Duration(milliseconds: 600));

    await openProjects(tester, ar);
    await tester.tap(find.byKey(const ValueKey('new-project')));
    await settle(tester, find.text(ar.projectNameHint));
    expect(find.text(ar.newProject), findsOneWidget);
    expect(find.text(ar.firstProjectTitle), findsNothing);
    expect(find.text(ar.firstProjectNameHint), findsNothing);
    expect(ar.projectNameHint, 'اسم المشروع');
    expect(en.projectNameHint, 'Project name');
    expect(en.firstProjectNameHint, 'Project name, e.g. Study');
  });
}

/// Counts moves and records the notes re-linked after one.
class _SpyNotes extends LocalNotesRepository {
  _SpyNotes(super.db);
  int moves = 0;
  final relinked = <String>[];

  /// When set, moves wait for it.
  Completer<void>? gate;

  @override
  Future<List<String>> moveNotes(Iterable<String> noteIds, String targetProjectId) async {
    moves++;
    await gate?.future;
    return super.moveNotes(noteIds, targetProjectId);
  }

  @override
  Future<void> applyInsights(String id, NoteInsights insights, {Note? basis, bool linksOnly = false}) {
    if (linksOnly) relinked.add(id);
    return super.applyInsights(id, insights, basis: basis, linksOnly: linksOnly);
  }
}

/// Counts delete-impact reads; [gate], when set, holds them.
class _SpyProjects extends LocalProjectsRepository {
  _SpyProjects(super.db);
  int counts = 0;
  Completer<void>? gate;

  @override
  Future<ProjectDeleteImpact> deleteImpact(String id) async {
    counts++;
    await gate?.future;
    return super.deleteImpact(id);
  }
}

/// Answers right away with no links, so re-linking finishes inside the test.
class _QuietAi implements AiService {
  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async =>
      NoteInsights(title: note.title, concepts: const [], cluster: 'k', links: const []);

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) => throw UnimplementedError();
}
