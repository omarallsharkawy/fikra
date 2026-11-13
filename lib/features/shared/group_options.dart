import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import 'group_form.dart';
import 'group_sheet.dart';
import 'note_groups.dart';

/// The options of [group]: rename, colour, put inside another group or take
/// it out, delete. One sheet at a time: each option closes this sheet first
/// and continues from [context] (the page), which outlives it.
Future<void> showGroupOptions(BuildContext context, WidgetRef ref, NoteGroup group) {
  // One option per sheet: a double tap must not open two flows.
  var chosen = false;
  void choose(BuildContext sheet, Future<void> Function() then) {
    if (chosen) return;
    chosen = true;
    Navigator.pop(sheet);
    if (context.mounted) then();
  }

  final repo = ref.read(groupsRepoProvider);
  return showFikraSheet<void>(
    context,
    title: group.name,
    builder: (sheet) => Consumer(
      builder: (sheet, sheetRef, _) {
        final groups = sheetRef.watch(groupsOfProjectProvider(group.projectId)).value ?? const <NoteGroup>[];
        final live = groups.where((g) => g.id == group.id).firstOrNull ?? group;
        final parent = groups.where((g) => g.id == live.parentId).firstOrNull;
        final l10n = context.l10n;
        return Column(
          children: [
            SheetOption(
              key: const ValueKey('group-rename'),
              label: l10n.renameGroup,
              icon: Icons.edit_outlined,
              onTap: () => choose(sheet, () async {
                final name = await askGroupName(context, initial: live.name);
                if (name == null || !context.mounted) return;
                await runGroupAction(context, () => repo.rename(live.id, name));
              }),
            ),
            SheetOption(
              key: const ValueKey('group-color'),
              label: l10n.changeGroupColor,
              icon: Icons.palette_outlined,
              onTap: () => choose(sheet, () async {
                final picked = await _askColor(context, live.color);
                if (picked == null || !context.mounted) return;
                await runGroupAction(context, () => repo.setColor(live.id, picked.color));
              }),
            ),
            if (parent == null && groups.any((g) => g.parentId == live.id))
              // Two levels only: a group with sub-groups can't go inside
              // another one, so the option is shown disabled, with why.
              _Disabled(
                reason: l10n.groupRuleHasChildren,
                child: SheetOption(
                  key: const ValueKey('group-nest'),
                  label: l10n.putInGroup,
                  icon: Icons.drive_folder_upload_outlined,
                  onTap: () {},
                ),
              )
            else if (parent == null)
              SheetOption(
                key: const ValueKey('group-nest'),
                label: l10n.putInGroup,
                icon: Icons.drive_folder_upload_outlined,
                onTap: () => choose(sheet, () async {
                  final target = await _askParent(context, live, groups);
                  if (target == null || !context.mounted) return;
                  // A sub-group added meanwhile: the repository's message shows.
                  await runGroupAction(context, () => repo.setParent(live.id, target.id));
                }),
              )
            else
              SheetOption(
                key: const ValueKey('group-unnest'),
                label: l10n.takeOutOfGroup(Fmt.isolate(parent.name)),
                icon: Icons.drive_folder_upload_outlined,
                onTap: () => choose(sheet, () => runGroupAction(context, () => repo.setParent(live.id, null))),
              ),
            SheetOption(
              key: const ValueKey('group-delete'),
              label: l10n.deleteGroup,
              icon: Icons.delete_outline_rounded,
              danger: true,
              onTap: () => choose(sheet, () async {
                final ok = await confirmDestructive(
                  context,
                  title: l10n.deleteGroupTitle(Fmt.isolate(live.name)),
                  message: l10n.deleteGroupBody,
                  danger: false,
                );
                if (!ok || !context.mounted) return;
                await runGroupAction(context, () => repo.delete(live.id), success: l10n.groupDeleted);
              }),
            ),
          ],
        );
      },
    ),
  );
}

/// The colour sheet. Null when dismissed; otherwise the picked colour
/// (null inside is "no colour").
Future<({int? color})?> _askColor(BuildContext context, int? current) {
  return showFikraSheet<({int? color})>(
    context,
    title: context.l10n.changeGroupColor,
    builder: (sheet) => GroupColorPicker(selected: current, onChanged: (c) => Navigator.pop(sheet, (color: c))),
  );
}

/// The top-level groups [group] can go inside, as they were when the sheet
/// opened (the repository checks the rule again when one is picked).
Future<NoteGroup?> _askParent(BuildContext context, NoteGroup group, List<NoteGroup> groups) {
  final candidates = [
    for (final g in groups)
      if (g.parentId == null && g.id != group.id) g,
  ];
  return showFikraSheet<NoteGroup>(
    context,
    title: context.l10n.putInGroup,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        if (candidates.isEmpty) {
          return Text(
            context.l10n.noParentGroups,
            key: const ValueKey('group-parent-empty'),
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          );
        }
        final counts = groupNoteCounts(ref.watch(notesOfProjectProvider(group.projectId)).value ?? const <Note>[]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final g in candidates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GroupRow(
                  key: ValueKey('group-parent-pick-${g.id}'),
                  group: g,
                  count: counts[g.id] ?? 0,
                  onTap: () => Navigator.pop(sheet, g),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// An option that can't be used now: dimmed, not tappable, disabled for a
/// screen reader, with [reason] under it (and as its hint).
class _Disabled extends StatelessWidget {
  const _Disabled({required this.reason, required this.child});
  final String reason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: false,
      hint: reason,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IgnorePointer(child: Opacity(opacity: 0.4, child: child)),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 10),
            child: ExcludeSemantics(
              child: Text(
                reason,
                key: const ValueKey('group-nest-reason'),
                style: context.text.caption.copyWith(color: context.colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
