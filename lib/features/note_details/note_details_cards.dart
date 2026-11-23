part of 'note_details_screen.dart';

/// AI rewrite waiting for the user's decision. Buttons lock while saving.
class _ProposalCard extends ConsumerStatefulWidget {
  const _ProposalCard({required this.note, required this.onAccepted});
  final Note note;
  final VoidCallback onAccepted;

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  bool _busy = false;

  Future<void> _decide({required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(notesRepoProvider);
    final id = widget.note.id;
    final ok = await runAction(context, () => accept ? repo.acceptRewrite(id) : repo.rejectRewrite(id));
    if (ok && accept) widget.onAccepted();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return SolidSurface(
      radius: FikraRadius.lg,
      borderColor: context.colors.accent.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: context.colors.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(context.l10n.suggestedRewrite, style: context.text.cardTitleSmall)),
              if (isDemo) FikraBadge(kind: BadgeKind.demo, label: context.l10n.demoBadge),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.note.proposedText!, style: context.text.body),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              const padding = 8.0;
              const gap = 10.0;
              double labelWidth(String label, TextStyle style) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  locale: Localizations.localeOf(context),
                )..layout();
                final width = painter.width;
                painter.dispose();
                return width;
              }

              final useWidth = labelWidth(context.l10n.useRewrite, context.text.button) + 20 + 8 + padding * 2;
              final keepWidth = labelWidth(context.l10n.keepOriginal, context.text.section) + padding * 2;
              final use = FikraButton(
                label: context.l10n.useRewrite,
                horizontalPadding: padding,
                growForText: true,
                icon: Icons.check_rounded,
                loading: _busy,
                onPressed: () => _decide(accept: true),
              );
              final keep = FikraButton.secondary(
                label: context.l10n.keepOriginal,
                horizontalPadding: padding,
                growForText: true,
                onPressed: _busy ? null : () => _decide(accept: false),
              );
              if (useWidth + keepWidth + gap > box.maxWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    use,
                    const SizedBox(height: gap),
                    keep,
                  ],
                );
              }
              // Give each label its natural width, then share the spare space.
              final extra = (box.maxWidth - useWidth - keepWidth - gap) / 2;
              return Row(
                children: [
                  Expanded(child: use),
                  const SizedBox(width: gap),
                  SizedBox(width: keepWidth + extra, child: keep),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Attachment extends ConsumerWidget {
  const _Attachment({required this.note, required this.attachments});
  final Note note;
  final List<NoteAttachment> attachments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final (i, a) in attachments.indexed)
          if (a.kind == AttachmentKind.pdf)
            Pressable(
              key: ValueKey('open-pdf-${a.id}'),
              onTap: () => context.push('/note/${note.id}/pdf/${a.id}'),
              pressedScale: 0.98,
              semanticLabel: context.l10n.openFileA11y(a.name ?? context.l10n.pdfFile),
              child: SolidSurface(
                radius: FikraRadius.lg,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: context.colors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.name ?? context.l10n.pdfFile,
                        style: context.text.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (a.bytes != null)
                      Text(
                        Fmt.bytes(context.l10n, a.bytes!),
                        textDirection: TextDirection.ltr,
                        style: context.text.meta,
                      ),
                    const SizedBox(width: 10),
                    Icon(Icons.open_in_new_rounded, size: 18, color: context.colors.textSecondary),
                  ],
                ),
              ),
            )
          else if (a.kind == AttachmentKind.voice)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VoicePlayer(key: ValueKey(a.id), path: a.path, durationMs: a.durationMs ?? 0),
                const SizedBox(height: FikraSpace.s8),
                VoiceTranscript(key: ValueKey('voice-transcript-${a.id}'), attachment: a),
              ],
            )
          else if (i == 0 || attachments[i - 1].kind != AttachmentKind.image)
            _Photos(
              paths: attachments.skip(i).takeWhile((a) => a.kind == AttachmentKind.image).map((a) => a.path).toList(),
              startIndex: attachments.take(i).where((a) => a.kind == AttachmentKind.image).length,
            ),
      ],
    );
  }
}

class _Photos extends ConsumerWidget {
  const _Photos({required this.paths, this.startIndex = 0});
  final List<String> paths;
  final int startIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (final (i, path) in paths.indexed)
          Pressable(
            key: ValueKey('open-photo-${startIndex + i}'),
            onTap: () => openAttachment(context, ref, path),
            pressedScale: 0.98,
            semanticLabel: context.l10n.openPhotoA11y(i + 1),
            child: PhotoThumb(path: path),
          ),
      ],
    );
  }
}
