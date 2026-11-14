import 'package:fikra/app/providers.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'graph_navigation_fixture.dart';
import 'support/app_harness.dart';
import 'support/selection_fixture.dart' show host;

void expectMatrix(Matrix4 actual, Matrix4 expected) {
  for (var i = 0; i < 16; i++) {
    expect(actual.storage[i], closeTo(expected.storage[i], 1e-6));
  }
}

void main() {
  setUpAll(loadAppFonts);
  for (final ar in [false, true]) {
    final locale = Locale(ar ? 'ar' : 'en');
    fikraTest('first/last group preserve pan and zoom; project switch re-homes (ar=$ar)', locale: locale, (
      t,
      db,
    ) async {
      navPhone(t);
      final notes = await seedGraph(t, db, arabic: ar);
      final before = graphPaths(t).layout;
      final original = Matrix4.translationValues(-137, -91, 0)..scaleByDouble(0.8, 0.8, 0.8, 1);
      navController(t).value = original.clone();
      await t.pump();
      final repo = LocalGroupsRepository(db);
      final group = await pumpFuture(t, () async {
        final g = await repo.create(notes.first.projectId, 'First');
        await repo.assignNotes(g.id, notes.map((n) => n.id).toList());
        return g;
      });
      await navPump(t);
      final after = graphPaths(t).layout;
      expect(after.width, isNot(before.width));
      final expected = original.clone();
      if (ar) expected.setEntry(0, 3, original.entry(0, 3) + (before.width - after.width) * 0.8);
      expectMatrix(navController(t).value, expected);
      await pumpFuture(t, () => repo.delete(group.id));
      await navPump(t);
      expect(graphPaths(t).layout.frames, isEmpty);
      expectMatrix(navController(t).value, original);

      await pumpFuture(t, () async {
        final other = await LocalProjectsRepository(db).create('Other');
        await repo.create(other.id, 'Other group');
      });
      await pumpUntil(t, find.text('Other group'));
      await navPump(t);
      final layout = graphPaths(t).layout;
      final size = t.getSize(find.byType(InteractiveViewer));
      expectMatrix(navController(t).value, Matrix4.translationValues(ar ? size.width - layout.width : 0, 0, 0));
    });

    fikraTest('wrapped header does not move canvas on selection at 320dp/2x (ar=$ar)', locale: locale, (t, db) async {
      navPhone(t);
      final notes = await seedGraph(t, db, arabic: ar);
      await pumpFuture(t, () => LocalGroupsRepository(db).create(notes.first.projectId, ar ? 'مجموعة' : 'Group'));
      await host(t, const LinksScreen(), locale: locale, scale: 2, overrides: [databaseProvider.overrideWithValue(db)]);
      t.view.physicalSize = const Size(320, 1100);
      await pumpUntil(t, navKey(notes.first.id));
      await navPump(t);
      final viewer = find.byType(InteractiveViewer);
      final top = t.getTopLeft(viewer).dy;
      final card = navKey(notes.first.id);
      final where = t.getCenter(card);
      await t.longPress(card);
      await navPump(t);
      expect(find.byType(SelectionHeader), findsOneWidget);
      expect(t.getTopLeft(viewer).dy, top);
      expect(t.getCenter(card), where);
      await t.tap(navKey('selection-close'));
      await navPump(t);
      expect(t.getTopLeft(viewer).dy, top);
      expect(t.getCenter(card), where);
      expect(t.takeException(), isNull);
    });
  }
}
