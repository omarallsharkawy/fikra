import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/ai/ai_service.dart';
import '../data/ai/demo_ai_service.dart';
import '../data/local/database.dart';
import '../data/repositories.dart';

/// `--dart-define=FIKRA_MODE=connected` switches to the backend once it exists.
const appMode = String.fromEnvironment('FIKRA_MODE', defaultValue: 'demo');
bool get isDemo => appMode != 'connected';

final databaseProvider = Provider<FikraDatabase>((ref) {
  final db = FikraDatabase();
  ref.onDispose(db.close);
  return db;
});

final projectsRepoProvider = Provider<ProjectsRepository>(
  (ref) => LocalProjectsRepository(ref.watch(databaseProvider)),
);
final notesRepoProvider = Provider<NotesRepository>((ref) => LocalNotesRepository(ref.watch(databaseProvider)));
final chatRepoProvider = Provider<ChatRepository>((ref) => LocalChatRepository(ref.watch(databaseProvider)));

// The connected build will swap these two for API-backed implementations.
final aiServiceProvider = Provider<AiService>((ref) => DemoAiService());
final uploaderProvider = Provider<AttachmentUploader>((ref) => DemoUploader());

final projectsProvider = StreamProvider<List<ProjectSummary>>((ref) => ref.watch(projectsRepoProvider).watchProjects());
final currentProjectIdProvider = StreamProvider<String?>((ref) => ref.watch(projectsRepoProvider).watchCurrentId());

/// The selected project, falling back to the first one.
final currentProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsProvider).value ?? const [];
  if (projects.isEmpty) return null;
  final id = ref.watch(currentProjectIdProvider).value;
  for (final p in projects) {
    if (p.project.id == id) return p.project;
  }
  return projects.first.project;
});

final notesProvider = StreamProvider<List<Note>>((ref) {
  final project = ref.watch(currentProjectProvider);
  if (project == null) return Stream.value(const []);
  return ref.watch(notesRepoProvider).watchNotes(project.id);
});

final noteProvider = StreamProvider.autoDispose.family<Note?, String>(
  (ref, id) => ref.watch(notesRepoProvider).watchNote(id),
);

final linksProvider = StreamProvider<List<NoteLink>>((ref) {
  final project = ref.watch(currentProjectProvider);
  if (project == null) return Stream.value(const []);
  return ref.watch(notesRepoProvider).watchLinks(project.id);
});

final chatProvider = StreamProvider<List<ChatEntry>>((ref) {
  final project = ref.watch(currentProjectProvider);
  if (project == null) return Stream.value(const []);
  return ref.watch(chatRepoProvider).watch(project.id);
});

/// On launch: re-run notes whose processing was cut off (app killed), and
/// remove attachment files no note points to any more.
final startupMaintenanceProvider = FutureProvider<void>((ref) async {
  final notes = ref.read(notesRepoProvider);
  final processor = ref.read(noteProcessorProvider);
  for (final n in await notes.notesWithStatus(ProcessingStatus.processing)) {
    unawaited(processor.process(n));
  }
  await sweepOrphanAttachments(notes);
});

Future<void> sweepOrphanAttachments(NotesRepository notes) async {
  final cutoff = DateTime.now().subtract(const Duration(hours: 1)); // never touch an in-flight save
  try {
    final referenced = await notes.attachmentPaths();
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'attachments'));
    if (await dir.exists()) {
      await for (final f in dir.list()) {
        if (f is File && !referenced.contains(f.path) && (await f.lastModified()).isBefore(cutoff)) {
          await deleteFilesQuietly([f.path]);
        }
      }
    }
    final tmp = await getTemporaryDirectory();
    await for (final f in tmp.list()) {
      if (f is File && p.basename(f.path).startsWith('rec_') && (await f.lastModified()).isBefore(cutoff)) {
        await deleteFilesQuietly([f.path]);
      }
    }
  } catch (_) {
    // Best effort; retried on next launch.
  }
}

final noteProcessorProvider = Provider<NoteProcessor>(
  (ref) => NoteProcessor(ref.watch(notesRepoProvider), ref.watch(aiServiceProvider)),
);

/// Runs the AI pass after a note is saved. The note is already stored, so a
/// failure here never loses what the user wrote. Jobs run one at a time so
/// each analysis sees the concepts of the notes processed before it.
class NoteProcessor {
  NoteProcessor(this.notes, this.ai, {this.timeout = const Duration(seconds: 90)});
  final NotesRepository notes;
  final AiService ai;
  final Duration timeout;
  Future<void> _queue = Future.value();

  Future<void> process(Note note) {
    final job = _queue.then((_) => _run(note.id));
    _queue = job.catchError((_) {});
    return job;
  }

  Future<void> _run(String id) async {
    final basis = await notes.watchNote(id).first;
    if (basis == null) return;
    try {
      await notes.markProcessing(id);
      final projectNotes = await notes.notesOf(basis.projectId);
      final insights = await ai.analyze(basis, projectNotes).timeout(timeout);
      await notes.applyInsights(id, insights, basis: basis);
    } catch (_) {
      await notes.markFailed(id);
    }
  }

  Future<void> retry(String id) async {
    final note = await notes.watchNote(id).first;
    if (note != null) await process(note);
  }
}
