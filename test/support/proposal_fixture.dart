import 'package:fikra/app/providers.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// The actual details screen, isolated from the covered tab shell when checking
/// very large text. Provider values contain the same pending proposal as a saved note.
Future<void> pumpProposalDetails(
  WidgetTester tester, {
  required Locale locale,
  double scale = 1,
  double width = 390,
  double pixelRatio = 1,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.physicalSize = Size(width * pixelRatio, 844 * pixelRatio);
  final note = Note(
    id: 'proposal',
    projectId: 'project',
    title: 'title',
    originalText: 'body',
    proposedText: 'proposal',
    source: NoteSource.text,
    status: ProcessingStatus.ready,
    rewrite: RewriteStatus.pending,
    imagePaths: '',
    concepts: '',
    createdAt: DateTime(2026, 11, 10),
    updatedAt: DateTime(2026, 11, 10),
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: appBoundaryKey,
      child: ProviderScope(
        key: const ValueKey('proposal-fixture'),
        overrides: [
          noteProvider(note.id).overrideWith((ref) => Stream.value(note)),
          noteAttachmentsProvider(note.id).overrideWith((ref) => Stream.value([])),
          linksOfProjectProvider(note.projectId).overrideWith((ref) => Stream.value([])),
          notesOfProjectProvider(note.projectId).overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: locale,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFikraTheme(brightness),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: NoteDetailsScreen(noteId: note.id),
            ),
          ),
        ),
      ),
    ),
  );
  final l10n = lookupAppLocalizations(locale);
  await pumpUntil(tester, find.text(l10n.keepOriginal));
  await tester.pumpAndSettle();
}
