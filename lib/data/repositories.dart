import 'package:drift/drift.dart';

import 'ai/ai_service.dart';
import 'files/attachment_store.dart';
import 'ids.dart';
import 'local/database.dart';

typedef ProjectSummary = ({Project project, int noteCount});

/// Projects + the "current project" selection.
abstract interface class ProjectsRepository {
  Stream<List<ProjectSummary>> watchProjects();
  Future<Project> create(String name);
  Future<void> rename(String id, String name);
  Future<void> delete(String id);
  Stream<String?> watchCurrentId();
  Future<void> setCurrent(String? id);
}

abstract interface class NotesRepository {
  Stream<List<Note>> watchNotes(String projectId);
  Stream<Note?> watchNote(String id);
  Future<List<Note>> notesOf(String projectId);

  /// Notes left in [status] across all projects (e.g. processing after a kill).
  Future<List<Note>> notesWithStatus(ProcessingStatus status);
  Future<Note> create({
    required String projectId,
    required String title,
    required String text,
    required NoteSource source,
    String? attachmentPath,
    String? attachmentName,
    int? attachmentBytes,
    String? voicePath,
    int? durationMs,
    List<String> imagePaths,
    DateTime? createdAt,
  });
  Future<void> markProcessing(String id);
  Future<void> markReady(String id);
  Future<void> markFailed(String id);

  /// Applies an AI result computed from [basis]. Fields the user changed while
  /// the analysis ran win over the result.
  Future<void> applyInsights(String id, NoteInsights insights, {Note? basis});
  Future<Set<String>> attachmentPaths();
  Future<void> acceptRewrite(String id);
  Future<void> rejectRewrite(String id);
  Future<void> edit(String id, {required String title, required String text});
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

class LocalNotesRepository implements NotesRepository {
  LocalNotesRepository(this.db);
  final FikraDatabase db;

