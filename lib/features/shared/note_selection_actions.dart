import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/local/database.dart';
import '../../l10n/localizations.dart';
import 'selection_actions.dart';
import 'selection_bar.dart';

/// Shared action wiring. Use the owning screen's context/ref: an assignment
/// can remove the bar (a filter or pruning) before its toast/Undo is ready.
Widget noteSelectionActions(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> selection,
  required VoidCallback onDone,
}) {
  /// Runs [action] on the selected notes as they are now. The selection may
  /// change while it runs; the action keeps the notes it started with, and
  /// ends only the selection it started from. One action or Undo at a time
  /// ([selectionBusyProvider]).
  Future<void> run(Future<bool> Function(List<Note> notes, String projectId) action) async {
    final project = ref.read(selectedProjectProvider);
    if (project == null) return;
    final notes = [
      for (final n in ref.read(selectedNotesProvider).value ?? const <Note>[])
        if (selection.contains(n.id)) n,
    ];
    if (notes.isEmpty) return;
    final guard = ref.read(selectionBusyProvider.notifier);
    if (!guard.claim()) return;
    // An earlier Undo can't be pressed while this one runs.
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    try {
      final done = await action(notes, project.id);
      if (done && context.mounted) onDone();
    } finally {
      guard.release();
    }
  }

  final count = selection.length;
  final l10n = context.l10n;
  final busy = ref.watch(selectionBusyProvider);
  final canLink = count >= 2 && count <= maxLinkTogether;
  List<String> ids(List<Note> notes) => [for (final n in notes) n.id];
  return SelectionActionBar(
    note: count > maxLinkTogether ? l10n.linkTogetherLimit(maxLinkTogether) : null,
    actions: [
      SelectionAction(
        key: const ValueKey('selection-link'),
        icon: Icons.hub_outlined,
        label: l10n.linkTogether,
        onTap: busy || !canLink ? null : () => run((notes, _) => linkTogether(context, ref, ids(notes))),
        disabledHint: count < 2 ? l10n.linkTogetherNeedsTwo : l10n.linkTogetherLimit(maxLinkTogether),
      ),
      SelectionAction(
        key: const ValueKey('selection-group'),
        icon: Icons.folder_copy_outlined,
        label: l10n.groupAction,
        onTap: busy
            ? null
            : () => run((notes, projectId) => groupNotes(context, ref, projectId: projectId, notes: notes)),
      ),
      SelectionAction(
        key: const ValueKey('selection-move'),
        icon: Icons.drive_file_move_outline,
        label: l10n.moveConfirm,
        onTap: busy
            ? null
            : () => run((notes, projectId) => moveNotesTo(context, ref, projectId: projectId, noteIds: ids(notes))),
      ),
      SelectionAction(
        key: const ValueKey('selection-delete'),
        icon: Icons.delete_outline_rounded,
        label: l10n.delete,
        danger: true,
        onTap: busy ? null : () => run((notes, _) => deleteNotes(context, ref, ids(notes))),
      ),
    ],
  );
}
