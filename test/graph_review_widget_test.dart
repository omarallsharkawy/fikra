import 'dart:ui' show GestureSettings, Tristate;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/format.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'graph_route_assertions.dart';
import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

Finder k(String id) => find.byKey(ValueKey(id));
Finder card(String id) => find.descendant(of: k('graph-focus-$id'), matching: k(id));

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest('empty canvas aligns to logical start and summary fits (${locale.languageCode})', locale: locale, (
      t,
      db,
    ) async {
      phone(t);
      final notes = await seedGraph(t, db, arabic: locale.languageCode == 'ar');
      final group = await pumpFuture(t, () async {
        final g = await LocalGroupsRepository(db).create(notes.first.projectId, 'Empty');
        await db.delete(db.notes).go();
        return g;
      });
      await settle(t, k('graph-frame-${group.id}'));
      final r = t.getRect(k('graph-frame-${group.id}'));
      expect(locale.languageCode == 'ar' ? 390 - r.right : r.left, closeTo(24, 0.1));
      final l = locale.languageCode == 'ar' ? arL10n : enL10n;
      final summary = find.text(l.linksSummary(Fmt.notes(l, 0), Fmt.links(l, 0)));
      expect(t.getSize(summary).width, greaterThan(180));
      expect(t.renderObject<RenderParagraph>(summary).didExceedMaxLines, isFalse);
    });
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest(
      'measured short labels and suggested title fit their rendered style (${locale.languageCode})',
      locale: locale,
      (t, db) async {
        phone(t, height: 1200);
        final notes = await seedGraph(t, db, arabic: locale.languageCode == 'ar');
        final group = await pumpFuture(t, () => LocalGroupsRepository(db).create(notes.first.projectId, 'Empty'));
        await settle(t, k('graph-frame-${group.id}'));
        final layout = graphPaths(t).layout;
        for (final label in layout.labels) {
          final target = label.row == null
              ? find.text(locale.languageCode == 'ar' ? arL10n.suggestedTopics : enL10n.suggestedTopics)
              : k('graph-cluster-${label.row!.index}');
          final paragraph = t.renderObject<RenderParagraph>(target);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.textSize.height, lessThanOrEqualTo(label.bounds.height));
          if (label.control != null) {
            final control = k('graph-make-group-${label.row!.index}');
            final box = t.renderObject<RenderBox>(graphPaint);
            final actual = Rect.fromPoints(
              box.globalToLocal(t.getTopLeft(control)),
              box.globalToLocal(t.getBottomRight(control)),
            );
            expect(actual.left, closeTo(label.control!.left, 0.01));
            expect(actual.top, closeTo(label.control!.top, 0.01));
            expect(actual.size, const Size(48, 48));
          }
        }
      },
    );
  }

  fikraTest('device slop cancels a hold before a small slow drag can start selection', locale: const Locale('en'), (
    t,
    db,
  ) async {
    phone(t);
    // The physical slop is divided by DPR by MediaQuery (8 logical pixels).
    t.view.gestureSettings = const GestureSettings(physicalTouchSlop: 24);
    final notes = await seedGraph(t, db);
    final g = await t.startGesture(t.getCenter(card(notes.first.id)));
    await t.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(9, 0));
    await t.pump(const Duration(milliseconds: 600));
    await g.up();
    await t.pump();
    expect(find.byType(SelectionHeader), findsNothing);
  });

  fikraTest('viewer interaction start cancels a pending hold even below raw slop', locale: const Locale('en'), (
    t,
    db,
  ) async {
    phone(t);
    final notes = await seedGraph(t, db);
    final g = await t.startGesture(t.getCenter(card(notes.first.id)));
    await t.pump(const Duration(milliseconds: 100));
    t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).onInteractionStart!(ScaleStartDetails());
    await t.pump(const Duration(milliseconds: 600));
    await g.up();
    await t.pump();
    expect(find.byType(SelectionHeader), findsNothing);
  });

  fikraTest(
    'card semantics name groups and traverse header, own cards, child, child cards',
    locale: const Locale('en'),
    (t, db) async {
      phone(t, height: 1600);
      final notes = await seedGraph(t, db);
      final gs = await pumpFuture(t, () async {
        final repo = LocalGroupsRepository(db);
        final p = await repo.create(notes.first.projectId, 'Parent');
        final c = await repo.create(notes.first.projectId, 'Child', parentId: p.id);
        await repo.assignNotes(p.id, [notes[0].id]);
        await repo.assignNotes(c.id, [notes[1].id]);
        return [p, c];
      });
      await settle(t, k('graph-frame-${gs.last.id}'));
      final layout = graphPaths(t).layout;
      expectClearGraphInk(layout);

      expect(t.getSemantics(card(notes[0].id)).label, enL10n.graphNoteInGroup(notes[0].title, 'Parent'));
      expect(t.getSemantics(card(notes[1].id)).label, enL10n.graphNoteInGroup(notes[1].title, 'Child'));
      final labels = <String>[];
      void walk(SemanticsNode n) {
        labels.add(n.label);
        for (final c in n.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)) {
          walk(c);
        }
      }

      walk(t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
      final p = labels.indexWhere((l) => l.startsWith('Group Parent,')),
          own = labels.indexOf(enL10n.graphNoteInGroup(notes[0].title, 'Parent'));
      final c = labels.indexWhere((l) => l.startsWith('Group Child,')),
          child = labels.indexOf(enL10n.graphNoteInGroup(notes[1].title, 'Child'));
      expect(p, greaterThanOrEqualTo(0));
      expect(own, greaterThan(p));
      expect(c, greaterThan(own));
      expect(child, greaterThan(c));
    },
  );

  fikraTest(
    'selection visibly disables frame/topic/overflow controls and removes tap semantics',
    locale: const Locale('en'),
    (t, db) async {
      phone(t, height: 1200);
      final notes = await seedGraph(t, db);
      final g = await pumpFuture(t, () async {
        final repo = LocalGroupsRepository(db);
        final g = await repo.create(notes.first.projectId, 'Waiting');
        await repo.assignNotes(g.id, [notes.first.id]);
        await (db.update(db.notes)..where((n) => n.id.equals(notes.first.id))).write(
          const NotesCompanion(status: Value(ProcessingStatus.processing)),
        );
        return g;
      });
      await settle(t, k('graph-frame-${g.id}'));
      await t.longPress(card(notes[2].id));
      await t.pump();
      expect(find.byType(SelectionHeader), findsOneWidget);
      final controls = [
        k('graph-group-options-${g.id}'),
        k('graph-make-group-${graphPaths(t).layout.rows.firstWhere((r) => r.groupId == null && r.canMakeGroup).index}'),
        find.text('+1'),
      ];
      for (final target in controls) {
        final press = find.descendant(of: target, matching: find.byType(Pressable));
        final widget = press.evaluate().isEmpty
            ? t.widget<Pressable>(find.ancestor(of: target, matching: find.byType(Pressable)).first)
            : t.widget<Pressable>(press.first);
        expect(widget.onTap, isNull);
        final node = t.getSemantics(target);
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      }
      for (final target in controls.take(2)) {
        expect(t.widget<Opacity>(find.ancestor(of: target, matching: find.byType(Opacity)).first).opacity, 0.4);
      }
    },
  );

  fikraTest('frame overflow sheet and announcement contain only actually hidden notes', locale: const Locale('en'), (
    t,
    db,
  ) async {
    phone(t);
    final notes = await seedGraph(t, db);
    await pumpFuture(t, () async {
      final repo = LocalGroupsRepository(db);
      final g = await repo.create(notes.first.projectId, 'Large');
      for (var i = 0; i < 245; i++) {
        await db
            .into(db.notes)
            .insert(notes.first.copyWith(id: 'large-$i', title: 'Large $i', status: ProcessingStatus.ready));
      }
      await repo.assignNotes(g.id, (await db.select(db.notes).get()).map((n) => n.id));
    });
    await pumpUntil(t, find.text('+11'));
    await pumpAnimations(t);
    final l = graphPaths(t).layout, row = l.rows.last;
    expect(row.hiddenCount, 11);
    final tc = t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
    final p = l.positionInRow(row.index, row.visible.length);
    tc.value = Matrix4.translationValues(60 - p.left, 80 - p.top, 0);
    await t.pump();
    expect(t.getSemantics(find.text('+11')).label, enL10n.showGroupA11y(Fmt.notes(enL10n, 11), 'Large'));
    await t.tap(find.text('+11'));
    await settle(t, find.byType(BottomSheet));
    final sheet = find.byType(BottomSheet);
    final list = find.descendant(of: sheet, matching: find.byType(ListView));
    expect(t.widget<ListView>(list).childrenDelegate.estimatedChildCount, 11);
    final titles = <String>{};
    void collect() {
      final tiles = find.descendant(of: sheet, matching: find.byType(ListTile));
      for (final w in t.widgetList<ListTile>(tiles)) {
        titles.add((w.title! as Text).data!);
      }
    }

    collect();
    await t.scrollUntilVisible(
      find.descendant(of: sheet, matching: find.text(row.hiddenNotes.last.title)),
      200,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first,
    );
    await t.pump();
    collect();
    expect(titles, row.hiddenNotes.map((n) => n.title).toSet());
    expect(titles.any((s) => row.visible.any((n) => n.title == s)), isFalse);
  });
}
