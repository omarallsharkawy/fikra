import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';

/// Icon for where a note came from. Shared by the list card and details.
IconData sourceIcon(NoteSource s) => switch (s) {
  NoteSource.text => Icons.notes_rounded,
  NoteSource.voice => Icons.mic_none_rounded,
  NoteSource.pdf => Icons.picture_as_pdf_outlined,
};

/// Every source of a note: a PDF with a voice memo shows both icons.
List<IconData> sourceIcons(Note n) => [
  if (n.hasPdf) Icons.picture_as_pdf_outlined,
  if (n.hasVoice) Icons.mic_none_rounded,
  if (n.hasImages) Icons.image_outlined,
  if (!n.hasPdf && !n.hasVoice && !n.hasImages) sourceIcon(n.source),
];

/// Title shown when a note has none yet (the AI suggests one after analysis).
String noteTitle(BuildContext context, Note n) => n.title.trim().isEmpty ? context.l10n.untitledNote : n.title;
