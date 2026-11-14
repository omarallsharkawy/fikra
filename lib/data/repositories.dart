import 'package:drift/drift.dart';

import 'ai/ai_service.dart';
import 'attachment_draft.dart';
import 'files/attachment_store.dart';
import 'ids.dart';
import 'link_label.dart';
import 'local/database.dart';
import 'local/transcription_order.dart';
import 'links_repository.dart';

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
  Future<void> edit(String id, {required String title, required String text, List<AttachmentDraft>? attachments});
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

class LocalNotesRepository implements NotesRepository {
  LocalNotesRepository(this.db, {Future<void> Function(Iterable<String>)? deleteFiles})
    : _deleteFiles = deleteFiles ?? AttachmentStore.deleteQuietly;
  final Future<void> Function(Iterable<String>) _deleteFiles;
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
    List<AttachmentDraft> attachments = const [],
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final id = newId();
    return db.transaction(() async {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              id: id,
              projectId: projectId,
              title: title.trim(),
              originalText: text.trim(),
              source: source,
              status: ProcessingStatus.processing,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _replaceAttachments(id, attachments);
      return (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
    });
  }

  @override
  Stream<List<NoteAttachment>> watchAttachments(String noteId) =>
      (db.select(db.noteAttachments)
            ..where((a) => a.noteId.equals(noteId))
            ..orderBy([(a) => OrderingTerm.asc(a.position), (a) => OrderingTerm.asc(a.id)]))
          .watch();

  @override
  Stream<Map<String, List<NoteAttachment>>> watchProjectAttachments(String projectId) =>
      (db.select(db.noteAttachments).join([
              innerJoin(db.notes, db.notes.id.equalsExp(db.noteAttachments.noteId), useColumns: false),
            ])
            ..where(db.notes.projectId.equals(projectId))
            ..orderBy([OrderingTerm.asc(db.noteAttachments.position), OrderingTerm.asc(db.noteAttachments.id)]))
          .watch()
          .map((rows) {
            final grouped = <String, List<NoteAttachment>>{};
            for (final row in rows) {
              final a = row.readTable(db.noteAttachments);
              (grouped[a.noteId] ??= []).add(a);
            }
            return grouped;
          });

