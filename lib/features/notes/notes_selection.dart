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

  Widget _actionBar(BuildContext context, int count) {
    final selection = _selection!;
    return noteSelectionActions(
      context,
      ref,
      selection: selection,
      onDone: () {
        if (identical(_selection, selection)) _endSelection();
      },
    );
  }
}
