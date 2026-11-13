// Links phase 5a captures: selection mode in the notes list, its action bar,
// the group sheet and new-group form, the group filter row and group options,
// in both languages and themes, at phone size with the real fonts.
//   rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots
@Tags(['screenshots'])
library;

import 'package:fikra/core/format.dart';
import 'package:fikra/data/demo/demo_seed.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/selection_fixture.dart' show QuietAi, card, reveal, select;

void main() {
  setUpAll(loadAppFonts);

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);
    final ar = locale.languageCode == 'ar';
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'selection and groups (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        clock: () => DateTime(2026, 11, 10, 12),
        aiService: QuietAi(),
        tags: 'screenshots',
        (tester, db) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          addTearDown(tester.view.reset);
          Future<void> capture(String name) =>
              saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/$name');
          Future<void> settle(Finder finder) async {
            await pumpUntil(tester, finder);
            await tester.pump(const Duration(milliseconds: 600));
          }

          Future<void> frames() async {
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
          }

          Future<void> close() async {
            await tester.tapAt(const Offset(195, 60));
            await frames();
          }

          Future<void> tapKey(String key) async {
            await tester.ensureVisible(find.byKey(ValueKey(key)));
            await tester.pump();
            await tester.tap(find.byKey(ValueKey(key)));
            await frames();
          }

          await pumpUntil(tester, find.text(l10n.startNewProject));
          final (notes, parent, child) = await pumpFuture(tester, () async {
            final projects = LocalProjectsRepository(db);
            final repo = LocalNotesRepository(db);
            final groups = LocalGroupsRepository(db);
            final sample = await seedDemoProject(projects, repo, locale: locale, clock: () => DateTime(2026, 11, 10));
            final study = await projects.create(ar ? 'مذاكرة' : 'Study');
            final n = await repo.create(projectId: study.id, title: 'x', text: 'x', source: NoteSource.text);
            await repo.markReady(n.id);
            await projects.setCurrent(sample.id);
            final notes = await repo.notesOf(sample.id);
            final parent = await groups.create(sample.id, ar ? 'أفكار المشروع' : 'Project ideas', color: 0);
            final child = await groups.create(sample.id, ar ? 'الذكاء الاصطناعي' : 'AI', parentId: parent.id, color: 1);
            await groups.create(sample.id, ar ? 'محاضرات' : 'Lectures', color: 2);
            await groups.assignNotes(parent.id, [notes[0].id, notes[3].id]);
            await groups.assignNotes(child.id, [notes[1].id, notes[5].id]);
            return (notes, parent, child);
          });
          await settle(find.byKey(const ValueKey('group-filter-all')));
          await capture('45_notes_groups');

          await tapKey('group-filter-${parent.id}');
          await settle(find.byKey(ValueKey('group-filter-${child.id}')));
          await capture('46_group_filter_parent');
          await tapKey('group-filter-all');

          await select(tester, [notes[0], notes[1], notes[3]]);
          await frames();
          await capture('47_selection_mode');
          tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
          await frames();
          await capture('48_selection_keyboard');
          tester.view.resetViewInsets();
          await frames();

          await tapKey('selection-group');
          await settle(find.text(l10n.chooseGroup));
          await capture('49_group_sheet');
          await tapKey('group-pick-new');
          await settle(find.text(l10n.groupNameHint));
          await tester.enterText(
            find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)),
            ar ? 'قراءات' : 'Reading',
          );
          await tester.pump();
          await tapKey('group-color-3');
          await tapKey('group-parent-${parent.id}');
          FocusManager.instance.primaryFocus?.unfocus();
          await frames();
          await capture('50_new_group_form');
          await close();

          for (final n in [notes[2], notes[4], notes[5], notes[6]]) {
            await reveal(tester, n.id);
            await tester.tap(card(n.id));
            await tester.pump();
          }
          await frames();
          await capture('51_selection_limit');

          await tapKey('selection-move');
          await settle(find.text(l10n.moveToProject));
          await tester.tap(find.text(ar ? 'مذاكرة' : 'Study'));
          await settle(find.text(l10n.moveNotesTitle(Fmt.notes(l10n, 7), Fmt.isolate(ar ? 'مذاكرة' : 'Study'))));
          await capture('52_move_notes_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await frames();

          await tapKey('selection-delete');
          await settle(find.text(l10n.deleteNotesTitle(Fmt.notes(l10n, 7))));
          await capture('53_delete_notes_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await frames();

          for (final n in [notes[3], notes[4], notes[5], notes[6]]) {
            await reveal(tester, n.id);
            await tester.tap(card(n.id));
            await tester.pump();
          }
          await tapKey('selection-link');
          await settle(find.text(l10n.undo));
          await capture('54_link_undo_toast');
          await tester.pump(const Duration(seconds: 7));
          await frames();

          await tester.longPress(find.byKey(ValueKey('group-filter-${parent.id}')));
          await settle(find.byKey(const ValueKey('group-delete')));
          await capture('55_group_options');
          await tapKey('group-delete');
          await settle(find.text(l10n.deleteGroupBody));
          await capture('56_delete_group_confirm');
        },
      );
    }
  }
}
