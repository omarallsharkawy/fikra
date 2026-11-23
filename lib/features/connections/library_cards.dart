import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/motion/container_transform.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/note_presentation.dart';
import 'links_index.dart';

void openConnections(BuildContext context, String id, {LibraryNote? initial, CardOrigin? origin}) =>
    context.push('/links/note/$id', extra: (initial, origin));

class LibraryNoteText extends StatelessWidget {
  const LibraryNoteText({super.key, required this.note, this.lines = 1});
  final LibraryNote note;
  final int lines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        noteTitleText(context, note.title),
        style: context.text.body.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Text(note.text, style: context.text.caption, maxLines: lines, overflow: TextOverflow.ellipsis),
    ],
  );
}

class BrowseNoteCard extends StatelessWidget {
  const BrowseNoteCard({super.key, required this.entry});
  final BrowseEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Builder(
      builder: (cardContext) => ContainerTransformSource(
        child: Pressable(
          onTap: () => openConnections(
            cardContext,
            entry.note.id,
            initial: entry.note,
            origin: CardOrigin.fromContext(cardContext, borderRadius: FikraRadius.md),
          ),
          pressedScale: .98,
          child: SolidSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LibraryNoteText(note: entry.note),
                const SizedBox(height: 12),
                Text(Fmt.links(context.l10n, entry.others.length), style: context.text.meta),
                const SizedBox(height: 4),
                Text(
                  [
                    // Isolated so a mixed Arabic/English title never reorders the row.
                    for (final n in entry.others.take(2)) Fmt.isolate(noteTitleText(context, n.title)),
                    if (entry.others.length > 2) '+${entry.others.length - 2}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.meta.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
