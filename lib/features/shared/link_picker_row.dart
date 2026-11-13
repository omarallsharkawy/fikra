part of 'link_picker.dart';

/// One candidate note. The check icon changes shape when picked, so the state
/// never relies on colour; an already-linked note is dimmed and says so.
class _PickRow extends StatelessWidget {
  const _PickRow({super.key, required this.note, required this.origin, required this.picked, required this.onTap});
  final Note note;
  final LinkOrigin? origin;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final linked = origin == LinkOrigin.user;
    final title = noteTitle(context, note);
    final detail = linked
        ? context.l10n.alreadyLinked
        : origin == LinkOrigin.ai
        ? context.l10n.linkSuggestedTag
        : null;
    final snippet = note.displayText.trim().split('\n').first;
    final (IconData icon, Color iconColor) = linked
        ? (Icons.link_rounded, context.colors.textMeta)
        : picked
        ? (Icons.check_circle_rounded, context.colors.accentLight)
        : (Icons.radio_button_unchecked_rounded, context.colors.textMeta);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        checked: linked ? null : picked,
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.98,
          semanticLabel: detail == null ? title : context.l10n.linkRowA11y(title, detail),
          child: Opacity(
            opacity: linked ? 0.6 : 1,
            child: Glass(
              radius: FikraRadius.md,
              borderColor: picked ? context.colors.borderFocus : null,
              borderWidth: picked ? 1 : FikraSpace.hairline,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Pressable.minTargetSize - 20),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: context.text.body.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (snippet.isNotEmpty && snippet != title)
                            Text(
                              snippet,
                              style: context.text.meta.copyWith(color: context.colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (linked) ...[
                      const SizedBox(width: 8),
                      Text(context.l10n.alreadyLinked, style: context.text.meta),
                    ] else if (origin == LinkOrigin.ai) ...[
                      const SizedBox(width: 8),
                      const LinkSuggestedTag(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred message in place of the list (no notes, no results, load failure).
/// Scrolls instead of overflowing when the keyboard leaves little room.
class _PickerMessage extends StatelessWidget {
  const _PickerMessage({required this.text, this.title, this.icon});
  final String text;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 28, color: context.colors.textSecondary), const SizedBox(height: 8)],
            if (title != null) ...[
              Text(title!, style: context.text.cardTitleSmall, textAlign: TextAlign.center),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: context.text.body.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
