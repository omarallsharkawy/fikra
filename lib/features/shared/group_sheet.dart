import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import 'note_groups.dart';

/// What was picked in [showGroupSheet].
sealed class GroupPick {
  const GroupPick();
}

/// An existing group.
class GroupPickExisting extends GroupPick {
  const GroupPickExisting(this.group);
  final NoteGroup group;
}

/// "New group": the caller asks for its details after the sheet closed.
class GroupPickNew extends GroupPick {
  const GroupPickNew();
}

/// "Remove from group".
class GroupPickNone extends GroupPick {
  const GroupPickNone();
}

/// Lists [projectId]'s groups (sub-groups indented under their parent, each
/// with its own note count), "New group" and, with [canRemove], "Remove from
/// group". Returns the pick, or null when dismissed. It knows nothing of who
/// asks: the notes list and the graph both use it.
Future<GroupPick?> showGroupSheet(BuildContext context, {required String projectId, required bool canRemove}) {
  return showFikraSheet<GroupPick>(
    context,
    title: context.l10n.chooseGroup,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final groups = ref.watch(groupsOfProjectProvider(projectId)).value ?? const <NoteGroup>[];
        final notes = ref.watch(notesOfProjectProvider(projectId)).value ?? const <Note>[];
        final counts = groupNoteCounts(notes);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SmartText(
                  context.l10n.noGroupsYet,
                  content: ReadOnlyContent.chrome,
                  key: const ValueKey('group-sheet-empty'),
                  style: context.text.body.copyWith(color: context.colors.textSecondary),
                ),
              ),
            for (final (:group, :parent) in groupTree(groups))
              Padding(
                padding: EdgeInsetsDirectional.only(start: parent == null ? 0 : 28, bottom: 8),
                child: GroupRow(
                  key: ValueKey('group-pick-${group.id}'),
                  group: group,
                  parent: parent,
                  count: counts[group.id] ?? 0,
                  onTap: () => Navigator.pop(sheet, GroupPickExisting(group)),
                ),
              ),
            const SizedBox(height: 4),
            SheetOption(
              key: const ValueKey('group-pick-new'),
              label: context.l10n.newGroup,
              icon: Icons.add_rounded,
              onTap: () => Navigator.pop(sheet, const GroupPickNew()),
            ),
            if (canRemove)
              SheetOption(
                key: const ValueKey('group-pick-none'),
                label: context.l10n.removeFromGroup,
                icon: Icons.folder_off_outlined,
                onTap: () => Navigator.pop(sheet, const GroupPickNone()),
              ),
          ],
        );
      },
    ),
  );
}

/// One group in a sheet: colour dot, name and note count. A sub-group says
/// which group it is in to a screen reader (the indent is visual only).
class GroupRow extends StatelessWidget {
  const GroupRow({super.key, required this.group, required this.count, required this.onTap, this.parent});
  final NoteGroup group;
  final NoteGroup? parent;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parent = this.parent;
    final notes = Fmt.notes(context.l10n, count);
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: parent == null
          ? context.l10n.linkRowA11y(group.name, notes)
          : context.l10n.subGroupA11y(group.name, parent.name, notes),
      child: SolidSurface(
        radius: FikraRadius.md,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              parent == null
                  ? Icons.folder_copy_outlined
                  : Directionality.of(context) == TextDirection.rtl
                  ? Icons.subdirectory_arrow_left_rounded
                  : Icons.subdirectory_arrow_right_rounded,
              size: 20,
              color: context.colors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SmartText(group.name, style: context.text.section.copyWith(fontWeight: FontWeight.w600)),
                  SmartText(notes, style: context.text.meta.copyWith(color: context.colors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GroupDot(color: group.color, size: 10),
          ],
        ),
      ),
    );
  }
}
