// Renders every main screen to build/screenshots/{ar,en}/{dark,light}/*.png with the real Arabic
// font and icons, at phone size. For design review, not a regression test:
//   flutter test test/screenshots --tags screenshots
@Tags(['screenshots'])
library;

import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'all screens (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        clock: () => DateTime(2026, 11, 10, 12),
        tags: 'screenshots',
        (tester, db) async {
          Future<void> capture(String name) =>
              saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/$name');
          phone(tester);
          BuildContext ctx() => tester.element(find.byType(Scaffold).last);

          await pumpUntil(tester, find.text(l10n.trySampleProject));
          await capture('01_welcome');

          await tester.tap(find.text(l10n.trySampleProject));
          await pumpUntil(tester, find.text(l10n.sample7Title));
          await capture('02_notes');

          // Details of a note with a pending rewrite, concepts and links.
          final rag = await pumpFuture(
            tester,
            () => (db.select(db.notes)..where((n) => n.title.equals(l10n.sample2Title))).getSingle(),
          );
          ctx().push('/note/${rag.id}');
          await pumpUntil(tester, find.text(l10n.suggestedRewrite));
          await tester.pump(const Duration(milliseconds: 400));
          for (final label in [l10n.useRewrite, l10n.keepOriginal]) {
            expect(tester.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines, isFalse, reason: label);
          }
          await capture('03_details_top');
          await tester.drag(find.byType(ListView).last, const Offset(0, -600));
          await pumpUntil(tester, find.text(l10n.relatedNotesHeader));
          await capture('04_details_bottom');

          await tester.tap(find.bySemanticsLabel(l10n.options));
          await pumpUntil(tester, find.text(l10n.noteOptions));
          await capture('05_note_options_sheet');
          await tester.tap(find.text(l10n.deleteNote));
          await pumpUntil(tester, find.text(l10n.deleteNoteTitle));
          await capture('06_delete_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await pumpUntil(tester, find.text(l10n.noteOptions));
          await tester.tap(find.text(l10n.edit));
          await pumpUntil(tester, find.text(l10n.editNoteTitle));
          await capture('07_edit');
          ctx().go('/notes');
          await pumpUntil(tester, find.text(l10n.sample7Title));

          await tester.tap(Tabs.finder(Tabs.add));
          await pumpUntil(tester, find.byKey(const ValueKey('add-mic')));
          await capture('08_add_empty');
          await tester.enterText(find.byType(TextField).last, l10n.sample1Body);
          await tester.pump();
          await capture('09_add_typed');

          await tester.tap(Tabs.finder(Tabs.links));
          final aiGroup = await DemoAiService.clusterFor('rag', locale: locale);
          await pumpUntil(tester, find.text(aiGroup));
          await capture('10_links');
          await tester.tap(find.text(l10n.sample2Title));
          await pumpUntil(tester, find.text(l10n.openNote));
          await capture('11_links_selected');

          await tester.tap(Tabs.finder(Tabs.ask));
          await pumpUntil(tester, find.text(l10n.askEmptyTitle));
          await capture('12_ask_empty');
          await tester.tap(find.text(l10n.askSuggestion(l10n.sample7Title)).first);
          await pumpUntil(tester, find.text(l10n.sources));
          await capture('13_ask_answer');
          await tester.enterText(find.byType(TextField).last, 'cooking?');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await pumpUntil(tester, find.text(l10n.notFoundInNotes));
          await tester.drag(find.byType(ListView).last, const Offset(0, -600));
          await tester.pump(const Duration(milliseconds: 400));
          await capture('14_ask_not_found');

          await tester.tap(find.text(l10n.sampleProjectName).first);
          await pumpUntil(tester, find.text(l10n.projectsTitle));
          await capture('15_projects_sheet');
          await tester.tap(find.text(l10n.newProject));
          await pumpUntil(tester, find.text(l10n.projectNameHint));
          await tester.enterText(find.byType(TextField).last, l10n.sample7Title);
          await tester.pump();
          await capture('16_new_project');
          await tester.tap(find.text(l10n.create));
          await pumpUntil(tester, find.text(l10n.sample7Title));

          await tester.tap(Tabs.finder(Tabs.notes));
          await pumpUntil(tester, find.text(l10n.notesEmptyTitle));
          await capture('17_notes_empty');
          await tester.tap(Tabs.finder(Tabs.links));
          await pumpUntil(tester, find.text(l10n.linksEmptyTitle));
          await capture('18_links_empty');

          await tester.tap(find.byIcon(Icons.settings_outlined).hitTestable().first);
          await pumpUntil(tester, find.text(l10n.appearance));
          await capture('19_settings');
        },
      );
    }
  }
}
