part of 'note_details_screen.dart';

/// Options for one of your links: edit its reason, or remove it. Removing asks
/// first, because the analysis won't suggest that pair again. [remove] starts
/// with the options sheet's own (live) context and needs nothing from [context],
/// which may be gone by the time the confirmation ends. The sheet's content is
/// built from its own context for the same reason: it can rebuild after the
/// page under it is disposed.
Future<void> _showLinkOptions(
  BuildContext context,
  NoteLinkEntry entry, {
  required Future<void> Function(BuildContext sheet) remove,
}) {
  final l10n = context.l10n;
  var handled = false; // one choice per sheet, even on a double tap
  return showFikraSheet<void>(
    context,
    title: l10n.linkOptionsTitle,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          noteTitle(sheet, entry.other),
          style: sheet.text.body.copyWith(color: sheet.colors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        SheetOption(
          label: l10n.editLinkReason,
          icon: Icons.edit_outlined,
          onTap: () {
            if (handled) return;
            handled = true;
            Navigator.pop(sheet);
            // Opened from the page once this sheet is closing, not on top of it.
            if (!context.mounted) return;
            showFikraSheet<void>(
              context,
              title: l10n.editLinkReason,
              builder: (_) => _LinkReasonSheet(link: entry.link),
            );
          },
        ),
        SheetOption(
          label: l10n.removeLink,
          icon: Icons.link_off_rounded,
          danger: true,
          onTap: () async {
            if (handled) return;
            handled = true;
            final ok = await confirmDestructive(
              sheet,
              title: l10n.removeLinkTitle,
              message: l10n.removeLinkBody,
              confirmLabel: l10n.removeLinkConfirm,
            );
            if (!sheet.mounted) return;
            if (!ok) {
              handled = false;
              return;
            }
            final done = remove(sheet);
            Navigator.pop(sheet);
            await done;
          },
        ),
      ],
    ),
  );
}

/// Edits the reason of one of your links. An empty reason removes it. A link
/// removed meanwhile just closes the sheet (`updateLabel` is a no-op then).
class _LinkReasonSheet extends ConsumerStatefulWidget {
  const _LinkReasonSheet({required this.link});
  final NoteLink link;

  @override
  ConsumerState<_LinkReasonSheet> createState() => _LinkReasonSheetState();
}

class _LinkReasonSheetState extends ConsumerState<_LinkReasonSheet> {
  late final _reason = TextEditingController(text: widget.link.label);
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final route = ModalRoute.of(context);
    try {
      await ref.read(linksRepoProvider).updateLabel(widget.link.id, _reason.text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    // Dismissed while saving: the sheet is already closing, and popping now
    // would close the page under it.
    if (mounted && (route?.isCurrent ?? false)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinkReasonField(controller: _reason, autofocus: true, onSubmitted: (_) => _save()),
        if (_failed) ...[
          const SizedBox(height: 8),
          StatusBanner(kind: BannerKind.error, message: context.l10n.linkUpdateFailed),
        ],
        const SizedBox(height: 16),
        FikraButton(
          key: const ValueKey('link-reason-save'),
          label: context.l10n.save,
          loading: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}
