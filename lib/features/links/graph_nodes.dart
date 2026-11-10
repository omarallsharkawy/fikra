part of 'links_screen.dart';

Rect _rect(GraphPosition position) => Rect.fromLTWH(position.left, position.top, position.width, position.height);

String _graphTitle(BuildContext context, GraphNote note) => noteTitleText(context, note.title);

class _OverflowNode extends StatelessWidget {
  const _OverflowNode({required this.label, required this.onTap, this.semanticLabel, this.numbersOnly = false});

  final String label;
  final String? semanticLabel;
  final bool numbersOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: semanticLabel ?? label,
    child: Glass(
      radius: FikraRadius.sm,
      child: Center(
        child: Text(
          label,
          textDirection: numbersOnly ? TextDirection.ltr : Directionality.of(context),
          style: context.text.chip,
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
  const _Node({super.key, required this.note, required this.selected, required this.onTap});
  final GraphNote note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: _graphTitle(context, note),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          gradient: selected ? context.colors.selectedGradient : context.colors.glassGradient,
          color: selected ? null : context.colors.glass,
          borderRadius: BorderRadius.circular(FikraRadius.sm),
          border: Border.all(
            color: selected ? context.colors.accentLight : context.colors.borderGraph,
            width: selected ? 1.2 : FikraSpace.hairline,
          ),
        ),
        child: Text(
          _graphTitle(context, note),
          style: context.text.chip.copyWith(
            color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
