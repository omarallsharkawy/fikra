import 'package:flutter/material.dart';

import '../../data/local/database.dart';

/// Icon for where a note came from. Shared by the list card and details.
IconData sourceIcon(NoteSource s) => switch (s) {
  NoteSource.text => Icons.notes_rounded,
  NoteSource.voice => Icons.mic_none_rounded,
  NoteSource.pdf => Icons.picture_as_pdf_outlined,
};

/// Title shown when a note has none yet (the AI suggests one after analysis).
String noteTitle(Note n) => n.title.trim().isEmpty ? 'نوت جديدة' : n.title;
