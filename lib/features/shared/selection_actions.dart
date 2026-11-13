import 'dart:async';

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/groups_repository.dart';
import '../../data/links_repository.dart';
import '../../data/local/database.dart';
import 'group_form.dart';
import 'group_sheet.dart';
import 'move_confirm.dart';
import 'note_groups.dart';
import 'project_picker.dart';

// The actions on a selection of notes, shared by every selection mode (the
// notes list now, the graph later). Each takes the notes as they were when
// the action started, returns true when it is done (the caller then ends
// the selection) and false when it was cancelled or failed.

/// "Link together" is offered for this many notes at most; above it a group
/// fits better.
const maxLinkTogether = 6;

/// Claimed by a selection action from its first tap to its end, and by an
/// Undo while it runs: one at a time, so a slow Undo can't undo over a newer
/// action and an action can't start on top of an Undo. True while claimed.
class SelectionGuard extends Notifier<bool> {
  @override
  bool build() => false;

  /// Claims the guard; false (and nothing changes) when it is taken.
  bool claim() {
    if (state) return false;
    state = true;
    return true;
  }

  void release() => state = false;
}

final selectionBusyProvider = NotifierProvider<SelectionGuard, bool>(SelectionGuard.new);

/// Links every note in [noteIds] with every other one, with no reason, in
/// one call per note but the last. Pairs already linked are left as they
/// are. If a call fails, the pairs linked so far are put back as they were.
/// The toast's Undo puts back exactly the pairs this action linked: no row,
/// the suggestion, or the rejection they had (`undoLinks`), leaving pairs
/// whose notes were moved or deleted meanwhile alone.
Future<bool> linkTogether(BuildContext context, WidgetRef ref, List<String> noteIds) async {
  final l10n = context.l10n;
  final repo = ref.read(linksRepoProvider);
  final changes = <LinkChange>[];
  try {
    for (var i = 0; i < noteIds.length - 1; i++) {
      changes.addAll(await repo.linkNotesForUndo(noteIds[i], noteIds.sublist(i + 1)));
    }
  } catch (_) {
    await _quietly(() => repo.undoLinks(changes));
    if (context.mounted) showToast(context, l10n.linkFailed);
    return false;
  }
  if (context.mounted) {
    showToast(
      context,
      l10n.linksAdded(changes.length),
      actionLabel: changes.isEmpty ? null : l10n.undo,
      onAction: _undo(context, () => repo.undoLinks(changes)),
    );
  }
  return true;
}

/// Puts [notes] (of [projectId]) in a group picked from the group sheet, a
/// new one, or none. The toast's Undo puts back only the notes still in
/// [projectId] and still in the group this action gave them, each in the
/// group it was in (ungrouped if that group was deleted meanwhile); a group
/// made by this action is then deleted if it still exists and is empty.
Future<bool> groupNotes(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required List<Note> notes,
}) async {
  final l10n = context.l10n;
  final repo = ref.read(groupsRepoProvider);
  final notesRepo = ref.read(notesRepoProvider);
  final pick = await showGroupSheet(context, projectId: projectId, canRemove: notes.any((n) => n.groupId != null));
  if (pick == null || !context.mounted) return false;
  NoteGroup? target;
  NoteGroup? created;
  switch (pick) {
    case GroupPickExisting(:final group):
      target = group;
    case GroupPickNone():
      target = null;
    case GroupPickNew():
      final form = await showNewGroupForm(context, projectId: projectId);
      if (form == null || !context.mounted) return false;
      final ok = await runGroupAction(
        context,
        () async => created = await repo.create(projectId, form.name, parentId: form.parentId, color: form.color),
      );
      if (!ok || created == null || !context.mounted) return false;
      target = created;
  }
  // The groups as they are now, not when the selection started.
  final live = {for (final n in ref.read(notesOfProjectProvider(projectId)).value ?? notes) n.id: n};
  final previous = {
    for (final n in notes)
      if (live[n.id] case final note?) note.id: note.groupId,
  };
  if (previous.isEmpty) return true; // every note was deleted meanwhile
  final done = await runGroupAction(context, () => repo.assignNotes(target?.id, previous.keys));
  if (!done) {
    // Nothing was assigned: don't leave the new group behind empty.
    if (created case final group?) await _quietly(() => repo.delete(group.id));
    return false;
  }
  if (!context.mounted) return true;
  final count = Fmt.notes(l10n, previous.length);
  showToast(
    context,
    target == null ? l10n.groupRemovedFrom(count) : l10n.notesGrouped(count, Fmt.isolate(target.name)),
    actionLabel: l10n.undo,
    onAction: _undo(context, () async {
      final assigned = target?.id;
      // Notes moved to another project, or regrouped since, are left alone.
      final now = await notesRepo.notesOf(projectId);
      final byGroup = <String?, List<String>>{};
      for (final n in now) {
        if (n.groupId == assigned && previous.containsKey(n.id)) (byGroup[previous[n.id]] ??= []).add(n.id);
      }
      for (final MapEntry(key: group, value: ids) in byGroup.entries) {
        if (group == assigned) continue;
        try {
          await repo.assignNotes(group, ids);
        } on GroupRuleException {
          await repo.assignNotes(null, ids); // that group is gone
        }
      }
      if (created case final group?) {
        final groups = await repo.watchGroups(projectId).first;
        final notes = await notesRepo.notesOf(projectId);
        final empty = !notes.any((n) => n.groupId == group.id) && !groups.any((g) => g.parentId == group.id);
        if (empty && groups.any((g) => g.id == group.id)) await repo.delete(group.id);
      }
    }),
  );
  return true;
}

