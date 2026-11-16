part of 'links_screen.dart';

extension _GraphFrames on _LinksScreenState {
  Future<void> _groupOptions(String id) async {
    if (_selection != null || _groupOptionsOpen) return;
    final group = _groupsSource?.where((g) => g.id == id).firstOrNull;
    if (group == null) return;
    _groupOptionsOpen = true;
    try {
      await showGroupOptions(context, ref, group);
    } finally {
      _groupOptionsOpen = false;
    }
  }

  Future<void> _makeGroup(GraphRow row) async {
    if (_selection != null || !row.canMakeGroup) return;
    final project = ref.read(selectedProjectProvider);
    if (project == null) return;
    final guard = ref.read(selectionBusyProvider.notifier);
    if (!guard.claim()) return;
    final repo = ref.read(groupsRepoProvider);
    NoteGroup? created;
    try {
      // Read the complete project, including notes hidden by graph limits and
      // non-ready notes. Never take grouped notes sharing the topic's name.
      final all = await ref.read(notesRepoProvider).notesOf(project.id);
      final topic = row.notes.first.cluster;
      final notes = all.where((n) => n.groupId == null && n.cluster == topic).toList();
      if (notes.isEmpty || !mounted) return;
      final name = row.cluster.trim().characters.take(groupNameMaxLength).toString().trim();
      final groups = await repo.watchGroups(project.id).first;
      if (!mounted) return;
      var target = groups.where((g) => g.parentId == null && g.name.trim() == name).firstOrNull;
      if (target == null) {
        final ok = await runGroupAction(context, () async {
          created = await repo.create(project.id, name);
        });
        if (!ok || created == null) return;
        target = created;
      }
      if (!mounted) {
        if (created != null) await repo.delete(created!.id);
        return;
      }
      await assignSelectionGroup(
        context,
        ref,
        projectId: project.id,
        notes: notes,
        target: target,
        created: created,
        freshlyRead: true,
      );
    } finally {
      guard.release();
    }
  }

  Widget _frame(GraphLayout layout, GraphFrame frame, Set<String> focus) {
    final dim = _selected != null && !frame.noteIds.any(focus.contains) && !focus.contains(frame.endpointId);
    final colors = context.colors;
    final border = groupColor(context, frame.group.color) ?? colors.borderGraph;
    final text = dim ? _mutedGraphText(context) : colors.textSecondary;
    return Semantics(
      key: ValueKey('graph-frame-${frame.group.id}'),
      container: true,
      sortKey: _graphSort(layout, frame.header),
      explicitChildNodes: true,
      label: frame.collapsed
          ? context.l10n.graphCollapsedGroup(Fmt.isolate(frame.group.name), Fmt.notes(context.l10n, frame.count))
          : context.l10n.graphGroupA11y(frame.group.name, Fmt.notes(context.l10n, frame.count)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(frame.collapsed ? FikraRadius.full : FikraRadius.lg),
          border: Border.all(color: dim ? Color.alphaBlend(border.withValues(alpha: 0.16), colors.canvas) : border),
        ),
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: frame.collapsed ? frame.bounds.height : frame.header.height,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
            child: Row(
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          frame.group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.chip.copyWith(color: text),
                        ),
                        Text(
                          Fmt.notes(context.l10n, frame.count),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption.copyWith(color: text),
                        ),
                      ],
                    ),
                  ),
                ),
                // Both header controls share the selection-mode dimming and the
                // focus-fade icon colour.
                Opacity(
                  opacity: _selection == null ? 1 : 0.4,
                  child: IconTheme.merge(
                    data: IconThemeData(color: text),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FikraIconButton(
                          key: ValueKey('graph-group-collapse-${frame.group.id}'),
                          icon: frame.collapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                          label: frame.collapsed
                              ? context.l10n.graphExpandGroup(Fmt.isolate(frame.group.name))
                              : context.l10n.graphCollapseGroup(Fmt.isolate(frame.group.name)),
                          size: 48,
                          onTap: _selection == null
                              ? () => _setState(() {
                                  _travel.stop();
                                  if (!_collapsed.remove(frame.group.id)) _collapsed.add(frame.group.id);
                                })
                              : null,
                        ),
                        FikraIconButton(
                          key: ValueKey('graph-group-options-${frame.group.id}'),
                          icon: Icons.more_horiz_rounded,
                          label: context.l10n.groupOptionsA11y(frame.group.name),
                          size: 48,
                          onTap: _selection == null ? () => _groupOptions(frame.group.id) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topicLabel(GraphRow row) => Text(
    row.cluster,
    key: ValueKey('graph-cluster-${row.index}'),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.text.chip.copyWith(
      color: _selected == null ? context.colors.textSecondary : _mutedGraphText(context),
    ),
  );

  Widget _topicControl(GraphRow row) {
    final disabled = _selection != null || ref.watch(selectionBusyProvider);
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: FikraIconButton(
        key: ValueKey('graph-make-group-${row.index}'),
        icon: Icons.create_new_folder_outlined,
        size: 48,
        label: context.l10n.makeTopicGroup(row.cluster),
        onTap: disabled ? null : () => _makeGroup(row),
      ),
    );
  }
}
