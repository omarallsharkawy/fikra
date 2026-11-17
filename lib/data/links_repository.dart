import 'package:drift/drift.dart';

import 'ids.dart';
import 'link_label.dart';
import 'local/database.dart';

/// One link made by [LinksRepository.linkNotesForUndo]: its row id, its
/// project, and the rows its pair had before (empty when it had none).
class LinkChange {
  const LinkChange({required this.linkId, required this.projectId, required this.before});
  final String linkId;
  final String projectId;
  final List<NoteLink> before;
}

/// What [LinksRepository.acceptPairForUndo] or
/// [LinksRepository.dismissPairForUndo] changed: the pair's rows right before
/// and right after, in [projectId], so [LinksRepository.undoPairChange] can put
/// the pair back exactly.
class PairChange {
  const PairChange({
    required this.projectId,
    required this.a,
    required this.b,
    required this.before,
    required this.after,
  });
  final String projectId;
  final String a, b;
  final List<NoteLink> before;
  final List<NoteLink> after;
}

abstract interface class LinksRepository {
  Stream<List<NoteLink>> watchLinks(String projectId);
  Future<List<String>> linkNotes(String sourceId, Iterable<String> targetIds, {String? label});

  /// [linkNotes] with no label that also returns, for each link it made, the
  /// rows the pair had before, so [undoLinks] can put the pair back.
  Future<List<LinkChange>> linkNotesForUndo(String sourceId, Iterable<String> targetIds);

  /// Puts each pair of [changes] back as it was before [linkNotesForUndo], in
  /// one transaction: no row, its suggestion, or its rejection. Skips a pair
  /// whose link was removed, or whose notes were deleted or moved, meanwhile.
  Future<void> undoLinks(Iterable<LinkChange> changes);
  Future<void> updateLabel(String linkId, String? label);
  Future<void> removeLink(String linkId);
  Future<void> acceptSuggestion(String linkId);
  Future<void> dismissSuggestion(String linkId);

  /// Accepts the live suggestion between notes [a] and [b], whatever its row
  /// id is now (a re-analysis replaces suggestion rows with new ids). Does
  /// nothing when the pair is already yours, was rejected or removed, or has no
  /// live suggestion.
  Future<void> acceptPair(String a, String b);

  /// Rejects the pair [a]–[b] so the analysis never suggests it again, even if
  /// its suggestion row was replaced or dropped meanwhile. Does nothing when
  /// the pair became your link.
  Future<void> dismissPair(String a, String b);

  /// [acceptPair] that also returns the pair's rows before and after, for
  /// [undoPairChange]. Null when it changed nothing (no live suggestion).
  Future<PairChange?> acceptPairForUndo(String a, String b);

  /// [dismissPair] that also returns the pair's rows before and after, for
  /// [undoPairChange]. Null when it changed nothing.
  Future<PairChange?> dismissPairForUndo(String a, String b);

  /// Puts the pair of [change] back exactly as it was before, in one
  /// transaction: the suggestion row with its id, reason, strength and state,
  /// and no accepted row or rejection. Skipped, returning false, when the pair
  /// changed meanwhile (removed, relinked, reason edited, re-analysed) or a
  /// note was deleted or moved to another project.
  Future<bool> undoPairChange(PairChange change);
}

class LocalLinksRepository implements LinksRepository {
  LocalLinksRepository(this.db);
  final FikraDatabase db;

  Expression<bool> _pair(NoteLinks l, String a, String b) =>
      (l.sourceId.equals(a) & l.targetId.equals(b)) | (l.sourceId.equals(b) & l.targetId.equals(a));

  @override
  Stream<List<NoteLink>> watchLinks(String projectId) =>
      (db.select(db.noteLinks)..where((l) => l.projectId.equals(projectId) & l.dismissed.equals(false))).watch();

  @override
  Future<List<String>> linkNotes(String sourceId, Iterable<String> targetIds, {String? label}) =>
      _link(sourceId, targetIds, label: label);

  @override
  Future<List<LinkChange>> linkNotesForUndo(String sourceId, Iterable<String> targetIds) async {
    final changes = <LinkChange>[];
    await _link(sourceId, targetIds, changes: changes);
    return changes;
  }

