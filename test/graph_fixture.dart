import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/local/database.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/links/graph_edge_paths.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

Future<List<Note>> seedGraph(WidgetTester tester, FikraDatabase db, {bool arabic = false}) async {
  final l10n = lookupAppLocalizations(Locale(arabic ? 'ar' : 'en'));
  await pumpUntil(tester, find.text(l10n.startNewProject));
  final notes = await pumpFuture(tester, () async {
    final project = await LocalProjectsRepository(db).create(arabic ? 'أفكاري' : 'My ideas');
    final titles = arabic
        ? ['فكرة التطبيق', 'البحث', 'تجربة أولى', 'مراجعة', 'ملاحظة تانية', 'تفاصيل']
        : ['App idea', 'Search', 'First trial', 'Review', 'Another note', 'Details'];
    final clusters = arabic ? ['أفكار', 'تجارب', 'بعد كده'] : ['Ideas', 'Trials', 'Later'];
    final repo = LocalNotesRepository(db);
    final result = <Note>[];
    for (var i = 0; i < titles.length; i++) {
      final note = await repo.create(
        projectId: project.id,
        title: titles[i],
        text: titles[i],
        source: NoteSource.text,
        createdAt: DateTime(2026, 11, 1 + i),
      );
      await repo.markReady(note.id);
      await (db.update(
        db.notes,
      )..where((n) => n.id.equals(note.id))).write(NotesCompanion(cluster: Value(clusters[i ~/ 2])));
      result.add(note);
    }
    for (final (id, a, b, origin, label) in [
      ('ac', 0, 2, LinkOrigin.user, arabic ? 'نجرب الفكرة' : 'Try the idea'),
      (
        'ab',
        0,
        1,
        LinkOrigin.ai,
        arabic ? 'موضوع مشترك طويل عشان نراجع شكل السبب' : 'A shared topic with a long reason to check ellipsis',
      ),
      ('ad', 0, 3, LinkOrigin.ai, ''),
      ('cd', 2, 3, LinkOrigin.user, arabic ? 'مراجعة التجربة' : 'Review the trial'),
      ('ef', 4, 5, LinkOrigin.user, arabic ? 'تفاصيل بعدين' : 'Details for later'),
    ]) {
      await db
          .into(db.noteLinks)
          .insert(
            NoteLink(
              id: id,
              projectId: project.id,
              sourceId: result[a].id,
              targetId: result[b].id,
              origin: origin,
              label: label,
              strength: 0.5,
              dismissed: false,
            ),
          );
    }
    return result;
  });
  await pumpUntil(tester, find.text(notes.last.title));
  await tester.tap(Tabs.finder(Tabs.links));
  await pumpUntil(tester, find.byKey(const ValueKey('graph-edges')));
  await tester.pump(const Duration(milliseconds: 500));
  return notes;
}

Finder get graphPaint => find.byKey(const ValueKey('graph-edges'));
GraphEdgePaths graphPaths(WidgetTester tester) =>
    (tester.widget<CustomPaint>(graphPaint).painter as dynamic).paths as GraphEdgePaths;

Future<void> tapGraphEdge(WidgetTester tester, String id) async {
  final edge = graphPaths(tester).edges.firstWhere((e) => e.geometry.link.id == id).geometry;
  final box = tester.renderObject<RenderBox>(graphPaint);
  await tester.tapAt(box.localToGlobal(Offset(edge.middle.x, edge.middle.y)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Text graphCardText(WidgetTester tester, String id) =>
    tester.widget<Text>(find.descendant(of: find.byKey(ValueKey('graph-focus-$id')), matching: find.byType(Text)));
bool graphCardDimmed(WidgetTester tester, String id) {
  final key = find.byKey(ValueKey('graph-focus-$id'));
  expect(tester.widget(key), isNot(isA<Opacity>()));
  final color = graphCardText(tester, id).style!.color!;
  final palette = tester.element(key).colors;
  return color != palette.textPrimary && color != palette.accent;
}
