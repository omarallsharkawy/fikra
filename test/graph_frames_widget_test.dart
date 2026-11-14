import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/format.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/shared/note_groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

Finder key(String s) => find.byKey(ValueKey(s));

void main() {
  final en = enL10n;
  Future<void> options(WidgetTester t, String id) async {
    await t.tap(key('graph-group-options-$id'));
    await settle(t, key('group-rename'));
  }

  fikraTest(
    'frame options rename, recolour, nest, unnest and delete the right live group',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester, height: 1400);
      final notes = await seedGraph(tester, db);
      final repo = LocalGroupsRepository(db);
      final gs = await pumpFuture(tester, () async {
        final a = await repo.create(notes.first.projectId, 'First');
        final b = await repo.create(notes.first.projectId, 'Second');
        await repo.assignNotes(a.id, [notes.first.id]);
        return [a, b];
      });
      final a = gs.first, b = gs.last;
      await settle(tester, key('graph-frame-${b.id}'));
      await options(tester, a.id);
      await tester.tap(key('group-rename'));
      final field = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
      await settle(tester, field);
      await tester.enterText(field, 'Renamed');
      await tester.tap(key('group-rename-save'));
      await settle(tester, find.text('Renamed'));
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);

      await options(tester, a.id);
      await tester.tap(key('group-color'));
      await settle(tester, key('group-color-2'));
      await tester.tap(key('group-color-2'));
      await pumpUntil(tester, find.text('Renamed'));
      await pumpAnimations(tester);
      final frame = tester.widget<Semantics>(key('graph-frame-${a.id}'));
      final container = frame.child! as Container;
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, groupColor(tester.element(key('graph-frame-${a.id}')), 2));

      await options(tester, a.id);
      await tester.tap(key('group-nest'));
      await settle(tester, key('group-parent-pick-${b.id}'));
      await tester.tap(key('group-parent-pick-${b.id}'));
      await pumpAnimations(tester);
      await pumpUntil(tester, key('graph-frame-${a.id}'));
      var l = graphPaths(tester).layout;
      expect(l.frames.first.group.id, b.id);
      expect(l.frames.last.group.parentId, b.id);
      expect(l.frames.last.bounds.top, greaterThan(l.frames.first.bounds.top));
      expect(l.frames.first.bounds.height, greaterThan(l.frames.last.bounds.height));

      await options(tester, a.id);
      await tester.tap(key('group-unnest'));
      await pumpAnimations(tester);
      l = graphPaths(tester).layout;
      expect(l.frames.first.group.id, a.id);
      expect(l.frames.first.group.parentId, isNull);

      await options(tester, a.id);
      await tester.tap(key('group-delete'));
      await settle(tester, find.byType(Dialog));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(en.delete)));
      await pumpAnimations(tester);
      await pumpUntil(tester, key('graph-frame-${b.id}'));
      expect(key('graph-frame-${a.id}'), findsNothing);
      expect((await readNote(tester, db, notes.first.id)).groupId, isNull);
      expect((await allGroups(tester, db)).single.id, b.id);
    },
  );

  fikraTest(
    'topic conversion includes hidden and non-ready ungrouped notes, guards double taps, and Undo',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      await pumpFuture(tester, () async {
        for (var i = 0; i < 70; i++) {
          await db
              .into(db.notes)
              .insert(
                notes.first.copyWith(
                  id: 'topic-$i',
                  title: 'Topic $i',
                  cluster: const Value('Topic'),
                  status: i == 69 ? ProcessingStatus.processing : ProcessingStatus.ready,
                ),
              );
        }
        final group = await LocalGroupsRepository(db).create(notes.first.projectId, 'Already grouped');
        await (db.update(db.notes)..where((n) => n.id.equals(notes.last.id))).write(
          NotesCompanion(cluster: const Value('Topic'), groupId: Value(group.id)),
        );
      });
      await pumpAnimations(tester);
      final l = graphPaths(tester).layout;
      final row = l.rows.firstWhere((r) => r.cluster == 'Topic');
      expect(row.hiddenCount, greaterThan(0));
      // Topic is after the first frame; move the viewport to it.
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      viewer.transformationController!.value = Matrix4.translationValues(0, -row.labelTop + 60, 0);
      await tester.pump();
      final button = key('graph-make-group-${row.index}');
      final at = tester.getCenter(button);
      await tester.tapAt(at);
      await tester.tapAt(at);
      await settle(tester, find.text(en.undo));
      final groups = await allGroups(tester, db);
      expect(groups.where((g) => g.name == 'Topic'), hasLength(1));
      final target = groups.firstWhere((g) => g.name == 'Topic');
      final assigned = await pumpFuture(
        tester,
        () => (db.select(db.notes)..where((n) => n.id.isIn([for (var i = 0; i < 70; i++) 'topic-$i']))).get(),
      );
      expect(assigned, hasLength(70));
      expect(assigned.every((n) => n.groupId == target.id), isTrue);
      expect((await readNote(tester, db, notes.last.id)).groupId, isNot(target.id));
      await tester.tap(find.text(en.undo));
      await pumpAnimations(tester);
      await pumpUntil(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.key == const ValueKey('graph-edges') &&
              !(w.painter as dynamic).paths.layout.frames.any((f) => f.group.id == target.id),
        ),
      );
      expect((await allGroups(tester, db)).any((g) => g.id == target.id), isFalse);
      expect((await readNote(tester, db, 'topic-0')).groupId, isNull);
      expect((await readNote(tester, db, 'topic-69')).groupId, isNull);
    },
  );

  fikraTest(
    'empty project group still renders; blank topic uses fallback without a conversion control',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      await pumpFuture(tester, () async {
        await LocalGroupsRepository(db).create(notes.first.projectId, 'Empty');
        await (db.update(db.notes)).write(const NotesCompanion(cluster: Value('')));
      });
      await pumpAnimations(tester);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text(en.clusterGeneral), findsOneWidget);
      expect(key('graph-make-group-0'), findsNothing);
      final semantics = tester.getSemantics(key('graph-frame-${(await allGroups(tester, db)).single.id}'));
      expect(semantics.label, contains('Empty'));
      expect(semantics.label, en.graphGroupA11y('Empty', Fmt.notes(en, 0)));
      await pumpFuture(tester, () => db.delete(db.notes).go());
      await pumpAnimations(tester);
      expect(find.text('Empty'), findsOneWidget);
      expect(graphPaint, findsOneWidget);
    },
  );

  fikraTest(
    'focus fades unrelated frames and preserves a parent containing a highlighted child',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester, height: 1400);
      final notes = await seedGraph(tester, db);
      final repo = LocalGroupsRepository(db);
      final gs = await pumpFuture(tester, () async {
        final p = await repo.create(notes.first.projectId, 'Parent', color: 1);
        final c = await repo.create(notes.first.projectId, 'Child', parentId: p.id, color: 2);
        final u = await repo.create(notes.first.projectId, 'Unrelated', color: 0);
        await repo.assignNotes(c.id, [notes.first.id]);
        await repo.assignNotes(u.id, [notes.last.id]);
        return [p, c, u];
      });
      await pumpAnimations(tester);
      Color border(String id) {
        final w = tester.widget<Semantics>(key('graph-frame-$id'));
        return ((w.child! as Container).decoration! as BoxDecoration).border!.top.color;
      }

      final colors = gs.map((g) => border(g.id)).toList();
      await tester.tap(key(notes.first.id));
      await tester.pump();
      expect(border(gs[0].id), colors[0]);
      expect(border(gs[1].id), colors[1]);
      expect(border(gs[2].id), isNot(colors[2]));
      expect(find.text(en.openNote), findsOneWidget);
      await tester.tapAt(tester.getTopLeft(key('graph-frame-${gs.first.id}')) + const Offset(80, 20));
      await tester.pump();
      expect(find.text(en.openNote), findsOneWidget); // blank header space is inert
    },
  );
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest('frame header scales and keeps 48 dp labelled options (${locale.languageCode})', locale: locale, (
      tester,
      db,
    ) async {
      phone(tester);
      final notes = await seedGraph(tester, db, arabic: locale.languageCode == 'ar');
      final g = await pumpFuture(
        tester,
        () => LocalGroupsRepository(db).create(notes.first.projectId, 'Long group name ' * 8),
      );
      await pumpAnimations(tester);
      await host(
        tester,
        const LinksScreen(),
        locale: locale,
        scale: 3,
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      await settle(tester, key('graph-frame-${g.id}'));
      final frame = graphPaths(tester).layout.frames.single;
      expect(frame.header.height, greaterThan(64));
      final control = key('graph-group-options-${g.id}');
      expect(tester.getSize(control), const Size(48, 48));
      expect(tester.getSemantics(control).label, contains(g.name));
      expect(tester.takeException(), isNull);
    });
  }
}