  @override
  Future<void> undoLinks(Iterable<LinkChange> changes) => db.transaction(() async {
    for (final change in changes) {
      final row = await _read(change.linkId);
      // Removed (or turned back) meanwhile: leave it.
      if (row == null || row.origin != LinkOrigin.user || row.dismissed) continue;
      // A note deleted, or moved to another project (the link moves with
      // the notes): leave it too.
      final notes = await (db.select(db.notes)..where((n) => n.id.isIn([row.sourceId, row.targetId]))).get();
      if (notes.length != 2 || notes.any((n) => n.projectId != change.projectId)) continue;
      await (db.delete(db.noteLinks)..where((l) => _pair(l, row.sourceId, row.targetId))).go();
      for (final before in change.before) {
        await db.into(db.noteLinks).insertOnConflictUpdate(before);
      }
    }
  });

  Future<List<String>> _link(String sourceId, Iterable<String> targetIds, {String? label, List<LinkChange>? changes}) =>
      db.transaction(() async {
        final source = await (db.select(db.notes)..where((n) => n.id.equals(sourceId))).getSingleOrNull();
        if (source == null) return [];
        final normalized = _label(label);
        final result = <String>[];
        for (final targetId in targetIds.toSet()) {
          if (targetId == sourceId) continue;
          final target = await (db.select(db.notes)..where((n) => n.id.equals(targetId))).getSingleOrNull();
          if (target == null || target.projectId != source.projectId) continue;
          final rows = await (db.select(db.noteLinks)..where((l) => _pair(l, sourceId, targetId))).get();
          final users = rows.where((l) => l.origin == LinkOrigin.user);
          final existing = users.firstOrNull ?? rows.firstOrNull;
          if (users.isEmpty) {
            final id = existing?.id ?? newId();
            await db
                .into(db.noteLinks)
                .insertOnConflictUpdate(
                  NoteLink(
                    id: id,
                    projectId: source.projectId,
                    sourceId: sourceId,
                    targetId: targetId,
                    label: normalized ?? existing?.label ?? '',
                    strength: 1.0,
                    origin: LinkOrigin.user,
                    dismissed: false,
                    createdAt: DateTime.now(),
                  ),
                );
            result.add(id);
            changes?.add(LinkChange(linkId: id, projectId: source.projectId, before: rows));
          }
          final redundant = rows.where((l) => l.id != existing?.id && (l.origin == LinkOrigin.ai || l.dismissed));
          await (db.delete(db.noteLinks)..where((l) => l.id.isIn(redundant.map((r) => r.id)))).go();
        }
        return result;
      });

  @override
  Future<void> updateLabel(String linkId, String? label) => db.transaction(() async {
    final row = await _read(linkId);
    // Gone, or removed meanwhile (a removed link is kept as a dismissed row).
    if (row == null || row.dismissed) return;
    if (row.origin != LinkOrigin.user) throw StateError('Accept the suggestion before editing its label');
    await (db.update(
      db.noteLinks,
    )..where((l) => l.id.equals(linkId))).write(NoteLinksCompanion(label: Value(_label(label) ?? '')));
  });

  @override
  Future<void> removeLink(String linkId) => db.transaction(() async {
    final row = await _read(linkId);
    if (row == null) return;
    await (db.update(db.noteLinks)..where((l) => l.id.equals(linkId))).write(
      const NoteLinksCompanion(origin: Value(LinkOrigin.ai), dismissed: Value(true)),
    );
    // Dismiss legacy reverse suggestions too, so a removed pair disappears.
    await dismissSuggestion(linkId);
  });

  @override
  Future<void> acceptSuggestion(String linkId) => db.transaction(() async {
    final row = await _read(linkId);
    if (row == null || row.origin != LinkOrigin.ai || row.dismissed) return;
    await (db.update(db.noteLinks)..where((l) => l.id.equals(linkId))).write(
      NoteLinksCompanion(
        origin: const Value(LinkOrigin.user),
        dismissed: const Value(false),
        strength: const Value(1.0),
        createdAt: Value(row.createdAt ?? DateTime.now()),
      ),
    );
    await (db.delete(db.noteLinks)..where(
          (l) =>
              _pair(l, row.sourceId, row.targetId) &
              l.id.equals(linkId).not() &
              l.origin.equalsValue(LinkOrigin.ai) &
              l.dismissed.equals(false),
        ))
        .go();
  });

