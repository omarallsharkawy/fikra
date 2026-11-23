import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import 'group_form.dart';

/// Filter by group: "All", then each top-level group. When a group with
/// sub-groups is selected (or one of its sub-groups), a second row lists the
/// sub-groups. Tapping the selected chip again goes one level up. The
/// selected group has an options control at the end of the first row, and a
/// long press on any group chip opens that group's options.
class GroupFilterRow extends StatelessWidget {
  const GroupFilterRow({
    super.key,
    required this.groups,
    required this.selectedId,
    required this.onSelect,
    required this.onOptions,
    this.counts,
    this.clearSelectedChild = false,
    this.leadingChips = const [],
    this.allSelected,
  });

  final Map<String, int>? counts;
  final bool clearSelectedChild;

  /// Optional filter chips placed immediately after "All" and before user groups.
  final List<Widget> leadingChips;

  /// Overrides whether the "All" chip appears selected (defaults to `selectedId == null`).
  final bool? allSelected;
  final List<NoteGroup> groups;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<NoteGroup> onOptions;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final g in groups) g.id: g};
    bool isTop(NoteGroup g) => g.parentId == null || !byId.containsKey(g.parentId);
    final selected = byId[selectedId];
    final parent = selected == null ? null : (isTop(selected) ? selected : byId[selected.parentId]);
    final children = [
      if (parent != null)
        for (final g in groups)
          if (g.parentId == parent.id) g,
    ];
    Widget chip(NoteGroup g, {required bool on, required VoidCallback onTap}) => ChoiceTag(
      key: ValueKey('group-filter-${g.id}'),
      label: counts == null ? g.name : '${g.name} ${counts![g.id] ?? 0}',
      color: g.color,
      selected: on,
      onTap: onTap,
      onLongPress: () => onOptions(g),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _ChipRow(
                  children: [
                    ChoiceTag(
                      key: const ValueKey('group-filter-all'),
                      label: context.l10n.allGroupsFilter,
                      selected: allSelected ?? selected == null,
                      onTap: () => onSelect(null),
                    ),
                    ...leadingChips,
                    for (final g in groups)
                      if (isTop(g))
                        chip(g, on: g.id == parent?.id, onTap: () => onSelect(g.id == selectedId ? null : g.id)),
                  ],
                ),
              ),
              if (selected != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: FikraSpace.screen - 8),
                  child: FikraIconButton(
                    key: const ValueKey('group-filter-options'),
                    icon: Icons.more_horiz_rounded,
                    label: context.l10n.groupOptionsA11y(selected.name),
                    size: 36,
                    onTap: () => onOptions(selected),
                  ),
                ),
            ],
          ),
          if (children.isNotEmpty)
            _ChipRow(
              key: const ValueKey('group-filter-children'),
              children: [
                for (final g in children)
                  chip(
                    g,
                    on: g.id == selectedId,
                    onTap: () => onSelect(g.id == selectedId ? (clearSelectedChild ? null : parent!.id) : g.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen - 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bounded, so a long name wraps or ends with an ellipsis.
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: c),
          ],
        ],
      ),
    );
  }
}
