@Tags(['screenshots'])
library;

import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../support/app_harness.dart';
import '../support/proposal_fixture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'phone fixes (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        tags: 'screenshots',
        pdfLoader: (_) async => throw const PdfPasswordException('locked'),
        (tester, db) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          addTearDown(tester.view.reset);
          final l10n = lookupAppLocalizations(locale);
          Future<void> capture(String name) =>
              saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/$name');
          await pumpUntil(tester, find.text(l10n.startNewProject));
          final note = await pumpFuture(tester, () async {
            final p = await LocalProjectsRepository(db).create('project');
            return LocalNotesRepository(db).create(
              projectId: p.id,
              title: 'locked.pdf',
              text: '',
              source: NoteSource.pdf,
              attachments: const [
                AttachmentDraft(kind: AttachmentKind.pdf, path: '/private/locked.pdf', name: 'locked.pdf'),
              ],
            );
          });
          final attachment = (await pumpFuture(
            tester,
            () => LocalNotesRepository(db).watchAttachments(note.id).first,
          )).single;
          await pumpUntil(tester, find.text('project'));
          tester.element(find.text('project').first).push('/note/${note.id}/pdf/${attachment.id}');
          await pumpUntil(tester, find.text(l10n.pdfPasswordProtected));
          expect(find.text(l10n.retry), findsNothing);
          await capture('26_pdf_password');
          for (final scale in [1.0, 2.0, 3.0]) {
            await pumpProposalDetails(tester, locale: locale, brightness: brightness, scale: scale, pixelRatio: 3);
            final label = find.text(l10n.keepOriginal);
            if (scale == 1) {
              final paragraph = tester.renderObject<RenderParagraph>(label);
              final painter = TextPainter(
                text: paragraph.text,
                textDirection: paragraph.textDirection,
                textScaler: paragraph.textScaler,
                locale: paragraph.locale,
              )..layout(maxWidth: paragraph.size.width);
              expect(painter.computeLineMetrics(), hasLength(1));
              painter.dispose();
            }
            final actions = find.ancestor(of: label, matching: find.byType(LayoutBuilder)).first;
            await Scrollable.ensureVisible(tester.element(actions), alignment: 0.5);
            await tester.pumpAndSettle();
            await capture('27_proposal_scale_${scale.toInt()}');
          }
        },
      );
    }
  }
}
