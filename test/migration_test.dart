import 'package:drift/drift.dart' show driftRuntimeOptions, Migrator;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fikra/data/local/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';

/// Schema snapshots live in drift_schemas/. After changing the tables:
///   dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/
///   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 → v6 produces exactly the current schema', () async {
    final db = FikraDatabase(await verifier.startAt(1));
    await verifier.migrateAndValidate(db, 6);
    await db.close();
  });

  test('v1 → v2 moves recordings to voicePath and keeps PDFs, text and the rest', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO projects (id, name, created_at) VALUES ('p', 'مشروع', 1700000000)");
    void note(String id, String source, {String? path, String? name, int? bytes, int? ms}) => raw.execute(
      'INSERT INTO notes (id, project_id, title, original_text, source, status, rewrite, attachment_path, '
      'attachment_name, attachment_bytes, duration_ms, concepts, created_at, updated_at) '
      "VALUES (?, 'p', ?, 'نص', ?, 'ready', 'none', ?, ?, ?, ?, 'RAG', 1700000000, 1700000000)",
      [id, 'title-$id', source, path, name, bytes, ms],
    );
    note('voice', 'voice', path: '/files/rec.m4a', name: 'تسجيل صوتي', bytes: 2048, ms: 61000);
    note('pdf', 'pdf', path: '/files/doc.pdf', name: 'lecture.pdf', bytes: 9000);
    note('text', 'text');

    final db = FikraDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    final byId = {for (final n in await db.select(db.notes).get()) n.id: n};

    final voice = byId['voice']!;
    expect(voice.voicePath, '/files/rec.m4a');
    expect(voice.durationMs, 61000);
    expect([voice.attachmentPath, voice.attachmentName, voice.attachmentBytes], everyElement(isNull));
    expect(voice.source, NoteSource.voice);
    expect(
      (await db.select(db.noteAttachments).get()).where((a) => a.noteId == voice.id).single.path,
      '/files/rec.m4a',
    );

    final pdf = byId['pdf']!;
    expect(pdf.attachmentPath, '/files/doc.pdf');
    expect(pdf.attachmentName, 'lecture.pdf');
    expect(pdf.attachmentBytes, 9000);
    expect(pdf.voicePath, isNull);

    final text = byId['text']!;
    expect((await db.select(db.noteAttachments).get()).where((a) => a.noteId == text.id), isEmpty);
    expect(text.conceptList, ['RAG']);
    expect(text.title, 'title-text');
    await db.close();
  });

  test('an interrupted v1 → v2 upgrade (column added, version still 1) still opens', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO projects (id, name, created_at) VALUES ('p', 'مشروع', 1700000000)");
    raw.execute(
      'INSERT INTO notes (id, project_id, title, original_text, source, status, rewrite, attachment_path, '
      "duration_ms, concepts, created_at, updated_at) VALUES ('v', 'p', '', '', 'voice', 'ready', 'none', "
      "'/files/rec.m4a', 5000, '', 1700000000, 1700000000)",
    );
    // What a crash right after ALTER TABLE leaves behind: user_version is still 1.
    raw.execute('ALTER TABLE notes ADD COLUMN voice_path TEXT NULL');
    expect(raw.userVersion, 1);

    final db = FikraDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    final n = await db.select(db.notes).getSingle();
    expect(n.voicePath, '/files/rec.m4a');
    expect(n.attachmentPath, isNull);
    expect(n.durationMs, 5000);
    await db.close();
  });

  test('v2 → v3 adds the indexes, and a re-run after an interruption still opens', () async {
    final schema = await verifier.schemaAt(2);
    // An interrupted v3 upgrade: one index already exists, user_version still 2.
    schema.rawDatabase.execute('CREATE INDEX notes_status ON notes (status)');
    final db = FikraDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    final names = (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index'").get())
        .map((r) => r.read<String>('name'))
        .toSet();
    expect(
      names,
      containsAll([
        'notes_project_created',
        'notes_status',
        'note_links_project',
        'note_links_source',
        'note_links_target',
        'chat_entries_project_created',
      ]),
    );
    final plan = await db
        .customSelect("EXPLAIN QUERY PLAN SELECT * FROM notes WHERE project_id = 'p' ORDER BY created_at DESC")
        .get();
    expect(plan.map((r) => r.read<String>('detail')).join(' '), contains('notes_project_created'));
    await db.close();
  });

  test('v3 → v4 adds photos without touching existing notes, and survives a re-run', () async {
    final schema = await verifier.schemaAt(3);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO projects (id, name, created_at) VALUES ('p', 'مشروع', 1700000000)");
    raw.execute(
      'INSERT INTO notes (id, project_id, title, original_text, extracted_text, source, status, rewrite, '
      "attachment_path, attachment_name, concepts, created_at, updated_at) VALUES ('n', 'p', 't', 'نص', 'مستخرج', "
      "'pdf', 'ready', 'none', '/files/doc.pdf', 'doc.pdf', 'RAG', 1700000000, 1700000000)",
    );
    // An interrupted upgrade: the column exists, user_version is still 3.
    raw.execute("ALTER TABLE notes ADD COLUMN image_paths TEXT NOT NULL DEFAULT ''");

    final db = FikraDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    final n = await db.select(db.notes).getSingle();
    expect((await db.select(db.noteAttachments).get()).where((a) => a.kind == AttachmentKind.image), isEmpty);
    expect(n.attachmentPath, '/files/doc.pdf');
    expect(n.extractedText, 'مستخرج');
    expect(n.displayText, 'نص\n\nمستخرج');
    await db.close();
  });
  for (final from in [4, 5]) {
    for (final partial in [false, true]) {
      test('populated v$from → v6 preserves rows; interrupted=$partial and full rerun', () async {
        final schema = await verifier.schemaAt(from);
        final raw = schema.rawDatabase;
        raw.execute("INSERT INTO projects VALUES ('p', 'project', 1700000000)");
        for (final id in ['a', 'b']) {
          raw.execute(
            'INSERT INTO notes (id, project_id, title, original_text, source, status, attachment_path, '
            'attachment_name, attachment_bytes, voice_path, duration_ms, image_paths, created_at, updated_at) '
            "VALUES (?, 'p', 'title', 'original', 'pdf', 'ready', '/a.pdf', 'a.pdf', 42, '/a.m4a', 123, "
            "'/a.jpg', 1700000000, 1700000000)",
            [id],
          );
        }
        raw.execute("INSERT INTO note_links VALUES ('ab', 'p', 'a', 'b', 'reason', 0.75)");
        raw.execute("INSERT INTO note_links VALUES ('ba', 'p', 'b', 'a', 'reverse', 0.25)");
        if (from == 5) {
          raw.execute(
            "INSERT INTO note_attachments (id, note_id, kind, path, position, created_at) "
            "VALUES ('saved', 'a', 'image', '/saved.jpg', 7, 1700000000)",
          );
        }
        if (partial) {
          // A partial v6 step with data already written must not be reset.
          final v6 = await verifier.schemaAt(6);
          raw.execute(
            v6.rawDatabase.select("SELECT sql FROM sqlite_master WHERE name = 'note_groups'").single['sql'] as String,
          );
          raw.execute('ALTER TABLE notes ADD COLUMN group_id TEXT NULL REFERENCES note_groups(id) ON DELETE SET NULL');
          raw.execute("ALTER TABLE note_links ADD COLUMN origin TEXT NOT NULL DEFAULT 'ai'");
          raw.execute("INSERT INTO note_groups VALUES ('g', 'p', NULL, 'group', 2, 0, 1700000000)");
          raw.execute("UPDATE notes SET group_id = 'g' WHERE id = 'a'");
          raw.execute('CREATE INDEX note_groups_project ON note_groups(project_id)');
          expect(raw.userVersion, from);
        }
        final db = FikraDatabase(schema.newConnection());
        try {
          await verifier.migrateAndValidate(db, 6);
          final declaredColumns = db.notes.$columns.map((c) => c.$name).toList();
          final physicalColumns = (await db.customSelect('PRAGMA table_info(notes)').get())
              .map((r) => r.read<String>('name'))
              .toList();
          expect(declaredColumns, physicalColumns);
          expect(declaredColumns.last, 'group_id');
          final labelColumn = (await db.customSelect('PRAGMA table_info(note_links)').get()).singleWhere(
            (r) => r.read<String>('name') == 'label',
          );
          expect(labelColumn.read<int>('notnull'), 1);
          final notesBefore = await db.select(db.notes).get();
          final linksBefore = await db.select(db.noteLinks).get();
          final filesBefore = await db.select(db.noteAttachments).get();
          final groupsBefore = await db.select(db.noteGroups).get();
          expect(notesBefore, hasLength(2));
          expect(notesBefore.first.originalText, 'original');
          expect(notesBefore.first.attachmentPath, '/a.pdf');
          expect(filesBefore, hasLength(from == 4 ? 6 : 1));
          if (from == 4) {
            expect(filesBefore.where((a) => a.noteId == 'a').map((a) => a.path), ['/a.pdf', '/a.m4a', '/a.jpg']);
          } else {
            expect(filesBefore.single.id, 'saved');
            expect(filesBefore.single.position, 7);
          }
          expect(linksBefore.map((l) => l.id), ['ab', 'ba']);
          expect(linksBefore.map((l) => l.label), ['reason', 'reverse']);
          expect(linksBefore.map((l) => l.strength), [0.75, 0.25]);
          expect(linksBefore.every((l) => l.origin == LinkOrigin.ai && !l.dismissed && l.createdAt == null), isTrue);
          expect(groupsBefore, hasLength(partial ? 1 : 0));
          expect(notesBefore.first.groupId, partial ? 'g' : null);
          await db.migration.onUpgrade(Migrator(db), 5, 6);
          await db.migration.onUpgrade(Migrator(db), 5, 6);
          expect(await db.select(db.notes).get(), notesBefore);
          expect(await db.select(db.noteLinks).get(), linksBefore);
          expect(await db.select(db.noteAttachments).get(), filesBefore);
          expect(await db.select(db.noteGroups).get(), groupsBefore);
          expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
        } finally {
          await db.close();
        }
      });
    }
  }
}
