import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/processing/transcript_corrections.dart';
import 'package:fikra/data/processing/transcript_paragraph.dart';
import 'package:fikra/data/processing/transcription_queue.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_transcription_engine.dart';
import 'voice_text/fake_voice_text_backend.dart';

void main() {
  late FikraDatabase db;
  late LocalNotesRepository notes;
  late TranscriptCorrections corrections;
  late Note note;
  late NoteAttachment attachment;
  late List<String> processed;
  setUp(() async {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    notes = LocalNotesRepository(db);
    final p = await LocalProjectsRepository(db).create('project');
    note = await notes.create(
      projectId: p.id,
      title: 'note',
      text: 'typed\n\nmachine',
      source: NoteSource.voice,
      attachments: [const AttachmentDraft(kind: AttachmentKind.voice, path: '/saved.m4a')],
    );
    attachment = (await notes.watchAttachments(note.id).first).single;
    await (db.update(db.noteAttachments)..where((a) => a.id.equals(attachment.id))).write(
      const NoteAttachmentsCompanion(
        transcript: Value('machine'),
        transcriptNoteText: Value('machine'),
        transcriptionStatus: Value(TranscriptionStatus.done),
      ),
    );
    processed = [];
    corrections = TranscriptCorrections(
      db,
      processNote: (id) async {
        processed.add(id);
      },
    );
  });
  Future<NoteAttachment> file() async => (await notes.watchAttachments(note.id).first).single;
  Future<Note> live() async => (await notes.watchNote(note.id).first)!;

  test('paragraph matching never replaces substrings, changed or duplicated paragraphs', () {
    expect(replaceTranscriptParagraph('typed\n\nmachine\n\nend', 'machine', 'corrected'), 'typed\n\ncorrected\n\nend');
    for (final text in ['machine changed', 'prefix machine', 'machine\n\nmachine', 'missing']) {
      expect(replaceTranscriptParagraph(text, 'machine', 'corrected'), isNull);
    }
    expect(replaceTranscriptParagraph('typed\r\n\r\nmachine', 'machine', 'corrected'), 'typed\r\n\r\ncorrected');
    expect(replaceTranscriptParagraph('a\n\nb', 'a\n\nb', 'c'), 'c');
  });
  test('correction replaces exact copy in both bodies, preserves machine and schedules analysis', () async {
    await notes.edit(note.id, title: 'note', text: 'edited\n\nmachine');
    final result = await corrections.save(attachment.id, revision: 0, correction: 'corrected');
    expect(result.noteChanged, isTrue);
    expect(processed, [note.id]);
    final a = await file(), n = await live();
    expect(a.transcript, 'machine');
    expect(a.transcriptCorrection, 'corrected');
    expect(a.correctedAt, isNotNull);
    expect(a.transcriptNoteText, 'corrected');
    expect(a.transcriptRevision, result.revision);
    expect(n.originalText, 'typed\n\ncorrected');
    expect(n.editedText, 'edited\n\ncorrected');
    await corrections.save(a.id, revision: a.transcriptRevision);
    expect((await file()).transcriptCorrection, isNull);
    expect((await live()).editedText, 'edited\n\nmachine');
  });
  for (final changed in ['changed copy', 'machine\n\nmachine', 'missing copy']) {
    test('unsafe edited body $changed keeps both bodies and offers explicit append', () async {
      await notes.edit(note.id, title: 'note', text: changed);
      final before = await live();
      final result = await corrections.save(attachment.id, revision: 0, correction: 'corrected');
      expect(result.noteChanged, isFalse);
      expect(processed, isEmpty);
      expect((await live()).originalText, before.originalText);
      expect((await live()).editedText, before.editedText);
      expect((await file()).transcriptCorrection, 'corrected');
      final appended = await corrections.save(
        attachment.id,
        revision: result.revision,
        correction: 'corrected',
        append: true,
      );
      expect(appended.noteChanged, isTrue);
      expect((await live()).editedText, '$changed\n\ncorrected');
    });
  }
  test('revision conflict leaves newer correction and note untouched', () async {
    await corrections.save(attachment.id, revision: 0, correction: 'newer');
    await expectLater(
      corrections.save(attachment.id, revision: 0, correction: 'stale'),
      throwsA(isA<TranscriptConflict>()),
    );
    expect((await file()).transcriptCorrection, 'newer');
    expect((await live()).originalText, 'typed\n\nnewer');
  });
  test('redo retains correction; use new clears it with safe copy update', () async {
    await corrections.save(attachment.id, revision: 0, correction: 'corrected');
    final engine = FakeTranscriptionEngine(action: (_, _) async => 'new machine');
    final q = TranscriptionQueue(db, FakeVoiceTextSettings(), () async => engine, processNote: (_) async {});
    await q.enqueue(attachment.id, redo: true, manual: true);
    await q.drained;
    final a = await file();
    expect(a.transcript, 'new machine');
    expect(a.transcriptCorrection, 'corrected');
    expect(a.transcriptRevision.isOdd, isTrue);
    expect((await live()).originalText, 'typed\n\ncorrected');
    await corrections.save(a.id, revision: a.transcriptRevision);
    expect((await file()).transcriptCorrection, isNull);
    expect((await live()).originalText, 'typed\n\nnew machine');
  });
  test('attachment replacement carries policy, correction, time, revision and marker from live row', () async {
    await corrections.save(attachment.id, revision: 0, correction: 'corrected');
    final a = await file();
    await notes.edit(note.id, title: 'note', text: (await live()).displayText, attachments: [AttachmentDraft.saved(a)]);
    expect(await file(), a);
  });
  test('off skips recovery; manual request works and becomes an explicit after-save policy', () async {
    await (db.update(db.noteAttachments)..where((a) => a.id.equals(attachment.id))).write(
      const NoteAttachmentsCompanion(
        transcriptionStatus: Value(TranscriptionStatus.queued),
        transcriptionPolicy: Value(TranscriptionPolicy.off),
      ),
    );
    final engine = FakeTranscriptionEngine();
    final q = TranscriptionQueue(db, FakeVoiceTextSettings(), () async => engine, processNote: (_) async {});
    await q.resumeInterrupted();
    await q.drained;
    expect(engine.paths, isEmpty);
    await q.enqueue(attachment.id, manual: true);
    await q.drained;
    expect(engine.paths, ['/saved.m4a']);
    expect((await file()).transcriptionPolicy, TranscriptionPolicy.afterSave);
  });
  test('explicit off defeats auto; default is resolved once without re-queueing existing files', () {
    for (final automatic in [true, false]) {
      final drafts = transcriptionDraft([
        const AttachmentDraft(kind: AttachmentKind.voice, path: '/off', policy: TranscriptionPolicy.off),
        const AttachmentDraft(kind: AttachmentKind.voice, path: '/default'),
        const AttachmentDraft(
          id: 'old',
          kind: AttachmentKind.voice,
          path: '/old',
          policy: TranscriptionPolicy.afterSave,
        ),
      ], automatic: automatic);
      expect(drafts.first.transcribe, isFalse);
      expect(newTranscriptionPaths(drafts), automatic ? ['/default'] : isEmpty);
    }
  });
  test('correction saved during redo wins presentation and stale editor revision conflicts', () async {
    final started = Completer<void>(), release = Completer<String>();
    final engine = FakeTranscriptionEngine(
      action: (_, _) {
        started.complete();
        return release.future;
      },
    );
    final queue = TranscriptionQueue(db, FakeVoiceTextSettings(), () async => engine, processNote: (_) async {});
    addTearDown(() async {
      if (!release.isCompleted) release.complete('new machine');
      await queue.drained;
    });
    await queue.enqueue(attachment.id, redo: true, manual: true);
    await started.future;
    final saved = await corrections.save(attachment.id, revision: 0, correction: 'human words');
    release.complete('new machine');
    await queue.drained;
    final a = await file();
    expect(a.transcriptCorrection, 'human words');
    expect(a.transcript, 'new machine');
    expect((await live()).originalText, 'typed\n\nhuman words');
    await expectLater(
      corrections.save(a.id, revision: saved.revision, correction: 'stale'),
      throwsA(isA<TranscriptConflict>()),
    );
  });
  test('an untouched stale attachment draft preserves a newer live policy and correction', () async {
    final stale = AttachmentDraft.saved(await file());
    await corrections.save(attachment.id, revision: 0, correction: 'new words');
    await (db.update(db.noteAttachments)..where((a) => a.id.equals(attachment.id))).write(
      const NoteAttachmentsCompanion(transcriptionPolicy: Value(TranscriptionPolicy.afterSave)),
    );
    await notes.edit(note.id, title: 'note', text: (await live()).displayText, attachments: [stale]);
    final a = await file();
    expect(a.transcriptCorrection, 'new words');
    expect(a.transcriptionPolicy, TranscriptionPolicy.afterSave);
    await notes.edit(
      note.id,
      title: 'note',
      text: (await live()).displayText,
      attachments: [AttachmentDraft.saved(a).withPolicy(TranscriptionPolicy.off)],
    );
    expect((await file()).transcriptionPolicy, TranscriptionPolicy.off);
  });
  test('an identical safe save keeps a pending proposal and skips analysis', () async {
    await (db.update(db.notes)..where((n) => n.id.equals(note.id))).write(
      const NotesCompanion(proposedText: Value('proposal'), rewrite: Value(RewriteStatus.pending)),
    );
    final result = await corrections.save(attachment.id, revision: 0, correction: 'machine');
    expect(result.noteChanged, isTrue);
    expect(processed, isEmpty);
    final n = await live();
    expect(n.proposedText, 'proposal');
    expect(n.rewrite, RewriteStatus.pending);
    expect((await file()).transcriptRevision, result.revision);
  });
  test('analysis failure after a committed correction is not reported as a failed save', () async {
    final failing = TranscriptCorrections(db, processNote: (_) => Future.error(StateError('ai down')));
    final result = await failing.save(attachment.id, revision: 0, correction: 'corrected');
    expect(result.noteChanged, isTrue);
    expect((await file()).transcriptCorrection, 'corrected');
  });
  for (final policy in TranscriptionPolicy.values) {
    test('a failed run records failure unless the row was switched off; policy=$policy', () async {
      final engine = FakeTranscriptionEngine(
        action: (_, _) async {
          await (db.update(db.noteAttachments)..where((a) => a.id.equals(attachment.id))).write(
            NoteAttachmentsCompanion(
              transcriptionPolicy: Value(policy),
              transcriptionStatus: Value(
                policy == TranscriptionPolicy.off ? TranscriptionStatus.none : TranscriptionStatus.running,
              ),
            ),
          );
          throw StateError('engine');
        },
      );
      final q = TranscriptionQueue(db, FakeVoiceTextSettings(), () async => engine, processNote: (_) async {});
      await q.enqueue(attachment.id, redo: true, manual: true);
      await q.drained;
      expect(
        (await file()).transcriptionStatus,
        policy == TranscriptionPolicy.off ? TranscriptionStatus.none : TranscriptionStatus.failed,
      );
    });
  }
}
