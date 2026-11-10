// Dependency wiring. Implementations live in lib/data; this file only decides
// which ones the app uses. Tests override [databaseProvider] (in-memory db) or
// [aiServiceProvider] (fakes).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/ai/ai_service.dart';
import '../data/ai/demo_ai_service.dart';
import '../data/files/attachment_store.dart';
import '../data/files/file_opener.dart';
import '../data/local/database.dart';
import '../data/links_repository.dart';
import '../data/groups_repository.dart';
import '../data/processing/note_processor.dart';
import '../data/repositories.dart';
import '../data/settings_repository.dart';
import 'app_config.dart';

export 'app_config.dart' show isDemo;
export '../data/settings_repository.dart' show AppTheme, AppLanguage, WipeFilesException;

// ---------------------------------------------------------------- services

final databaseProvider = Provider<FikraDatabase>((ref) {
  final db = FikraDatabase();
  ref.onDispose(db.close);
  return db;
});

final projectsRepoProvider = Provider<ProjectsRepository>(
  (ref) => LocalProjectsRepository(ref.watch(databaseProvider)),
);
final notesRepoProvider = Provider<NotesRepository>((ref) => LocalNotesRepository(ref.watch(databaseProvider)));
final linksRepoProvider = Provider<LinksRepository>((ref) => LocalLinksRepository(ref.watch(databaseProvider)));
final groupsRepoProvider = Provider<GroupsRepository>((ref) => LocalGroupsRepository(ref.watch(databaseProvider)));
final chatRepoProvider = Provider<ChatRepository>((ref) => LocalChatRepository(ref.watch(databaseProvider)));
final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(ref.watch(databaseProvider), ref.watch(attachmentStoreProvider)),
);

/// Saved appearance; `system` until the user picks one (and while loading).
final appThemeProvider = StreamProvider<AppTheme>((ref) => ref.watch(settingsRepoProvider).watchTheme());

/// Language preference uses the same persisted stream as appearance.
final appLanguageProvider = StreamProvider<AppLanguage>((ref) => ref.watch(settingsRepoProvider).watchLanguage());

class _DeviceLocale extends Notifier<Locale> with WidgetsBindingObserver {
  @override
  Locale build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    state = locales?.firstOrNull ?? const Locale('ar');
  }
}

final deviceLocaleProvider = NotifierProvider<_DeviceLocale, Locale>(_DeviceLocale.new);

/// Every device language except English resolves to Arabic.
final appLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(appLanguageProvider).value ?? AppLanguage.system;
  final device = ref.watch(deviceLocaleProvider);
  return Locale(switch (language) {
    AppLanguage.ar => 'ar',
    AppLanguage.en => 'en',
    AppLanguage.system => device.languageCode == 'en' ? 'en' : 'ar',
  });
});

/// Injectable clock for sample timestamps and date grouping in screenshot tests.
final appClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final attachmentStoreProvider = Provider<AttachmentStore>((ref) => AttachmentStore());

/// Backend seam: note analysis and question answering.
final aiServiceProvider = Provider<AiService>(
  (ref) => switch (appMode) {
    AppMode.demo => DemoAiService(activeLocale: () => ref.read(appLocaleProvider)),
    // Wire ApiAiService here (docs/backend-integration.md).
    AppMode.connected => throw UnimplementedError('FIKRA_MODE=connected has no AiService yet'),
  },
);

/// Opens an attachment in another app on the phone.
final fileOpenerProvider = Provider<FileOpener>((ref) => openWithSystem);

final noteProcessorProvider = Provider<NoteProcessor>(
  (ref) => NoteProcessor(ref.watch(notesRepoProvider), ref.watch(aiServiceProvider)),
);

