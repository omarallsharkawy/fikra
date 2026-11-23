part of 'repositories.dart';

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
      final policy = a.id != null && !a.policyChanged
          ? byId[a.id]!.transcriptionPolicy
          : a.policy ?? (a.transcribe ? TranscriptionPolicy.afterSave : TranscriptionPolicy.off);
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
              transcriptionPolicy: policy,
              transcriptCorrection: byId[a.id]?.transcriptCorrection,
              correctedAt: byId[a.id]?.correctedAt,
              transcriptRevision: byId[a.id]?.transcriptRevision ?? 0,
              transcriptNoteText: byId[a.id]?.transcriptNoteText,
              transcriptionOrder:
                  byId[a.id]?.transcriptionOrder ??
                  (a.id == null && a.kind == AttachmentKind.voice && a.transcribe ? requestOrder++ : null),
              transcriptionStatus:
                  (policy == TranscriptionPolicy.off &&
                          const [
                            TranscriptionStatus.queued,
                            TranscriptionStatus.running,
                          ].contains(byId[a.id]?.transcriptionStatus)
                      ? TranscriptionStatus.none
                      : byId[a.id]?.transcriptionStatus) ??
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
  Future<void> applyInsights(String id, NoteInsights i, {Note? basis, bool linksOnly = false}) =>
      _applyNoteInsights(this, id, i, basis: basis, linksOnly: linksOnly);

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
    NoteEditBasis? basis,
  }) => _editNote(this, id, title: title, text: text, attachments: attachments, basis: basis);

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