  @override
  Stream<List<Note>> watchNotes(String projectId) =>
      (db.select(db.notes)
            ..where((n) => n.projectId.equals(projectId))
            ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
          .watch();

  @override
  Stream<Note?> watchNote(String id) => (db.select(db.notes)..where((n) => n.id.equals(id))).watchSingleOrNull();

  @override
  Future<List<Note>> notesOf(String projectId) =>
      (db.select(db.notes)..where((n) => n.projectId.equals(projectId))).get();

  @override
  Future<List<Note>> notesWithStatus(ProcessingStatus status) =>
      (db.select(db.notes)..where((n) => n.status.equalsValue(status))).get();

  @override
  Future<Note> create({
    required String projectId,
    required String title,
    required String text,
    required NoteSource source,
    String? attachmentPath,
    String? attachmentName,
    int? attachmentBytes,
    String? voicePath,
    int? durationMs,
    List<String> imagePaths = const [],
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final note = Note(
      id: newId(),
      projectId: projectId,
      title: title.trim(),
      originalText: text.trim(),
      source: source,
      status: ProcessingStatus.processing,
      rewrite: RewriteStatus.none,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      attachmentBytes: attachmentBytes,
      voicePath: voicePath,
      durationMs: durationMs,
      imagePaths: imagePaths.join('|'),
      concepts: '',
      createdAt: now,
      updatedAt: now,
    );
    await db.into(db.notes).insert(note);
    return note;
  }

  Future<void> _write(String id, NotesCompanion c) =>
      (db.update(db.notes)..where((n) => n.id.equals(id))).write(c.copyWith(updatedAt: Value(DateTime.now())));

  @override
  Future<void> markProcessing(String id) =>
      _write(id, const NotesCompanion(status: Value(ProcessingStatus.processing)));

  @override
  Future<void> markReady(String id) => _write(id, const NotesCompanion(status: Value(ProcessingStatus.ready)));

  @override
  Future<void> markFailed(String id) => _write(id, const NotesCompanion(status: Value(ProcessingStatus.failed)));

  @override
  Future<void> applyInsights(String id, NoteInsights i, {Note? basis}) async {
    await db.transaction(() async {
      final live = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();
      if (live == null) return; // deleted while processing
      final b = basis ?? live;
      final userEdited = live.editedText != b.editedText || live.originalText != b.originalText;
      final keepTitle = live.title.trim().isNotEmpty;
      final proposal = userEdited || live.editedText != null ? null : i.proposedText;
      await _write(
        id,
        NotesCompanion(
          title: keepTitle ? const Value.absent() : Value(i.title),
          proposedText: Value(proposal),
          rewrite: Value(
            proposal != null
                ? RewriteStatus.pending
                : (live.rewrite == RewriteStatus.pending ? RewriteStatus.none : live.rewrite),
          ),
          concepts: Value(i.concepts.take(8).join('|')),
          cluster: Value(i.cluster),
          status: const Value(ProcessingStatus.ready),
        ),
      );

      // AI output is untrusted: keep only targets that exist in the same
      // project, no self links, no duplicates, strength in 0..1.
      final targetIds = i.links.map((l) => l.targetId).where((t) => t != id).toSet();
      final valid =
          (await (db.selectOnly(db.notes)
                    ..addColumns([db.notes.id])
                    ..where(db.notes.id.isIn(targetIds) & db.notes.projectId.equals(live.projectId)))
                  .map((r) => r.read(db.notes.id)!)
                  .get())
              .toSet();
      // This note owns its outgoing edges only.
      await (db.delete(db.noteLinks)..where((l) => l.sourceId.equals(id))).go();
      final seen = <String>{};
      for (final l in i.links) {
        if (!valid.contains(l.targetId) || !seen.add(l.targetId) || seen.length > 8) continue;
        final strength = l.strength.isFinite ? l.strength.clamp(0.0, 1.0) : 0.0;
        await db
            .into(db.noteLinks)
            .insert(
              NoteLink(
                id: newId(),
                projectId: live.projectId,
                sourceId: id,
                targetId: l.targetId,
                label: l.label.length > 80 ? l.label.substring(0, 80) : l.label,
                strength: strength,
              ),
            );
      }
    });
  }

  @override
  Future<Set<String>> attachmentPaths() async => (await _filePaths(db, null)).toSet();

  @override
  Future<void> acceptRewrite(String id) async {
    final n = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
    if (n.proposedText == null) return;
    await _write(
      id,
      NotesCompanion(
        editedText: Value(n.proposedText),
        proposedText: const Value(null),
        rewrite: const Value(RewriteStatus.accepted),
      ),
    );
  }

  @override
  Future<void> rejectRewrite(String id) =>
      _write(id, const NotesCompanion(proposedText: Value(null), rewrite: Value(RewriteStatus.rejected)));

  @override
  Future<void> edit(String id, {required String title, required String text}) async {
    final n = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
    final t = text.trim();
    await _write(
      id,
      NotesCompanion(
        title: Value(title.trim().isEmpty ? n.title : title.trim()),
        editedText: Value(t == n.originalContent ? null : t),
        // A proposal made from the old text no longer applies.
        proposedText: const Value(null),
        rewrite: Value(n.rewrite == RewriteStatus.pending ? RewriteStatus.none : n.rewrite),
      ),
    );
  }

  @override
  Future<void> restoreOriginal(String id) => _write(id, const NotesCompanion(editedText: Value(null)));

  @override
  Future<void> delete(String id) async {
    final n = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();
    await (db.delete(db.notes)..where((n) => n.id.equals(id))).go();
    if (n != null) await AttachmentStore.deleteQuietly(n.filePaths);
  }

  @override
  Stream<List<NoteLink>> watchLinks(String projectId) =>
      (db.select(db.noteLinks)..where((l) => l.projectId.equals(projectId))).watch();
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
  final q = db.selectOnly(db.notes)..addColumns([db.notes.attachmentPath, db.notes.voicePath, db.notes.imagePaths]);
  if (where != null) q.where(where);
  final rows = await q.get();
  return [
    for (final r in rows) ...[
      ?r.read(db.notes.attachmentPath),
      ?r.read(db.notes.voicePath),
      ...?r.read(db.notes.imagePaths)?.split('|').where((p) => p.isNotEmpty),
    ],
  ];
}