  @override
  Future<void> dismissSuggestion(String linkId) => db.transaction(() async {
    final row = await _read(linkId);
    if (row == null) return;
    await (db.update(db.noteLinks)
          ..where((l) => _pair(l, row.sourceId, row.targetId) & l.origin.equalsValue(LinkOrigin.ai)))
        .write(const NoteLinksCompanion(dismissed: Value(true)));
  });

  @override
  Future<void> acceptPair(String a, String b) => _acceptPair(a, b);

  @override
  Future<void> dismissPair(String a, String b) => _dismissPair(a, b);

  @override
  Future<PairChange?> acceptPairForUndo(String a, String b) => _forUndo(a, b, () => _acceptPair(a, b));

  @override
  Future<PairChange?> dismissPairForUndo(String a, String b) => _forUndo(a, b, () => _dismissPair(a, b));

  Future<PairChange?> _forUndo(String a, String b, Future<void> Function() change) => db.transaction(() async {
    if (a == b) return null;
    final before = await _pairRows(a, b);
    await change();
    final after = await _pairRows(a, b);
    if (_sameRows(before, after)) return null;
    final notes = await (db.select(db.notes)..where((n) => n.id.isIn([a, b]))).get();
    if (notes.length != 2) return null;
    return PairChange(projectId: notes.first.projectId, a: a, b: b, before: before, after: after);
  });

  @override
  Future<bool> undoPairChange(PairChange change) => db.transaction(() async {
    // Changed meanwhile, by the user or a re-analysis: leave it.
    if (!_sameRows(await _pairRows(change.a, change.b), change.after)) return false;
    final notes = await (db.select(db.notes)..where((n) => n.id.isIn([change.a, change.b]))).get();
    if (notes.length != 2 || notes.any((n) => n.projectId != change.projectId)) return false;
    await (db.delete(db.noteLinks)..where((l) => _pair(l, change.a, change.b))).go();
    for (final row in change.before) {
      await db.into(db.noteLinks).insert(row);
    }
    return true;
  });

  Future<List<NoteLink>> _pairRows(String a, String b) => (db.select(db.noteLinks)..where((l) => _pair(l, a, b))).get();

  /// Same rows, by id and every column, in any order.
  static bool _sameRows(List<NoteLink> x, List<NoteLink> y) {
    if (x.length != y.length) return false;
    final byId = {for (final row in x) row.id: row};
    return y.every((row) => byId[row.id] == row);
  }

  Future<void> _acceptPair(String a, String b) => db.transaction(() async {
    final rows = await (db.select(db.noteLinks)..where((l) => _pair(l, a, b))).get();
    // Already yours, or rejected/removed: a stale accept never revives the pair.
    if (rows.any((l) => l.origin == LinkOrigin.user || l.dismissed)) return;
    final live = rows.where((l) => l.origin == LinkOrigin.ai).firstOrNull;
    if (live != null) await acceptSuggestion(live.id);
  });

  Future<void> _dismissPair(String a, String b) => db.transaction(() async {
    if (a == b) return;
    final rows = await (db.select(db.noteLinks)..where((l) => _pair(l, a, b))).get();
    if (rows.any((l) => l.origin == LinkOrigin.user)) return;
    if (rows.isNotEmpty) {
      await (db.update(db.noteLinks)..where((l) => _pair(l, a, b) & l.origin.equalsValue(LinkOrigin.ai))).write(
        const NoteLinksCompanion(dismissed: Value(true)),
      );
      return;
    }
    // The suggestion was dropped by a newer analysis: remember the rejection.
    final notes = await (db.select(db.notes)..where((n) => n.id.isIn([a, b]))).get();
    if (notes.length != 2 || notes.first.projectId != notes.last.projectId) return;
    await db
        .into(db.noteLinks)
        .insert(
          NoteLink(
            id: newId(),
            projectId: notes.first.projectId,
            sourceId: a,
            targetId: b,
            label: '',
            strength: 0,
            origin: LinkOrigin.ai,
            dismissed: true,
            createdAt: DateTime.now(),
          ),
        );
  });

  Future<NoteLink?> _read(String id) => (db.select(db.noteLinks)..where((l) => l.id.equals(id))).getSingleOrNull();

  static String? _label(String? label) {
    final value = label?.trim();
    if (value == null || value.isEmpty) return null;
    return capLinkLabel(value);
  }
}
