import 'package:drift/drift.dart';

import 'ai/ai_service.dart';
import 'attachment_draft.dart';
import 'files/attachment_store.dart';
import 'ids.dart';
import 'link_label.dart';
import 'local/database.dart';
import 'local/transcription_order.dart';
import 'links_repository.dart';
import 'note_edit_merge.dart';

export 'note_edit_merge.dart';

part 'note_edit_repository.dart';
part 'note_insights_repository.dart';
part 'notes_repository.dart';

typedef ProjectSummary = ({Project project, int noteCount});

/// What deleting a project removes; see [ProjectsRepository.deleteImpact].
typedef ProjectDeleteImpact = ({int notes, int files, int links, bool chat});

/// Projects + the "current project" selection.
abstract interface class ProjectsRepository {
  Stream<List<ProjectSummary>> watchProjects();
  Future<Project> create(String name);
  Future<void> rename(String id, String name);
  Future<void> delete(String id);

  /// What [delete] would remove, read-only: the project's notes, their files
  /// (attachment rows), links counted once per note pair (your links and
  /// suggestions together, rejected ones not counted), and whether it has an
  /// Ask chat (a project with no notes can still have one).
  Future<ProjectDeleteImpact> deleteImpact(String id);
  Stream<String?> watchCurrentId();
  Future<void> setCurrent(String? id);
}

abstract interface class NotesRepository {
  Stream<List<Note>> watchNotes(String projectId);
  Stream<Note?> watchNote(String id);
  Stream<List<NoteAttachment>> watchAttachments(String noteId);
  Stream<Map<String, List<NoteAttachment>>> watchProjectAttachments(String projectId);
  Future<List<Note>> notesOf(String projectId);

  /// Notes left in [status] across all projects (e.g. processing after a kill).
  Future<List<Note>> notesWithStatus(ProcessingStatus status);
  Future<Note> create({
    required String projectId,
    required String title,
    required String text,
    required NoteSource source,
    List<AttachmentDraft> attachments,
    DateTime? createdAt,
  });
  Future<void> markProcessing(String id);
  Future<void> markReady(String id);
  Future<void> markFailed(String id);

  /// Applies an AI result computed from [basis]. Fields the user changed while
  /// the analysis ran win over the result.
  Future<void> applyInsights(String id, NoteInsights insights, {Note? basis, bool linksOnly = false});
  Future<({int userLinks, int suggestions})> moveImpact(Iterable<String> noteIds, String targetProjectId);
  Future<List<String>> moveNotes(Iterable<String> noteIds, String targetProjectId);
  Future<Set<String>> attachmentPaths();
  Future<void> acceptRewrite(String id);
  Future<void> rejectRewrite(String id);
  Future<void> edit(
    String id, {
    required String title,
    required String text,
    List<AttachmentDraft>? attachments,
    NoteEditBasis? basis,
  });
  Future<void> restoreOriginal(String id);
  Future<void> delete(String id);
  Stream<List<NoteLink>> watchLinks(String projectId);
}

abstract interface class ChatRepository {
  Stream<List<ChatEntry>> watch(String projectId);
  Future<void> add({
    required String projectId,
    required String role,
    required String body,
    List<String> sourceIds,
    bool found,
  });
  Future<void> clear(String projectId);
}

class LocalProjectsRepository implements ProjectsRepository {
  LocalProjectsRepository(this.db);
  final FikraDatabase db;
  static const _currentKey = 'current_project';

  @override
  Stream<List<ProjectSummary>> watchProjects() {
    return db
        .customSelect(
          'SELECT p.*, (SELECT COUNT(*) FROM notes n WHERE n.project_id = p.id) AS note_count '
          'FROM projects p ORDER BY p.created_at',
          readsFrom: {db.projects, db.notes},
        )
        .watch()
        .map(
          (rows) => [for (final r in rows) (project: db.projects.map(r.data), noteCount: r.read<int>('note_count'))],
        );
  }

  @override
  Future<Project> create(String name) async {
    final p = Project(id: newId(), name: name.trim(), createdAt: DateTime.now());
    await db.into(db.projects).insert(p);
    await setCurrent(p.id);
    return p;
  }

