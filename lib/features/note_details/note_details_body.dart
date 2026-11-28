part of 'note_details_screen.dart';

class _Body extends ConsumerWidget {
  const _Body({required this.note, required this.view, required this.onView});
  final Note note;
  final int view;
  final ValueChanged<int> onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(noteAttachmentsProvider(note.id));
    final improved = note.hasImprovedVersion;
    final text = improved && view == _originalView ? note.originalContent : note.displayText;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen, 8, FikraSpace.screen, 32),
      children: [
        Semantics(
          header: true,
          child: SmartText(noteTitle(context, note), style: context.text.title.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final icon in sourceIcons(note, attachments.value ?? const [])) ...[
              Icon(icon, size: 16, color: context.colors.textSecondary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: SmartText(
                [
                  Fmt.dayHeader(context.l10n, note.createdAt, now: ref.read(appClockProvider)()),
                  Fmt.time(context.l10n, note.createdAt),
                  ?note.cluster,
                ].join(' · '),
                style: context.text.meta.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FikraSwitcher(
          animateSize: true,
          child: Column(
            key: ValueKey(note.status),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note.status == ProcessingStatus.processing) ...[const _ProcessingCard(), const SizedBox(height: 16)],
              if (note.status == ProcessingStatus.failed) ...[
                StatusBanner(kind: BannerKind.error, message: context.l10n.analysisFailedBanner),
                const SizedBox(height: 10),
                FikraButton.secondary(
                  label: context.l10n.analyzeAgain,
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.read(noteProcessorProvider).retry(note.id),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        if (note.rewrite == RewriteStatus.pending && note.proposedText != null) ...[
          _ProposalCard(note: note, onAccepted: () => onView(_improvedView)),
          const SizedBox(height: 16),
        ],
        if (improved) ...[
          SegmentedPill(
            options: [context.l10n.viewEdited, context.l10n.viewOriginal],
            selected: view,
            onChanged: onView,
          ),
          const SizedBox(height: 14),
        ],
        if (note.rewrite == RewriteStatus.pending && note.proposedText != null && text.isNotEmpty) ...[
          SmartText(
            context.l10n.originalTextLabel,
            content: ReadOnlyContent.chrome,
            style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 6),
        ],
        if (text.isNotEmpty) SmartText(text, selectable: true, style: context.text.bodyLarge.copyWith(height: 1.7)),
        if (attachments.hasError && !attachments.hasValue)
          FikraButton.secondary(
            label: context.l10n.retry,
            onPressed: () => ref.invalidate(noteAttachmentsProvider(note.id)),
          ),
        if (attachments.value?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _Attachment(note: note, attachments: attachments.requireValue),
        ],
        if (note.conceptList.isNotEmpty) ...[
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: SmartText(
              context.l10n.topicsHeader,
              content: ReadOnlyContent.chrome,
              style: context.text.section.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in note.conceptList) FikraChip(label: c)]),
        ],
        const SizedBox(height: 24),
        _NoteLinks(note: note),
      ],
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return SolidSurface(
      radius: FikraRadius.lg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SmartText(context.l10n.analyzingBody, content: ReadOnlyContent.chrome, style: context.text.caption),
          ),
        ],
      ),
    );
  }
}
