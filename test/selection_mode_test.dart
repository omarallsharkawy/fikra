import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:flutter/material.dart';

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

void main() {
  final ar = arL10n;

  Finder check(String id, IconData icon) =>
      find.byWidgetPredicate((w) => w is Icon && w.key == ValueKey('note-check-$id') && w.icon == icon);
  bool selecting() => find.byType(SelectionHeader).evaluate().isNotEmpty;

  fikraTest('a long press selects; taps toggle without opening; the last deselect ends it', (tester, db) async {
    phone(tester);
    final (_, _, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
    expect(find.byKey(ValueKey('note-check-${a.id}')), findsNothing);

    await tester.longPress(card(a.id));
    await tester.pump();
    expect(selecting(), isTrue);
    expect(find.byType(ProjectHeader), findsNothing);
    expect(find.text(ar.selectedCount(1)), findsOneWidget);
    expect(check(a.id, Icons.check_circle_rounded), findsOneWidget);
    expect(check(b.id, Icons.radio_button_unchecked_rounded), findsOneWidget);
    expect(tester.getSemantics(card(a.id)).flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.getSemantics(card(b.id)).flagsCollection.isSelected, Tristate.isFalse);
    // The action bar is above the tab bar, not under it.
    final bar = tester.getRect(find.byType(SelectionActionBar));
    expect(bar.bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('nav-0'))).top));

    await tester.tap(card(b.id));
    await tester.pump();
    await tester.longPress(card(c.id)); // a long press toggles too while selecting
    await tester.pump();
    expect(find.text(ar.selectedCount(3)), findsOneWidget);
    await tester.tap(card(a.id));
    await tester.pump();
    expect(find.text(ar.selectedCount(2)), findsOneWidget);
    expect(check(a.id, Icons.radio_button_unchecked_rounded), findsOneWidget);
    await pumpAnimations(tester);
    expect(find.byType(NoteDetailsScreen), findsNothing);

    await tester.tap(card(b.id));
    await tester.pump();
    await tester.tap(card(c.id));
    await tester.pump();
    expect(selecting(), isFalse);
    expect(find.byType(ProjectHeader), findsOneWidget);
    expect(find.byType(SelectionActionBar), findsNothing);
    expect(find.byKey(ValueKey('note-check-${a.id}')), findsNothing);

    // Outside selection a tap opens the note as before.
    await tester.tap(card(a.id));
    await settle(tester, find.byType(NoteDetailsScreen));
  });

  fikraTest('Back and the close control end the selection and stay on the list', (tester, db) async {
    phone(tester);
    final (_, _, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
    await select(tester, [a, b]);
    await tester.binding.handlePopRoute();
    await pumpAnimations(tester);
    expect(selecting(), isFalse);
    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('A'), findsOneWidget);

    await select(tester, [a]);
    await tester.tap(find.byKey(const ValueKey('selection-close')));
    await tester.pump();
    expect(selecting(), isFalse);
    expect(find.bySemanticsLabel(ar.closeSelection), findsNothing);
  });

  fikraTest('notes hidden by the search leave the selection; another group filter clears it', (tester, db) async {
    phone(tester, height: 1100);
    final (p, _, [a, b, c, d]) = await seedNotes(tester, db, ['A', 'B', 'C', 'D']);
    final g = await pumpFuture(tester, () => LocalGroupsRepository(db).create(p.id, 'G'));
    await pumpFuture(tester, () => LocalGroupsRepository(db).assignNotes(g.id, [c.id, d.id]));
    await select(tester, [a, b]);
    await tester.enterText(find.byType(TextField), 'text of a');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(ar.selectedCount(1)), findsOneWidget);
    // B is hidden, so delete takes A alone.
    await tapAction(tester, 'delete');
    await tester.tap(find.text(ar.delete).last);
    await settle(tester, find.text(ar.noteDeleted));
    expect(await pumpFuture(tester, () => db.select(db.notes).get()), hasLength(4)); // B, C, D and Work's note
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));

    await select(tester, [b, c]);
    await tester.tap(find.byKey(ValueKey('group-filter-${g.id}')));
    await tester.pump();
    expect(selecting(), isFalse);

    // Inside the filter, a note taken out of the group leaves the selection.
    await select(tester, [c, d]);
    await pumpFuture(tester, () => LocalGroupsRepository(db).assignNotes(null, [d.id]));
    await pumpUntil(tester, find.text(ar.selectedCount(1)));
    expect(card(d.id), findsNothing);
  });

  fikraTest('Back while a sheet is open closes the sheet and keeps the selection', (tester, db) async {
    phone(tester);
    final (_, _, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
    await select(tester, [a, b]);
    await tapAction(tester, 'group');
    expect(find.text(ar.chooseGroup), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pumpAnimations(tester);
    expect(find.text(ar.chooseGroup), findsNothing);
    expect(find.text(ar.selectedCount(2)), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pumpAnimations(tester);
    expect(selecting(), isFalse);
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  fikraTest('notes deleted or moved meanwhile drop out of the selection', (tester, db) async {
    phone(tester);
    final (_, q, [a, b, c]) = await seedNotes(tester, db, ['A', 'B', 'C']);
    await select(tester, [a, b, c]);
    final repo = LocalNotesRepository(db);
    await pumpFuture(tester, () => repo.delete(b.id));
    await pumpUntil(tester, find.text(ar.selectedCount(2)));
    await pumpFuture(tester, () => repo.moveNotes([c.id], q.id));
    await pumpUntil(tester, find.text(ar.selectedCount(1)));
    await pumpFuture(tester, () => repo.delete(a.id));
    await pumpUntil(tester, find.byType(ProjectHeader));
    expect(selecting(), isFalse);
  });

  fikraTest('leaving the tab or switching project ends the selection', (tester, db) async {
    phone(tester);
    final (_, q, [a, b]) = await seedNotes(tester, db, ['A', 'B']);
    await select(tester, [a, b]);
    await tester.tap(Tabs.finder(Tabs.links));
    await pumpAnimations(tester);
    await tester.tap(Tabs.finder(Tabs.notes));
    await pumpAnimations(tester);
    expect(selecting(), isFalse);
    expect(find.text('A'), findsOneWidget);

    await select(tester, [a]);
    await pumpFuture(tester, () => LocalProjectsRepository(db).setCurrent(q.id));
    await pumpUntil(tester, find.text('Q note'));
    expect(selecting(), isFalse);
  });

  late SpyNotes spy;
  fikraTest(
    'switching project ends the selection before the other list arrives',
    notesRepository: (db) => spy = SpyNotes(db),
    (tester, db) async {
      phone(tester);
      final (_, q, [a]) = await seedNotes(tester, db, ['A']);
      await select(tester, [a]);
      spy.holdNotesOf = q.id;
      await pumpFuture(tester, () => LocalProjectsRepository(db).setCurrent(q.id));
      await pumpUntil(tester, find.byType(ProjectHeader));
      expect(selecting(), isFalse);
      expect(find.text('A'), findsNothing);
    },
  );

  fikraTest('"Link together" is off for one note and above six, and says why above six', (tester, db) async {
    phone(tester, height: 1500);
    final notes = (await seedNotes(tester, db, ['A', 'B', 'C', 'D', 'E', 'F', 'G'])).$3;
    final semantics = tester.ensureSemantics();
    await select(tester, notes.take(1).toList());
    final link = find.byKey(const ValueKey('selection-link'));
    expect(find.byKey(const ValueKey('selection-note')), findsNothing);
    expect(tester.getSemantics(link).hint, ar.linkTogetherNeedsTwo);
    expect(tester.getSemantics(link).flagsCollection.isEnabled, Tristate.isFalse);
    for (final n in notes.skip(1).take(5)) {
      await tester.tap(card(n.id));
      await tester.pump();
    }
    expect(find.text(ar.selectedCount(6)), findsOneWidget);
    expect(tester.getSemantics(link).flagsCollection.isEnabled, Tristate.isTrue);
    await tester.tap(card(notes.last.id));
    await tester.pump();
    expect(find.text(ar.linkTogetherLimit(6)), findsOneWidget);
    expect(tester.getSemantics(link).flagsCollection.isEnabled, Tristate.isFalse);
    await tester.tap(link);
    await pumpAnimations(tester);
    expect(await allLinks(tester, db), isEmpty);
    expect(selecting(), isTrue);
    // Every action is a labelled 48 dp target.
    for (final key in ['link', 'group', 'move', 'delete']) {
      final size = tester.getSize(find.byKey(ValueKey('selection-$key')));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    for (final label in [ar.linkTogether, ar.groupAction, ar.moveConfirm, ar.delete]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });
}
