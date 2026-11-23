part of 'repositories.dart';

Future<void> _editNote(
  LocalNotesRepository repo,
  String id, {
  required String title,
  required String text,
  List<AttachmentDraft>? attachments,
  NoteEditBasis? basis,
}) async {
  final db = repo.db;
  final removed = await db.transaction(() async {
    final n = await (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle();
    final old = await (db.select(db.noteAttachments)..where((a) => a.noteId.equals(id))).get();
    final t = basis == null ? text.trim() : reconcileNoteEdit(basis, text, n, old);
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
    var savedTitle = title.trim().isEmpty ? n.title : title.trim();
    if (basis != null && n.title != basis.note.title) {
      if (title.trim() == basis.note.title.trim()) {
        savedTitle = n.title;
      } else if (savedTitle != n.title) {
        throw const NoteEditConflict();
      }
    }
    await repo._write(
      id,
      NotesCompanion(
        source: Value(source),
        title: Value(savedTitle),
        editedText: textChanged ? Value(t == n.originalContent ? null : t) : const Value.absent(),
        proposedText: textChanged ? const Value(null) : const Value.absent(),
        rewrite: textChanged && n.rewrite == RewriteStatus.pending
            ? const Value(RewriteStatus.none)
            : const Value.absent(),
      ),
    );
    if (attachments == null) return <String>[];
    await repo._replaceAttachments(id, attachments);
    final kept = attachments.map((a) => a.path).toSet();
    return old.map((a) => a.path).where((p) => !kept.contains(p)).toList();
  });
  // Only committed removals reach disk. Failures here are retried by the sweep.
  try {
    await repo._deleteFiles(removed);
  } catch (_) {
    // The database commit succeeded. Cleanup must never make the caller
    // roll back copies that now belong to the saved note; the sweep retries.
  }
}
