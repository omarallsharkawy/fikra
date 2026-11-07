import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../data/local/database.dart';
import '../features/add/add_screen.dart';
import '../features/ask/ask_screen.dart';
import '../features/links/links_screen.dart';
import '../features/note_details/edit_note_screen.dart';
import '../features/note_details/note_details_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/projects/welcome_screen.dart';
import '../features/settings/settings_screen.dart';
import 'providers.dart';
import 'shell.dart';
import 'storage_error_screen.dart';

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
        builder: (context, _) => ColoredBox(color: context.colors.screen),
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
            routes: [GoRoute(path: '/links', builder: (_, _) => const LinksScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/ask', builder: (_, _) => const AskScreen())],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/note/:id',
        // `extra` is the note the caller already has, so the screen draws it on
        // the first frame instead of waiting for the query. Deep links omit it.
        builder: (_, s) => NoteDetailsScreen(
          noteId: s.pathParameters['id']!,
          initial: switch (s.extra) {
            final Note n when n.id == s.pathParameters['id'] => n,
            _ => null,
          },
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => EditNoteScreen(noteId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
