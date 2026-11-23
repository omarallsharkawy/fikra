import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../ai/demo_ai_service.dart';
import '../local/database.dart';
import '../repositories.dart';

/// "جرّب مشروع تجريبي": a ready project so the demo has something to show.
Future<Project> seedDemoProject(
  ProjectsRepository projects,
  NotesRepository notes, {
  Locale locale = const Locale('ar'),
  DateTime Function()? clock,
}) async {
  final l10n = lookupAppLocalizations(locale);
  final project = await projects.create(l10n.sampleProjectName);
  final ai = DemoAiService(latency: Duration.zero, locale: locale);

  final samples = <(String, String)>[
    (l10n.sample1Title, l10n.sample1Body),
    (l10n.sample2Title, l10n.sample2Body),
    (l10n.sample3Title, l10n.sample3Body),
    (l10n.sample4Title, l10n.sample4Body),
    (l10n.sample5Title, l10n.sample5Body),
    (l10n.sample6Title, l10n.sample6Body),
    (l10n.sample7Title, l10n.sample7Body),
  ];

  final base = (clock ?? DateTime.now)().subtract(const Duration(days: 2));
  var i = 0;
  for (final (title, text) in samples) {
    // Spread the samples over the last two days so the list shows day groups.
    final note = await notes.create(
      projectId: project.id,
      title: title,
      text: text,
      source: NoteSource.text,
      createdAt: base.add(Duration(hours: i * 7)),
    );
    final insights = await ai.analyze(note, await notes.notesOf(project.id));
    await notes.applyInsights(note.id, insights);
    i++;
  }
  return project;
}
