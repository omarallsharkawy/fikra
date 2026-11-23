import 'dart:async';

import 'package:fikra/core/format.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

// Undo and overlapping actions in the notes list's selection mode (links
// phase 5a review): one action or Undo at a time, an older action never
// ends a newer selection, and Undo only puts back what is still as the
// action left it.
void main() {
  final ar = arL10n;
  bool selecting() => find.byType(SelectionHeader).evaluate().isNotEmpty;
  Finder key(String k) => find.byKey(ValueKey(k));
  final sheetField = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
  Future<NoteGroup> makeGroup(WidgetTester tester, FikraDatabase db, String projectId, String name) =>
      pumpFuture(tester, () => LocalGroupsRepository(db).create(projectId, name));
  Future<void> assign(WidgetTester tester, FikraDatabase db, NoteGroup? g, List<Note> notes) =>
      pumpFuture(tester, () => LocalGroupsRepository(db).assignNotes(g?.id, [for (final n in notes) n.id]));
  Future<String?> groupOf(WidgetTester tester, FikraDatabase db, Note n) async =>
      (await readNote(tester, db, n.id)).groupId;
  Future<void> undo(WidgetTester tester) async {
    await tester.tap(find.text(ar.undo));
    await pumpAnimations(tester);
    await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }

  late SpyLinks links;
  fikraTest('a slow Undo holds every action until it ends', linksRepository: (db) => links = SpyLinks(db), (
    tester,
    db,
  ) async {
    phone(tester);
    final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
    await select(tester, [a, b]);
    await tapAction(tester, 'link');
    await settle(tester, find.text(ar.linksAdded(1)));
    links.undoGate = Completer<void>();
    await tester.tap(find.text(ar.undo));
    await pumpAnimations(tester);

    await select(tester, [c]);
    await tapAction(tester, 'group');
    expect(find.text(ar.chooseGroup), findsNothing); // held while Undo runs
    expect(selecting(), isTrue);

    links.undoGate!.complete();
    await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(await userPairs(tester, db), isEmpty);
    await tapAction(tester, 'group');
    expect(find.text(ar.chooseGroup), findsOneWidget);
  });

  fikraTest(
    'an action finishing late ends only the selection it started from',
    linksRepository: (db) => links = SpyLinks(db),
    (tester, db) async {
      phone(tester);
      final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
      links.linkGate = Completer<void>();
      await select(tester, [a, b]);
      await tapAction(tester, 'link');
      await tester.binding.handlePopRoute(); // Back while linking
      await pumpAnimations(tester);
      expect(selecting(), isFalse);
      await tester.longPress(card(c.id));
      await tester.pump();
      expect(find.text(ar.selectedCount(1)), findsOneWidget);

      links.linkGate!.complete();
      await settle(tester, find.text(ar.linksAdded(1)));
      expect(selecting(), isTrue);
      expect(find.text(ar.selectedCount(1)), findsOneWidget);
    },
  );

  fikraTest('Undo of "link together" puts back the suggestion, the rejection and no row', (tester, db) async {
    phone(tester);
    final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
    await insertLink(tester, db, b, a, origin: LinkOrigin.ai); // a suggestion
    await insertLink(tester, db, a, c, origin: LinkOrigin.ai, dismissed: true); // rejected
    final before = await allLinks(tester, db);
    await select(tester, [a, b, c]);
    await tapAction(tester, 'link');
    await settle(tester, find.text(ar.linksAdded(3)));
    expect((await userPairs(tester, db)).length, 3);
    await undo(tester);
    expect(await allLinks(tester, db), unorderedEquals(before));
  });

  fikraTest('Undo of "link together" leaves notes moved or deleted meanwhile alone', (tester, db) async {
    phone(tester, height: 1100);
    final (_, q, [a, b, c, d]) = await seedNotes(tester, db, ['A', 'B', 'C', 'D']);
    await select(tester, [a, b, c, d]);
    await tapAction(tester, 'link');
    await settle(tester, find.text(ar.linksAdded(6)));
    final repo = LocalNotesRepository(db);
    await pumpFuture(tester, () => repo.moveNotes([c.id, d.id], q.id)); // c–d goes with them
    await pumpFuture(tester, () => repo.delete(b.id));
    await tester.pump();
    await undo(tester);
    expect(find.text(ar.undoFailed), findsNothing);
    expect(await userPairs(tester, db), {
      {c.id, d.id},
    });
    expect((await allLinks(tester, db)).single.projectId, q.id);
  });

  fikraTest('grouping Undo leaves moved and regrouped notes alone; a deleted old group means none', (tester, db) async {
    phone(tester, height: 1100);
    final (p, q, [a, b, c, d]) = await seedNotes(tester, db, ['A', 'B', 'C', 'D']);
    final old = await makeGroup(tester, db, p.id, 'Old');
    final target = await makeGroup(tester, db, p.id, 'Target');
    final later = await makeGroup(tester, db, p.id, 'Later');
    final there = await makeGroup(tester, db, q.id, 'There');
    await assign(tester, db, old, [b, c]);
    await select(tester, [a, b, c, d]);
    await tapAction(tester, 'group');
    await tester.tap(key('group-pick-${target.id}'));
    await settle(tester, find.text(ar.notesGrouped(Fmt.notes(ar, 4), Fmt.isolate('Target'))));

    // While the toast is up: a moves to Work and gets a group there, d is
    // regrouped, and b and c's old group is deleted.
    await pumpFuture(tester, () => LocalNotesRepository(db).moveNotes([a.id], q.id));
    await assign(tester, db, there, [a]);
    await assign(tester, db, later, [d]);
    await pumpFuture(tester, () => LocalGroupsRepository(db).delete(old.id));
    await tester.pump();
    await undo(tester);
    expect(await groupOf(tester, db, a), there.id);
    expect(await groupOf(tester, db, b), isNull);
    expect(await groupOf(tester, db, c), isNull);
    expect(await groupOf(tester, db, d), later.id);
  });

  fikraTest('Undo into a new group deletes it only while it is still empty', (tester, db) async {
    phone(tester);
    final (_, _, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
    Future<NoteGroup> group(List<Note> notes, String name) async {
      await select(tester, notes);
      await tapAction(tester, 'group');
      await tester.tap(key('group-pick-new'));
      await settle(tester, find.text(ar.groupNameHint));
      await tester.enterText(sheetField, name);
      await tester.pump();
      await tester.tap(key('group-create'));
      await settle(tester, find.text(ar.notesGrouped(Fmt.notes(ar, notes.length), Fmt.isolate(name))));
      return (await allGroups(tester, db)).singleWhere((g) => g.name == name);
    }

    await group([a], 'Fresh');
    await undo(tester);
    expect(await allGroups(tester, db), isEmpty);
    expect(await groupOf(tester, db, a), isNull);

    final kept = await group([a], 'Kept');
    await assign(tester, db, kept, [b]); // someone else's note went in meanwhile
    await tester.pump();
    await undo(tester);
    expect((await allGroups(tester, db)).map((g) => g.id), [kept.id]);
    expect(await groupOf(tester, db, a), isNull);
    expect(await groupOf(tester, db, b), kept.id);
  });

  late SpyGroups groups;
  fikraTest(
    'a new group is deleted again when putting the notes in it fails',
    groupsRepository: (db) => groups = SpyGroups(db)..failAssign = true,
    (tester, db) async {
      phone(tester);
      final (_, _, [a]) = await seedNotes(tester, db, ['A']);
      await select(tester, [a]);
      await tapAction(tester, 'group');
      await tester.tap(key('group-pick-new'));
      await settle(tester, find.text(ar.groupNameHint));
      await tester.enterText(sheetField, 'Doomed');
      await tester.pump();
      await tester.tap(key('group-create'));
      await settle(tester, find.text(ar.groupFailed));
      expect(groups.assigns, 1);
      expect(await allGroups(tester, db), isEmpty);
      expect(await groupOf(tester, db, a), isNull);
      expect(selecting(), isTrue);
    },
  );
}
