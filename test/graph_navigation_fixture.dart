import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'support/app_harness.dart';

Finder navKey(String id) => find.byKey(ValueKey(id));
Future<void> navPump(WidgetTester t) async {
  await t.pump();
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
  await t.pump();
}

void navPhone(WidgetTester t, {double height = 844}) {
  t.view.devicePixelRatio = 3;
  t.view.physicalSize = Size(390 * 3, height * 3);
  addTearDown(t.view.reset);
}

TransformationController navController(WidgetTester t) =>
    t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;

Future<({List<Note> notes, NoteGroup parent, NoteGroup child, NoteGroup other})> seedNavigation(
  WidgetTester t,
  FikraDatabase db, {
  bool arabic = false,
}) async {
  final notes = await seedGraph(t, db, arabic: arabic);
  final repo = LocalGroupsRepository(db);
  final groups = await pumpFuture(t, () async {
    final parent = await repo.create(notes.first.projectId, arabic ? 'مجموعة الأفكار' : 'Ideas group', color: 0);
    final child = await repo.create(
      notes.first.projectId,
      arabic ? 'البحث' : 'Research',
      parentId: parent.id,
      color: 1,
    );
    final other = await repo.create(notes.first.projectId, arabic ? 'التجارب' : 'Trials', color: 2);
    await repo.assignNotes(parent.id, [notes[0].id, notes[1].id]);
    await repo.assignNotes(child.id, [notes[2].id]);
    await repo.assignNotes(other.id, [notes[3].id, notes[4].id]);
    return (parent: parent, child: child, other: other);
  });
  await pumpUntil(t, navKey('graph-frame-${groups.other.id}'));
  await navPump(t);
  return (notes: notes, parent: groups.parent, child: groups.child, other: groups.other);
}

Future<void> graphQuery(WidgetTester t, String text) async {
  await t.tap(navKey('graph-search-open'));
  await t.pump();
  await t.enterText(find.descendant(of: navKey('graph-search-field'), matching: find.byType(TextField)), text);
  await t.pump();
}

void expectCentred(WidgetTester t, Offset point) {
  final m = navController(t).value;
  final actual = MatrixUtils.transformPoint(m, point);
  final size = t.getSize(find.byType(InteractiveViewer));
  expect(actual.dx, closeTo(size.width / 2, 0.01));
  expect(actual.dy, closeTo(size.height / 2, 0.01));
}

/// One parent row of five notes: the widest frame, wider than a phone at the
/// minimum zoom. The "other" group is left empty (header only).
Future<void> widenParent(WidgetTester t, FikraDatabase db, NoteGroup parent, List<Note> notes) async {
  await pumpFuture(
    t,
    () => LocalGroupsRepository(db).assignNotes(parent.id, [
      for (final i in [0, 1, 3, 4, 5]) notes[i].id,
    ]),
  );
  await navPump(t);
}

double viewScale(WidgetTester t) => navController(t).value.entry(0, 0);
Rect sceneOnScreen(WidgetTester t, Rect scene) => MatrixUtils.transformRect(navController(t).value, scene);
