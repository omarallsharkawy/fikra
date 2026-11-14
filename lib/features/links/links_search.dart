part of 'links_screen.dart';

extension _LinksSearch on _LinksScreenState {
  bool get _navigationReady => _layout != null && _installedInput != null && identical(_installedInput, _input);

  void _closeSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    _setState(() {
      _searchOpen = false;
      _search.clear();
    });
  }

  void _pickSearch(GraphSearchResult result) {
    if (!_navigationReady) return;
    _closeSearch();
    _setState(() {
      final groups = _groupsSource ?? const <NoteGroup>[];
      // Expand every folded ancestor, retaining a group's own collapsed state
      // when the result is the group itself (its capsule can be fitted).
      final targets = result.kind == GraphSearchKind.group
          ? {result.id}
          : {
              for (final n in _notesSource!)
                if (result.noteIds.contains(n.id)) ?n.groupId,
            };
      for (final target in targets) {
        final ancestors = <String>{};
        String? id = target;
        while (id != null && ancestors.add(id)) {
          if (result.kind != GraphSearchKind.group || id != result.id) _collapsed.remove(id);
          id = groups.where((g) => g.id == id).firstOrNull?.parentId;
        }
      }
      _pendingJump = result;
    });
  }

  void _finishJump() {
    if (_pendingJump == null || !_navigationReady || _searchOpen || View.of(context).viewInsets.bottom > 0) {
      return;
    }
    final result = _pendingJump!;
    _pendingJump = null;
    final layout = _layout!;
    if (result.kind == GraphSearchKind.group) {
      final frame = layout.frames.where((f) => f.group.id == result.id).firstOrNull;
      if (frame != null) _fitFrame(frame);
      return;
    }
    final input = _installedInput!;
    final link = result.kind == GraphSearchKind.link ? resolveGraphSearchLink(input, result) : null;
    if (result.kind == GraphSearchKind.link && link == null) {
      showToast(context, context.l10n.linkRemoved);
      return;
    }
    // A changed/deleted note is not evidence of a layout cap.
    if (!result.noteIds.every((id) => input.notes.any((n) => n.id == id && n.status == 1))) return;
    if (result.noteIds.any(layout.foldedNotes.containsKey)) {
      // A membership can change while the keyboard or worker is finishing.
      _pickSearch(result);
      return;
    }
    if (layout.readyCount < 2 && input.groups.isEmpty) {
      _openNote(result.noteIds.first);
      return;
    }
    final missing = result.noteIds.where((id) => !layout.nodes.containsKey(id)).firstOrNull;
    if (missing != null) {
      // Layout caps are intentional; take the existing direct note route.
      showToast(context, context.l10n.graphSearchLimited);
      _openNote(missing);
      return;
    }
    final note = layout.positions[result.noteIds.first]!;
    final edge = link != null ? layout.edges.where((e) => e.link.id == link.id).firstOrNull : null;
    if (result.kind == GraphSearchKind.link && edge == null) {
      showToast(context, context.l10n.graphSearchLimited);
      _openNote(result.noteIds.first);
      return;
    }
    _setState(() => _selected = result.noteIds.first);
    _centreViewport(edge == null ? _rect(note).center : Offset(edge.middle.x, edge.middle.y));
  }
}

/// Search field and results. Listens to its own controller, so a keystroke
/// rebuilds only this panel, never the graph under it.
class _GraphSearchPanel extends StatelessWidget {
  const _GraphSearchPanel({
    required this.controller,
    required this.index,
    required this.enabled,
    required this.onPick,
    required this.onClose,
  });
  final TextEditingController controller;
  final GraphSearchIndex? index;
  final bool enabled;
  final ValueChanged<GraphSearchResult> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    String kind(GraphSearchKind k) => switch (k) {
      GraphSearchKind.note => context.l10n.graphSearchNote,
      GraphSearchKind.link => context.l10n.graphSearchLink,
      GraphSearchKind.group => context.l10n.graphSearchGroup,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 8),
          child: Row(
            children: [
              Expanded(
                child: FikraField(
                  key: const ValueKey('graph-search-field'),
                  controller: controller,
                  hint: context.l10n.graphSearchHint,
                  icon: Icons.search_rounded,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                ),
              ),
              FikraIconButton(
                key: const ValueKey('graph-search-close'),
                icon: Icons.close_rounded,
                label: context.l10n.close,
                onTap: onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              // Nothing to say before the first character.
              if (value.text.trim().isEmpty) return const SizedBox.shrink();
              final results = index?.search(value.text) ?? const <GraphSearchResult>[];
              if (results.isEmpty) {
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsets.all(FikraSpace.screen),
                    child: Text(context.l10n.graphSearchEmpty, style: context.text.meta),
                  ),
                );
              }
              return ListView.builder(
                key: const ValueKey('graph-search-results'),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final r = results[i];
                  final title = noteTitleText(context, r.title);
                  return ListTile(
                    key: ValueKey('graph-search-${r.kind.name}-${r.id}'),
                    title: Text(
                      r.kind == GraphSearchKind.link
                          ? '${Fmt.isolate(title)} · ${Fmt.isolate(noteTitleText(context, r.otherTitle))}'
                          : title,
                      style: context.text.chip,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      r.kind == GraphSearchKind.link ? '${kind(r.kind)} · ${r.reason}' : kind(r.kind),
                      style: context.text.meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    enabled: enabled,
                    onTap: enabled ? () => onPick(r) : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
