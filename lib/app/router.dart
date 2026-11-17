import '../features/note_details/transcript_editor_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/container_transform.dart';
import '../core/theme/tokens.dart';
import '../data/local/database.dart';
import '../features/add/add_screen.dart';
import '../features/ask/ask_screen.dart';
import '../features/links/links_screen.dart';
import '../features/connections/links_library_screen.dart';
import '../features/connections/note_connections_screen.dart';
import '../features/note_details/edit_note_screen.dart';
import '../features/note_details/note_details_screen.dart';
import '../features/note_details/pdf_viewer_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/projects/welcome_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/voice_text/voice_text_screen.dart';
import '../features/voice_text/service_form_screen.dart';
import 'providers.dart';
import 'shell.dart';
import 'storage_error_screen.dart';

/// A screen pushed on top of another one, with the app's push transition
/// (FikraPageTransitionsBuilder) and predictive back.
///
/// Built explicitly because go_router 18 only recognises `MaterialApp` from
/// `package:material_ui`. With Flutter's own `MaterialApp` it falls back to
/// `NoTransitionPage` for `builder:` routes, and every push jumps in one frame.
/// Routes that replace each other (splash, welcome, the shell) keep that.
Page<void> _pushed(GoRouterState state, Widget child, {CardOrigin? origin}) {
  final args = <String, String>{...state.pathParameters, ...state.uri.queryParameters};
  if (origin != null) {
    return ContainerTransformPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      arguments: args,
      restorationId: state.pageKey.value,
      origin: origin,
      child: child,
    );
  }
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: args,
    restorationId: state.pageKey.value,
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever the project list changes (first project created,
  // last project deleted).
  final refresh = ValueNotifier<int>(0);
  ref.listen(projectsProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final projects = ref.read(projectsProvider);
      final loc = state.matchedLocation;
      if (projects.hasError && !projects.hasValue) return loc == '/storage-error' ? null : '/storage-error';
      if (!projects.hasValue) return loc == '/splash' ? null : '/splash';
      final empty = projects.requireValue.isEmpty;
      if (empty) return loc == '/welcome' ? null : '/welcome';
      if (loc == '/welcome' || loc == '/splash' || loc == '/storage-error') return '/notes';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, _) => ColoredBox(color: context.colors.canvas),
      ),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/storage-error', builder: (_, _) => const StorageErrorScreen()),
      StatefulShellRoute(
        navigatorContainerBuilder: (context, shell, children) =>
            FikraBranchContainer(index: shell.currentIndex, children: children),
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/add', builder: (_, _) => const AddScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/notes', builder: (_, _) => const NotesScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/links',
                builder: (_, _) => const LinksLibraryScreen(),
                routes: [
                  GoRoute(path: 'graph', pageBuilder: (_, s) => _pushed(s, const LinksScreen())),
                  GoRoute(
                    path: 'note/:id',
                    pageBuilder: (_, s) => _pushed(
                      s,
                      NoteConnectionsScreen(noteId: s.pathParameters['id']!),
                      origin: s.extra is CardOrigin ? s.extra as CardOrigin : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/ask', builder: (_, _) => const AskScreen())],
          ),
        ],
      ),
      GoRoute(path: '/settings', pageBuilder: (_, s) => _pushed(s, const SettingsScreen())),
      GoRoute(path: '/settings/voice-text', pageBuilder: (_, s) => _pushed(s, const VoiceTextScreen())),
      GoRoute(path: '/settings/voice-text/service/new', pageBuilder: (_, s) => _pushed(s, const ServiceFormScreen())),
      GoRoute(
        path: '/settings/voice-text/service/:id',
        pageBuilder: (_, s) => _pushed(s, ServiceFormScreen(serviceId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/note/:id',
        // `extra` supplies the note (for first-frame rendering) and/or the
        // tapped card's CardOrigin (for the container-transform transition).
        pageBuilder: (_, s) {
          final id = s.pathParameters['id']!;
          final (initial, origin) = switch (s.extra) {
            final Note n when n.id == id => (n, null),
            (final Note? n, final CardOrigin? o) => (n?.id == id ? n : null, o),
            final CardOrigin o => (null, o),
            _ => (null, null),
          };
          return _pushed(
            s,
            NoteDetailsScreen(noteId: id, initial: initial),
            origin: origin,
          );
        },
        routes: [
          GoRoute(
            path: 'pdf/:attachmentId',
            pageBuilder: (_, s) => _pushed(
              s,
              PdfViewerScreen(noteId: s.pathParameters['id']!, attachmentId: s.pathParameters['attachmentId']!),
            ),
          ),
          GoRoute(
            path: 'transcript/:attachmentId',
            pageBuilder: (_, s) => _pushed(
              s,
              TranscriptEditorScreen(noteId: s.pathParameters['id']!, attachmentId: s.pathParameters['attachmentId']!),
            ),
          ),
          GoRoute(
            path: 'edit',
            pageBuilder: (_, s) => _pushed(s, EditNoteScreen(noteId: s.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
