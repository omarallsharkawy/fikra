// Links phase 3 captures: moving a note to another project and deleting a
// project, in both languages and themes, at phone size with the real fonts.
//   rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots
@Tags(['screenshots'])
library;

import 'package:fikra/core/format.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/demo/demo_seed.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);
    final ar = locale.languageCode == 'ar';
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'projects (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        clock: () => DateTime(2026, 11, 10, 12),
        aiService: _QuietAi(),
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

          Future<void> close() async {
            await tester.tapAt(const Offset(195, 60));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
          }

          BuildContext ctx() => tester.element(find.byType(Scaffold).last);

          await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
          final longName = ar ? 'تدريب الصيف في الشركة، الأسبوع الأول والتاني' : 'Summer internship, weeks one and two';
          final (rag, plain) = await pumpFuture(tester, () async {
            final projects = LocalProjectsRepository(db);
            final notes = LocalNotesRepository(db);
            final sample = await seedDemoProject(projects, notes, locale: locale, clock: () => DateTime(2026, 11, 10));
            for (final (name, count) in [(ar ? 'مذاكرة' : 'Study', 3), (longName, 1)]) {
              final p = await projects.create(name);
              for (var i = 0; i < count; i++) {
                final n = await notes.create(projectId: p.id, title: '$name $i', text: 'x', source: NoteSource.text);
                await notes.markReady(n.id);
              }
            }
            await projects.setCurrent(sample.id);
            final all = await notes.notesOf(sample.id);
            final rag = all.singleWhere((n) => n.title == l10n.sample2Title);
            // One link of yours next to the analysis suggestions.
            await LocalLinksRepository(db).linkNotes(rag.id, [
              all.singleWhere((n) => n.title == l10n.sample7Title).id,
              all.singleWhere((n) => n.title == l10n.sample3Title).id,
            ]);
            final plain = await notes.create(
              projectId: sample.id,
              title: ar ? 'فكرة لوحدها' : 'A note on its own',
              text: 'x',
              source: NoteSource.text,
              createdAt: DateTime(2026, 11, 10, 11),
            );
            await notes.markReady(plain.id);
            return (rag, plain);
          });
          await pumpUntil(tester, find.text(l10n.sample7Title));

          ctx().push('/note/${rag.id}');
          await settle(find.text(l10n.suggestedRewrite));
          await tester.tap(find.bySemanticsLabel(l10n.options));
          await settle(find.text(l10n.noteOptions));
          await capture('35_note_options_move');
          await tester.tap(find.byKey(const ValueKey('note-move')));
          await settle(find.text(l10n.moveToProject));
          await capture('36_move_picker');
          await tester.tap(find.text(longName));
          await settle(find.text(l10n.moveConfirm));
          await capture('37_move_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          ctx().pushReplacement('/note/${plain.id}');
          await settle(find.text(plain.title));
          await tester.tap(find.bySemanticsLabel(l10n.options));
          await settle(find.text(l10n.noteOptions));
          await tester.tap(find.byKey(const ValueKey('note-move')));
          await settle(find.text(l10n.moveToProject));
          await tester.tap(find.text(ar ? 'مذاكرة' : 'Study'));
          await settle(find.text(l10n.moveNoteBodyNoLinks));
          await capture('38_move_confirm_no_links');
          await tester.tap(find.text(l10n.cancel).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          ctx().go('/notes');
          await settle(find.text(l10n.sample7Title));
          await tester.tap(find.bySemanticsLabel(l10n.projectPillA11y(l10n.sampleProjectName)).first);
          await settle(find.text(l10n.projectsTitle));
          await tester.tap(find.bySemanticsLabel(l10n.projectOptionsA11y(l10n.sampleProjectName)));
          await settle(find.text(l10n.deleteProject));
          await tester.tap(find.text(l10n.deleteProject));
          await settle(find.text(l10n.deleteProjectTitle(Fmt.isolate(l10n.sampleProjectName))));
          await capture('39_delete_project_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await close();
          await close();

          await pumpFuture(tester, () async {
            final projects = LocalProjectsRepository(db);
            final empty = await projects.create(ar ? 'فاضي' : 'Empty');
            await projects.setCurrent(empty.id);
          });
          await pumpUntil(tester, find.bySemanticsLabel(l10n.projectPillA11y(ar ? 'فاضي' : 'Empty')));
          await tester.tap(find.bySemanticsLabel(l10n.projectPillA11y(ar ? 'فاضي' : 'Empty')).first);
          await settle(find.text(l10n.projectsTitle));
          await tester.tap(find.bySemanticsLabel(l10n.projectOptionsA11y(ar ? 'فاضي' : 'Empty')));
          await settle(find.text(l10n.deleteProject));
          await tester.tap(find.text(l10n.deleteProject));
          await settle(find.text(l10n.deleteProjectEmptyBody));
          await capture('40_delete_project_empty');
          await tester.tap(find.text(l10n.cancel).last);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await close();
          await close();

          // UX-16: the name sheet alone, after the projects sheet closed.
          await tester.tap(find.bySemanticsLabel(l10n.projectPillA11y(ar ? 'فاضي' : 'Empty')).first);
          await settle(find.text(l10n.projectsTitle));
          await tester.tap(find.byKey(const ValueKey('new-project')));
          await settle(find.text(l10n.projectNameHint));
          await capture('41_new_project_one_sheet');
        },
      );
    }
  }
}

/// Re-linking after a move needs no analysis here.
class _QuietAi implements AiService {
  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async =>
      NoteInsights(title: note.title, concepts: const [], cluster: 'k', links: const []);

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) => throw UnimplementedError();
}
