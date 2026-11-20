import 'package:fikra/core/format.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:fikra/features/note_details/pdf_viewer_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/features/shared/note_presentation.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/proposal_fixture.dart';

void phone(WidgetTester tester, {double width = 390}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);
}

Future<List<Note>> graphNotes(WidgetTester tester, FikraDatabase db) async {
  await pumpUntil(tester, find.text(lookupAppLocalizations(tester.platformDispatcher.locale).welcomeStartWriting));
  final notes = await pumpFuture(tester, () async {
    final project = await LocalProjectsRepository(db).create('project');
    final repo = LocalNotesRepository(db);
    final all = <Note>[];
    for (final title in ['', '   ', 'named']) {
      final n = await repo.create(projectId: project.id, title: title, text: 'body', source: NoteSource.text);
      await repo.markReady(n.id);
      all.add(n);
    }
    return all;
  });
  await pumpUntil(tester, find.text('project'));
  await tester.tap(Tabs.finder(Tabs.links));
  await pumpUntil(tester, find.byKey(const ValueKey('links-open-graph')));
  await tester.tap(find.byKey(const ValueKey('links-open-graph')));
  await pumpUntil(tester, find.byType(InteractiveViewer));
  await tester.pumpAndSettle();
  return notes;
}

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest('blank graph nodes reuse the note-title fallback (${locale.languageCode})', locale: locale, (
      tester,
      db,
    ) async {
      phone(tester);
      final notes = await graphNotes(tester, db);
      final context = tester.element(find.byType(LinksScreen));
      for (final note in notes.take(2)) {
        final node = find.byKey(ValueKey(note.id));
        expect(find.descendant(of: node, matching: find.text(noteTitle(context, note))), findsOneWidget);
      }
    });

    for (final resize in [false, true]) {
      fikraTest('zoom keeps the graph viewport centre fixed (${locale.languageCode}, resize=$resize)', locale: locale, (
        tester,
        db,
      ) async {
        phone(tester);
        await graphNotes(tester, db);
        if (resize) {
          tester.view.physicalSize = const Size(390, 620);
          await tester.pumpAndSettle();
        }
        final viewport = find.byType(InteractiveViewer);
        final controller = tester.widget<InteractiveViewer>(viewport).transformationController!;
        controller.value = Matrix4.translationValues(-45, -30, 0)..scaleByDouble(1.2, 1.2, 1, 1);
        await tester.pump();
        final centre = tester.getSize(viewport).center(Offset.zero);
        final scene = controller.toScene(centre);
        final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
        for (final label in [l10n.zoomIn, l10n.zoomOut]) {
          await tester.tap(find.bySemanticsLabel(label));
          await tester.pumpAndSettle();
          final projected = MatrixUtils.transformPoint(controller.value, scene);
          expect(projected.dx, closeTo(centre.dx, 0.001));
          expect(projected.dy, closeTo(centre.dy, 0.001));
        }
        expect(controller.value.getMaxScaleOnAxis(), closeTo(1.2, 0.001));
      });
    }

    fikraTest('PDF taps work during forward and return route transitions (${locale.languageCode})', locale: locale, (
      tester,
      db,
    ) async {
      phone(tester);
      final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
      await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
      final note = await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('project');
        return LocalNotesRepository(db).create(
          projectId: p.id,
          title: 'files',
          text: '',
          source: NoteSource.pdf,
          attachments: const [
            AttachmentDraft(
              kind: AttachmentKind.pdf,
              path: '/private/lecture.pdf',
              name: 'lecture.pdf',
              bytes: 54945382,
            ),
          ],
        );
      });
      final a = (await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(note.id).first)).single;
      await pumpUntil(tester, find.text('project'));
      tester.element(find.text('project').first).push('/note/${note.id}');
      final row = find.byKey(ValueKey('open-pdf-${a.id}'));
      await pumpUntil(tester, row);
      expect(ModalRoute.of(tester.element(row))!.animation!.status, AnimationStatus.forward);
      for (var i = 0; i < 3; i++) {
        await tester.tap(row);
        await pumpUntil(tester, find.byType(PdfViewerScreen));
        await tester.pumpAndSettle();
        expect(GoRouterState.of(tester.element(find.byType(PdfViewerScreen))).uri.path, '/note/${note.id}/pdf/${a.id}');
        if (i < 2) {
          tester.element(find.byType(PdfViewerScreen)).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 20));
        }
      }
    });

    for (final scale in [1.0, 1.5, 2.0, 3.0]) {
      testWidgets('proposal labels fit and respect text scale (${locale.languageCode}, scale=$scale)', (tester) async {
        addTearDown(tester.view.reset);
        final l10n = lookupAppLocalizations(locale);
        await pumpProposalDetails(tester, locale: locale, scale: scale, width: scale == 1 ? 390 : 320);
        for (final label in [l10n.useRewrite, l10n.keepOriginal]) {
          final text = find.text(label);
          final paragraph = tester.renderObject<RenderParagraph>(text);
          final painter = TextPainter(
            text: paragraph.text,
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
            locale: paragraph.locale,
          )..layout(maxWidth: paragraph.size.width);
          if (scale == 1) expect(painter.computeLineMetrics(), hasLength(1), reason: label);
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          expect(
            paragraph.size.height,
            greaterThanOrEqualTo(painter.height - 0.01),
            reason: 'Full text height: $label',
          );
          final button = find.ancestor(of: text, matching: find.byType(FikraButton));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(paragraph.size.height), reason: label);
          expect(paragraph.textScaler.scale(17), closeTo(17 * scale, 0.01));
          painter.dispose();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final screen in ['add', 'edit', 'details']) {
    fikraTest('RTL file-size glyph order is number then Latin unit in $screen', (tester, db) async {
      phone(tester);
      final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
      await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
      final note = await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('project');
        final repo = LocalNotesRepository(db);
        final note = await repo.create(
          projectId: p.id,
          title: 'files',
          text: '',
          source: NoteSource.pdf,
          attachments: const [
            AttachmentDraft(
              kind: AttachmentKind.pdf,
              path: '/private/lecture.pdf',
              name: 'lecture.pdf',
              bytes: 54945382,
            ),
          ],
        );
        await repo.markReady(note.id);
        return note;
      });
      await pumpUntil(tester, find.text('project'));
      final context = tester.element(find.text('project').first);
      if (screen == 'add') {
        context.go('/add');
        await pumpUntil(tester, find.byType(AddScreen));
        final draft = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
        draft.updateDraft(
          () => draft.draftFiles = const [
            AttachmentDraft(
              kind: AttachmentKind.pdf,
              path: '/private/lecture.pdf',
              name: 'lecture.pdf',
              bytes: 54945382,
            ),
          ],
        );
      } else {
        context.push('/note/${note.id}${screen == 'edit' ? '/edit' : ''}');
      }
      final formatted = Fmt.bytes(l10n, 54945382);
      await pumpUntil(tester, find.text(formatted));
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(find.text(formatted));
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
        locale: paragraph.locale,
      )..layout(maxWidth: paragraph.size.width);
      final space = formatted.indexOf(' ');
      final number = painter.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: space));
      final unit = painter.getBoxesForSelection(TextSelection(baseOffset: space + 1, extentOffset: formatted.length));
      expect(number.first.left, lessThan(unit.first.left));
      painter.dispose();
    });
  }
}
