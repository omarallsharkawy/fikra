import 'package:drift/drift.dart';

import 'ids.dart';
import 'local/database.dart';

enum GroupRuleReason { emptyName, invalidColor, missingProject, missingGroup, invalidParent, selfParent, hasChildren }

class GroupRuleException implements Exception {
  const GroupRuleException(this.reason);
  final GroupRuleReason reason;

  @override
  String toString() => 'GroupRuleException: ${reason.name}';
}

abstract interface class GroupsRepository {
  Stream<List<NoteGroup>> watchGroups(String projectId);
  Future<NoteGroup> create(String projectId, String name, {String? parentId, int? color});
  Future<void> rename(String id, String name);
  Future<void> setColor(String id, int? color);
  Future<void> setParent(String id, String? parentId);
  Future<void> delete(String id);
  Future<void> assignNotes(String? groupId, Iterable<String> noteIds);
}

class LocalGroupsRepository implements GroupsRepository {
  LocalGroupsRepository(this.db);
  final FikraDatabase db;

  @override
  Stream<List<NoteGroup>> watchGroups(String projectId) =>
      (db.select(db.noteGroups)
            ..where((g) => g.projectId.equals(projectId))
            ..orderBy([(g) => OrderingTerm.asc(g.position), (g) => OrderingTerm.asc(g.id)]))
          .watch();

  @override
  Future<NoteGroup> create(String projectId, String name, {String? parentId, int? color}) => db.transaction(() async {
    final trimmed = _name(name);
    _color(color);
    if (await (db.select(db.projects)..where((p) => p.id.equals(projectId))).getSingleOrNull() == null) {
      throw const GroupRuleException(GroupRuleReason.missingProject);
    }
    await _parent(projectId, parentId);
    final last =
        await (db.select(db.noteGroups)
              ..where((g) => g.projectId.equals(projectId))
              ..orderBy([(g) => OrderingTerm.desc(g.position)])
              ..limit(1))
            .getSingleOrNull();
    final group = NoteGroup(
      id: newId(),
      projectId: projectId,
      parentId: parentId,
      name: trimmed,
      color: color,
      position: (last?.position ?? -1) + 1,
      createdAt: DateTime.now(),
    );
    await db.into(db.noteGroups).insert(group);
    return (db.select(db.noteGroups)..where((g) => g.id.equals(group.id))).getSingle();
  });

  @override
  Future<void> rename(String id, String name) async {
    final trimmed = _name(name);
    await (db.update(db.noteGroups)..where((g) => g.id.equals(id))).write(NoteGroupsCompanion(name: Value(trimmed)));
  }

  @override
  Future<void> setColor(String id, int? color) async {
    _color(color);
    await (db.update(db.noteGroups)..where((g) => g.id.equals(id))).write(NoteGroupsCompanion(color: Value(color)));
  }

  @override
  Future<void> setParent(String id, String? parentId) => db.transaction(() async {
    final group = await _read(id);
    if (group == null) throw const GroupRuleException(GroupRuleReason.missingGroup);
    if (id == parentId) throw const GroupRuleException(GroupRuleReason.selfParent);
    if (parentId != null) {
      final child =
          await (db.select(db.noteGroups)
                ..where((g) => g.parentId.equals(id))
                ..limit(1))
              .getSingleOrNull();
      if (child != null) throw const GroupRuleException(GroupRuleReason.hasChildren);
    }
    await _parent(group.projectId, parentId);
    await (db.update(
      db.noteGroups,
    )..where((g) => g.id.equals(id))).write(NoteGroupsCompanion(parentId: Value(parentId)));
  });

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.noteGroups)..where((g) => g.id.equals(id))).go();
  }

  @override
  Future<void> assignNotes(String? groupId, Iterable<String> noteIds) => db.transaction(() async {
    final group = groupId == null ? null : await _read(groupId);
    if (groupId != null && group == null) throw const GroupRuleException(GroupRuleReason.missingGroup);
    await (db.update(db.notes)..where(
          (n) => n.id.isIn(noteIds) & (group == null ? const Constant(true) : n.projectId.equals(group.projectId)),
        ))
        .write(NotesCompanion(groupId: Value(groupId), updatedAt: Value(DateTime.now())));
  });

  Future<NoteGroup?> _read(String id) => (db.select(db.noteGroups)..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<void> _parent(String projectId, String? parentId) async {
    if (parentId == null) return;
    final parent = await _read(parentId);
    if (parent == null || parent.projectId != projectId || parent.parentId != null) {
      throw const GroupRuleException(GroupRuleReason.invalidParent);
    }
  }

  static String _name(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const GroupRuleException(GroupRuleReason.emptyName);
    return trimmed;
  }

  static void _color(int? color) {
    if (color != null && (color < 0 || color > 3)) throw const GroupRuleException(GroupRuleReason.invalidColor);
  }
}
