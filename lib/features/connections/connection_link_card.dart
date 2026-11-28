import 'package:flutter/material.dart';

import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/note_links.dart';
import '../shared/note_presentation.dart';
import 'library_cards.dart';
import 'links_library_provider.dart';

/// Connections need a body preview and an explicit empty-reason state; the
/// existing note-details row intentionally retains its more compact layout.
class ConnectionLinkCard extends StatelessWidget {
  const ConnectionLinkCard({super.key, required this.entry, required this.onOptions});
  final NoteLinkEntry entry;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SolidSurface(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Pressable(
              onTap: () => openConnections(context, entry.other.id, initial: projectNote(entry.other)),
              onLongPress: onOptions,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LibraryNoteText(note: projectNote(entry.other)),
                    const SizedBox(height: 8),
                    SmartText(
                      entry.link.label.trim().isEmpty ? context.l10n.linkNoReason : entry.link.label,
                      style: context.text.meta.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FikraIconButton(
            key: ValueKey('connection-options-${entry.other.id}'),
            icon: Icons.more_horiz_rounded,
            label: context.l10n.linkOptionsA11y(noteTitle(context, entry.other)),
            onTap: onOptions,
          ),
        ],
      ),
    ),
  );
}
