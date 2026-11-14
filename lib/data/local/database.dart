import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum NoteSource { text, voice, pdf }

enum AttachmentKind { pdf, voice, image }

enum LinkOrigin { ai, user }

enum TranscriptionStatus { none, queued, running, done, failed }

/// "Saved" and "AI finished" are separate states.
enum ProcessingStatus { processing, ready, failed }

enum RewriteStatus { none, pending, accepted, rejected }

@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Note')
@TableIndex(name: 'notes_project_created', columns: {#projectId, #createdAt})
@TableIndex(name: 'notes_status', columns: {#status})
@TableIndex(name: 'notes_group', columns: {#groupId})
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();

  /// Exactly what the user typed. Never overwritten.
  TextColumn get originalText => text()();

  /// Text the old demo filled in from a recording or PDF. Nothing writes it
  /// now: attachments stay on the phone and are never parsed.
  TextColumn get extractedText => text().nullable()();

  /// The version shown when set: an accepted AI rewrite or a user edit.
  TextColumn get editedText => text().nullable()();

  /// AI rewrite waiting for accept / reject.
  TextColumn get proposedText => text().nullable()();

  /// The main content: `pdf` when a PDF is attached (a voice memo may sit
  /// beside it), `voice` for a recording alone, otherwise `text`.
  TextColumn get source => textEnum<NoteSource>()();
  TextColumn get status => textEnum<ProcessingStatus>()();
  TextColumn get rewrite => textEnum<RewriteStatus>().withDefault(const Constant('none'))();

  /// Legacy PDF columns, retained for migration/recovery only since v5.
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get attachmentName => text().nullable()();
  IntColumn get attachmentBytes => integer().nullable()();

  /// Legacy recording columns, retained for migration/recovery only since v5.
  TextColumn get voicePath => text().nullable()();
  IntColumn get durationMs => integer().nullable()();

  /// Legacy photo paths separated by '|', retained for migration/recovery only.
  TextColumn get imagePaths => text().withDefault(const Constant(''))();

  /// Concepts separated by '|'.
  TextColumn get concepts => text().withDefault(const Constant(''))();
  TextColumn get cluster => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get groupId => text().nullable().references(NoteGroups, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NoteGroup')
@TableIndex(name: 'note_groups_project', columns: {#projectId})
@TableIndex(name: 'note_groups_parent', columns: {#parentId})
class NoteGroups extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentId => text().nullable().references(NoteGroups, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NoteAttachment')
@TableIndex(name: 'note_attachments_note', columns: {#noteId})
class NoteAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<AttachmentKind>()();
  TextColumn get path => text()();
  TextColumn get name => text().nullable()();
  IntColumn get bytes => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get transcript => text().nullable()();

  /// Last transcript represented in the note body, retained across redos so a
  /// different result cannot get appended again on every retry.
  TextColumn get transcriptNoteText => text().nullable()();
  IntColumn get transcriptionOrder => integer().nullable()();
  TextColumn get transcriptionStatus => textEnum<TranscriptionStatus>().withDefault(const Constant('none'))();
  TextColumn get transcriptionFailure => text().nullable()();
  TextColumn get transcriptionEngine => text().nullable()();
  DateTimeColumn get transcribedAt => dateTime().nullable()();

  /// Runs started since the last manual request, written before inference
  /// begins, so a native crash or out-of-memory kill still counts.
  IntColumn get transcriptionAttempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NoteLink')
@TableIndex(name: 'note_links_project', columns: {#projectId})
@TableIndex(name: 'note_links_source', columns: {#sourceId})
@TableIndex(name: 'note_links_target', columns: {#targetId})
class NoteLinks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('outgoingLinks')
  TextColumn get sourceId => text().references(Notes, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('incomingLinks')
  TextColumn get targetId => text().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  RealColumn get strength => real()();
  TextColumn get origin => textEnum<LinkOrigin>().withDefault(const Constant('ai'))();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChatEntry')
@TableIndex(name: 'chat_entries_project_created', columns: {#projectId, #createdAt})
class ChatEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()(); // 'user' | 'assistant'
  TextColumn get body => text()();

  /// Cited note ids separated by '|'.
  TextColumn get sourceIds => text().withDefault(const Constant(''))();
  BoolColumn get found => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Projects, NoteGroups, Notes, NoteAttachments, NoteLinks, ChatEntries, Settings])
class FikraDatabase extends _$FikraDatabase {
  FikraDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'fikra'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // Drift doesn't wrap onUpgrade in a transaction, and user_version only
      // moves after it returns. So each step is atomic and safe to re-run: an
      // interrupted upgrade must never leave the app unable to open.
      if (from < 2) {
        await transaction(() async {
          // v2: a note can hold a PDF and a recording. Recordings move from the
          // attachment columns to voicePath; durationMs stays the voice length.
          final columns = await customSelect('PRAGMA table_info(notes)').get();
          if (!columns.any((c) => c.read<String>('name') == 'voice_path')) {
            await m.addColumn(notes, notes.voicePath);
          }
          await customStatement(
            "UPDATE notes SET voice_path = COALESCE(voice_path, attachment_path), attachment_path = NULL, "
            "attachment_name = NULL, attachment_bytes = NULL "
            "WHERE source = 'voice' AND attachment_path IS NOT NULL",
          );
        });
      }
      if (from < 3) {
        // v3: indexes for per-project lists, link lookups (and FK cascades),
        // chat history and the startup "stuck in processing" scan.
        await transaction(() async {
          for (final index in [
            notesProjectCreated,
            notesStatus,
            noteLinksProject,
            noteLinksSource,
            noteLinksTarget,
            chatEntriesProjectCreated,
          ]) {
            await customStatement(
              index.createStatementsByDialect[SqlDialect.sqlite]!.replaceFirst(
                'CREATE INDEX ',
                'CREATE INDEX IF NOT EXISTS ',
              ),
            );
          }
        });
      }
      if (from < 4) {
        // v4: a note can hold photos.
        await transaction(() async {
          final columns = await customSelect('PRAGMA table_info(notes)').get();
          if (!columns.any((c) => c.read<String>('name') == 'image_paths')) {
            await m.addColumn(notes, notes.imagePaths);
          }
        });
      }
      if (from < 5) {
        await transaction(() async {
          final tables = await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'note_attachments'",
          ).get();
          if (tables.isEmpty) await m.createTable(noteAttachments);
          await customStatement('CREATE INDEX IF NOT EXISTS note_attachments_note ON note_attachments (note_id)');
          // Stable IDs make partial backfills and a repeated upgrade harmless.
          // Keep the original columns intact for recovery.
          // Do not select the current Notes model here: later schema columns
          // (such as v6 group_id) do not exist yet on a v4 database.
          final legacy = await customSelect(
            'SELECT id, attachment_path, attachment_name, attachment_bytes, voice_path, '
            'duration_ms, image_paths, created_at FROM notes',
          ).get();
          for (final note in legacy) {
            var position = 0;
            Future<void> copy(
              String key,
              AttachmentKind kind,
              String? path, {
              String? name,
              int? bytes,
              int? durationMs,
            }) async {
              if (path == null || path.trim().isEmpty) return;
              await customStatement(
                'INSERT OR IGNORE INTO note_attachments '
                '(id, note_id, kind, path, name, bytes, duration_ms, position, created_at) '
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                  'legacy:${note.read<String>('id')}:$key',
                  note.read<String>('id'),
                  kind.name,
                  path,
                  name,
                  bytes,
                  durationMs,
                  position++,
                  note.read<DateTime>('created_at').millisecondsSinceEpoch ~/ 1000,
                ],
              );
            }

            await copy(
              'pdf',
              AttachmentKind.pdf,
              note.readNullable<String>('attachment_path'),
              name: note.readNullable<String>('attachment_name'),
              bytes: note.readNullable<int>('attachment_bytes'),
            );
            await copy(
              'voice',
              AttachmentKind.voice,
              note.readNullable<String>('voice_path'),
              durationMs: note.readNullable<int>('duration_ms'),
            );
            for (final (i, path) in note.read<String>('image_paths').split('|').indexed) {
              await copy('image:$i', AttachmentKind.image, path);
            }
          }
        });
      }
      if (from < 6) {
        await transaction(() async {
          final tables = await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'note_groups'",
          ).get();
          if (tables.isEmpty) await m.createTable(noteGroups);
          // The referenced table must exist before notes gains its foreign key.
          final noteColumns = await customSelect('PRAGMA table_info(notes)').get();
          if (!noteColumns.any((c) => c.read<String>('name') == 'group_id')) {
            await m.addColumn(notes, notes.groupId);
          }
          final linkColumns = await customSelect('PRAGMA table_info(note_links)').get();
          for (final column in <GeneratedColumn<Object>>[noteLinks.origin, noteLinks.dismissed, noteLinks.createdAt]) {
            if (!linkColumns.any((c) => c.read<String>('name') == column.$name)) {
              await m.addColumn(noteLinks, column);
            }
          }
          await customStatement('CREATE INDEX IF NOT EXISTS note_groups_project ON note_groups (project_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS note_groups_parent ON note_groups (parent_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS notes_group ON notes (group_id)');
        });
      }
      if (from < 7) {
        await transaction(() async {
          final columns = await customSelect('PRAGMA table_info(note_attachments)').get();
          for (final column in <GeneratedColumn<Object>>[
            noteAttachments.transcript,
            noteAttachments.transcriptNoteText,
            noteAttachments.transcriptionOrder,
            noteAttachments.transcriptionStatus,
            noteAttachments.transcriptionFailure,
            noteAttachments.transcriptionEngine,
            noteAttachments.transcribedAt,
            noteAttachments.transcriptionAttempts,
          ]) {
            if (!columns.any((c) => c.read<String>('name') == column.$name)) {
              await m.addColumn(noteAttachments, column);
            }
          }
        });
      }
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

extension NoteX on Note {
  List<String> get conceptList => concepts.isEmpty ? const [] : concepts.split('|');

  /// Original content: what was typed, plus any text an old note carried.
  String get originalContent {
    final parts = [originalText.trim(), (extractedText ?? '').trim()].where((s) => s.isNotEmpty);
    return parts.join('\n\n');
  }

  /// What the user sees by default.
  String get displayText => editedText ?? originalContent;

  bool get hasImprovedVersion => editedText != null && editedText != originalContent;
}

extension ChatEntryX on ChatEntry {
  List<String> get sourceList => sourceIds.isEmpty ? const [] : sourceIds.split('|');
  bool get isUser => role == 'user';
}
