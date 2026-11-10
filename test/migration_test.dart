import 'package:drift/drift.dart' show driftRuntimeOptions;
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

  test('v1 → v5 produces exactly the current schema', () async {
    final db = FikraDatabase(await verifier.startAt(1));
    await verifier.migrateAndValidate(db, 5);
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
    await verifier.migrateAndValidate(db, 5);
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
    await verifier.migrateAndValidate(db, 5);
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
    await verifier.migrateAndValidate(db, 5);
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
    await verifier.migrateAndValidate(db, 5);
    final n = await db.select(db.notes).getSingle();
    expect((await db.select(db.noteAttachments).get()).where((a) => a.kind == AttachmentKind.image), isEmpty);
    expect(n.attachmentPath, '/files/doc.pdf');
    expect(n.extractedText, 'مستخرج');
    expect(n.displayText, 'نص\n\nمستخرج');
    await db.close();
  });
}
