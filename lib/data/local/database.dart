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

  TextColumn get source => textEnum<NoteSource>()();
  TextColumn get status => textEnum<ProcessingStatus>()();
  TextColumn get rewrite => textEnum<RewriteStatus>().withDefault(Constant(RewriteStatus.none.name))();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get attachmentName => text().nullable()();
  IntColumn get attachmentBytes => integer().nullable()();
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'));
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

  bool get hasImprovedVersion => editedText != null && editedText != originalContent;
}

extension ChatEntryX on ChatEntry {
  List<String> get sourceList => sourceIds.isEmpty ? const [] : sourceIds.split('|');
  bool get isUser => role == 'user';
}
