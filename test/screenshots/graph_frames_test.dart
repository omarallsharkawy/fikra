@Tags(['screenshots'])
library;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../graph_fixture.dart';
import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'group frames, selection and focus (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        tags: 'screenshots',
        (tester, db) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          addTearDown(tester.view.reset);
          final ar = locale.languageCode == 'ar';
          final notes = await seedGraph(tester, db, arabic: ar);
          final repo = LocalGroupsRepository(db);
          final emptyId = await pumpFuture(tester, () async {
            final p = await repo.create(notes.first.projectId, ar ? 'فكرة التطبيق' : 'App ideas', color: 0);
            final c = await repo.create(notes.first.projectId, ar ? 'البحث' : 'Research', parentId: p.id, color: 1);
            final empty = await repo.create(notes.first.projectId, ar ? 'مجموعة فاضية' : 'Empty group', color: 2);
            await repo.assignNotes(p.id, [notes[0].id, notes[1].id]);
            await repo.assignNotes(c.id, [notes[2].id]);
            await (db.update(db.notes)..where((n) => n.id.isIn(notes.skip(3).map((n) => n.id)))).write(
              NotesCompanion(cluster: Value(ar ? 'الخطوة الجاية' : 'Next steps')),
            );
            return empty.id;
          });
          await pumpUntil(tester, find.byKey(ValueKey('graph-frame-$emptyId')));
          await tester.pump(const Duration(milliseconds: 600));
          final tc = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
          final layout = graphPaths(tester).layout;
          tc.value = Matrix4.translationValues(ar ? 390 - layout.width * 0.65 : 0, 0, 0)
            ..scaleByDouble(0.65, 0.65, 1, 1);
          await tester.pump();
          final prefix = '${locale.languageCode}/${brightness.name}';
          await saveScreenshot(tester, '$prefix/57_graph_groups');
          await tester.longPress(find.byKey(ValueKey(notes.first.id)));
          await tester.pump();
          await saveScreenshot(tester, '$prefix/59_graph_selection');
          await tester.tap(find.byKey(const ValueKey('selection-close')));
          await tester.pump();
          await tester.tap(find.byKey(ValueKey(notes.first.id)));
          await tester.pump();
          await saveScreenshot(tester, '$prefix/60_graph_frame_focus');
          await pumpFuture(tester, () async {
            await db.delete(db.notes).go();
            await (db.delete(db.noteGroups)..where((g) => g.id.isNotValue(emptyId))).go();
          });
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump();
          await saveScreenshot(tester, '$prefix/58_graph_empty');
        },
      );
    }
  }
}
