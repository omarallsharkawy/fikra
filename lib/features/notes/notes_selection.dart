part of 'notes_screen.dart';

/// Selection mode of the notes list. A long press on a card starts it with
/// that note; then a tap toggles a card. It ends with the close control,
/// Back, the last deselect, a project switch, a finished action, or leaving
/// the tab: the Notes tab keeps its state while hidden, and a selection found
/// again later would be easy to act on by mistake.
mixin _Selection on ConsumerState<NotesScreen> {
  /// The selected note ids; null outside selection mode. Each selection is a
  /// new set, so its identity tells one selection from the next.
  Set<String>? _selection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // False while another tab is shown (or a page covers this one).
    if (!TickerMode.valuesOf(context).enabled) _selection = null;
  }

  void _startSelection(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    // A toast (an earlier Undo) would sit over the action bar.
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    setState(() => _selection = {id});
  }

  void _toggle(String id) {
    final selection = _selection;
    if (selection == null) return;
    setState(() {
      if (!selection.remove(id)) selection.add(id);
      if (selection.isEmpty) _selection = null;
    });
  }

  void _endSelection() {
    if (_selection != null) setState(() => _selection = null);
  }

  /// Only notes on screen stay selected: notes deleted or moved away, or
  /// hidden by the search or the group filter, leave the selection, so an
  /// action never touches a note you can't see. Called during build, with
  /// the ids of the listed notes.
  void _keepVisible(Map<String, Object> visible) {
    final selection = _selection;
    if (selection == null || selection.every(visible.containsKey)) return;
    selection.removeWhere((id) => !visible.containsKey(id));
    if (selection.isEmpty) _selection = null;
  }

  /// Runs [action] on the selected notes as they are now. The selection may
  /// change while it runs; the action keeps the notes it started with, and
  /// ends only the selection it started from. One action or Undo at a time
  /// ([selectionBusyProvider]).
  Future<void> _run(Future<bool> Function(List<Note> notes, String projectId) action) async {
    final selection = _selection;
    final project = ref.read(selectedProjectProvider);
    if (selection == null || project == null) return;
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
      if (done && mounted && identical(_selection, selection)) _endSelection();
    } finally {
      guard.release();
    }
  }

  Widget _actionBar(BuildContext context, int count) {
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
          onTap: busy || !canLink ? null : () => _run((notes, _) => linkTogether(context, ref, ids(notes))),
          disabledHint: count < 2 ? l10n.linkTogetherNeedsTwo : l10n.linkTogetherLimit(maxLinkTogether),
        ),
        SelectionAction(
          key: const ValueKey('selection-group'),
          icon: Icons.folder_copy_outlined,
          label: l10n.groupAction,
          onTap: busy
              ? null
              : () => _run((notes, projectId) => groupNotes(context, ref, projectId: projectId, notes: notes)),
        ),
        SelectionAction(
          key: const ValueKey('selection-move'),
          icon: Icons.drive_file_move_outline,
          label: l10n.moveConfirm,
          onTap: busy
              ? null
              : () => _run((notes, projectId) => moveNotesTo(context, ref, projectId: projectId, noteIds: ids(notes))),
        ),
        SelectionAction(
          key: const ValueKey('selection-delete'),
          icon: Icons.delete_outline_rounded,
          label: l10n.delete,
          danger: true,
          onTap: busy ? null : () => _run((notes, _) => deleteNotes(context, ref, ids(notes))),
        ),
      ],
    );
  }
}
