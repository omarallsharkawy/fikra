import 'package:fikra/core/format.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/shared/note_groups.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

void main() {
  final ar = arL10n;
  final en = enL10n;
  bool selecting() => find.byType(SelectionHeader).evaluate().isNotEmpty;
  Finder key(String k) => find.byKey(ValueKey(k));
  final sheetField = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
  Future<NoteGroup> makeGroup(
    WidgetTester tester,
    FikraDatabase db,
    Project p,
    String name, {
    String? parent,
    int? color,
  }) => pumpFuture(tester, () => LocalGroupsRepository(db).create(p.id, name, parentId: parent, color: color));
  Future<void> assign(WidgetTester tester, FikraDatabase db, NoteGroup? g, List<Note> notes) =>
      pumpFuture(tester, () => LocalGroupsRepository(db).assignNotes(g?.id, [for (final n in notes) n.id]));
  Future<String?> groupOf(WidgetTester tester, FikraDatabase db, Note n) async =>
      (await readNote(tester, db, n.id)).groupId;

  test('every group rule has its own plain message in both languages', () {
    for (final l10n in [ar, en]) {
      final messages = {for (final r in GroupRuleReason.values) groupRuleMessage(l10n, r)};
      expect(messages, hasLength(GroupRuleReason.values.length));
    }
    expect(groupRuleMessage(ar, GroupRuleReason.hasChildren), ar.groupRuleHasChildren);
    expect(groupRuleMessage(en, GroupRuleReason.invalidParent), en.groupRuleInvalidParent);
    expect(groupRuleMessage(en, GroupRuleReason.missingGroup), en.groupRuleMissingGroup);
    expect(groupRuleMessage(en, GroupRuleReason.selfParent), en.groupRuleSelfParent);
    expect(groupRuleMessage(en, GroupRuleReason.emptyName), en.groupRuleEmptyName);
    expect(groupRuleMessage(en, GroupRuleReason.invalidColor), en.groupRuleInvalidColor);
    expect(groupRuleMessage(en, GroupRuleReason.missingProject), en.groupRuleMissingProject);
  });

  group('the group action', () {
    late SpyGroups spy;
    fikraTest(
      'assigns an existing group, tags the cards, and Undo restores a mixed selection',
      groupsRepository: (db) => spy = SpyGroups(db),
      (tester, db) async {
        phone(tester, height: 1100);
        final (p, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
        final g1 = await makeGroup(tester, db, p, 'One');
        final g2 = await makeGroup(tester, db, p, 'Two');
        final sub = await makeGroup(tester, db, p, 'Sub', parent: g1.id);
        final g3 = await makeGroup(tester, db, p, 'Three');
        await assign(tester, db, g1, [a]);
        await assign(tester, db, g2, [b]);
        await pumpUntil(tester, key('note-group-${a.id}'));
        expect(find.descendant(of: key('note-group-${b.id}'), matching: find.text('Two')), findsOneWidget);
        expect(key('note-group-${c.id}'), findsNothing);

        await select(tester, [a, b, c]);
        await tapAction(tester, 'group');
        expect(find.text(ar.chooseGroup), findsOneWidget);
        // Sub-groups sit under their parent, indented, with their own counts.
        final rows = [g1, sub, g2, g3].map((g) => tester.getRect(key('group-pick-${g.id}'))).toList();
        for (var i = 1; i < rows.length; i++) {
          expect(rows[i].top, greaterThan(rows[i - 1].top));
        }
        expect(rows[1].width, lessThan(rows[0].width));
        expect(find.descendant(of: key('group-pick-${g1.id}'), matching: find.text(ar.notesCount(1))), findsOneWidget);
        expect(find.bySemanticsLabel(ar.subGroupA11y('Sub', 'One', ar.notesCount(0))), findsOneWidget);
        expect(key('group-pick-none'), findsOneWidget);
        await tester.tap(key('group-pick-${g3.id}'));
        await settle(tester, find.text(ar.notesGrouped(Fmt.notes(ar, 3), Fmt.isolate('Three'))));
        expect(spy.assigns, 1);
        expect(selecting(), isFalse);
        for (final n in [a, b, c]) {
          expect(await groupOf(tester, db, n), g3.id);
        }
        await pumpUntil(tester, key('note-group-${c.id}'));
        expect(find.descendant(of: key('note-group-${c.id}'), matching: find.text('Three')), findsOneWidget);

        await tester.tap(find.text(ar.undo));
        await pumpAnimations(tester);
        await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
        expect(await groupOf(tester, db, a), g1.id);
        expect(await groupOf(tester, db, b), g2.id);
        expect(await groupOf(tester, db, c), isNull);
      },
    );

    fikraTest('a new group with a colour and a parent, then remove from group', (tester, db) async {
      phone(tester);
      final (p, _, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
      final parent = await makeGroup(tester, db, p, 'Parent');
      await select(tester, [a]);
      await tapAction(tester, 'group');
      expect(key('group-pick-none'), findsNothing); // nothing selected is in a group
      await tester.tap(key('group-pick-new'));
      await settle(tester, find.text(ar.groupNameHint));
      expect(find.text(ar.chooseGroup), findsNothing); // one sheet at a time
      expect(tester.widget<FikraButton>(find.widgetWithText(FikraButton, ar.create)).onPressed, isNull);
      await tester.enterText(sheetField, '  Reading  ');
      await tester.pump();
      await tester.tap(key('group-color-1'));
      await tester.pump();
      expect(find.text(ar.groupColorLabel(ar.colorGreen)), findsOneWidget);
      await tester.tap(key('group-parent-${parent.id}'));
      await tester.pump();
      await tester.tap(key('group-create'));
      await settle(tester, find.text(ar.notesGrouped(Fmt.notes(ar, 1), Fmt.isolate('Reading'))));
      final made = (await allGroups(tester, db)).singleWhere((g) => g.name == 'Reading');
      expect(made.color, 1);
      expect(made.parentId, parent.id);
      expect(await groupOf(tester, db, a), made.id);

      await select(tester, [a, b]);
      await tapAction(tester, 'group');
      await tester.tap(key('group-pick-none'));
      await settle(tester, find.text(ar.groupRemovedFrom(Fmt.notes(ar, 2))));
      expect(await groupOf(tester, db, a), isNull);
      expect(ar.groupRemovedFrom(Fmt.notes(ar, 2)), 'اتشالت المجموعة من ملاحظتين');
      // The group itself stays.
      expect((await allGroups(tester, db)).map((g) => g.name), containsAll(['Reading', 'Parent']));
    });

    fikraTest('a parent deleted while the form is open shows the rule and leaves no group behind', (tester, db) async {
      phone(tester);
      final (p, _, [a]) = await seedNotes(tester, db, ['A']);
      final parent = await makeGroup(tester, db, p, 'Parent');
      await select(tester, [a]);
      await tapAction(tester, 'group');
      await tester.tap(key('group-pick-new'));
      await settle(tester, find.text(ar.groupNameHint));
      await tester.enterText(sheetField, 'Child');
      await tester.tap(key('group-parent-${parent.id}'));
      await tester.pump();
      // The parent becomes a sub-group meanwhile: it can't hold a group now.
      final other = await makeGroup(tester, db, p, 'Other');
      await pumpFuture(tester, () => LocalGroupsRepository(db).setParent(parent.id, other.id));
      await tester.tap(key('group-create'));
      await settle(tester, find.text(ar.groupRuleInvalidParent));
      expect((await allGroups(tester, db)).map((g) => g.name), isNot(contains('Child')));
      expect(await groupOf(tester, db, a), isNull);
      expect(selecting(), isTrue);
    });
  });

  fikraTest('the filter row: shows type chips with no groups, a parent shows its sub-groups, search still works', (
    tester,
    db,
  ) async {
    phone(tester, height: 1100);
    final (p, _, [a, b, c, d]) = await seedNotes(tester, db, ['Alpha', 'Beta', 'Gamma', 'Delta']);
    expect(key('group-filter-all'), findsOneWidget);
    expect(key('notes-filter-voice'), findsOneWidget);
    expect(key('notes-filter-files'), findsOneWidget);
    final parent = await makeGroup(tester, db, p, 'Parent', color: 0);
    final child = await makeGroup(tester, db, p, 'Child', parent: parent.id);
    final other = await makeGroup(tester, db, p, 'Other');
    await assign(tester, db, parent, [a]);
    await assign(tester, db, child, [b]);
    await assign(tester, db, other, [d]);
    await pumpUntil(tester, key('group-filter-all'));
    expect(key('group-filter-${child.id}'), findsNothing); // second row only for a picked parent

    Future<void> tapChip(String k) async {
      final f = key(k);
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await tester.pump();
    }

    await tapChip('group-filter-${parent.id}');
    for (final (n, shown) in [(a, true), (b, true), (c, false), (d, false)]) {
      expect(card(n.id), shown ? findsOneWidget : findsNothing, reason: n.title);
    }
    expect(key('group-filter-children'), findsOneWidget);
    expect(find.bySemanticsLabel(ar.groupOptionsA11y('Parent')), findsOneWidget);

    await tapChip('group-filter-${child.id}');
    expect(card(a.id), findsNothing);
    expect(card(b.id), findsOneWidget);

    await tapChip('group-filter-${child.id}'); // again: back to the parent
    expect(card(a.id), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pump(const Duration(milliseconds: 300));
    expect(card(a.id), findsNothing);
    expect(card(b.id), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'gamma');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(ar.noResultsTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    await tapChip('group-filter-${other.id}');
    expect(card(d.id), findsOneWidget);
    expect(card(a.id), findsNothing);
    await assign(tester, db, null, [d]);
    await pumpUntil(tester, find.text(ar.groupEmptyTitle));

    await tapChip('group-filter-all');
    await pumpAnimations(tester);
    for (final n in [a, b, c, d]) {
      expect(card(n.id), findsOneWidget);
    }
    // The selected group's filter goes back to all when the group is deleted.
    await tapChip('group-filter-${other.id}');
    await pumpFuture(tester, () => LocalGroupsRepository(db).delete(other.id));
    await pumpUntil(tester, card(c.id));
    await pumpAnimations(tester);
    expect(card(a.id), findsOneWidget);
  });

  group('managing a group from the filter row', () {
    Future<void> options(WidgetTester tester, NoteGroup g) async {
      final f = key('group-filter-${g.id}');
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.longPress(f);
      await settle(tester, key('group-delete'));
    }

    fikraTest('rename, colour, nest, take out, and delete keeping the notes', (tester, db) async {
      phone(tester, height: 1100);
      final (p, _, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
      final top = await makeGroup(tester, db, p, 'Top');
      final loose = await makeGroup(tester, db, p, 'Loose');
      await assign(tester, db, loose, [a, b]);
      await pumpUntil(tester, key('group-filter-${loose.id}'));

      await options(tester, loose);
      expect(find.text('Loose'), findsWidgets);
      await tester.tap(key('group-rename'));
      await settle(tester, key('group-rename-save'));
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.enterText(sheetField, 'Renamed');
      await tester.pump();
      await tester.tap(key('group-rename-save'));
      await pumpUntil(tester, find.descendant(of: key('group-filter-${loose.id}'), matching: find.text('Renamed')));

      await options(tester, loose);
      await tester.tap(key('group-color'));
      await settle(tester, key('group-color-2'));
      await tester.tap(key('group-color-2'));
      await pumpAnimations(tester);
      await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect((await allGroups(tester, db)).singleWhere((g) => g.id == loose.id).color, 2);

      await options(tester, loose);
      await tester.tap(key('group-nest'));
      await settle(tester, key('group-parent-pick-${top.id}'));
      expect(key('group-parent-pick-${loose.id}'), findsNothing);
      await tester.tap(key('group-parent-pick-${top.id}'));
      await pumpAnimations(tester);
      await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect((await allGroups(tester, db)).singleWhere((g) => g.id == loose.id).parentId, top.id);

      await tester.ensureVisible(key('group-filter-${top.id}'));
      await tester.pump();
      await tester.tap(key('group-filter-${top.id}'));
      await tester.pump();
      await pumpUntil(tester, key('group-filter-${loose.id}'));
      await options(tester, loose);
      expect(find.text(ar.takeOutOfGroup(Fmt.isolate('Top'))), findsOneWidget);
      await tester.tap(key('group-unnest'));
      await pumpAnimations(tester);
      await pumpFuture(tester, () => Future<void>.delayed(const Duration(milliseconds: 20)));
      expect((await allGroups(tester, db)).singleWhere((g) => g.id == loose.id).parentId, isNull);

      await tester.ensureVisible(key('group-filter-${loose.id}'));
      await tester.pump();
      await tester.tap(key('group-filter-${loose.id}'));
      await tester.pump();
      await tester.tap(key('group-filter-options'));
      await settle(tester, key('group-delete'));
      await tester.tap(key('group-delete'));
      await settle(tester, find.text(ar.deleteGroupBody));
      expect(find.text(ar.deleteGroupTitle(Fmt.isolate('Renamed'))), findsOneWidget);
      // Nothing is lost: the confirm is the plain (not red) button.
      expect(tester.widget<FikraButton>(find.widgetWithText(FikraButton, ar.delete)).style, FikraButtonStyle.primary);
      await tester.tap(find.text(ar.delete).last);
      await settle(tester, find.text(ar.groupDeleted));
      expect((await allGroups(tester, db)).map((g) => g.id), [top.id]);
      expect(await groupOf(tester, db, a), isNull);
      expect(card(a.id), findsOneWidget);
      expect(card(b.id), findsOneWidget);
    });
  });
}
