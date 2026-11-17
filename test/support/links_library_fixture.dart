import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'selection_fixture.dart';

/// Real repository writes and streams; only timing/failure is controlled.
class LibrarySpy extends LocalLinksRepository {
  LibrarySpy(super.db);
  int accepts = 0, rejects = 0;
  bool fail = false;
  Completer<void>? gate;
  Future<void>? pending;
  @override
  Future<void> acceptPair(String a, String b) async {
    accepts++;
    final done = Completer<void>();
    pending = done.future;
    try {
      await gate?.future;
      if (fail) throw StateError('fixture');
      await super.acceptPair(a, b);
    } finally {
      done.complete();
    }
  }

  @override
  Future<void> dismissPair(String a, String b) async {
    rejects++;
    final done = Completer<void>();
    pending = done.future;
    try {
      await gate?.future;
      if (fail) throw StateError('fixture');
      await super.dismissPair(a, b);
    } finally {
      done.complete();
    }
  }
}

Future<List<Note>> seedLibrary(
  WidgetTester tester,
  FikraDatabase db, {
  int count = 6,
  AppLocalizations? l10n,
  bool localizedContent = false,
}) async {
  final arabic = localizedContent && (l10n?.localeName.startsWith('ar') ?? true);
  final titles = arabic
      ? [
          'تسعير الاشتراك',
          'مقابلات أول ١٠ عملاء',
          'خطة إطلاق النسخة الأولى',
          'تكلفة التشغيل الشهرية',
          'أفكار حملة الجامعة',
          'مراجعة تجربة الاشتراك',
        ]
      : [
          'Subscription pricing',
          'First customer interviews',
          'Launch plan',
          'Monthly running costs',
          'Campus campaign ideas',
          'Subscription trial review',
        ];
  final (_, _, notes) = await seedNotes(
    tester,
    db,
    List.generate(count, (i) => localizedContent ? titles[i % titles.length] : 'Note $i'),
    l10n: l10n,
  );
  await pumpFuture(tester, () async {
    await db
        .into(db.noteGroups)
        .insert(
          NoteGroup(
            id: 'parent',
            projectId: notes[0].projectId,
            name: arabic ? 'أفكار المشروع' : 'Study',
            position: 0,
            createdAt: DateTime(2026),
          ),
        );
    await db
        .into(db.noteGroups)
        .insert(
          NoteGroup(
            id: 'child',
            projectId: notes[0].projectId,
            name: arabic ? 'مراجعة' : 'Revision',
            parentId: 'parent',
            position: 1,
            createdAt: DateTime(2026),
          ),
        );
    for (var i = 0; i < notes.length; i++) {
      await (db.update(db.notes)..where((n) => n.id.equals(notes[i].id))).write(
        NotesCompanion(
          groupId: Value(
            i == 0
                ? 'parent'
                : i == 1
                ? 'child'
                : null,
          ),
          cluster: Value(arabic ? 'التسعير' : 'Ideas'),
          originalText: localizedContent
              ? Value(
                  arabic
                      ? 'نراجع التجربة ونسمع رأي العملاء قبل الخطوة الجاية.'
                      : 'Review the trial and customer feedback before the next step.',
                )
              : const Value.absent(),
        ),
      );
    }
  });
  for (var i = 1; i < notes.length; i++) {
    await insertLink(tester, db, notes[i - 1], notes[i]);
  }
  await insertLink(tester, db, notes[0], notes[3], origin: LinkOrigin.ai);
  await insertLink(tester, db, notes[1], notes[4], origin: LinkOrigin.ai);
  await insertLink(tester, db, notes[2], notes[5], origin: LinkOrigin.ai);
  await tester.tap(Tabs.finder(Tabs.links));
  await pumpUntil(tester, find.byKey(ValueKey('browse-${notes.last.id}')));
  return notes;
}

Finder get libraryScroll => find.descendant(
  of: find.byType(LinksLibraryScreen),
  matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
);
Future<void> librarySegment(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey('links-segment-$index')));
  await tester.pumpAndSettle();
}

Future<void> openNoteConnections(WidgetTester tester, List<Note> notes, int i) async {
  final row = find.byKey(ValueKey('browse-${notes[i].id}'));
  await tester.scrollUntilVisible(row, 200, scrollable: libraryScroll);
  await Scrollable.ensureVisible(tester.element(row), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}
