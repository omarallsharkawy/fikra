import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/features/note_details/pdf_viewer_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  late Directory dir;
  final store = AttachmentStore(documentsDir: () async => dir, tempDir: () async => dir);
  late _Picker picker;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fikra-flow-');
    picker = _Picker();
    final previous = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = previous);
    addTearDown(() => dir.delete(recursive: true));
  });

  Future<Note> seed(WidgetTester tester, FikraDatabase db, {bool single = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    return pumpFuture(tester, () async {
      final p = await LocalProjectsRepository(db).create('p');
      return LocalNotesRepository(db).create(
        projectId: p.id,
        title: 'a',
        text: '',
        source: NoteSource.pdf,
        attachments: [
          AttachmentDraft(kind: AttachmentKind.pdf, path: '${dir.path}/a.pdf', name: 'a.pdf', bytes: 54945382),
          if (!single) AttachmentDraft(kind: AttachmentKind.pdf, path: '${dir.path}/b.pdf', name: 'b.pdf'),
        ],
      );
    });
  }

  Future<void> openEdit(WidgetTester tester, Note n) async {
    await pumpUntil(tester, find.text('p'));
    tester.element(find.text('p').first).push('/note/${n.id}/edit');
    await pumpUntil(tester, find.text('a.pdf'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> removeFirst(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('a.pdf'),
      150,
      scrollable: find.descendant(of: find.byType(EditNoteScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final remove = find.descendant(of: find.byType(EditNoteScreen), matching: find.byIcon(Icons.close_rounded)).first;
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await pumpUntil(tester, find.text(l10n.removeAttachmentBody));
    await tester.tap(find.text(l10n.delete));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.byType(EditNoteScreen).evaluate().isNotEmpty
        ? find.text(l10n.saveChanges).last
        : find.byKey(const ValueKey('add-save'));
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(save);
  }

  final loadedPdfPaths = <String>[];
  fikraTest(
    'two PDFs open their own stored path and attachment route',
    (tester, db) async {
      loadedPdfPaths.clear();
      final n = await seed(tester, db);
      await pumpUntil(tester, find.text('p'));
      tester.element(find.text('p').first).push('/note/${n.id}');
      await pumpUntil(tester, find.text('b.pdf'));
      expect(tester.widget<Text>(find.text('52.4 MB')).textDirection, TextDirection.ltr);
      await tester.pump(const Duration(milliseconds: 400));
      final attached = await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first);
      for (final a in attached) {
        await tester.tap(find.byKey(ValueKey('open-pdf-${a.id}')));
        await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
        final context = tester.element(find.byType(PdfViewerScreen));
        expect(GoRouterState.of(context).uri.path, '/note/${n.id}/pdf/${a.id}');
        final viewer = tester.widget<PdfViewerScreen>(find.byType(PdfViewerScreen));
        expect(viewer.attachmentId, a.id);
        expect(find.text(a.name!), findsWidgets);
        context.pop();
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(loadedPdfPaths, ['${dir.path}/a.pdf', '${dir.path}/b.pdf']);
    },
    attachmentStore: store,
    pdfLoader: (path) async {
      loadedPdfPaths.add(path);
      throw FileSystemException('', path);
    },
  );

  fikraTest('removal is a draft; leaving discards it and deletes temporary recordings', (tester, db) async {
    final n = await seed(tester, db);
    await tester.runAsync(() => File('${dir.path}/a.pdf').writeAsString('a'));
    await openEdit(tester, n);
    await removeFirst(tester);
    expect(find.text('a.pdf'), findsNothing);
    expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first), hasLength(2));
    expect(await tester.runAsync(() => File('${dir.path}/a.pdf').exists()), isTrue);
    final temp = await tester.runAsync(() => File('${dir.path}/rec_draft.m4a').writeAsString('voice'));
    final state = tester.state(find.byType(EditNoteScreen)) as AttachmentEditing<EditNoteScreen>;
    state.updateDraft(
      () => state.draftFiles = [
        ...state.draftFiles,
        AttachmentDraft(kind: AttachmentKind.voice, path: temp!.path, durationMs: 1000),
      ],
    );
    await tester.pump();
    final mic = find.descendant(of: find.byKey(const ValueKey('add-mic')), matching: find.byType(Pressable));
    expect(tester.widget<Pressable>(mic).onTap, isNotNull);
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text(l10n.unsavedTitle));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(l10n.discardChanges));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(EditNoteScreen), findsNothing);
    expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first), hasLength(2));
    expect(await tester.runAsync(() => File('${dir.path}/a.pdf').exists()), isTrue);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(await tester.runAsync(() => temp!.exists()), isFalse);
  }, attachmentStore: store);

  fikraTest('empty draft is blocked on the edit screen', (tester, db) async {
    final n = await seed(tester, db, single: true);
    await openEdit(tester, n);
    await removeFirst(tester);
    await tapSave(tester);
    await pumpUntil(tester, find.text(l10n.emptyNoteBlocked));
    expect(find.byType(EditNoteScreen), findsOneWidget);
    expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first), hasLength(1));
  }, attachmentStore: store);

  final ai = _CountingAi();
  fikraTest(
    'saved attachment-only changes add files without analysis; file-only Add uses the first name',
    (tester, db) async {
      ai.calls = 0;
      final n = await seed(tester, db);
      await pumpFuture(
        tester,
        () => LocalNotesRepository(db).applyInsights(
          n.id,
          const NoteInsights(
            title: 'files',
            concepts: ['topic'],
            cluster: 'cluster',
            links: [],
            proposedText: 'proposal',
          ),
        ),
      );
      await openEdit(tester, n);
      final picked = await tester.runAsync(() => File('${dir.path}/extra.pdf').writeAsString('extra'));
      picker.files = [_PickedFile(picked!.uri)];
      final pdf = find.byKey(const ValueKey('add-pdf'));
      await Scrollable.ensureVisible(tester.element(pdf), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(pdf);
      await pumpUntil(tester, find.text('extra.pdf'));
      await tapSave(tester);
      await pumpUntil(tester, find.text(l10n.changesSaved));
      expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first), hasLength(3));
      final edited = (await pumpFuture(tester, () => LocalNotesRepository(db).watchNote(n.id).first))!;
      expect(edited.proposedText, 'proposal');
      expect(edited.rewrite, RewriteStatus.pending);
      expect(ai.calls, 0);
      await tester.pumpAndSettle();
      tester.element(find.text('p').first).go('/add');
      await pumpUntil(tester, find.byKey(const ValueKey('add-pdf')));
      await tester.tap(find.byKey(const ValueKey('add-pdf')));
      await pumpUntil(tester, find.text('extra.pdf'));
      await tapSave(tester);
      await pumpUntil(tester, find.text(l10n.noteSaved));
      final all = await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(n.projectId));
      expect(all, hasLength(2));
      expect(all.singleWhere((note) => note.id != n.id).title, 'extra');
      expect(ai.calls, 0);
    },
    attachmentStore: store,
    aiService: ai,
  );

  fikraTest('Add can pick multiple PDFs repeatedly and failed save keeps the draft', (tester, db) async {
    final n = await seed(tester, db);
    await pumpUntil(tester, find.text('p'));
    tester.element(find.text('p').first).go('/add');
    await pumpUntil(tester, find.byKey(const ValueKey('add-pdf')));
    final files = await tester.runAsync(
      () async => [for (var i = 1; i <= 2; i++) await File('${dir.path}/picked-$i.pdf').writeAsString('$i')],
    );
    picker.files = [for (final f in files!) _PickedFile(f.uri)];
    await tester.tap(find.byKey(const ValueKey('add-pdf')));
    await pumpUntil(tester, find.text('picked-2.pdf'));
    final state = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
    expect(state.draftFiles, hasLength(2));
    final pdfButton = find.descendant(of: find.byKey(const ValueKey('add-pdf')), matching: find.byType(Pressable));
    expect(tester.widget<Pressable>(pdfButton).onTap, isNotNull);
    await tester.ensureVisible(find.byKey(const ValueKey('add-pdf')));
    await tester.tap(find.byKey(const ValueKey('add-pdf')));
    await pumpUntil(tester, find.text('picked-2.pdf').last);
    // Wait for the file reads, even though earlier chips already match.
    await pumpFuture(tester, () async {
      while (state.picking) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(state.draftFiles, hasLength(4));
    await pumpFuture(
      tester,
      () => db.customStatement(
        "CREATE TRIGGER fail_save BEFORE INSERT ON note_attachments "
        "BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      ),
    );
    await tapSave(tester);
    await pumpUntil(tester, find.text(l10n.noteSaveFailed));
    expect(state.draftFiles, hasLength(4));
    expect(await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(n.projectId)), hasLength(1));
  }, attachmentStore: store);
}

class _Picker extends FilePickerPlatform {
  List<PlatformFile> files = [];
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files;
}

final class _PickedFile extends PlatformFile {
  _PickedFile(this.uri);
  @override
  final Uri uri;
  @override
  String get name => uri.pathSegments.last;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingAi implements AiService {
  int calls = 0;
  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async {
    calls++;
    return const NoteInsights(title: 'analysis', concepts: [], cluster: '', links: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
