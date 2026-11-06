import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';

IconData sourceIcon(NoteSource s) => switch (s) {
  NoteSource.text => Icons.notes_rounded,
  NoteSource.voice => Icons.mic_none_rounded,
  NoteSource.pdf => Icons.picture_as_pdf_outlined,
};

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
      semanticLabel: note.title,
      child: Glass(
        radius: FikraRadius.lg,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sourceIcon(note.source), size: 18, color: FikraColors.accentLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'نوت جديدة' : note.title,
                    style: FikraText.cardTitleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(Fmt.time(note.createdAt), style: FikraText.meta),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.displayText.isEmpty ? (note.attachmentName ?? '') : note.displayText,
              style: FikraText.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            switch (note.status) {
              ProcessingStatus.processing => const FikraBadge(kind: BadgeKind.processing, label: 'بيتحلّل…'),
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
        color: FikraColors.pressed,
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: FikraColors.border, width: FikraSpace.hairline),
      ),
      child: Text(label, style: FikraText.meta.copyWith(color: FikraColors.textSecondary, fontSize: 11.5)),
    );
  }
}
