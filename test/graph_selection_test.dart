import 'dart:ui' show CheckedState;

import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

Finder key(String s) => find.byKey(ValueKey(s));
Finder graphNode(String id) => find.descendant(of: key('graph-focus-$id'), matching: key(id));
bool selecting() => find.byType(SelectionHeader).evaluate().isNotEmpty;
Future<void> pick(WidgetTester tester, String id) async {
  await tester.longPress(graphNode(id));
  await tester.pump();
}

void main() {
  final en = enL10n;
  fikraTest(
    'stationary hold selects; taps toggle; lines, previews and frame controls are off; Back first',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      final group = await pumpFuture(tester, () => LocalGroupsRepository(db).create(notes.first.projectId, 'Empty'));
      await pumpAnimations(tester);
      await tester.tap(graphNode(notes.first.id));
      await pumpAnimations(tester);
      expect(find.text(en.openNote), findsOneWidget);
      await pick(tester, notes.first.id);
      expect(find.text(en.openNote), findsNothing);
      expect(selecting(), isTrue);
      expect(tester.getSemantics(graphNode(notes.first.id)).flagsCollection.isChecked, CheckedState.isTrue);
      expect(find.text(en.selectedCount(1)), findsOneWidget);
      expect(tester.widget<Icon>(key('graph-check-${notes.first.id}')).icon, Icons.check_circle_rounded);
      await tester.tap(graphNode(notes[1].id));
      await tester.pump();
      expect(find.text(en.selectedCount(2)), findsOneWidget);
      await tester.tap(graphNode(notes.first.id));
      await tester.pump();
      expect(find.text(en.selectedCount(1)), findsOneWidget);
      expect(find.text(en.openNote), findsNothing);
      await tapGraphEdge(tester, 'ab');
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(key('graph-group-options-${group.id}'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(BottomSheet), findsNothing);
      final bar = tester.getRect(find.byType(SelectionActionBar));
      expect(bar.bottom, lessThanOrEqualTo(tester.getRect(Tabs.finder(Tabs.links)).top));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(selecting(), isFalse);
      expect(graphPaint, findsOneWidget);
    },
  );

  fikraTest(
    'drag beyond slop and any second pointer cancel hold; pan, pinch and buttons work while selecting',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final tc = viewer.transformationController!;
      final start = tc.value.clone();
      var g = await tester.startGesture(tester.getCenter(graphNode(notes.first.id)));
      await tester.pump(const Duration(milliseconds: 100));
      await g.moveBy(const Offset(-30, 30));
      await tester.pump(const Duration(milliseconds: 700));
      await g.up();
      await tester.pump();
      expect(selecting(), isFalse);
      tc.value = start.clone();
      await tester.pump();
      g = await tester.startGesture(tester.getCenter(graphNode(notes.first.id)), pointer: 1);
      await tester.pump(const Duration(milliseconds: 200));
      final second = await tester.startGesture(tester.getCenter(graphNode(notes[1].id)), pointer: 2);
      await second.up(); // even a second finger that lifts before the deadline cancels
      await tester.pump(const Duration(milliseconds: 700));
      await g.up();
      await tester.pump();
      expect(selecting(), isFalse);
      tc.value = start.clone();
      await tester.pump();
      await pick(tester, notes.first.id);
      expect(selecting(), isTrue);
      final beforePan = tc.value.clone();
      await tester.dragFrom(tester.getCenter(graphNode(notes.first.id)), const Offset(-65, 45));
      await tester.pump();
      expect(tc.value, isNot(beforePan));
      final beforeZoom = tc.value.clone();
      await tester.tap(find.bySemanticsLabel(en.zoomIn));
      await tester.pump();
      expect(tc.value, isNot(beforeZoom));
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final beforePinch = tc.value.clone();
      final a = await tester.startGesture(center - const Offset(30, 0), pointer: 3);
      final b = await tester.startGesture(center + const Offset(30, 0), pointer: 4);
      await a.moveBy(const Offset(-25, 0));
      await b.moveBy(const Offset(25, 0));
      await tester.pump();
      await a.up();
      await b.up();
      expect(tc.value, isNot(beforePinch));
      expect(selecting(), isTrue);
    },
  );

  fikraTest(
    'deleted selections prune, leaving tab ends mode, and project switch clears it',
    locale: const Locale('en'),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      await pick(tester, notes.first.id);
      await tester.tap(graphNode(notes[1].id));
      await tester.pump();
      await pumpFuture(tester, () => LocalNotesRepository(db).delete(notes.first.id));
      await pumpAnimations(tester);
      expect(find.text(en.selectedCount(1)), findsOneWidget);
      await tester.tap(Tabs.finder(Tabs.notes));
      await pumpAnimations(tester);
      await tester.tap(Tabs.finder(Tabs.links));
      await pumpAnimations(tester);
      expect(selecting(), isFalse);
      await pick(tester, notes[1].id);
      final projects = LocalProjectsRepository(db);
      await pumpFuture(tester, () async {
        final p = await projects.create('Other');
        await projects.setCurrent(p.id);
      });
      await pumpAnimations(tester);
      expect(selecting(), isFalse);
    },
  );

  fikraTest('graph link action links two notes and Undo restores the suggestion', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    await pick(tester, notes.first.id);
    await tester.tap(graphNode(notes[1].id));
    await tester.pump();
    await tapAction(tester, 'link');
    expect(selecting(), isFalse);
    expect(
      (await allLinks(
        tester,
        db,
      )).where((l) => l.origin.name == 'user' && {l.sourceId, l.targetId}.containsAll([notes.first.id, notes[1].id])),
      hasLength(1),
    );
    await tester.tap(find.text(en.undo));
    await pumpAnimations(tester);
    expect((await allLinks(tester, db)).firstWhere((l) => l.id == 'ab').origin.name, 'ai');
  });

  fikraTest('graph group action uses existing picker and Undo', locale: const Locale('en'), (tester, db) async {
    phone(tester);
    final notes = await seedGraph(tester, db);
    final group = await pumpFuture(tester, () => LocalGroupsRepository(db).create(notes.first.projectId, 'Target'));
    await pumpAnimations(tester);
    await pick(tester, notes.first.id);
    await tapAction(tester, 'group');
    await tester.tap(key('group-pick-${group.id}'));
    await pumpAnimations(tester);
    expect(selecting(), isFalse);
    expect((await readNote(tester, db, notes.first.id)).groupId, group.id);
    await tester.tap(find.text(en.undo));
    await pumpAnimations(tester);
    expect((await readNote(tester, db, notes.first.id)).groupId, isNull);
  });

  fikraTest(
    'graph move and delete actions use confirmations and leave the selection',
    locale: const Locale('en'),
    aiService: QuietAi(),
    (tester, db) async {
      phone(tester);
      final notes = await seedGraph(tester, db);
      final other = await pumpFuture(tester, () async {
        final repo = LocalProjectsRepository(db);
        final p = await repo.create('Other');
        await repo.setCurrent(notes.first.projectId);
        return p;
      });
      await pumpAnimations(tester);
      await pick(tester, notes.first.id);
      await tapAction(tester, 'move');
      await tester.tap(key('project-pick-${other.id}'));
      await settle(tester, find.byType(Dialog));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(en.moveConfirm)));
      await pumpAnimations(tester);
      expect((await readNote(tester, db, notes.first.id)).projectId, other.id);
      expect(selecting(), isFalse);
      await waitOutToast(tester);
      await pick(tester, notes[1].id);
      await tapAction(tester, 'delete');
      await settle(tester, find.byType(Dialog));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(en.delete)));
      await pumpAnimations(tester);
      expect(graphNode(notes[1].id), findsNothing);
      expect(selecting(), isFalse);
    },
  );
}
