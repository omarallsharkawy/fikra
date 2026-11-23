import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/notes/notes_action_strip.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  test('activeDaysThisWeek counts distinct calendar days in the rolling 7-day window', () {
    Note noteAt(String id, DateTime at) => Note(
      id: id,
      projectId: 'p1',
      title: id,
      originalText: '',
      source: NoteSource.text,
      imagePaths: '',
      concepts: '',
      status: ProcessingStatus.ready,
      rewrite: RewriteStatus.none,
      createdAt: at,
      updatedAt: at,
    );

    final now = DateTime(2026, 11, 10, 14, 0);
    expect(activeDaysThisWeek(const [], now), 0);
    expect(
      activeDaysThisWeek([
        noteAt('a', DateTime(2026, 11, 10, 9)), // today (day 0)
        noteAt('b', DateTime(2026, 11, 10, 13)), // same day -> still 1
        noteAt('c', DateTime(2026, 11, 8, 22)), // day 2
        noteAt('d', DateTime(2026, 11, 4, 0, 1)), // day 6 -> included
        noteAt('e', DateTime(2026, 11, 3, 23, 59)), // day 7 -> excluded
        noteAt('f', DateTime(2026, 11, 11, 1)), // future -> excluded
      ], now),
      3,
    );
  });

  fikraTest(
    'home chips filter voice, files, and groups; active chip uses lime fill + dark ink; badges and link-count pill render',
    clock: () => DateTime(2026, 11, 10, 12),
    (tester, db) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1400);
      addTearDown(tester.view.reset);

      final l = lookupAppLocalizations(const Locale('ar'));
      await pumpUntil(tester, find.byKey(const ValueKey('welcome-start')));

      final (textNote, voiceNote, pdfNote, photoNote, group) = await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('مشروع');
        final notes = LocalNotesRepository(db);
        final groups = LocalGroupsRepository(db);
        final links = LocalLinksRepository(db);

        final g = await groups.create(p.id, 'مذاكرة', color: 0);
        final t = await notes.create(
          projectId: p.id,
          title: 'ملاحظة نصية',
          text: 'محتوى نصي عادي',
          source: NoteSource.text,
          createdAt: DateTime(2026, 11, 10, 11),
        );
        final v = await notes.create(
          projectId: p.id,
          title: 'ملاحظة صوتية',
          text: 'تفريغ صوت',
          source: NoteSource.voice,
          attachments: [AttachmentDraft(kind: AttachmentKind.voice, path: '/rec.m4a', durationMs: 5000)],
          createdAt: DateTime(2026, 11, 9, 10),
        );
        final pdf = await notes.create(
          projectId: p.id,
          title: 'ملزمة PDF',
          text: 'شرح المادة',
          source: NoteSource.pdf,
          attachments: [AttachmentDraft(kind: AttachmentKind.pdf, path: '/a.pdf', name: 'a.pdf')],
          createdAt: DateTime(2026, 11, 8, 9),
        );
        final photo = await notes.create(
          projectId: p.id,
          title: 'صورة السبورة',
          text: '',
          source: NoteSource.text,
          attachments: [AttachmentDraft(kind: AttachmentKind.image, path: '/p.png', name: 'p.png')],
          createdAt: DateTime(2026, 11, 1, 9), // older than 7 days
        );

        for (final n in [t, v, pdf, photo]) {
          await notes.markReady(n.id);
        }
        await (db.update(db.notes)..where((r) => r.id.equals(t.id))).write(
          const NotesCompanion(rewrite: Value(RewriteStatus.pending), proposedText: Value('صياغة محسنة')),
        );
        await groups.assignNotes(g.id, [t.id]);
        await links.linkNotes(t.id, [v.id, pdf.id], label: 'مرتبطة');
        return (t, v, pdf, photo, g);
      });

      await pumpUntil(tester, find.byKey(ValueKey(textNote.id)));
      await tester.pump(const Duration(milliseconds: 500));

      // Active-days chip shows 3 rolling days (Nov 10, Nov 9, Nov 8; Nov 1 excluded).
      expect(find.byKey(const ValueKey('notes-active-days')), findsOneWidget);
      expect(find.text(l.activeDaysThisWeek(3)), findsOneWidget);

      // Type badges: voice purple, PDF blue, photo slate, text none.
      expect(find.byKey(ValueKey('note-type-voice-${voiceNote.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('note-type-pdf-${pdfNote.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('note-type-image-${photoNote.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('note-type-voice-${textNote.id}')), findsNothing);
      expect(find.byKey(ValueKey('note-type-pdf-${textNote.id}')), findsNothing);
      expect(find.byKey(ValueKey('note-type-image-${textNote.id}')), findsNothing);

      // Pending-rewrite badge uses warning kind (amber), not processing.
      final rewriteBadge = tester.widget<FikraBadge>(find.byKey(ValueKey('note-rewrite-${textNote.id}')));
      expect(rewriteBadge.kind, BadgeKind.warning);

      // Link-count pill shows 2 for textNote (linked to voiceNote + pdfNote), hidden for photoNote.
      expect(find.byKey(ValueKey('note-links-${textNote.id}')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(ValueKey('note-links-${textNote.id}')), matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('note-links-${photoNote.id}')), findsNothing);

      // Active chip ("All") has brandLime fill + onBrandLime text.
      final allChipContainer = tester.widget<Container>(
        find.descendant(of: find.byKey(const ValueKey('group-filter-all')), matching: find.byType(Container)).first,
      );
      expect((allChipContainer.decoration! as BoxDecoration).color, FikraPalette.dark.brandLime);

      // Filter by Voice.
      await tester.tap(find.byKey(const ValueKey('notes-filter-voice')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ValueKey(voiceNote.id)), findsOneWidget);
      expect(find.byKey(ValueKey(textNote.id)), findsNothing);
      expect(find.byKey(ValueKey(pdfNote.id)), findsNothing);

      // Filter by Files (matches PDF + photo).
      await tester.tap(find.byKey(const ValueKey('notes-filter-files')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ValueKey(pdfNote.id)), findsOneWidget);
      expect(find.byKey(ValueKey(photoNote.id)), findsOneWidget);
      expect(find.byKey(ValueKey(voiceNote.id)), findsNothing);
      expect(find.byKey(ValueKey(textNote.id)), findsNothing);

      // Filter by user group.
      await tester.tap(find.byKey(ValueKey('group-filter-${group.id}')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ValueKey(textNote.id)), findsOneWidget);
      expect(find.byKey(ValueKey(pdfNote.id)), findsNothing);

      // Back to All.
      await tester.tap(find.byKey(const ValueKey('group-filter-all')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ValueKey(textNote.id)), findsOneWidget);
      expect(find.byKey(ValueKey(voiceNote.id)), findsOneWidget);
    },
  );

  fikraTest(
    'action strip hidden at 0, follows failed -> suggestions -> rewrites priority, dismissible, and active-days hidden at 0',
    clock: () => DateTime(2026, 11, 20, 12),
    (tester, db) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1400);
      addTearDown(tester.view.reset);

      final l = lookupAppLocalizations(const Locale('ar'));
      await pumpUntil(tester, find.byKey(const ValueKey('welcome-start')));

      final (project, n1, n2) = await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('أفكار');
        final notes = LocalNotesRepository(db);
        // Created 15 days ago -> activeDaysThisWeek == 0.
        final a = await notes.create(
          projectId: p.id,
          title: 'ملاحظة قديمة أ',
          text: 'نص أ',
          source: NoteSource.text,
          createdAt: DateTime(2026, 11, 1, 10),
        );
        final b = await notes.create(
          projectId: p.id,
          title: 'ملاحظة قديمة ب',
          text: 'نص ب',
          source: NoteSource.text,
          createdAt: DateTime(2026, 11, 2, 10),
        );
        await notes.markReady(a.id);
        await notes.markReady(b.id);
        return (p, a, b);
      });

      await pumpUntil(tester, find.byKey(ValueKey(n1.id)));
      await tester.pump(const Duration(milliseconds: 400));

      // At 0: both action strip and active-days chip are hidden.
      expect(find.byKey(const ValueKey('notes-action-strip')), findsNothing);
      expect(find.byKey(const ValueKey('notes-active-days')), findsNothing);

      // Seed all 3 action conditions: 1 failed, 1 suggestion, 1 pending rewrite.
      await pumpFuture(tester, () async {
        await (db.update(
          db.notes,
        )..where((r) => r.id.equals(n1.id))).write(const NotesCompanion(status: Value(ProcessingStatus.failed)));
        await (db.update(db.notes)..where((r) => r.id.equals(n2.id))).write(
          const NotesCompanion(rewrite: Value(RewriteStatus.pending), proposedText: Value('نسخة مقترحة')),
        );
        await db
            .into(db.noteLinks)
            .insert(
              NoteLink(
                id: 'sugg-1',
                projectId: project.id,
                sourceId: n1.id,
                targetId: n2.id,
                label: 'مقترح',
                strength: 0.9,
                origin: LinkOrigin.ai,
                dismissed: false,
              ),
            );
      });

      // Priority 1: failed analysis strip appears first.
      await pumpUntil(tester, find.text(l.actionStripFailed(1)));
      expect(find.byKey(const ValueKey('notes-action-strip')), findsOneWidget);

      // Dismiss priority 1 -> priority 2 (suggestions) appears.
      await tester.tap(find.byKey(const ValueKey('notes-action-strip-dismiss')));
      await pumpUntil(tester, find.text(l.actionStripSuggestions(1)));

      // Tapping priority 2 opens Links on the Suggestions segment.
      await tester.tap(find.byKey(const ValueKey('notes-action-strip-tap')));
      await pumpUntil(tester, find.byType(LinksLibraryScreen));
      await tester.pump(const Duration(milliseconds: 400));
      final suggSegment = tester.getSemantics(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.suggestions)));
      expect(suggSegment.flagsCollection.isSelected, Tristate.isTrue);

      // Return to Notes, dismiss priority 2 -> priority 3 (rewrites) appears.
      await tester.tap(Tabs.finder(Tabs.notes));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('notes-action-strip-dismiss')));
      await pumpUntil(tester, find.text(l.actionStripRewrites(1)));

      // Tapping priority 3 opens the note with pending rewrite.
      await tester.tap(find.byKey(const ValueKey('notes-action-strip-tap')));
      await pumpUntil(tester, find.byType(NoteDetailsScreen));
      tester.element(find.byType(NoteDetailsScreen)).pop();
      await tester.pump(const Duration(milliseconds: 400));

      // Dismiss priority 3 -> action strip disappears for the session.
      await tester.tap(find.byKey(const ValueKey('notes-action-strip-dismiss')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('notes-action-strip')), findsNothing);
    },
  );
}
