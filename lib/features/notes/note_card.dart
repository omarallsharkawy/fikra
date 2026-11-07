import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../shared/note_presentation.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.onTap});
  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final concepts = note.conceptList;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Glass(
        radius: FikraRadius.lg,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final icon in sourceIcons(note)) ...[
                  Icon(icon, size: 18, color: context.colors.accentLight),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    noteTitle(note),
                    style: context.text.cardTitleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(Fmt.time(note.createdAt), style: context.text.meta),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.displayText.isEmpty ? (note.attachmentName ?? '') : note.displayText,
              style: context.text.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            FikraSwitcher(
              alignment: AlignmentDirectional.topStart,
              child: KeyedSubtree(
                key: ValueKey(note.status),
                child: switch (note.status) {
                  ProcessingStatus.processing => const FikraBadge(kind: BadgeKind.processing),
                  ProcessingStatus.failed => const FikraBadge(kind: BadgeKind.failed, label: 'التحليل فشل'),
                  ProcessingStatus.ready => Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (note.rewrite == RewriteStatus.pending)
                        const FikraBadge(kind: BadgeKind.processing, label: 'في اقتراح صياغة'),
                      for (final c in concepts.take(3)) _ConceptTag(c),
                      if (concepts.isEmpty && note.rewrite != RewriteStatus.pending)
                        const FikraBadge(kind: BadgeKind.saved, label: 'محفوظة'),
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