/// Moves [noteIds] from [projectId] to a picked project after one
/// confirmation for all of them (asked again if the numbers change), then
/// re-links them there in the background. No Undo.
Future<bool> moveNotesTo(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required List<String> noteIds,
}) async {
  final l10n = context.l10n;
  final count = noteIds.length;
  final failure = count == 1 ? l10n.moveNoteFailed : l10n.moveNotesFailed;
  final target = await showProjectPicker(
    context,
    title: l10n.moveToProject,
    excludeProjectId: projectId,
    empty: count == 1 ? l10n.moveNoOtherProject : l10n.moveNotesNoOtherProject,
  );
  if (target == null || !context.mounted) return false;
  final repo = ref.read(notesRepoProvider);
  final processor = ref.read(noteProcessorProvider);
  final name = Fmt.isolate(target.name);
  final confirmed = await confirmMove(
    context,
    impact: () => repo.moveImpact(noteIds, target.id),
    title: count == 1 ? l10n.moveNoteTitle(name) : l10n.moveNotesTitle(Fmt.notes(l10n, count), name),
    message: (impact) => moveMessage(l10n, impact, notes: count),
    failure: failure,
  );
  if (!confirmed || !context.mounted) return false;
  var moved = const <String>[];
  final done = await runAction(context, () async => moved = await repo.moveNotes(noteIds, target.id), failure: failure);
  if (!done) return false;
  if (moved.isEmpty) return true; // all deleted meanwhile
  unawaited(processor.relink(moved));
  if (context.mounted) {
    showToast(context, moved.length == 1 ? l10n.noteMoved(name) : l10n.notesMoved(Fmt.notes(l10n, moved.length), name));
  }
  return true;
}

/// Deletes [noteIds] and their files after one confirmation, one note at a
/// time like the single delete. If one fails the rest stay; those already
/// deleted are gone. No Undo.
Future<bool> deleteNotes(BuildContext context, WidgetRef ref, List<String> noteIds) async {
  final l10n = context.l10n;
  final count = noteIds.length;
  final ok = await confirmDestructive(
    context,
    title: count == 1 ? l10n.deleteNoteTitle : l10n.deleteNotesTitle(Fmt.notes(l10n, count)),
    message: count == 1 ? l10n.deleteNoteBody : l10n.deleteNotesBody(count),
  );
  if (!ok || !context.mounted) return false;
  final repo = ref.read(notesRepoProvider);
  return runAction(
    context,
    () async {
      for (final id in noteIds) {
        await repo.delete(id);
      }
    },
    success: count == 1 ? l10n.noteDeleted : l10n.notesDeleted(Fmt.notes(l10n, count)),
    failure: count == 1 ? l10n.genericError : l10n.deleteNotesFailed,
  );
}

/// An Undo callback that runs [undo] under [selectionBusyProvider] and shows
/// [AppLocalizations.undoFailed] if it throws or another action is running.
VoidCallback _undo(BuildContext context, Future<void> Function() undo) {
  final failed = context.l10n.undoFailed;
  final messenger = ScaffoldMessenger.maybeOf(context);
  // The container outlives the page, so Undo works after it closed.
  final guard = ProviderScope.containerOf(context, listen: false).read(selectionBusyProvider.notifier);
  void fail() => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(failed), duration: const Duration(seconds: 3)));
  return () async {
    if (!guard.claim()) return fail();
    try {
      await undo();
    } catch (_) {
      fail();
    } finally {
      guard.release();
    }
  };
}

Future<void> _quietly(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {}
}
