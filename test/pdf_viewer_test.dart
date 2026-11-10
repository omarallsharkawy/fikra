import 'package:fikra/data/attachment_draft.dart';

import 'dart:async';
import 'dart:io';

import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/note_details/pdf_document_provider.dart';
import 'package:fikra/features/note_details/pdf_viewer_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import 'support/app_harness.dart';

void main() {
  for (final failure in [const FormatException('corrupt'), const PdfPasswordException('locked')]) {
    fikraTest(
      '$failure uses the PDF error view and keeps the external action',
      pdfLoader: (path) async => throw failure,
      opener: (path) async => throw StateError('platform opener failed'),
      (tester, db) async {
        final l10n = lookupAppLocalizations(const Locale('ar'));
        await pumpUntil(tester, find.text(l10n.startNewProject));
        final note = await pumpFuture(tester, () async {
          final project = await LocalProjectsRepository(db).create('test');
          return LocalNotesRepository(db).create(
            projectId: project.id,
            title: 'test',
            text: '',
            source: NoteSource.pdf,
            attachments: [AttachmentDraft(kind: AttachmentKind.pdf, path: '/private/test.pdf')],
          );
        });
        await pumpUntil(tester, find.text('test'));
        tester
            .element(find.text('test').first)
            .push(
              '/note/${note.id}/pdf/${(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(note.id).first)).firstOrNull?.id ?? 'missing'}',
            );
        final locked = failure is PdfPasswordException;
        await pumpUntil(tester, find.text(locked ? l10n.pdfPasswordProtected : l10n.pdfLoadFailed));
        expect(find.text(l10n.retry), locked ? findsNothing : findsOneWidget);
        expect(find.text(locked ? l10n.pdfLoadFailed : l10n.pdfPasswordProtected), findsNothing);
        expect(find.byType(LoadErrorView), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(const ValueKey('pdf-open-elsewhere')));
        await tester.pump();
        expect(find.text(l10n.openFileFailed), findsOneWidget);
        expect(find.byType(PdfViewerScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('an encrypted document accepting an empty password is classified and disposed', () async {
    final document = _Document(encrypted: true);
    final container = ProviderContainer(
      overrides: [pdfDocumentLoaderProvider.overrideWithValue((_) async => document)],
    );
    addTearDown(container.dispose);
    container.listen(pdfDocumentProvider('/private/encrypted.pdf'), (_, _) {});
    await expectLater(
      container.read(pdfDocumentProvider('/private/encrypted.pdf').future),
      throwsA(isA<PdfPasswordException>()),
    );
    expect(document.disposals, 1);
  });

  test('default loader rejects a missing file before native initialization', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final directory = await Directory.systemTemp.createTemp('fikra-pdf-missing-');
    addTearDown(() => directory.delete(recursive: true));
    await expectLater(
      container.read(pdfDocumentLoaderProvider)('${directory.path}/missing.pdf'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('releasing the provider disposes its loaded document', () async {
    final document = _Document();
    final container = ProviderContainer(
      overrides: [pdfDocumentLoaderProvider.overrideWithValue((_) async => document)],
    );
    final subscription = container.listen(pdfDocumentProvider('/private/test.pdf'), (_, _) {});
    expect(await container.read(pdfDocumentProvider('/private/test.pdf').future), same(document));
    subscription.close();
    await container.pump();
    expect(document.disposals, 1);
    container.dispose();
    expect(document.disposals, 1);
  });

  test('a load finishing after the viewer closes is disposed too', () async {
    final document = _Document();
    final pending = Completer<PdfDocument>();
    final container = ProviderContainer(
      overrides: [pdfDocumentLoaderProvider.overrideWithValue((_) => pending.future)],
    );
    container.listen(pdfDocumentProvider('/private/test.pdf'), (_, _) {});
    container.dispose();
    pending.complete(document);
    await Future<void>.delayed(Duration.zero);
    expect(document.disposals, 1);
  });
}

// Lifecycle tests never create a native document or a PdfViewer.
class _Document extends PdfDocument {
  _Document({this.encrypted = false}) : super(sourceName: 'test');
  final bool encrypted;
  @override
  bool get isEncrypted => encrypted;
  int disposals = 0;

  @override
  Future<void> dispose() async => disposals++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