  @override
  Future<void> rename(String id, String name) =>
      (db.update(db.projects)..where((p) => p.id.equals(id))).write(ProjectsCompanion(name: Value(name.trim())));

  @override
  Future<void> delete(String id) async {
    final files = await db.transaction(() async {
      final paths = await _filePaths(db, db.notes.projectId.equals(id));
      await (db.delete(db.projects)..where((p) => p.id.equals(id))).go();
      final current = await _readCurrent();
      if (current == id) {
        final first =
            await (db.select(db.projects)
                  ..orderBy([(p) => OrderingTerm.asc(p.createdAt)])
                  ..limit(1))
                .getSingleOrNull();
        await setCurrent(first?.id);
      }
      return paths;
    });
    // Anything missed here (crash, I/O error) is swept by AttachmentStore.sweepOrphans.
    await AttachmentStore.deleteQuietly(files);
  }

  @override
  Future<ProjectDeleteImpact> deleteImpact(String id) async {
    // Four aggregates in one statement, so the numbers agree with each other.
    // Links include every row the cascade removes: either end in the project.
    const inProject = 'SELECT id FROM notes WHERE project_id = ?';
    final row = await db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM notes WHERE project_id = ?) AS notes, '
          '(SELECT COUNT(*) FROM note_attachments a JOIN notes n ON n.id = a.note_id WHERE n.project_id = ?) AS files, '
          '(SELECT COUNT(*) FROM (SELECT DISTINCT MIN(l.source_id, l.target_id), MAX(l.source_id, l.target_id) '
          'FROM note_links l WHERE l.dismissed = 0 '
          'AND (l.project_id = ? OR l.source_id IN ($inProject) OR l.target_id IN ($inProject)))) AS links, '
          'EXISTS (SELECT 1 FROM chat_entries WHERE project_id = ?) AS chat',
          variables: [for (var i = 0; i < 6; i++) Variable.withString(id)],
          readsFrom: {db.notes, db.noteAttachments, db.noteLinks, db.chatEntries},
        )
        .getSingle();
    return (
      notes: row.read<int>('notes'),
      files: row.read<int>('files'),
      links: row.read<int>('links'),
      chat: row.read<int>('chat') != 0,
    );
  }

  Future<String?> _readCurrent() async =>
      (await (db.select(db.settings)..where((s) => s.key.equals(_currentKey))).getSingleOrNull())?.value;

  @override
  Stream<String?> watchCurrentId() =>
      (db.select(db.settings)..where((s) => s.key.equals(_currentKey))).watchSingleOrNull().map((s) => s?.value);

  @override
  Future<void> setCurrent(String? id) async {
    if (id == null) {
      await (db.delete(db.settings)..where((s) => s.key.equals(_currentKey))).go();
    } else {
      await db.into(db.settings).insertOnConflictUpdate(Setting(key: _currentKey, value: id));
    }
  }
}

class LocalChatRepository implements ChatRepository {
  LocalChatRepository(this.db);
  final FikraDatabase db;

  @override
  Stream<List<ChatEntry>> watch(String projectId) =>
      (db.select(db.chatEntries)
            ..where((c) => c.projectId.equals(projectId))
            ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
          .watch();

  @override
  Future<void> add({
    required String projectId,
    required String role,
    required String body,
    List<String> sourceIds = const [],
    bool found = true,
  }) => db
      .into(db.chatEntries)
      .insert(
        ChatEntry(
          id: newId(),
          projectId: projectId,
          role: role,
          body: body,
          sourceIds: sourceIds.join('|'),
          found: found,
          createdAt: DateTime.now(),
        ),
      );

  @override
  Future<void> clear(String projectId) => (db.delete(db.chatEntries)..where((c) => c.projectId.equals(projectId))).go();
}

/// Every attachment file (PDF, voice, photos) of the notes matching [where].
Future<List<String>> _filePaths(FikraDatabase db, Expression<bool>? where) async {
  final q = db.select(db.noteAttachments).join([
    innerJoin(db.notes, db.notes.id.equalsExp(db.noteAttachments.noteId), useColumns: false),
  ]);
  if (where != null) q.where(where);
  return (await q.get()).map((r) => r.readTable(db.noteAttachments).path).toList();
}
