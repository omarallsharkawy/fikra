import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/link_label.dart';
import '../../data/local/database.dart';

/// Longest reason a link keeps, in characters (grapheme clusters), the same
/// unit the repository caps at.
const linkReasonMaxLength = linkLabelMaxLength;

/// One link as shown on a note's page: the note at the other end and the row
/// that links them.
typedef NoteLinkEntry = ({Note other, NoteLink link});

/// The links of [noteId], one per other note, whichever end the note is on.
///
/// Legacy data can hold two rows for one pair (A→B and B→A): the user's row
/// wins, otherwise the first suggestion. Dismissed rows and links to notes
/// missing from [notesById] are skipped. Your links come first (newest first),
/// then suggestions in stored order.
List<NoteLinkEntry> linksOfNote(String noteId, Iterable<NoteLink> links, Map<String, Note> notesById) {
  final chosen = <String, NoteLink>{};
  for (final l in links) {
    if (l.dismissed || (l.sourceId != noteId && l.targetId != noteId)) continue;
    final otherId = l.sourceId == noteId ? l.targetId : l.sourceId;
    if (otherId == noteId || !notesById.containsKey(otherId)) continue;
    final current = chosen[otherId];
    if (current == null || (current.origin != LinkOrigin.user && l.origin == LinkOrigin.user)) chosen[otherId] = l;
  }
  final entries = [for (final e in chosen.entries) (other: notesById[e.key]!, link: e.value)];
  final order = {for (final (i, e) in entries.indexed) e.link.id: i};
  int rank(NoteLinkEntry e) => e.link.origin == LinkOrigin.user ? 0 : 1;
  entries.sort((a, b) {
    final byOrigin = rank(a) - rank(b);
    if (byOrigin != 0) return byOrigin;
    if (rank(a) == 0) {
      final at = a.link.createdAt, bt = b.link.createdAt;
      if (at != null && bt != null && at != bt) return bt.compareTo(at);
      if ((at == null) != (bt == null)) return at == null ? 1 : -1;
    }
    return order[a.link.id]! - order[b.link.id]!;
  });
  return entries;
}

/// The small outlined "Suggested" tag, so a suggestion never relies on colour.
class LinkSuggestedTag extends StatelessWidget {
  const LinkSuggestedTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: context.colors.borderGraph, width: 1),
      ),
      child: Text(
        context.l10n.linkSuggestedTag,
        style: context.text.meta.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

/// Optional reason input with its visible `used/80` counter at the end.
class LinkReasonField extends StatelessWidget {
  const LinkReasonField({super.key, required this.controller, this.autofocus = false, this.onSubmitted});
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FikraField(
          key: const ValueKey('link-reason'),
          controller: controller,
          hint: context.l10n.linkReasonHint,
          icon: Icons.short_text_rounded,
          autofocus: autofocus,
          maxLength: linkReasonMaxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 20),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) => Text(
                '${value.text.characters.length}/$linkReasonMaxLength',
                key: const ValueKey('link-reason-count'),
                textDirection: TextDirection.ltr,
                style: context.text.meta,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
