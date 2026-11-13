part of 'note_details_screen.dart';

/// One link. Your link: solid glass card, link icon, options control.
/// Suggestion: no fill, dashed outline, sparkle icon, "Suggested" tag, and
/// inline accept / reject. The shape cues and the tag carry the difference, so
/// it never relies on colour alone. Tapping the text opens the other note.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    super.key,
    required this.entry,
    required this.busy,
    required this.onOpen,
    required this.onOptions,
    required this.onAccept,
    required this.onReject,
  });
  final NoteLinkEntry entry;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onOptions;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestion = entry.link.origin != LinkOrigin.user;
    final title = noteTitle(context, entry.other);
    final reason = entry.link.label.trim();
    final name = suggestion ? l10n.suggestedLinkA11y(title) : title;
    final id = entry.other.id;

    final open = Pressable(
      key: ValueKey('open-link-$id'),
      onTap: onOpen,
      pressedScale: 0.98,
      semanticLabel: reason.isEmpty ? name : l10n.linkRowA11y(name, reason),
      child: ConstrainedBox(
        // A suggestion without a reason would otherwise be a 42 dp target.
        constraints: const BoxConstraints(minHeight: Pressable.minTargetSize),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14, 12, suggestion ? 14 : 4, suggestion ? 6 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  suggestion ? Icons.auto_awesome_outlined : Icons.link_rounded,
                  size: 18,
                  color: suggestion ? context.colors.textMeta : context.colors.accentLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.body.copyWith(fontWeight: FontWeight.w600)),
                    if (reason.isNotEmpty)
                      Text(reason, style: context.text.meta.copyWith(color: context.colors.textLink)),
                  ],
                ),
              ),
              if (suggestion) ...[
                const SizedBox(width: 8),
                const Padding(padding: EdgeInsets.only(top: 2), child: LinkSuggestedTag()),
              ],
            ],
          ),
        ),
      ),
    );

    if (!suggestion) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Glass(
          radius: FikraRadius.md,
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: open),
              Pressable(
                key: ValueKey('link-options-$id'),
                onTap: busy ? null : onOptions,
                minTarget: true,
                semanticLabel: l10n.linkOptionsA11y(title),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.more_horiz_rounded, color: context.colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomPaint(
        foregroundPainter: _DashedOutline(color: context.colors.borderGraph, radius: FikraRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            open,
            Padding(
              // Lines the actions up under the title (icon 18 + gap 10).
              padding: const EdgeInsetsDirectional.fromSTEB(14 + 18 + 10 - 6, 0, 8, 4),
              child: Wrap(
                spacing: 4,
                children: [
                  _InlineAction(
                    key: ValueKey('link-accept-$id'),
                    icon: Icons.check_rounded,
                    label: l10n.acceptLink,
                    semanticLabel: l10n.acceptLinkA11y(title),
                    primary: true,
                    onTap: busy ? null : onAccept,
                  ),
                  _InlineAction(
                    key: ValueKey('link-reject-$id'),
                    icon: Icons.close_rounded,
                    label: l10n.rejectLink,
                    semanticLabel: l10n.rejectLinkA11y(title),
                    onTap: busy ? null : onReject,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill with a 48 dp target: accept (primary) or reject (secondary).
class _InlineAction extends StatelessWidget {
  const _InlineAction({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? context.colors.textOnLight : context.colors.textPrimary;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Pressable(
        onTap: onTap,
        minTarget: true,
        semanticLabel: semanticLabel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: primary ? context.colors.primaryGradient : context.colors.glassGradient,
              borderRadius: BorderRadius.circular(FikraRadius.full),
              border: primary ? null : Border.all(color: context.colors.border, width: FikraSpace.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Text(label, style: context.text.chip.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded outline for suggestion rows (your links have a solid card).
class _DashedOutline extends CustomPainter {
  const _DashedOutline({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)));
    const dash = 5.0, gap = 4.0;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => old.color != color || old.radius != radius;
}
