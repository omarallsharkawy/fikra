import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../data/attachment_draft.dart';

import '../../data/local/database.dart';

/// Icon for where a note came from. Shared by the list card and details.
IconData sourceIcon(NoteSource s) => switch (s) {
  NoteSource.text => Icons.notes_rounded,
  NoteSource.voice => Icons.mic_none_rounded,
  NoteSource.pdf => Icons.picture_as_pdf_outlined,
};

/// Every source of a note: a PDF with a voice memo shows both icons.
List<({IconData icon, int count})> attachmentIcons(Note n, List<NoteAttachment> attachments) {
  final counts = <AttachmentKind, int>{};
  for (final a in attachments) {
    counts.update(a.kind, (v) => v + 1, ifAbsent: () => 1);
  }
  return counts.isEmpty
      ? [(icon: sourceIcon(n.source), count: 1)]
      : [
          for (final kind in AttachmentKind.values)
            if (counts.containsKey(kind))
              (
                icon: switch (kind) {
                  AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
                  AttachmentKind.voice => Icons.mic_none_rounded,
                  AttachmentKind.image => Icons.image_outlined,
                },
                count: counts[kind]!,
              ),
        ];
}

List<IconData> sourceIcons(Note n, [List<NoteAttachment> attachments = const []]) =>
    attachmentIcons(n, attachments).map((a) => a.icon).toList();

/// Title shown when a note has none yet (the AI suggests one after analysis).
String noteTitle(BuildContext context, Note n) => noteTitleText(context, n.title);

/// Shared by full notes and the graph's lightweight projection.
String noteTitleText(BuildContext context, String title) => title.trim().isEmpty ? context.l10n.untitledNote : title;

/// The original file-only title rules; attachment counts live on the card.
String attachmentTitle(AppLocalizations l10n, AttachmentDraft attachment) => switch (attachment.kind) {
  AttachmentKind.voice => l10n.voiceRecording,
  AttachmentKind.pdf => p.basenameWithoutExtension(attachment.name ?? attachment.path),
  AttachmentKind.image => l10n.photosTitle,
};
