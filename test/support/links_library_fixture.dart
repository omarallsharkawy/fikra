import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/features/connections/map_canvas.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'selection_fixture.dart';

/// Real repository writes and streams; only timing/failure is controlled.
class LibrarySpy extends LocalLinksRepository {
  LibrarySpy(super.db);
  int accepts = 0, rejects = 0, undos = 0;
  bool fail = false;
  Completer<void>? gate;

  /// When set, a pair Undo waits for it (a slow Undo).
  Completer<void>? undoGate;
  Future<void>? pending;

  Future<PairCommandResult?> _gated(Future<PairCommandResult?> Function() write) async {
    final done = Completer<void>();
    pending = done.future;
    try {
      await gate?.future;
      if (fail) throw StateError('fixture');
      return await write();
    } finally {
      done.complete();
    }
  }

  @override
  Future<PairCommandResult?> acceptPairForUndo(String a, String b, {required String expectedProjectId}) {
    accepts++;
    return _gated(() => super.acceptPairForUndo(a, b, expectedProjectId: expectedProjectId));
  }

  @override
  Future<PairCommandResult?> dismissPairForUndo(String a, String b, {required String expectedProjectId}) {
    rejects++;
    return _gated(() => super.dismissPairForUndo(a, b, expectedProjectId: expectedProjectId));
  }

  @override
  Future<bool> undoPairChange(PairChange change) async {
    undos++;
    final done = Completer<void>();
    pending = done.future;
    try {
      await undoGate?.future;
      return await super.undoPairChange(change);
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
  bool browse = true,
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
  await pumpUntil(tester, find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.map)));
  if (browse) {
    await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
    await pumpUntil(tester, find.byKey(ValueKey('browse-${notes.last.id}')));
  }
  return notes;
}

Finder get libraryScroll => find.descendant(
  of: find.byType(LinksLibraryScreen),
  matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
);
Future<void> librarySegment(WidgetTester tester, int segment) async {
  await tester.tap(find.byKey(LinksLibrarySegment.key(segment)));
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

/// Taps the real painted node through Flutter's world-to-screen transform.
Future<void> tapMapNode(WidgetTester tester, String id) async {
  final canvas = find.byKey(const ValueKey('map-paint'));
  final view = find.byKey(const ValueKey('map-viewport'));
  await Scrollable.ensureVisible(tester.element(view), alignment: .5);
  await tester.pump();
  final painter = tester.widget<CustomPaint>(canvas).painter! as LinksMapPainter;
  expect(painter.layout.positions, contains(id), reason: 'Visible Map nodes before tap: ${painter.nodes}');
  final p = painter.layout.positions[id]!;
  final box = tester.renderObject<RenderBox>(canvas);
  final viewport = find.byKey(const ValueKey('map-viewport'));
  if (!tester.getRect(viewport).deflate(8).contains(box.localToGlobal(Offset(p.x, p.y)))) {
    final controller = tester.widget<InteractiveViewer>(viewport).transformationController!;
    final scale = controller.value.getMaxScaleOnAxis();
    final centre = tester.getSize(viewport).center(Offset.zero);
    controller.value = Matrix4.identity()
      ..translateByDouble(centre.dx - p.x * scale, centre.dy - p.y * scale, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
    await tester.pump();
  }
  await tester.tapAt(box.localToGlobal(Offset(p.x, p.y)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
