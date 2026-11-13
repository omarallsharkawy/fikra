import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import 'note_groups.dart';

/// The longest group name the field takes.
const groupNameMaxLength = 40;

typedef NewGroup = ({String name, int? color, String? parentId});

/// Asks for a new group's name, an optional colour and an optional parent
/// among [projectId]'s top-level groups. Null when dismissed.
Future<NewGroup?> showNewGroupForm(BuildContext context, {required String projectId}) {
  final controller = TextEditingController();
  int? color;
  String? parentId;
  return showFikraSheet<NewGroup>(
    context,
    title: context.l10n.newGroup,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final parents = [
          for (final g in ref.watch(groupsOfProjectProvider(projectId)).value ?? const <NoteGroup>[])
            if (g.parentId == null) g,
        ];
        // A picked parent that stops being top-level meanwhile is kept, so
        // the repository refuses it with its message instead of the form
        // quietly making a top-level group.
        return StatefulBuilder(
          builder: (sheet, setState) {
            final name = controller.text.trim();
            void submit() {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.pop(sheet, (name: name, color: color, parentId: parentId));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FikraField(
                  controller: controller,
                  hint: context.l10n.groupNameHint,
                  icon: Icons.folder_copy_outlined,
                  autofocus: true,
                  maxLength: groupNameMaxLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 16),
                GroupColorPicker(selected: color, onChanged: (c) => setState(() => color = c)),
                if (parents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(context.l10n.groupParentLabel, style: context.text.section),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceTag(
                        key: const ValueKey('group-parent-none'),
                        label: context.l10n.groupParentNone,
                        selected: parentId == null,
                        onTap: () => setState(() => parentId = null),
                      ),
                      for (final g in parents)
                        ChoiceTag(
                          key: ValueKey('group-parent-${g.id}'),
                          label: g.name,
                          color: g.color,
                          selected: parentId == g.id,
                          onTap: () => setState(() => parentId = g.id),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                FikraButton(
                  key: const ValueKey('group-create'),
                  // Large text: the button grows instead of clipping its label.
                  growForText: true,
                  label: context.l10n.create,
                  onPressed: name.isEmpty ? null : submit,
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

/// Asks for a group name (rename). Null when dismissed or unchanged-empty.
Future<String?> askGroupName(BuildContext context, {required String initial}) {
  final controller = TextEditingController(text: initial);
  return showFikraSheet<String>(
    context,
    title: context.l10n.renameGroup,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final name = controller.text.trim();
        void submit() {
          final name = controller.text.trim();
          if (name.isNotEmpty) Navigator.pop(sheet, name);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FikraField(
              controller: controller,
              hint: context.l10n.groupNameHint,
              icon: Icons.folder_copy_outlined,
              autofocus: true,
              maxLength: groupNameMaxLength,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 16),
            FikraButton(
              key: const ValueKey('group-rename-save'),
              // Large text: the button grows instead of clipping its label.
              growForText: true,
              label: context.l10n.save,
              onPressed: name.isEmpty ? null : submit,
            ),
          ],
        );
      },
    ),
  );
}

/// "No colour" and the four shades, each a 48 dp target named for screen
/// readers; the chosen one's name is written above them.
class GroupColorPicker extends StatelessWidget {
  const GroupColorPicker({super.key, required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.groupColorLabel(groupColorName(context.l10n, selected)),
          key: const ValueKey('group-color-label'),
          style: context.text.section,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            for (final c in [null, ...groupColors])
              Pressable(
                key: ValueKey('group-color-${c ?? 'none'}'),
                onTap: () => onChanged(c),
                selected: c == selected,
                semanticLabel: groupColorName(context.l10n, c),
                minTarget: true,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: groupColor(context, c),
                    border: Border.all(
                      color: c == selected ? context.colors.textPrimary : context.colors.border,
                      width: c == selected ? 2.5 : 1,
                    ),
                  ),
                  child: c == null
                      ? Icon(Icons.block_rounded, size: 18, color: context.colors.textSecondary)
                      : c == selected
                      ? Icon(Icons.check_rounded, size: 18, color: context.colors.screen)
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A selectable tag that grows with large text instead of clipping, with an
/// optional group colour dot.
class ChoiceTag extends StatelessWidget {
  const ChoiceTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int? color;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.textOnSelected : context.colors.textPrimary;
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      minTarget: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: selected ? context.colors.selectedGradient : null,
          color: selected ? null : context.colors.glassHighlight,
          borderRadius: BorderRadius.circular(FikraRadius.full),
          border: selected ? null : Border.all(color: context.colors.border, width: FikraSpace.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[Icon(Icons.check_rounded, size: 16, color: fg), const SizedBox(width: 4)],
            if (color != null) ...[GroupDot(color: color), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.chip.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
