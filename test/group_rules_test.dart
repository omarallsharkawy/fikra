import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:flutter/material.dart';

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

// Group rules broken from the group options (links phase 5a): each shows
// its own message, and "put inside" is disabled for a group with sub-groups.
void main() {
  final ar = arL10n;
  Finder key(String k) => find.byKey(ValueKey(k));
  Future<NoteGroup> makeGroup(WidgetTester tester, FikraDatabase db, Project p, String name, {String? parent}) =>
      pumpFuture(tester, () => LocalGroupsRepository(db).create(p.id, name, parentId: parent));
  Future<void> options(WidgetTester tester, NoteGroup g) async {
    await tester.longPress(key('group-filter-${g.id}'));
    await settle(tester, key('group-delete'));
  }

  fikraTest('each rule broken from the options shows its message', (tester, db) async {
    phone(tester, height: 1100);
    final (p, _, _) = await seedNotes(tester, db, ['A']);
    final parent = await makeGroup(tester, db, p, 'Parent');
    final child = await makeGroup(tester, db, p, 'Child', parent: parent.id);
    final other = await makeGroup(tester, db, p, 'Other');
    final target = await makeGroup(tester, db, p, 'Target');
    await pumpUntil(tester, key('group-filter-${target.id}'));

    // A group with sub-groups can't go inside another one: the option is
    // disabled, says why, and does nothing.
    final semantics = tester.ensureSemantics();
    await options(tester, parent);
    expect(find.text(ar.groupRuleHasChildren), findsOneWidget);
    final nest = tester.getSemantics(key('group-nest'));
    expect(nest.flagsCollection.isEnabled, Tristate.isFalse);
    expect(nest.hint, ar.groupRuleHasChildren);
    semantics.dispose();
    await tester.tap(key('group-nest'), warnIfMissed: false);
    await pumpAnimations(tester);
    expect(key('group-delete'), findsOneWidget); // the options stay open
    expect(find.text(ar.putInGroup), findsOneWidget);
    expect(key('group-parent-pick-${other.id}'), findsNothing);
    Navigator.of(tester.element(key('group-delete'))).pop();
    await pumpAnimations(tester);

    // The picked parent became a sub-group after the list was shown.
    await options(tester, other);
    await tester.tap(key('group-nest'));
    await settle(tester, key('group-parent-pick-${target.id}'));
    await pumpFuture(tester, () => LocalGroupsRepository(db).setParent(target.id, parent.id));
    await tester.tap(key('group-parent-pick-${target.id}'));
    await settle(tester, find.text(ar.groupRuleInvalidParent));
    expect((await allGroups(tester, db)).singleWhere((g) => g.id == other.id).parentId, isNull);
    await waitOutToast(tester);

    // The group was deleted while its options were open.
    await tester.tap(key('group-filter-${parent.id}'));
    await tester.pump();
    await options(tester, child);
    await pumpFuture(tester, () => LocalGroupsRepository(db).delete(child.id));
    await tester.tap(key('group-unnest'));
    await settle(tester, find.text(ar.groupRuleMissingGroup));
    await waitOutToast(tester);

    // A sub-group added while the parent list is open: the repository's
    // own message shows, and nothing changes.
    await options(tester, other);
    await tester.tap(key('group-nest'));
    await settle(tester, key('group-parent-pick-${parent.id}'));
    await makeGroup(tester, db, p, 'Late', parent: other.id);
    await tester.tap(key('group-parent-pick-${parent.id}'));
    await settle(tester, find.text(ar.groupRuleHasChildren));
    expect((await allGroups(tester, db)).singleWhere((g) => g.id == other.id).parentId, isNull);
  });
}
