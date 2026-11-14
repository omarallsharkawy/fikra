import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/data/processing/transcription_queue.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_transcription_engine.dart';
import 'voice_text/fake_voice_text_backend.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FikraDatabase db;
  late LocalNotesRepository notes;
  late Project project;
  late FakeTranscriptionEngine engine;
  late FakeVoiceTextSettings settings;
  late TranscriptionQueue queue;
  late List<String> processed;

  setUp(() async {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    notes = LocalNotesRepository(db);
    project = await LocalProjectsRepository(db).create('p');
    engine = FakeTranscriptionEngine();
    settings = FakeVoiceTextSettings(language: 'en');
    processed = [];
    queue = TranscriptionQueue(
      db,
      settings,
      () async => engine,
      processNote: (id) async {
        processed.add(id);
      },
    );
  });

  Completer<String> releaseGate() {
    final gate = Completer<String>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete('teardown');
    });
    return gate;
  }

  Future<Note> seed({String text = 'typed', int voices = 1}) => notes.create(
    projectId: project.id,
    title: 'note',
    text: text,
    source: NoteSource.voice,
    attachments: [for (var i = 0; i < voices; i++) AttachmentDraft(kind: AttachmentKind.voice, path: '/$i.m4a')],
  );
  Future<List<NoteAttachment>> files(Note n) => notes.watchAttachments(n.id).first;
  Future<Note> live(Note n) async => (await notes.watchNote(n.id).first)!;

  test('FIFO, one at a time, idempotent while queued/running; processor after success', () async {
    final n = await seed(voices: 3);
    final a = await files(n);
    final started = Completer<void>();
    final release = releaseGate();
    var active = 0;
    var maxActive = 0;
    engine.action = (path, language) async {
      active++;
      if (active > maxActive) maxActive = active;
      if (path == a[0].path) {
        started.complete();
        await release.future;
      }
      active--;
      return 'transcript $path';
    };
    await queue.enqueue(a[0].id);
    await started.future;
    await queue.enqueue(a[1].id);
    await queue.enqueue(a[0].id);
    await queue.enqueue(a[1].id);
    await queue.enqueue(a[2].id);
    expect(engine.paths, [a[0].path]);
    expect((await files(n))[1].transcriptionStatus, TranscriptionStatus.queued);
    release.complete('ok');
    await queue.drained;
    expect(engine.paths, a.map((a) => a.path));
    expect(engine.languages, everyElement('en'));
    expect(maxActive, 1);
    expect(processed, [n.id, n.id, n.id]);
    expect((await files(n)).every((a) => a.transcriptionStatus == TranscriptionStatus.done), isTrue);
  });

  test('success stores engine/time, appends once, user edit during inference wins', () async {
    final n = await seed();
    final a = (await files(n)).single;
    final started = Completer<void>();
    final release = releaseGate();
    engine.action = (_, _) {
      started.complete();
      return release.future;
    };
    await queue.enqueue(a.id);
    await started.future;
    await notes.edit(n.id, title: 'edited title', text: 'new text');
    release.complete('spoken words');
    await queue.drained;
    final result = (await files(n)).single;
    expect(result.transcript, 'spoken words');
    expect(result.transcriptionEngine, engine.id);
    expect(result.transcribedAt, isNotNull);
    expect(result.transcriptionFailure, isNull);
    expect((await live(n)).displayText, 'new text\n\nspoken words');
    expect((await live(n)).originalText, 'typed');
    expect((await live(n)).title, 'edited title');
    engine.action = (_, _) async => 'spoken words';
    await queue.enqueue(a.id, redo: true);
    await queue.drained;
    expect((await live(n)).displayText, 'new text\n\nspoken words');
  });

  test('redo replaces attachment text without doubling note text; removed old text permits append', () async {
    final n = await seed(text: '');
    final id = (await files(n)).single.id;
    engine.action = (_, _) async => 'old words';
    await queue.enqueue(id, redo: true);
    await queue.drained;
    expect((await live(n)).displayText, 'old words');
    engine.action = (_, _) async => 'new words';
    await queue.enqueue(id, redo: true);
    await queue.drained;
    expect((await files(n)).single.transcript, 'new words');
    expect((await live(n)).displayText, 'old words');
    await queue.enqueue(id, redo: true);
    await queue.drained;
    expect((await live(n)).displayText, 'old words');
    await notes.edit(n.id, title: '', text: 'user removed transcript');
    await queue.enqueue(id, redo: true);
    await queue.drained;
    expect((await live(n)).displayText, 'user removed transcript\n\nnew words');
    await queue.enqueue(id, redo: true);
    await queue.drained;
    expect((await live(n)).displayText, 'user removed transcript\n\nnew words');
  });

  for (final kind in ['note', 'attachment', 'kind']) {
    test('queued $kind deletion/change skipped without writes or engine invocation', () async {
      final first = await seed();
      final second = await seed();
      final a = (await files(first)).single;
      final b = (await files(second)).single;
      final started = Completer<void>();
      final release = releaseGate();
      engine.action = (_, _) {
        started.complete();
        return release.future;
      };
      await queue.enqueue(a.id);
      await started.future;
      await queue.enqueue(b.id);
      if (kind == 'note') {
        await notes.delete(second.id);
      } else if (kind == 'attachment') {
        await (db.delete(db.noteAttachments)..where((a) => a.id.equals(b.id))).go();
      } else {
        await (db.update(
          db.noteAttachments,
        )..where((a) => a.id.equals(b.id))).write(const NoteAttachmentsCompanion(kind: Value(AttachmentKind.image)));
      }
      release.complete('first');
      await queue.drained;
      expect(engine.paths, [a.path]);
      expect(processed, [first.id]);
      if (kind == 'kind') {
        expect((await files(second)).single.transcriptionStatus, TranscriptionStatus.queued);
        expect((await files(second)).single.transcript, isNull);
      }
    });
  }

  test('deletion while inference is running does not resurrect rows or analyze', () async {
    final n = await seed();
    final a = (await files(n)).single;
    final started = Completer<void>();
    final release = releaseGate();
    engine.action = (_, _) {
      started.complete();
      return release.future;
    };
    await queue.enqueue(a.id);
    await started.future;
    await notes.delete(n.id);
    release.complete('gone');
    await queue.drained;
    expect(await files(n), isEmpty);
    expect(processed, isEmpty);
  });

  for (final reason in TranscriptionFailureReason.values) {
    test('failure ${reason.name} is explainable and never stalls next job', () async {
      final n = await seed(voices: 2);
      final a = await files(n);
      engine.action = (path, _) async {
        if (path == a[0].path) throw TranscriptionFailure(reason);
        return 'second';
      };
      await queue.enqueue(a[0].id);
      await queue.enqueue(a[1].id);
      await queue.drained;
      final result = await files(n);
      expect(result[0].transcriptionStatus, TranscriptionStatus.failed);
      expect(result[0].transcriptionFailure, reason.name);
      expect(result[1].transcriptionStatus, TranscriptionStatus.done);
    });
  }

  test('empty audio output and unexpected errors have stable failure reasons', () async {
    final n = await seed(voices: 2);
    final a = await files(n);
    engine.action = (path, _) async {
      if (path == a[0].path) return '  ';
      throw StateError('native details');
    };
    await queue.enqueue(a[0].id);
    await queue.enqueue(a[1].id);
    await queue.drained;
    expect((await files(n)).map((a) => a.transcriptionFailure), ['audioUnreadable', 'other']);
  });

  test('resumeInterrupted recovers queued and running only, repeated calls are idempotent', () async {
    final n = await seed(voices: 3);
    final a = await files(n);
    for (final (i, status) in [TranscriptionStatus.queued, TranscriptionStatus.running].indexed) {
      await (db.update(
        db.noteAttachments,
      )..where((f) => f.id.equals(a[i].id))).write(NoteAttachmentsCompanion(transcriptionStatus: Value(status)));
    }
    final started = Completer<void>();
    final release = releaseGate();
    engine.action = (path, _) async {
      if (path == a[0].path) {
        started.complete();
        return release.future;
      }
      return 'recovered';
    };
    await queue.resumeInterrupted();
    await started.future;
    await queue.resumeInterrupted();
    release.complete('first');
    await queue.drained;
    expect(engine.paths, a.take(2).map((a) => a.path));
    expect((await files(n))[2].transcriptionStatus, TranscriptionStatus.none);
  });
  test('normal enqueue ignores completed rows; save wake-up is restricted to newly copied paths', () async {
    final n = await seed(voices: 2);
    final a = await files(n);
    await queue.enqueue(a[0].id);
    await queue.drained;
    await queue.enqueue(a[0].id);
    await queue.drained;
    expect(engine.paths, [a[0].path]);
    await (db.update(db.noteAttachments)..where((f) => f.id.equals(a[0].id))).write(
      const NoteAttachmentsCompanion(transcriptionStatus: Value(TranscriptionStatus.failed)),
    );
    await (db.update(db.noteAttachments)..where((f) => f.id.equals(a[1].id))).write(
      const NoteAttachmentsCompanion(transcriptionStatus: Value(TranscriptionStatus.queued)),
    );
    await queue.saved(n.id, [a[1].path]);
    await queue.drained;
    expect(engine.paths, [a[0].path, a[1].path]);
    expect((await files(n))[0].transcriptionStatus, TranscriptionStatus.failed);
  });
  test('resume respects original request order rather than note creation order', () async {
    final older = await seed();
    final newer = await seed();
    final first = (await files(older)).single;
    final second = (await files(newer)).single;
    await (db.update(db.noteAttachments)..where((a) => a.id.equals(first.id))).write(
      const NoteAttachmentsCompanion(
        transcriptionStatus: Value(TranscriptionStatus.queued),
        transcriptionOrder: Value(2),
      ),
    );
    await (db.update(db.noteAttachments)..where((a) => a.id.equals(second.id))).write(
      const NoteAttachmentsCompanion(
        path: Value('/newer.m4a'),
        transcriptionStatus: Value(TranscriptionStatus.running),
        transcriptionOrder: Value(1),
      ),
    );
    await queue.resumeInterrupted();
    await queue.drained;
    expect(engine.paths, ['/newer.m4a', first.path]);
  });

  test('engine preparation failure marks model missing without touching note text', () async {
    final n = await seed();
    final id = (await files(n)).single.id;
    queue = TranscriptionQueue(
      db,
      settings,
      () async => throw const TranscriptionFailure(TranscriptionFailureReason.modelMissing),
      processNote: (id) async {
        processed.add(id);
      },
    );
    await queue.enqueue(id);
    await queue.drained;
    expect((await files(n)).single.transcriptionFailure, 'modelMissing');
    expect((await live(n)).displayText, 'typed');
    expect(processed, isEmpty);
    expect(engine.paths, isEmpty);
  });

  group('the app closing during transcription', () {
    // A new queue over the same database is a new process after a kill: the
    // old queue's job never finishes (native work died with the process).
    Future<TranscriptionQueue> launch(Completer<void> started, Completer<String> hang) async {
      final process = TranscriptionQueue(db, settings, () async => engine, processNote: (_) async {});
      engine.action = (_, _) {
        if (!started.isCompleted) started.complete();
        return hang.future;
      };
      await process.resumeInterrupted();
      return process;
    }

    Future<void> killMidRun(Future<void> Function() start) async {
      final started = Completer<void>();
      final hang = releaseGate();
      engine.action = (_, _) {
        started.complete();
        return hang.future;
      };
      await start();
      await started.future;
    }

    test('two kills mark the recording failed on the next launch without running it again', () async {
      final n = await seed();
      final id = (await files(n)).single.id;
      await killMidRun(() => queue.enqueue(id));
      var row = (await files(n)).single;
      expect(row.transcriptionStatus, TranscriptionStatus.running);
      expect(row.transcriptionAttempts, 1);

      // Second launch: resumed once, killed again during inference.
      final started = Completer<void>();
      await launch(started, releaseGate());
      await started.future;
      row = (await files(n)).single;
      expect(row.transcriptionStatus, TranscriptionStatus.running);
      expect(row.transcriptionAttempts, 2);

      // Third launch: not started again.
      final calls = engine.paths.length;
      final third = TranscriptionQueue(db, settings, () async => engine, processNote: (_) async {});
      await third.resumeInterrupted();
      await third.drained;
      row = (await files(n)).single;
      expect(engine.paths, hasLength(calls));
      expect(row.transcriptionStatus, TranscriptionStatus.failed);
      expect(row.transcriptionFailure, TranscriptionFailureReason.interruptedTwice.name);
      expect((await live(n)).displayText, 'typed');
    });

    test('one kill while waiting in the queue does not count; a kill during inference does', () async {
      final n = await seed(voices: 2);
      final a = await files(n);
      await killMidRun(() async {
        await queue.enqueue(a[0].id);
        await queue.enqueue(a[1].id);
      });
      final rows = await files(n);
      expect(rows.map((r) => (r.transcriptionStatus, r.transcriptionAttempts)), [
        (TranscriptionStatus.running, 1),
        (TranscriptionStatus.queued, 0),
      ]);
    });

    test("the user's retry starts the count again", () async {
      final n = await seed();
      final id = (await files(n)).single.id;
      await (db.update(db.noteAttachments)..where((a) => a.id.equals(id))).write(
        const NoteAttachmentsCompanion(
          transcriptionStatus: Value(TranscriptionStatus.running),
          transcriptionAttempts: Value(2),
        ),
      );
      await queue.resumeInterrupted();
      await queue.drained;
      expect((await files(n)).single.transcriptionFailure, 'interruptedTwice');
      expect(engine.paths, isEmpty);

      engine.action = null;
      await queue.enqueue(id, manual: true);
      await queue.drained;
      final row = (await files(n)).single;
      expect(row.transcriptionStatus, TranscriptionStatus.done);
      expect(row.transcriptionAttempts, 1);
      expect(engine.paths, [row.path]);

      // Redo also starts again, so a later kill gets two more launches.
      await (db.update(
        db.noteAttachments,
      )..where((a) => a.id.equals(id))).write(const NoteAttachmentsCompanion(transcriptionAttempts: Value(2)));
      await queue.enqueue(id, redo: true, manual: true);
      await queue.drained;
      expect((await files(n)).single.transcriptionAttempts, 1);
    });

    test('launch recovery and save wake-ups keep the count', () async {
      final n = await seed();
      final id = (await files(n)).single.id;
      await (db.update(db.noteAttachments)..where((a) => a.id.equals(id))).write(
        const NoteAttachmentsCompanion(
          transcriptionStatus: Value(TranscriptionStatus.queued),
          transcriptionAttempts: Value(1),
        ),
      );
      await queue.saved(n.id, [(await files(n)).single.path]);
      await queue.drained;
      expect((await files(n)).single.transcriptionAttempts, 2);
    });
  });
}
