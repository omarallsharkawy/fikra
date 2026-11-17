import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/note_link_actions.dart';
import '../shared/note_presentation.dart';
import 'library_cards.dart';
import 'link_pair_busy.dart';
import 'links_index.dart';

/// Busy state belongs to the unordered pair, even if analysis replaces its id.
class SuggestionCard extends ConsumerStatefulWidget {
  const SuggestionCard({super.key, required this.entry, this.here});
  final SuggestionEntry entry;

  /// The note whose connections page shows this card. Its own row is not a
  /// link to the page that is already open.
  final String? here;

  @override
  ConsumerState<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<SuggestionCard> {
  String get _pair => '${widget.entry.a.projectId}:${pairKey(widget.entry.a.id, widget.entry.b.id)}';

  Future<void> _act(bool accept) async {
    final pair = _pair;
    final guard = ref.read(linkPairBusyProvider.notifier);
    if (!guard.claim(pair, project: widget.entry.a.projectId, pair: pairKey(widget.entry.a.id, widget.entry.b.id))) {
      return;
    }
    final e = widget.entry;
    var ok = false;
    try {
      // False when nothing changed (or another accept/reject or Undo runs):
      // unlock at once rather than wait for a snapshot that may never come.
      ok = await changeSuggestedPair(context, a: e.a.id, b: e.b.id, accept: accept);
    } finally {
      guard.finish(pair, success: ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry, l10n = context.l10n;
    final busy = ref.watch(linkPairBusyProvider.select((pairs) => pairs.containsKey(_pair)));
    final pair =
        '${Fmt.isolate(noteTitleText(context, e.a.title))} · ${Fmt.isolate(noteTitleText(context, e.b.title))}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SolidSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final n in [e.a, e.b])
              Pressable(
                key: ValueKey('suggestion-note-${e.link.id}-${n.id}'),
                onTap: n.id == widget.here ? null : () => openConnections(context, n.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LibraryNoteText(note: n),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_outlined, size: 16, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.link.reason.trim().isEmpty ? l10n.linkNoReason : e.link.reason,
                    style: context.text.meta.copyWith(color: context.colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final accept in [true, false])
                  Semantics(
                    label: accept ? l10n.acceptLinkA11y(pair) : l10n.rejectLinkA11y(pair),
                    button: true,
                    enabled: !busy,
                    onTap: busy ? null : () => _act(accept),
                    excludeSemantics: true,
                    child: TextButton.icon(
                      key: ValueKey('${accept ? 'accept' : 'reject'}-${pairKey(e.a.id, e.b.id)}'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.textPrimary,
                        backgroundColor: context.colors.chip,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: busy ? null : () => _act(accept),
                      icon: Icon(accept ? Icons.check_rounded : Icons.close_rounded, size: 18),
                      label: Text(accept ? l10n.acceptLink : l10n.rejectLink),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
