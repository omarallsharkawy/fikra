part of 'note_details_screen.dart';

/// "Links": every note linked to [note] in either direction, one row per other
/// note, with the button that opens the picker. Your links have an options
/// control; suggestions from the analysis have accept and reject.
class _NoteLinks extends ConsumerStatefulWidget {
  const _NoteLinks({required this.note});
  final Note note;

  @override
  ConsumerState<_NoteLinks> createState() => _NoteLinksState();
}

class _NoteLinksState extends ConsumerState<_NoteLinks> {
  /// Note pairs with an accept, reject or remove in flight; their actions are
  /// off. Keyed by pair, not row id: a re-analysis replaces suggestion ids.
  final _busy = <String>{};

  /// True from a tap that opens a page or sheet until it closes, so a second
  /// tap (even in the same frame, before the route is pushed) does nothing.
  bool _away = false;

  String _pair(Note other) => _pairKey(widget.note.id, other.id);

  /// Runs [action] with [from] as a live context for its toasts, which is
  /// read before the first await. Safe after this state is disposed (an
  /// options sheet can outlive the page): it only touches [_busy] then.
  Future<void> _run(BuildContext from, String pair, Future<void> Function() action, {String? success}) async {
    if (!_busy.add(pair)) return;
    if (mounted) setState(() {});
    await runAction(from, action, success: success, failure: from.l10n.linkUpdateFailed);
    _busy.remove(pair);
    if (mounted) setState(() {});
  }

  Future<void> _leave(Future<void> Function() open) async {
    if (_away || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _away = true;
    try {
      await open();
    } finally {
      _away = false;
    }
  }

  /// Accept or reject, with the shared toast and Undo. The pair's actions are
  /// off until it is done.
  Future<void> _change(NoteLinkEntry entry, {required bool accept}) async {
    final pair = _pair(entry.other);
    if (!_busy.add(pair)) return;
    setState(() {});
    await changeSuggestedPair(
      context,
      a: entry.link.sourceId,
      b: entry.link.targetId,
      accept: accept,
      expectedProjectId: entry.link.projectId,
    );
    _busy.remove(pair);
    if (mounted) setState(() {});
  }

  void _open(Note other) => _leave(() => context.push('/note/${other.id}', extra: other));

  void _link() => _leave(() => showLinkPicker(context, source: widget.note));

  void _options(NoteLinkEntry entry) {
    final pair = _pair(entry.other);
    if (_busy.contains(pair)) return;
    // Captured now: the confirmation can end after this page is gone.
    final repo = _linksRepo;
    final linkId = entry.link.id;
    _leave(
      () => showLinkOptions(
        context,
        entry,
        remove: (sheet) => _run(sheet, pair, () => repo.removeLink(linkId), success: sheet.l10n.linkRemoved),
      ),
    );
  }

  LinksRepository get _linksRepo => ref.read(linksRepoProvider);

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final linksAsync = ref.watch(linksOfProjectProvider(note.projectId));
    final notesAsync = ref.watch(notesOfProjectProvider(note.projectId));

    final Widget content;
    if ((linksAsync.hasError && !linksAsync.hasValue) || (notesAsync.hasError && !notesAsync.hasValue)) {
      content = SmartText(
        context.l10n.noteLinksLoadFailed,
        content: ReadOnlyContent.chrome,
        key: const ValueKey('links-failed'),
        style: context.text.caption,
      );
    } else if (!linksAsync.hasValue || !notesAsync.hasValue) {
      content = const SizedBox(key: ValueKey('links-loading'), height: 48);
    } else {
      final byId = {for (final n in notesAsync.requireValue) n.id: n};
      final entries = linksOfNote(note.id, linksAsync.requireValue, byId);
      content = entries.isEmpty
          ? SmartText(
              context.l10n.noteLinksEmpty,
              content: ReadOnlyContent.chrome,
              key: const ValueKey('links-empty'),
              style: context.text.caption,
            )
          : Column(
              key: const ValueKey('links-list'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in entries)
                  _LinkRow(
                    key: ValueKey('note-link-${entry.other.id}'),
                    entry: entry,
                    busy: _busy.contains(_pair(entry.other)),
                    onOpen: () => _open(entry.other),
                    onOptions: () => _options(entry),
                    onAccept: () => _change(entry, accept: true),
                    onReject: () => _change(entry, accept: false),
                  ),
              ],
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: SmartText(
            context.l10n.noteLinksHeader,
            content: ReadOnlyContent.chrome,
            style: context.text.section.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        FikraButton.secondary(
          key: const ValueKey('link-to-note'),
          label: context.l10n.linkToNote,
          icon: Icons.add_link_rounded,
          onPressed: _link,
        ),
        const SizedBox(height: 12),
        FikraSwitcher(animateSize: true, child: content),
      ],
    );
  }
}

/// One key per unordered note pair.
String _pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
