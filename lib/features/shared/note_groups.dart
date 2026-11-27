import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/groups_repository.dart';
import '../../data/local/database.dart';

/// A project's groups, ordered by position (one query per project).
final groupsOfProjectProvider = StreamProvider.autoDispose.family<List<NoteGroup>, String>(
  (ref, projectId) => ref.watch(groupsRepoProvider).watchGroups(projectId),
);

/// The stored colours (0..3); null is "no colour".
const groupColors = [0, 1, 2, 3];

/// The calm, muted hue for a stored colour (blue, sage, sand, gray). Only ever
/// a marker next to the group's name, never the only signal.
Color? groupColor(BuildContext context, int? color) => switch (color) {
  0 => context.colors.groupBlue,
  1 => context.colors.groupSage,
  2 => context.colors.groupSand,
  3 => context.colors.groupGray,
  _ => null,
};

String groupColorName(AppLocalizations l10n, int? color) => switch (color) {
  0 => l10n.colorBlue,
  1 => l10n.colorGreen,
  2 => l10n.colorYellow,
  3 => l10n.colorGray,
  _ => l10n.colorNone,
};

/// The plain message for a broken group rule.
String groupRuleMessage(AppLocalizations l10n, GroupRuleReason reason) => switch (reason) {
  GroupRuleReason.emptyName => l10n.groupRuleEmptyName,
  GroupRuleReason.invalidColor => l10n.groupRuleInvalidColor,
  GroupRuleReason.missingProject => l10n.groupRuleMissingProject,
  GroupRuleReason.missingGroup => l10n.groupRuleMissingGroup,
  GroupRuleReason.invalidParent => l10n.groupRuleInvalidParent,
  GroupRuleReason.selfParent => l10n.groupRuleSelfParent,
  GroupRuleReason.hasChildren => l10n.groupRuleHasChildren,
};

/// Top-level groups in order, each followed by its sub-groups. A sub-group
/// whose parent is missing is listed as top-level.
List<({NoteGroup group, NoteGroup? parent})> groupTree(List<NoteGroup> groups) {
  final ids = {for (final g in groups) g.id};
  bool top(NoteGroup g) => g.parentId == null || !ids.contains(g.parentId);
  return [
    for (final g in groups)
      if (top(g)) ...[
        (group: g, parent: null),
        for (final c in groups)
          if (c.parentId == g.id) (group: c, parent: g),
      ],
  ];
}

/// [id] and its sub-groups' ids.
Set<String> groupWithChildren(List<NoteGroup> groups, String id) => {
  id,
  for (final g in groups)
    if (g.parentId == id) g.id,
};

/// How many notes each group holds directly (sub-groups counted apart).
Map<String, int> groupNoteCounts(Iterable<Note> notes) {
  final counts = <String, int>{};
  for (final n in notes) {
    final g = n.groupId;
    if (g != null) counts[g] = (counts[g] ?? 0) + 1;
  }
  return counts;
}

/// Runs a group write, showing the plain message for a broken rule and the
/// group failure otherwise. Returns whether it succeeded.
Future<bool> runGroupAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  void toast(String m) => showMessengerToast(messenger, m, measureContext: context.mounted ? context : null);
  try {
    await action();
    if (success != null) toast(success);
    return true;
  } on GroupRuleException catch (e) {
    toast(groupRuleMessage(l10n, e.reason));
  } catch (_) {
    toast(l10n.groupFailed);
  }
  return false;
}

/// A small colour dot, or nothing for a group with no colour.
class GroupDot extends StatelessWidget {
  const GroupDot({super.key, required this.color, this.size = 8});
  final int? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = groupColor(context, color);
    if (c == null) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

/// The group's name as a small tag (note cards).
class GroupTag extends StatelessWidget {
  const GroupTag({super.key, required this.group});
  final NoteGroup group;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.noteGroupA11y(group.name),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FikraRadius.full),
          border: Border.all(color: groupColor(context, group.color) ?? context.colors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_copy_outlined, size: 13, color: context.colors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: SmartText(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(color: context.colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