/// Runs once at launch (watched by FikraApp).
final startupMaintenanceProvider = FutureProvider<void>((ref) async {
  await ref.read(appLanguageProvider.future);
  await ref.read(noteProcessorProvider).resumeInterrupted();
  final notes = ref.read(notesRepoProvider);
  await ref.read(attachmentStoreProvider).sweepOrphans(await notes.attachmentPaths());
});

// ---------------------------------------------------------------- projects

final projectsProvider = StreamProvider<List<ProjectSummary>>((ref) => ref.watch(projectsRepoProvider).watchProjects());
final _selectedProjectIdProvider = StreamProvider<String?>((ref) => ref.watch(projectsRepoProvider).watchCurrentId());

/// The project picked in the header pill (falls back to the first one). Tab
/// screens read data through the `selected*` providers below.
final selectedProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsProvider).value ?? const [];
  if (projects.isEmpty) return null;
  final id = ref.watch(_selectedProjectIdProvider).value;
  for (final p in projects) {
    if (p.project.id == id) return p.project;
  }
  return projects.first.project;
});

// ---------------------------------------------------------------- per project
// Use these with an explicit project id (e.g. a note's own `projectId`).

final notesOfProjectProvider = StreamProvider.autoDispose.family<List<Note>, String>(
  (ref, projectId) => ref.watch(notesRepoProvider).watchNotes(projectId),
);
final linksOfProjectProvider = StreamProvider.autoDispose.family<List<NoteLink>, String>(
  (ref, projectId) => ref.watch(notesRepoProvider).watchLinks(projectId),
);
final chatOfProjectProvider = StreamProvider.autoDispose.family<List<ChatEntry>, String>(
  (ref, projectId) => ref.watch(chatRepoProvider).watch(projectId),
);
final noteProvider = StreamProvider.autoDispose.family<Note?, String>(
  (ref, id) => ref.watch(notesRepoProvider).watchNote(id),
);

// ---------------------------------------------------------------- selected project

AsyncValue<T> _forSelected<T>(Ref ref, T empty, AsyncValue<T> Function(String id) watch) {
  final project = ref.watch(selectedProjectProvider);
  return project == null ? AsyncData(empty) : watch(project.id);
}

final selectedNotesProvider = Provider.autoDispose<AsyncValue<List<Note>>>(
  (ref) => _forSelected(ref, const <Note>[], (id) => ref.watch(notesOfProjectProvider(id))),
);
final selectedLinksProvider = Provider.autoDispose<AsyncValue<List<NoteLink>>>(
  (ref) => _forSelected(ref, const <NoteLink>[], (id) => ref.watch(linksOfProjectProvider(id))),
);
final selectedChatProvider = Provider.autoDispose<AsyncValue<List<ChatEntry>>>(
  (ref) => _forSelected(ref, const <ChatEntry>[], (id) => ref.watch(chatOfProjectProvider(id))),
);

/// One indexed stream for the note page and editor.
final noteAttachmentsProvider = StreamProvider.autoDispose.family<List<NoteAttachment>, String>(
  (ref, id) => ref.watch(notesRepoProvider).watchAttachments(id),
);

/// One joined query per project, shared by every visible card (no per-card query).
final projectAttachmentsProvider = StreamProvider.autoDispose.family<Map<String, List<NoteAttachment>>, String>(
  (ref, id) => ref.watch(notesRepoProvider).watchProjectAttachments(id),
);

final audioRecorderFactoryProvider = Provider<AudioRecorder Function()>((ref) => AudioRecorder.new);
final microphonePermissionProvider = Provider<Future<PermissionStatus> Function()>(
  (ref) =>
      () => Permission.microphone.request(),
);

class RecordingActivity extends Notifier<bool> {
  Object? _owner;
  @override
  bool build() => false;
  bool claim(Object owner) {
    if (_owner != null) return false;
    _owner = owner;
    state = true;
    return true;
  }

  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    if (ref.mounted) state = false;
  }
}

final recordingActiveProvider = NotifierProvider<RecordingActivity, bool>(RecordingActivity.new);
