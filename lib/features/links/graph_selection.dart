part of 'links_screen.dart';

extension _GraphSelection on _LinksScreenState {
  void _startSelection(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    // A toast (an earlier Undo) would sit over the action bar.
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    _setState(() {
      _selected = null;
      _selection = {id};
    });
  }

  void _toggle(String id) {
    final selection = _selection;
    if (selection == null) return;
    _setState(() {
      if (!selection.remove(id)) selection.add(id);
      if (selection.isEmpty) _selection = null;
    });
  }

  void _endSelection() {
    if (_selection != null) _setState(() => _selection = null);
  }

  Widget _selectionBar(int count) {
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
