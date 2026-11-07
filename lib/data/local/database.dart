import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum NoteSource { text, voice, pdf }

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
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();

  /// Exactly what the user typed. Never overwritten.
  TextColumn get originalText => text()();

  /// Transcript (voice) or extracted text (PDF), filled by processing.
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

  /// The PDF (since schema v2; v1 also kept recordings here).
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get attachmentName => text().nullable()();
  IntColumn get attachmentBytes => integer().nullable()();

  /// The voice recording and its length, alone or beside a PDF (schema v2).
  TextColumn get voicePath => text().nullable()();
  IntColumn get durationMs => integer().nullable()();

  /// Concepts separated by '|'.
  TextColumn get concepts => text().withDefault(const Constant(''))();
  TextColumn get cluster => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

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

@DriftDatabase(tables: [Projects, Notes, NoteLinks, ChatEntries, Settings])
class FikraDatabase extends _$FikraDatabase {
  FikraDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'fikra'));

  @override
  int get schemaVersion => 3;

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
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

extension NoteX on Note {
  List<String> get conceptList => concepts.isEmpty ? const [] : concepts.split('|');

  /// Original content: what was typed, or the transcript / extracted text.
  String get originalContent {
    final parts = [originalText.trim(), (extractedText ?? '').trim()].where((s) => s.isNotEmpty);
    return parts.join('\n\n');
  }

  /// What the user sees by default.
  String get displayText => editedText ?? originalContent;

  bool get hasPdf => attachmentPath != null;
  bool get hasVoice => voicePath != null;

  /// Every file this note owns on disk.
  List<String> get filePaths => [?attachmentPath, ?voicePath];

  bool get hasImprovedVersion => editedText != null && editedText != originalContent;
}

extension ChatEntryX on ChatEntry {
  List<String> get sourceList => sourceIds.isEmpty ? const [] : sourceIds.split('|');
  bool get isUser => role == 'user';
}
