part of 'links_screen.dart';

extension _GraphCards on _LinksScreenState {
  Widget _positionedCard(GraphLayout layout, GraphNote n, Set<String> focus) {
    final position = layout.positions[n.id]!;
    final groupId = _input?.memberships[n.id];
    final group = layout.frames.where((f) => f.group.id == groupId).firstOrNull;
    return Positioned.fromRect(
      rect: _rect(position),
      child: KeyedSubtree(
        key: ValueKey('graph-focus-${n.id}'),
        child: Semantics(
          container: true,
          sortKey: _graphSort(layout, position),
          customSemanticsActions: n.id == _selected ? _linkSemantics(layout, n.id) : null,
          child: _GraphHold(
            onHold: () => _selection == null ? _startSelection(n.id) : _toggle(n.id),
            onTap: () =>
                _selection != null ? _toggle(n.id) : _setState(() => _selected = n.id == _selected ? null : n.id),
            registerCancel: (cancel) {
              _cancelHold?.call();
              _cancelHold = cancel;
            },
            canHold: () => _pointers.length <= 1 && TickerMode.valuesOf(context).enabled,
            builder: (tap, hold) => _Node(
              key: ValueKey(n.id),
              note: n,
              semanticLabel: group == null
                  ? _graphTitle(context, n)
                  : context.l10n.graphNoteInGroup(_graphTitle(context, n), group.group.name),
              selected: _selection?.contains(n.id) ?? (n.id == _selected),
              selecting: _selection != null,
              onHold: hold,
              dimmed: _selected != null && !focus.contains(n.id),
              onTap: tap,
            ),
          ),
        ),
      ),
    );
  }
}
