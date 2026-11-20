// Renders every main screen to build/screenshots/{ar,en}/{dark,light}/*.png with the real Arabic
// font and icons, at phone size. For design review, not a regression test:
//   flutter test test/screenshots --tags screenshots
@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
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

          await pumpUntil(tester, find.text(l10n.welcomeTrySample));
          await capture('01_welcome');

          await tester.tap(find.text(l10n.welcomeTrySample));
          await pumpUntil(tester, find.text(l10n.sample7Title));
          await capture('02_notes');

          final photoDirectory = await tester.runAsync(() async {
            final dir = await Directory.systemTemp.createTemp('fikra-screenshot-photos-');
            for (var i = 1; i <= 2; i++) {
              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              canvas.drawColor(const Color(0xff666666), BlendMode.src);
              canvas.drawRect(Rect.fromLTWH(i * 20, 20, 50, 70), Paint()..color = const Color(0xffcccccc));
              final picture = recorder.endRecording();
              final image = await picture.toImage(120, 120);
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              await File('${dir.path}/photo-$i.png').writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
              picture.dispose();
            }
            return dir;
          });
          addTearDown(() => photoDirectory!.delete(recursive: true));
          await tester.runAsync(() async {
            for (var i = 1; i <= 2; i++) {
              await precacheImage(
                ResizeImage(FileImage(File('${photoDirectory!.path}/photo-$i.png')), width: 360),
                ctx(),
              );
            }
          });
          final multipleFiles = <AttachmentDraft>[
            for (var i = 1; i <= 2; i++)
              AttachmentDraft(
                kind: AttachmentKind.pdf,
                path: '/private/lecture-$i.pdf',
                name: 'lecture-$i.pdf',
                bytes: 54945382,
              ),
            for (var i = 1; i <= 2; i++)
              AttachmentDraft(kind: AttachmentKind.voice, path: '/private/rec-$i.m4a', durationMs: 61000),
            for (var i = 1; i <= 2; i++)
              AttachmentDraft(
                kind: AttachmentKind.image,
                path: '${photoDirectory!.path}/photo-$i.png',
                name: 'photo-$i.png',
              ),
          ];
          final multi = await pumpFuture(tester, () async {
            final repo = LocalNotesRepository(db);
            final p = (await db.select(db.projects).get()).first;
            final n = await repo.create(
              projectId: p.id,
              title: 'lecture-1',
              text: '',
              source: NoteSource.pdf,
              attachments: multipleFiles,
              createdAt: DateTime(2026, 11, 10, 11, 59),
            );
            await repo.markReady(n.id);
            return n;
          });
          await pumpUntil(tester, find.text('lecture-1'));
          await capture('25_notes_files');
          ctx().push('/note/${multi.id}');
          await pumpUntil(tester, find.text('lecture-2.pdf'));
          await capture('21_details_files');
          ctx().push('/note/${multi.id}/edit');
          await pumpUntil(tester, find.text(l10n.editNoteTitle));
          await capture('22_edit_files');
          await tester.drag(
            find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.vertical).last,
            const Offset(0, -450),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await capture('23_edit_files_bottom');
          ctx().go('/add');
          await pumpUntil(tester, find.byType(AddScreen));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
          final draft = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          draft.updateDraft(() => draft.draftFiles = multipleFiles);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey('add-save'))), alignment: 0.7);
          await tester.pump(const Duration(milliseconds: 400));
          await capture('24_add_files');
          draft.updateDraft(() => draft.draftFiles = []);
          ctx().go('/notes');
          await pumpUntil(tester, find.text(l10n.sample7Title));

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
          await pumpUntil(tester, find.text(l10n.noteLinksHeader));
          await capture('04_details_bottom');

          // Links section: the picker (with and without the keyboard), your
          // links next to the analysis suggestions, and the link options.
          Future<void> settle(Finder finder) async {
            await pumpUntil(tester, finder);
            await tester.pump(const Duration(milliseconds: 500));
          }

          Finder textField(String key) =>
              find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));
          await tester.ensureVisible(find.byKey(const ValueKey('link-to-note')));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byKey(const ValueKey('link-to-note')));
          await settle(find.byKey(const ValueKey('link-confirm')));
          for (final title in [l10n.sample7Title, l10n.sample4Title]) {
            await tester.tap(
              find.descendant(of: find.byKey(const ValueKey('link-picker-list')), matching: find.text(title)),
            );
            await tester.pump();
          }
          await tester.enterText(
            textField('link-reason'),
            locale.languageCode == 'ar' ? 'نفس المحاضرة' : 'Same lecture',
          );
          await tester.pump();
          await capture('28_link_picker');
          tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await capture('29_link_picker_keyboard');
          tester.view.resetViewInsets();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byKey(const ValueKey('link-confirm')));
          await settle(find.text(l10n.notesLinked(2)));
          final networks = await pumpFuture(
            tester,
            () => (db.select(db.notes)..where((n) => n.title.equals(l10n.sample7Title))).getSingle(),
          );
          final options = find.byKey(ValueKey('link-options-${networks.id}'));
          await tester.ensureVisible(find.text(l10n.noteLinksHeader));
          await tester.pump(const Duration(milliseconds: 400));
          await capture('30_details_links');
          // Let the toast go, so nothing covers the suggestion's actions.
          await tester.pump(const Duration(seconds: 4));
          await tester.drag(find.byType(ListView).last, const Offset(0, -600));
          await tester.pump(const Duration(milliseconds: 400));
          await capture('31_details_links_bottom');
          await tester.ensureVisible(options);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(options);
          await settle(find.text(l10n.linkOptionsTitle));
          await capture('32_link_options');
          await tester.tap(find.text(l10n.editLinkReason));
          await settle(find.byKey(const ValueKey('link-reason-save')));
          await capture('33_link_reason');
          await tester.tap(find.byKey(const ValueKey('link-reason-save')));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(options);
          await settle(find.text(l10n.removeLink));
          await tester.tap(find.text(l10n.removeLink));
          await settle(find.text(l10n.removeLinkTitle));
          await capture('34_link_remove_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await tester.pump(const Duration(milliseconds: 500));
          Navigator.of(tester.element(find.text(l10n.linkOptionsTitle))).pop();
          await tester.pump(const Duration(milliseconds: 600));

          await tester.tap(find.bySemanticsLabel(l10n.options));
          await pumpUntil(tester, find.text(l10n.noteOptions));
          await capture('05_note_options_sheet');
          await tester.tap(find.text(l10n.deleteNote));
          await pumpUntil(tester, find.text(l10n.deleteNoteTitle));
          await capture('06_delete_confirm');
          await tester.tap(find.text(l10n.cancel).last);
          await pumpUntil(tester, find.text(l10n.noteOptions));
          await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(l10n.edit)));
          await pumpUntil(tester, find.text(l10n.editNoteTitle));
          await capture('07_edit');
          ctx().go('/notes');
          await pumpUntil(tester, find.text(l10n.sample7Title));

          await tester.tap(Tabs.addButton);
          await pumpUntil(tester, find.byKey(const ValueKey('add-mic')));
          await capture('08_add_empty');
          await tester.enterText(find.byType(TextField).last, l10n.sample1Body);
          await tester.pump();
          await capture('09_add_typed');

          await tester.tap(find.byKey(const ValueKey('add-close')));
          await tester.pumpAndSettle();
          await tester.tap(Tabs.finder(Tabs.links));
          await pumpUntil(tester, find.byKey(const ValueKey('links-open-graph')));
          await tester.tap(find.byKey(const ValueKey('links-open-graph')));
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

          await tester.tap(Tabs.finder(Tabs.me));
          await pumpUntil(tester, find.text(l10n.appearance));
          await capture('19_settings');

          // Route through a real note, but inject a failed document load: no native
          // PDFium rendering in this widget screenshot suite.
          final pdf = await pumpFuture(
            tester,
            () => LocalNotesRepository(db).create(
              projectId: rag.projectId,
              title: l10n.pdfFile,
              text: '',
              source: NoteSource.pdf,
              attachments: [
                AttachmentDraft(kind: AttachmentKind.pdf, path: '/private/document.pdf', name: 'document.pdf'),
              ],
            ),
          );
          ctx().push(
            '/note/${pdf.id}/pdf/${(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(pdf.id).first)).first.id}',
          );
          await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
          await capture('20_pdf_failure');
        },
      );
    }
  }
}
