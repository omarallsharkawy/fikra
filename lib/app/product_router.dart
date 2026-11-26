import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/account/session_controller.dart';
import '../features/capture/composer_screen.dart';
import '../features/conversation/conversation_screen.dart';
import '../features/workspace/graph_screen.dart';
import '../features/workspace/note_screen.dart';
import '../features/workspace/notes_screen.dart';
import '../features/workspace/project_controls.dart';
import 'product_runtime.dart';
import 'shell.dart';

final productRouterProvider = Provider<GoRouter>((ref) {
  final runtime = ref.watch(productRuntimeProvider);
  final router = GoRouter(
    initialLocation: '/session-loading',
    refreshListenable: runtime.session,
    redirect: (_, state) {
      final stage = runtime.session.stage;
      final path = state.uri.path;
      if (stage == SessionStage.restoring) return path == '/session-loading' ? null : '/session-loading';
      if (stage != SessionStage.authenticated) return path == '/sign-in' ? null : '/sign-in';
      if (path == '/sign-in' || path == '/session-loading') return '/notes';
      return null;
    },
    routes: [
      GoRoute(
        path: '/session-loading',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const ProductAccountScreen()),
      StatefulShellRoute(
        navigatorContainerBuilder: (_, shell, children) =>
            FikraBranchContainer(index: shell.currentIndex, children: children),
        builder: (_, _, shell) => AppShell(shell: shell, showLegacyActivity: false),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/add', builder: (_, _) => const ProductComposerScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/notes', builder: (_, _) => const ProductNotesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/links', builder: (_, _) => const ProductGraphScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/ask', builder: (_, _) => const ProductConversationScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (_, _) => const ProductAccountScreen())],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const ProductSettingsScreen()),
      GoRoute(path: '/settings/projects', builder: (_, _) => const ProductProjectsScreen()),
      GoRoute(path: '/conversations', builder: (_, _) => const ProductConversationHistoryScreen()),
      GoRoute(
        path: '/note/:id',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: ProductNoteScreen(id: state.pathParameters['id']!),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