  Future<void> _replaceAttachments(String noteId, List<AttachmentDraft> attachments) async {
    // Existing IDs must belong to this note; callers cannot move another note's files.
    final existing = await (db.select(db.noteAttachments)..where((a) => a.noteId.equals(noteId))).get();
    final byId = {for (final a in existing) a.id: a};
    for (final a in attachments.where((a) => a.id != null)) {
      if (byId[a.id]?.path != a.path) throw StateError('Attachment no longer exists');
    }
    var requestOrder = attachments.any((a) => a.id == null && a.kind == AttachmentKind.voice && a.transcribe)
        ? await nextTranscriptionOrder(db)
        : 0;
    await (db.delete(db.noteAttachments)..where((a) => a.noteId.equals(noteId))).go();
    for (final (position, a) in attachments.indexed) {
      await db
          .into(db.noteAttachments)
          .insert(
            NoteAttachment(
              id: a.id ?? newId(),
              noteId: noteId,
              kind: a.kind,
              path: a.path,
              name: a.name,
              bytes: a.bytes,
              durationMs: a.durationMs,
              position: position,
              createdAt: byId[a.id]?.createdAt ?? DateTime.now(),
              transcript: byId[a.id]?.transcript,
              transcriptNoteText: byId[a.id]?.transcriptNoteText,
              transcriptionOrder:
                  byId[a.id]?.transcriptionOrder ??
                  (a.id == null && a.kind == AttachmentKind.voice && a.transcribe ? requestOrder++ : null),
              transcriptionStatus:
                  byId[a.id]?.transcriptionStatus ??
                  (a.kind == AttachmentKind.voice && a.transcribe
                      ? TranscriptionStatus.queued
                      : TranscriptionStatus.none),
              transcriptionFailure: byId[a.id]?.transcriptionFailure,
              transcriptionEngine: byId[a.id]?.transcriptionEngine,
              transcribedAt: byId[a.id]?.transcribedAt,
              transcriptionAttempts: byId[a.id]?.transcriptionAttempts ?? 0,
            ),
          );
    }
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
  Future<void> applyInsights(String id, NoteInsights i, {Note? basis, bool linksOnly = false}) async {
    await db.transaction(() async {
      final live = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();
      if (live == null) return; // deleted while processing
      final b = basis ?? live;
      final sameProject = b.projectId == live.projectId;
      if (linksOnly && !sameProject) return;
      final userEdited = live.editedText != b.editedText || live.originalText != b.originalText;
      final keepTitle = live.title.trim().isNotEmpty;
      final proposal = userEdited || live.editedText != null ? null : i.proposedText;
      await (db.update(db.notes)..where((n) => n.id.equals(id))).write(
        NotesCompanion(
          title: linksOnly || keepTitle ? const Value.absent() : Value(i.title),
          proposedText: linksOnly ? const Value.absent() : Value(proposal),
          rewrite: linksOnly
              ? const Value.absent()
              : Value(
                  proposal != null
                      ? RewriteStatus.pending
                      : (live.rewrite == RewriteStatus.pending ? RewriteStatus.none : live.rewrite),
                ),
          concepts: sameProject ? Value(i.concepts.take(8).join('|')) : const Value.absent(),
          cluster: sameProject ? Value(i.cluster) : const Value.absent(),
          status: linksOnly ? const Value.absent() : const Value(ProcessingStatus.ready),
          updatedAt: linksOnly ? const Value.absent() : Value(DateTime.now()),
        ),
      );

      // Concepts and links belong to the project used for analysis. A normal
      // job may still finish the title/rewrite/status after a move.
      if (!sameProject) return;

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
      await (db.delete(
        db.noteLinks,
      )..where((l) => l.sourceId.equals(id) & l.origin.equalsValue(LinkOrigin.ai) & l.dismissed.equals(false))).go();
      // Retained rows block the unordered pair, before applying the cap.
      final retained = await (db.select(
        db.noteLinks,
      )..where((l) => l.sourceId.equals(id) | l.targetId.equals(id))).get();
      final blocked = retained.map((l) => l.sourceId == id ? l.targetId : l.sourceId).toSet();
      final seen = <String>{};
      for (final l in i.links) {
        if (!valid.contains(l.targetId) || blocked.contains(l.targetId) || !seen.add(l.targetId) || seen.length > 8) {
          continue;
        }
        final strength = l.strength.isFinite ? l.strength.clamp(0.0, 1.0) : 0.0;
        await db
            .into(db.noteLinks)
            .insert(
              NoteLink(
                id: newId(),
                projectId: live.projectId,
                sourceId: id,
                targetId: l.targetId,
                label: capLinkLabel(l.label),
                strength: strength,
                origin: LinkOrigin.ai,
                dismissed: false,
                createdAt: DateTime.now(),
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
  Future<void> edit(
    String id, {
    required String title,
    required String text,
    List<AttachmentDraft>? attachments,
  }) async {
    final removed = await db.transaction(() async {
      final n = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
      final old = await (db.select(db.noteAttachments)..where((a) => a.noteId.equals(id))).get();
      final t = text.trim();
      if (t.isEmpty && (attachments?.isEmpty ?? old.isEmpty)) {
        throw const EmptyNoteException();
      }
      final kinds = attachments?.map((a) => a.kind) ?? old.map((a) => a.kind);
      final source = kinds.contains(AttachmentKind.pdf)
          ? NoteSource.pdf
          : kinds.contains(AttachmentKind.voice)
          ? NoteSource.voice
          : NoteSource.text;
      final textChanged = t != n.displayText.trim();
      await _write(
        id,
        NotesCompanion(
          source: Value(source),
          title: Value(title.trim().isEmpty ? n.title : title.trim()),
          editedText: textChanged ? Value(t == n.originalContent ? null : t) : const Value.absent(),
          proposedText: textChanged ? const Value(null) : const Value.absent(),
          rewrite: textChanged && n.rewrite == RewriteStatus.pending
              ? const Value(RewriteStatus.none)
              : const Value.absent(),
        ),
      );
      if (attachments == null) return <String>[];
      await _replaceAttachments(id, attachments);
      final kept = attachments.map((a) => a.path).toSet();
      return old.map((a) => a.path).where((p) => !kept.contains(p)).toList();
    });
    // Only committed removals reach disk. Failures here are retried by the sweep.
    try {
      await _deleteFiles(removed);
    } catch (_) {
      // The database commit succeeded. Cleanup must never make the caller
      // roll back copies that now belong to the saved note; the sweep retries.
    }
  }

  @override
  Future<void> restoreOriginal(String id) => _write(id, const NotesCompanion(editedText: Value(null)));

  @override
  Future<void> delete(String id) async {
    final paths = await db.transaction(() async {
      final paths = await _filePaths(db, db.notes.id.equals(id));
      await (db.delete(db.notes)..where((n) => n.id.equals(id))).go();
      return paths;
    });
    await AttachmentStore.deleteQuietly(paths);
  }

  @override
  Stream<List<NoteLink>> watchLinks(String projectId) => LocalLinksRepository(db).watchLinks(projectId);

  Future<Set<String>> _moving(Iterable<String> ids, String targetProjectId) async => (await (db.select(
    db.notes,
  )..where((n) => n.id.isIn(ids) & n.projectId.equals(targetProjectId).not())).get()).map((n) => n.id).toSet();

  Expression<bool> _crossing(NoteLinks l, Set<String> ids) =>
      (l.sourceId.isIn(ids) & l.targetId.isNotIn(ids)) | (l.targetId.isIn(ids) & l.sourceId.isNotIn(ids));

  @override
  Future<({int userLinks, int suggestions})> moveImpact(Iterable<String> noteIds, String targetProjectId) =>
      db.transaction(() async {
        final ids = await _moving(noteIds, targetProjectId);
        final rows = await (db.select(db.noteLinks)..where((l) => _crossing(l, ids) & l.dismissed.equals(false))).get();
        (String, String) pair(NoteLink l) =>
            l.sourceId.compareTo(l.targetId) < 0 ? (l.sourceId, l.targetId) : (l.targetId, l.sourceId);
        final users = rows.where((l) => l.origin == LinkOrigin.user).map(pair).toSet();
        final suggestions = rows.where((l) => l.origin == LinkOrigin.ai).map(pair).toSet();
        return (userLinks: users.length, suggestions: suggestions.difference(users).length);
      });

  @override
  Future<List<String>> moveNotes(Iterable<String> noteIds, String targetProjectId) => db.transaction(() async {
    if (await (db.select(db.projects)..where((p) => p.id.equals(targetProjectId))).getSingleOrNull() == null) {
      throw StateError('Target project does not exist');
    }
    final ids = await _moving(noteIds, targetProjectId);
    await (db.delete(db.noteLinks)..where((l) => _crossing(l, ids))).go();
    await (db.update(db.noteLinks)..where((l) => l.sourceId.isIn(ids) & l.targetId.isIn(ids))).write(
      NoteLinksCompanion(projectId: Value(targetProjectId)),
    );
    await (db.update(db.notes)..where((n) => n.id.isIn(ids))).write(
      NotesCompanion(projectId: Value(targetProjectId), groupId: const Value(null), updatedAt: Value(DateTime.now())),
    );
    return ids.toList();
  });
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
