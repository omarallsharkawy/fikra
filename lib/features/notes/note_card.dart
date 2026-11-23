import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/container_transform.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../connections/note_connections_provider.dart';
import '../shared/note_groups.dart';
import '../shared/note_presentation.dart';

class NoteCard extends ConsumerWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onOpenWithOrigin,
    this.onLongPress,
    this.selected,
    this.group,
  }) : assert((onTap == null) != (onOpenWithOrigin == null), 'Provide exactly one of onTap or onOpenWithOrigin.');
  final Note note;
  final VoidCallback? onTap;
  final ValueChanged<CardOrigin?>? onOpenWithOrigin;
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
    final linkCount = ref.watch(connectionsIndexProvider(note.projectId).select((v) => v.value?[note.id]?.length ?? 0));
    final selected = this.selected;
    final group = this.group;
    final on = selected ?? false;
    final kindBadges = _kindBadges(context, note, attachments);
    final hasTopMeta = selected != null || kindBadges.isNotEmpty;
    // The thicker border takes its width from the padding, so nothing moves.
    final inset = on ? 2 - FikraSpace.hairline : 0.0;
    return ContainerTransformSource(
      child: Pressable(
        onTap: onOpenWithOrigin == null
            ? onTap
            : () => onOpenWithOrigin!(CardOrigin.fromContext(context, borderRadius: FikraRadius.lg)),
        onLongPress: onLongPress,
        selected: selected,
        pressedScale: 0.98,
        child: SolidSurface(
          radius: FikraRadius.lg,
          padding: EdgeInsets.fromLTRB(18 - inset, 16 - inset, 18 - inset, 16 - inset),
          borderColor: on ? context.colors.accent : null,
          borderWidth: on ? 2 : FikraSpace.hairline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTopMeta) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (selected != null) ...[
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        key: ValueKey('note-check-${note.id}'),
                        size: 22,
                        color: selected ? context.colors.accent : context.colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: kindBadges.isEmpty
                          ? const SizedBox.shrink()
                          : Wrap(spacing: 6, runSpacing: 4, children: kindBadges),
                    ),
                    const SizedBox(width: 8),
                    Text(Fmt.time(context.l10n, note.createdAt), style: context.text.meta),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  noteTitle(context, note),
                  style: context.text.cardTitleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
              if (group != null || linkCount > 0) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (group != null) GroupTag(key: ValueKey('note-group-${note.id}'), group: group),
                    if (linkCount > 0) _LinkCountPill(noteId: note.id, count: linkCount),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              if (attachments.any(
                (a) =>
                    a.kind == AttachmentKind.voice &&
                    (a.transcriptionStatus == TranscriptionStatus.queued ||
                        a.transcriptionStatus == TranscriptionStatus.running),
              )) ...[
                FikraBadge(
                  key: ValueKey('transcribing-${note.id}'),
                  kind: BadgeKind.processing,
                  label: context.l10n.trWorking,
                ),
                const SizedBox(height: FikraSpace.s8),
              ],
              FikraSwitcher(
                alignment: AlignmentDirectional.topStart,
                child: KeyedSubtree(
                  key: ValueKey(note.status),
                  child: switch (note.status) {
                    ProcessingStatus.processing => const FikraBadge(kind: BadgeKind.processing),
                    ProcessingStatus.failed => FikraBadge(
                      kind: BadgeKind.failed,
                      label: context.l10n.noteAnalysisFailed,
                    ),
                    ProcessingStatus.ready => Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (note.rewrite == RewriteStatus.pending)
                          FikraBadge(
                            key: ValueKey('note-rewrite-${note.id}'),
                            kind: BadgeKind.warning,
                            label: context.l10n.noteRewriteSuggested,
                          ),
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
      ),
    );
  }
}

List<Widget> _kindBadges(BuildContext context, Note note, List<NoteAttachment> attachments) {
  final counts = <AttachmentKind, int>{};
  for (final a in attachments) {
    counts.update(a.kind, (v) => v + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) {
    return switch (note.source) {
      NoteSource.voice => [_TypeBadge(noteId: note.id, kind: AttachmentKind.voice, count: 1)],
      NoteSource.pdf => [_TypeBadge(noteId: note.id, kind: AttachmentKind.pdf, count: 1)],
      NoteSource.text => const [],
    };
  }
  return [
    for (final kind in AttachmentKind.values)
      if (counts.containsKey(kind)) _TypeBadge(noteId: note.id, kind: kind, count: counts[kind]!),
  ];
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.noteId, required this.kind, required this.count});
  final String noteId;
  final AttachmentKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final (IconData icon, String base, Color fg, Color bg) = switch (kind) {
      AttachmentKind.voice => (Icons.mic_none_rounded, l10n.filterVoice, c.brandPurpleFg, c.brandPurpleTint),
      AttachmentKind.pdf => (Icons.picture_as_pdf_outlined, l10n.badgePdf, c.brandBlueFg, c.brandBlueTint),
      AttachmentKind.image => (Icons.image_outlined, l10n.photosTitle, c.brandSlateFg, c.brandSlateTint),
    };
    final label = count > 1 ? '$base · $count' : base;
    return Container(
      key: ValueKey('note-type-${kind.name}-$noteId'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(FikraRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.meta.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LinkCountPill extends StatelessWidget {
  const _LinkCountPill({required this.noteId, required this.count});
  final String noteId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: Fmt.links(context.l10n, count),
      excludeSemantics: true,
      child: Container(
        key: ValueKey('note-links-$noteId'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: c.brandLimeTint, borderRadius: BorderRadius.circular(FikraRadius.full)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 14, color: c.brandLimeFg),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: context.text.meta.copyWith(color: c.brandLimeFg, fontWeight: FontWeight.w700),
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
        color: context.colors.chip,
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: context.colors.line, width: FikraSpace.hairline),
      ),
      child: Text(label, style: context.text.meta),
    );
  }
}
