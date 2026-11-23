import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions, Migrator;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fikra/core/widgets/voice_player.dart';
import 'package:fikra/features/shared/note_presentation.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';

import 'generated_migrations/schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory directory;
  late AttachmentStore store;
  late FikraDatabase db;
  late LocalNotesRepository notes;
  late Project project;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fikra-multi-');
    store = AttachmentStore(documentsDir: () async => directory, tempDir: () async => directory);
    db = FikraDatabase(NativeDatabase.memory());
    notes = LocalNotesRepository(db);
    project = await LocalProjectsRepository(db).create('p');
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<List<AttachmentDraft>> sources() async => [
    for (final (i, kind) in [
      AttachmentKind.pdf,
      AttachmentKind.voice,
      AttachmentKind.image,
      AttachmentKind.pdf,
      AttachmentKind.voice,
      AttachmentKind.image,
    ].indexed)
      AttachmentDraft(
        kind: kind,
        path: (await File('${directory.path}/source-$i').writeAsString('$i')).path,
        name: 'source-$i',
        bytes: 1,
        durationMs: kind == AttachmentKind.voice ? 3000 : null,
      ),
  ];
  Future<List<FileSystemEntity>> copies() async {
    final dir = Directory('${directory.path}/attachments');
    return await dir.exists() ? dir.list().toList() : [];
  }

  Future<Note> create(List<AttachmentDraft> draft) => saveAttachmentDraft(
    store,
    draft,
    (stored) =>
        notes.create(projectId: project.id, title: 'files', text: '', source: NoteSource.pdf, attachments: stored),
  );

  for (final interrupted in [false, true]) {
    test('v4 → v5 with data, empty paths and sweep; interrupted=$interrupted', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(4);
      final raw = schema.rawDatabase;
      raw.execute("INSERT INTO projects VALUES ('p', 'p', 1700000000)");
      final files = <String>[];
      for (var i = 0; i < 6; i++) {
        final f = File('${directory.path}/attachments/$i');
        await f.parent.create(recursive: true);
        await f.writeAsString('$i');
        await f.setLastModified(DateTime(2020));
        files.add(f.path);
      }
      raw.execute(
        'INSERT INTO notes (id, project_id, title, original_text, source, status, attachment_path, '
        'attachment_name, attachment_bytes, voice_path, duration_ms, image_paths, created_at, updated_at) '
        "VALUES ('n', 'p', '', '', 'pdf', 'ready', ?, 'book.pdf', 123, ?, 456, ?, 1700000000, 1700000000)",
        [files[0], files[1], files.sublist(2, 5).join('|')],
      );
      for (final id in ['empty', 'blank']) {
        raw.execute(
          'INSERT INTO notes (id, project_id, title, original_text, source, status, '
          'attachment_path, voice_path, image_paths, created_at, updated_at) '
          "VALUES (?, 'p', '', '', 'text', 'ready', ?, ?, ?, 1700000000, 1700000000)",
          [id, id == 'blank' ? ' ' : null, id == 'blank' ? '' : null, id == 'blank' ? '| |' : ''],
        );
      }
      if (interrupted) {
        final v5 = await verifier.schemaAt(5);
        final ddl =
            v5.rawDatabase.select("SELECT sql FROM sqlite_master WHERE name = 'note_attachments'").single['sql']
                as String;
        raw.execute(ddl);
        raw.execute('CREATE INDEX note_attachments_note ON note_attachments (note_id)');
        raw.execute(
          "INSERT INTO note_attachments (id, note_id, kind, path, name, bytes, position, created_at) "
          "VALUES ('legacy:n:pdf', 'n', 'pdf', ?, 'book.pdf', 123, 0, 1700000000)",
          [files[0]],
        );
      }
      final migrated = FikraDatabase(schema.newConnection());
      try {
        await verifier.migrateAndValidate(migrated, 8);
        await migrated.migration.onUpgrade(Migrator(migrated), 4, 5);
        final repo = LocalNotesRepository(migrated);
        final attachments = await repo.watchAttachments('n').first;
        expect(attachments.map((a) => a.kind), [
          AttachmentKind.pdf,
          AttachmentKind.voice,
          AttachmentKind.image,
          AttachmentKind.image,
          AttachmentKind.image,
        ]);
        expect(attachments.map((a) => a.path), files.take(5));
        expect(attachments.map((a) => a.position), [0, 1, 2, 3, 4]);
        expect(attachments.first.name, 'book.pdf');
        expect(attachments.first.bytes, 123);
        expect(attachments[1].durationMs, 456);
        expect(await migrated.select(migrated.noteAttachments).get(), hasLength(5));
        final legacy = await migrated.customSelect("SELECT image_paths FROM notes WHERE id = 'n'").getSingle();
        expect(legacy.read<String>('image_paths'), files.sublist(2, 5).join('|'));
        await store.sweepOrphans(await repo.attachmentPaths());
        for (final path in files.take(5)) {
          expect(await File(path).exists(), isTrue);
        }
        expect(await File(files.last).exists(), isFalse);
      } finally {
        await migrated.close();
      }
    });
  }

  test('create stores two of every kind in draft order, and project stream batches them', () async {
    final draft = await sources();
    final n = await create(draft);
    final attached = await notes.watchAttachments(n.id).first;
    expect(attached.map((a) => a.kind), draft.map((a) => a.kind));
    expect(attachmentIcons(n, attached).map((a) => a.count), [2, 2, 2]);
    expect(sourceIcons(n), hasLength(1));
    expect(attached.map((a) => a.position), [0, 1, 2, 3, 4, 5]);
    for (final (i, a) in attached.indexed) {
      expect(await File(a.path).readAsString(), '$i');
    }
    final grouped = await notes.watchProjectAttachments(project.id).first;
    expect(grouped[n.id], attached);
    expect(await notes.attachmentPaths(), attached.map((a) => a.path).toSet());
  });

  test('copy failure halfway rolls back copies and never inserts a note', () async {
    final draft = await sources();
    draft[3] = const AttachmentDraft(kind: AttachmentKind.pdf, path: '/missing/halfway.pdf');
    await expectLater(create(draft), throwsA(isA<FileSystemException>()));
    expect(await notes.notesOf(project.id), isEmpty);
    expect(await copies(), isEmpty);
    for (final a in draft.take(3)) {
      expect(await File(a.path).exists(), isTrue);
    }
  });

  test('attachment insert failure rolls back the note and all six copies', () async {
    await db.customStatement(
      "CREATE TRIGGER fail_attachment BEFORE INSERT ON note_attachments "
      "BEGIN SELECT RAISE(ABORT, 'injected insert failure'); END",
    );
    await expectLater(create(await sources()), throwsA(anything));
    expect(await notes.notesOf(project.id), isEmpty);
    expect(await copies(), isEmpty);
  });

  test('remove one PDF only after successful commit; attachment edits preserve analysis', () async {
    final n = await create(await sources());
    await notes.applyInsights(
      n.id,
      const NoteInsights(
        title: 'suggestion',
        proposedText: 'proposal',
        concepts: ['topic'],
        cluster: 'cluster',
        links: [],
      ),
    );
    final before = (await notes.watchNote(n.id).first)!;
    final old = await notes.watchAttachments(n.id).first;
    final draft = old.skip(1).map(AttachmentDraft.saved).toList();
    // Merely changing a draft changes neither rows nor files.
    expect(await notes.watchAttachments(n.id).first, old);
    expect(await File(old.first.path).exists(), isTrue);
    await db.customStatement(
      "CREATE TRIGGER fail_delete BEFORE DELETE ON note_attachments "
      "BEGIN SELECT RAISE(ABORT, 'injected commit failure'); END",
    );
    await expectLater(notes.edit(n.id, title: n.title, text: '', attachments: draft), throwsA(anything));
    expect(await notes.watchAttachments(n.id).first, old);
    for (final a in old) {
      expect(await File(a.path).exists(), isTrue);
    }
    await db.customStatement('DROP TRIGGER fail_delete');
    await notes.edit(n.id, title: n.title, text: '', attachments: draft);
    expect(await File(old.first.path).exists(), isFalse);
    for (final a in old.skip(1)) {
      expect(await File(a.path).exists(), isTrue);
    }
    final after = (await notes.watchNote(n.id).first)!;
    expect(after.proposedText, before.proposedText);
    expect(after.concepts, before.concepts);
    expect(after.rewrite, before.rewrite);
    expect(after.status, before.status);
  });

  test('edit adds files; failed commit removes new copies and preserves old rows', () async {
    final n = await create((await sources()).take(1).toList());
    final old = await notes.watchAttachments(n.id).first;
    final draft = [...old.map(AttachmentDraft.saved), ...(await sources()).skip(1)];
    await db.customStatement(
      "CREATE TRIGGER fail_edit BEFORE INSERT ON note_attachments "
      "BEGIN SELECT RAISE(ABORT, 'injected edit failure'); END",
    );
    Future<void> save() =>
        saveAttachmentDraft(store, draft, (stored) => notes.edit(n.id, title: n.title, text: '', attachments: stored));
    await expectLater(save(), throwsA(anything));
    expect(await notes.watchAttachments(n.id).first, old);
    expect((await copies()).map((f) => f.path).toSet(), old.map((a) => a.path).toSet());
    await db.customStatement('DROP TRIGGER fail_edit');
    await save();
    expect(await notes.watchAttachments(n.id).first, hasLength(6));
  });

  test('post-commit non-I/O deletion failure cannot roll back newly saved copies', () async {
    final n = await create((await sources()).take(1).toList());
    final repo = LocalNotesRepository(db, deleteFiles: (_) async => throw StateError('cleanup failure'));
    final added = (await sources()).skip(1).take(1).toList();
    await saveAttachmentDraft(store, added, (stored) => repo.edit(n.id, title: n.title, text: '', attachments: stored));
    final saved = await notes.watchAttachments(n.id).first;
    expect(saved, hasLength(1));
    expect(saved.single.kind, AttachmentKind.voice);
    expect(await File(saved.single.path).exists(), isTrue);
  });

  test('editing away the last PDF recomputes source without re-running analysis', () async {
    final n = await saveAttachmentDraft(
      store,
      (await sources()).take(1).toList(),
      (stored) => notes.create(
        projectId: project.id,
        title: 'files',
        text: 'body',
        source: NoteSource.pdf,
        attachments: stored,
      ),
    );
    await notes.applyInsights(n.id, const NoteInsights(title: 'files', concepts: ['topic'], cluster: '', links: []));
    await notes.edit(n.id, title: n.title, text: 'body', attachments: []);
    final saved = (await notes.watchNote(n.id).first)!;
    expect(saved.source, NoteSource.text);
    expect(saved.conceptList, ['topic']);
    expect(sourceIcons(saved), [sourceIcon(NoteSource.text)]);
  });

  test('an in-flight save is protected by sweepGrace before its paths are committed', () async {
    final draft = (await sources()).take(1).toList();
    final copied = Completer<List<AttachmentDraft>>();
    final commit = Completer<void>();
    final saving = saveAttachmentDraft(store, draft, (stored) async {
      copied.complete(stored);
      await commit.future;
      return notes.create(projectId: project.id, title: 'files', text: '', source: NoteSource.pdf, attachments: stored);
    });
    final pending = await copied.future;
    final file = File(pending.single.path);
    await file.setLastModified(DateTime.now().subtract(const Duration(minutes: 5)));
    try {
      expect(await notes.attachmentPaths(), isEmpty);
      await store.sweepOrphans(await notes.attachmentPaths());
      expect(await file.exists(), isTrue);
    } finally {
      commit.complete();
      await saving;
    }
  });

  test('empty draft is blocked; text edits retain the existing rewrite behavior', () async {
    final n = await create((await sources()).take(1).toList());
    await expectLater(notes.edit(n.id, title: n.title, text: ' ', attachments: []), throwsA(isA<EmptyNoteException>()));
    expect(await notes.watchAttachments(n.id).first, hasLength(1));
    await notes.applyInsights(
      n.id,
      const NoteInsights(
        title: 'suggestion',
        proposedText: 'proposal',
        concepts: ['topic'],
        cluster: 'cluster',
        links: [],
      ),
    );
    await notes.edit(n.id, title: 'title', text: 'new text');
    final edited = (await notes.watchNote(n.id).first)!;
    expect(edited.originalText, '');
    expect(edited.displayText, 'new text');
    expect(edited.proposedText, isNull);
    expect(edited.rewrite, RewriteStatus.none);
  });

  for (final wipe in [false, true]) {
    test('delete every file, wipe=$wipe', () async {
      final n = await create(await sources());
      final paths = await notes.attachmentPaths();
      if (wipe) {
        await LocalSettingsRepository(db, store, transcriptionServices: MemoryTranscriptionServices()).wipeAllData();
      } else {
        await notes.delete(n.id);
      }
      expect(await db.select(db.noteAttachments).get(), isEmpty);
      for (final path in paths) {
        expect(await File(path).exists(), isFalse);
      }
    });
  }

  test('voice starts serialize and stop the previous recording before playing', () async {
    final playback = VoicePlaybackCoordinator();
    final events = <String>[];
    Future<void> stop(String id) async {
      events.add('stop $id');
      await Future<void>.delayed(Duration.zero);
    }

    await Future.wait([
      playback.start('one', () => stop('one'), () => events.add('play one')),
      playback.start('two', () => stop('two'), () => events.add('play two')),
      playback.start('three', () => stop('three'), () => events.add('play three')),
    ]);
    expect(events, ['play one', 'stop one', 'play two', 'stop two', 'play three']);
  });
}
