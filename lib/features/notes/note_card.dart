import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../shared/note_groups.dart';
import '../shared/note_presentation.dart';

class NoteCard extends ConsumerWidget {
  const NoteCard({super.key, required this.note, required this.onTap, this.onLongPress, this.selected, this.group});
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Null outside a selection; in one, whether this card is selected (a check
  /// mark and an accent border, and `selected` for screen readers).
  final bool? selected;

  /// The note's group, shown as a small tag.
  final NoteGroup? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concepts = note.conceptList;
    final attachments =
        ref.watch(projectAttachmentsProvider(note.projectId)).value?[note.id] ?? const <NoteAttachment>[];
    final selected = this.selected;
    final group = this.group;
    final on = selected ?? false;
    // The thicker border takes its width from the padding, so nothing moves.
    final inset = on ? 2 - FikraSpace.hairline : 0.0;
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      pressedScale: 0.98,
      child: Glass(
        radius: FikraRadius.lg,
        padding: EdgeInsets.fromLTRB(18 - inset, 16 - inset, 18 - inset, 16 - inset),
        borderColor: on ? context.colors.accentLight : null,
        borderWidth: on ? 2 : FikraSpace.hairline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (selected != null) ...[
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    key: ValueKey('note-check-${note.id}'),
                    size: 22,
                    color: selected ? context.colors.accentLight : context.colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                ],
                for (final item in attachmentIcons(note, attachments)) ...[
                  Icon(item.icon, size: 18, color: context.colors.accentLight),
                  if (item.count > 1) Text(' ${item.count}', style: context.text.meta),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    noteTitle(context, note),
                    style: context.text.cardTitleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(Fmt.time(context.l10n, note.createdAt), style: context.text.meta),
              ],
            ),
            if (note.displayText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note.displayText, style: context.text.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            if (group != null) ...[
              GroupTag(key: ValueKey('note-group-${note.id}'), group: group),
              const SizedBox(height: 6),
            ],
            FikraSwitcher(
              alignment: AlignmentDirectional.topStart,
              child: KeyedSubtree(
                key: ValueKey(note.status),
                child: switch (note.status) {
                  ProcessingStatus.processing => const FikraBadge(kind: BadgeKind.processing),
                  ProcessingStatus.failed => FikraBadge(kind: BadgeKind.failed, label: context.l10n.noteAnalysisFailed),
                  ProcessingStatus.ready => Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (note.rewrite == RewriteStatus.pending)
                        FikraBadge(kind: BadgeKind.processing, label: context.l10n.noteRewriteSuggested),
                      for (final c in concepts.take(3)) _ConceptTag(c),
                      if (concepts.isEmpty && note.rewrite != RewriteStatus.pending)
                        FikraBadge(kind: BadgeKind.saved, label: context.l10n.noteSavedBadge),
                    ],
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConceptTag extends StatelessWidget {
  const _ConceptTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.pressed,
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: context.colors.border, width: FikraSpace.hairline),
      ),
      child: Text(label, style: context.text.meta.copyWith(color: context.colors.textSecondary, fontSize: 11.5)),
    );
  }
}
