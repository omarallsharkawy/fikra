part of 'repositories.dart';

Future<void> _applyNoteInsights(
  LocalNotesRepository repo,
  String id,
  NoteInsights i, {
  Note? basis,
  bool linksOnly = false,
}) async {
  final db = repo.db;
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
    final retained = await (db.select(db.noteLinks)..where((l) => l.sourceId.equals(id) | l.targetId.equals(id))).get();
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
