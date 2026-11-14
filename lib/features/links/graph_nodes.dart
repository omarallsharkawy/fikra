part of 'links_screen.dart';

Rect _rect(GraphPosition position) => Rect.fromLTWH(position.left, position.top, position.width, position.height);

String _graphTitle(BuildContext context, GraphNote note) => noteTitleText(context, note.title);

// Opaque composited token colours: subdued controls remain readable without
// allocating a compositing layer per card. Contrast is tested in both themes.
Color _mutedGraphText(BuildContext context) =>
    Color.alphaBlend(context.colors.textMeta.withValues(alpha: context.colors.textMeta.a * 0.8), context.colors.screen);

class _OverflowNode extends StatelessWidget {
  const _OverflowNode({
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.numbersOnly = false,
    this.dimmed = false,
  });

  final String label;
  final String? semanticLabel;
  final bool numbersOnly;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: semanticLabel ?? label,
    child: Glass(
      radius: FikraRadius.sm,
      color: dimmed || onTap == null ? context.colors.screen : null,
      gradient: dimmed || onTap == null ? null : context.colors.glassGradient,
      child: Center(
        child: Text(
          label,
          textDirection: numbersOnly ? TextDirection.ltr : Directionality.of(context),
          style: context.text.chip.copyWith(
            color: dimmed || onTap == null ? _mutedGraphText(context) : context.colors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// Bottom card for the selected node: what it is and why it's connected.
class _NodePreview extends StatelessWidget {
  const _NodePreview({required this.note, required this.reasons, required this.onOpen});
  final GraphNote note;
  final List<String> reasons;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.xl,
      color: context.colors.glass,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _graphTitle(context, note),
            style: context.text.cardTitleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.nodeMeta(note.cluster ?? context.l10n.clusterGeneral, Fmt.links(context.l10n, reasons.length)),
            style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in reasons.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: context.colors.textLink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: context.text.caption.copyWith(color: context.colors.textLink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          FikraButton(label: context.l10n.openNote, icon: Icons.open_in_new_rounded, onPressed: onOpen),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    super.key,
    required this.note,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
    this.selecting = false,
    this.onHold,
    this.semanticLabel,
  });
  final GraphNote note;
  final bool selected;
  final bool selecting;
  final VoidCallback? onHold;
  final String? semanticLabel;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selecting ? selected : null,
      onLongPress: onHold,
      child: Pressable(
        onTap: onTap,
        selected: selected,
        // Long-press recognition is pointer-tracked by _GraphHold. Expose the
        // equivalent action to assistive technology without joining the arena.
        semanticLabel: semanticLabel ?? _graphTitle(context, note),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            gradient: selected
                ? context.colors.selectedGradient
                : dimmed
                ? null
                : context.colors.glassGradient,
            color: selected
                ? null
                : dimmed
                ? context.colors.screen
                : context.colors.glass,
            borderRadius: BorderRadius.circular(FikraRadius.sm),
            border: Border.all(
              color: selected
                  ? context.colors.accentLight
                  : dimmed
                  ? context.colors.border
                  : context.colors.borderGraph,
              width: selected ? 1.2 : FikraSpace.hairline,
            ),
          ),
          child: Row(
            children: [
              if (selecting) ...[
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  key: ValueKey('graph-check-${note.id}'),
                  size: 20,
                  color: selected ? context.colors.textOnSelected : context.colors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  _graphTitle(context, note),
                  style: context.text.chip.copyWith(
                    color: selected
                        ? context.colors.textOnSelected
                        : dimmed
                        ? _mutedGraphText(context)
                        : context.colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
