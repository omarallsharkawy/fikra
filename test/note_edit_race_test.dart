import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/processing/transcript_corrections.dart';
import 'package:fikra/data/processing/transcription_queue.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_transcription_engine.dart';
import 'voice_text/fake_voice_text_backend.dart';

class _PausedCopies extends AttachmentStore {
  _PausedCopies(Directory dir) : super(documentsDir: () async => dir);
  final copied = Completer<void>();
  final proceed = Completer<void>();
  String? destination;
  @override
  Future<String> persist(String source, {required String extension}) async {
    destination = await super.persist(source, extension: extension);
    copied.complete();
    await proceed.future;
    return destination!;
  }
}

void main() {
  late FikraDatabase db;
  late LocalNotesRepository notes;
  late Project project;
  late FakeTranscriptionEngine engine;
  late TranscriptionQueue queue;
  late Directory dir;
  late File source;
  setUp(() async {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    notes = LocalNotesRepository(db);
    project = await LocalProjectsRepository(db).create('p');
    dir = await Directory.systemTemp.createTemp('fikra-edit-race-');
    addTearDown(() => dir.delete(recursive: true));
    source = await File('${dir.path}/source.jpg').writeAsString('fake image');
    engine = FakeTranscriptionEngine(action: (_, _) async => 'same words');
    queue = TranscriptionQueue(db, FakeVoiceTextSettings(), () async => engine, processNote: (_) async {});
  });
  Future<Note> seed({int voices = 1}) => notes.create(
    projectId: project.id,
    title: 'Title',
    text: 'Typed',
    source: NoteSource.voice,
    attachments: [
      for (var i = 0; i < voices; i++)
        AttachmentDraft(kind: AttachmentKind.voice, path: '${dir.path}/voice$i.m4a', transcribe: true),
    ],
  );
  Future<NoteEditBasis> basis(Note n) async =>
      NoteEditBasis((await notes.watchNote(n.id).first)!, await notes.watchAttachments(n.id).first);
  Future<void> finish(NoteAttachment a, {bool redo = false}) async {
    await queue.enqueue(a.id, redo: redo, manual: true);
    await queue.drained;
  }

  Future<void> save(NoteEditBasis base, String draft, {List<AttachmentDraft>? attachments}) =>
      notes.edit(base.note.id, title: base.note.title, text: draft, basis: base, attachments: attachments);

  for (final variant in [(false, 1), (true, 1), (false, 2), (true, 2)]) {
    final (edited, voices) = variant;
    test('$voices transcripts during staged save survive typed edit; prior edit=$edited', () async {
      final n = await seed(voices: voices);
      if (edited) await notes.edit(n.id, title: 'Title', text: 'Previously edited');
      final base = await basis(n);
      final store = _PausedCopies(dir);
      final draft = [
        ...base.attachments.map(AttachmentDraft.saved),
        AttachmentDraft(kind: AttachmentKind.image, path: source.path),
      ];
      final pending = saveAttachmentDraft(store, draft, (stored) => save(base, 'My typed edit', attachments: stored));
      addTearDown(() async {
        if (!store.proceed.isCompleted) store.proceed.complete();
        await pending.catchError((_) {});
      });
      await store.copied.future;
      for (final a in base.attachments) {
        await finish(a);
      }
      store.proceed.complete();
      await pending;
      final live = (await notes.watchNote(n.id).first)!;
      final appended = List.filled(voices, 'same words').join('\n\n');
      expect(live.displayText, 'My typed edit\n\n$appended');
      expect(live.editedText, live.displayText);
      expect(live.originalText, 'Typed\n\n$appended');
      expect((await notes.watchAttachments(n.id).first).where((a) => a.transcript == 'same words'), hasLength(voices));
      expect(await File(store.destination!).exists(), isTrue);
      expect(await source.exists(), isTrue);
    });
  }

  test('attachment-only save retains the completed body and original/edit state', () async {
    final n = await seed();
    final base = await basis(n);
    await finish(base.attachments.single);
    final before = (await notes.watchNote(n.id).first)!;
    await save(base, base.note.displayText, attachments: base.attachments.map(AttachmentDraft.saved).toList());
    final live = (await notes.watchNote(n.id).first)!;
    expect(live.displayText, before.displayText);
    expect(live.editedText, isNull);
    expect((await notes.watchAttachments(n.id).first).single.transcriptRevision, greaterThan(0));
  });

  test('prior correction, typed change and explicit removal survive a different attachment finishing', () async {
    final n = await seed(voices: 2);
    final initial = await basis(n);
    await finish(initial.attachments.first);
    final done = (await basis(n)).attachments.first;
    await TranscriptCorrections(
      db,
      processNote: (_) async {},
    ).save(done.id, revision: done.transcriptRevision, correction: 'Prior correction');
    final base = await basis(n);
    await finish(base.attachments.last);
    await save(base, 'Typed edit\n\nPrior correction');
    expect((await notes.watchNote(n.id).first)!.displayText, 'Typed edit\n\nPrior correction\n\nsame words');

    final next = await basis(n);
    // Remove the correction explicitly while a redo updates only machine text.
    engine.action = (_, _) async => 'redo machine';
    await finish(next.attachments.first, redo: true);
    await save(next, 'Typed edit\n\nsame words');
    expect((await notes.watchNote(n.id).first)!.displayText, 'Typed edit\n\nsame words');
    expect((await basis(n)).attachments.first.transcriptCorrection, 'Prior correction');
  });

  test('disjoint correction merges; concurrent transcript deletion stays deleted', () async {
    final n = await seed();
    await finish((await basis(n)).attachments.single);
    var base = await basis(n);
    await TranscriptCorrections(
      db,
      processNote: (_) async {},
    ).save(base.attachments.single.id, revision: base.attachments.single.transcriptRevision, correction: 'Corrected');
    await save(base, 'Typed edit\n\nsame words');
    expect((await notes.watchNote(n.id).first)!.displayText, 'Typed edit\n\nCorrected');
    base = await basis(n);
    await TranscriptCorrections(db, processNote: (_) async {}).save(
      base.attachments.single.id,
      revision: base.attachments.single.transcriptRevision,
      correction: 'Corrected again',
    );
    await save(base, 'Typed edit');
    expect((await notes.watchNote(n.id).first)!.displayText, 'Typed edit');
  });

  test('competing correction conflicts, keeps draft/source, and rolls back every staged copy', () async {
    final n = await seed();
    await finish((await basis(n)).attachments.single);
    final base = await basis(n);
    final store = _PausedCopies(dir);
    const draftText = 'Typed\n\nMy competing correction';
    final pending = saveAttachmentDraft(store, [
      ...base.attachments.map(AttachmentDraft.saved),
      AttachmentDraft(kind: AttachmentKind.image, path: source.path),
    ], (stored) => save(base, draftText, attachments: stored));
    final assertion = expectLater(pending, throwsA(isA<NoteEditConflict>()));
    addTearDown(() async {
      if (!store.proceed.isCompleted) store.proceed.complete();
      await assertion;
    });
    await store.copied.future;
    await TranscriptCorrections(db, processNote: (_) async {}).save(
      base.attachments.single.id,
      revision: base.attachments.single.transcriptRevision,
      correction: 'Background correction',
    );
    store.proceed.complete();
    await assertion;
    expect((await notes.watchNote(n.id).first)!.displayText, 'Typed\n\nBackground correction');
    expect(await notes.watchAttachments(n.id).first, hasLength(1));
    expect(await File(store.destination!).exists(), isFalse);
    expect(await source.exists(), isTrue);
    expect(await Directory('${dir.path}/attachments').list().toList(), isEmpty);
  });

  test('legacy extracted text remains visible beside an identified new transcript', () async {
    final n = await seed();
    await (db.update(
      db.notes,
    )..where((row) => row.id.equals(n.id))).write(const NotesCompanion(extractedText: Value('PDF kept')));
    final base = await basis(n);
    await finish(base.attachments.single);
    await save(base, 'Typed edit\n\nPDF kept');
    expect((await notes.watchNote(n.id).first)!.displayText, 'Typed edit\n\nPDF kept\n\nsame words');
  });

  test('unidentified concurrent body change returns typed conflict', () async {
    final n = await seed();
    final base = await basis(n);
    await notes.edit(n.id, title: 'Title', text: 'Other editor');
    await expectLater(save(base, 'My edit'), throwsA(isA<NoteEditConflict>()));
    expect((await notes.watchNote(n.id).first)!.displayText, 'Other editor');
  });
}
