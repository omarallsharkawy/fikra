# Projects

## Overview

Project selection and creation. It holds the header used by every tab, the project switcher sheet, and the first-run welcome screen mounted at `/welcome` by `lib/app/router.dart`.

## Interface

- `project_header.dart`
  - `ProjectHeader({required String title, Widget? trailing})`: `ConsumerWidget`.
  - `Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref)`.
  - `Future<String?> askProjectName(BuildContext context, {required String title, required String action, String initial = ''})`.
- `welcome_screen.dart`
  - `WelcomeScreen`: `ConsumerStatefulWidget` with no parameters.
- Consumes `selectedProjectProvider`, `projectsProvider`, `projectsRepoProvider`, and `notesRepoProvider` from `lib/app/providers.dart`, and `seedDemoProject` from `lib/data/demo/demo_seed.dart`.

## Invariants

- `askProjectName` returns a trimmed, non-blank name of at most 40 characters, or `null` when cancelled.
- Project deletion requires `confirmDestructive`.
- Project writes run through `runAction`, so failures show a toast instead of throwing into the UI.
- `WelcomeScreen` does not navigate. `lib/app/router.dart` redirects when `projectsProvider` becomes non-empty.
- `_seed` returns while `_seeding` is true, and the create button is disabled during seeding.

## Side Effects

- Calls `ProjectsRepository.create`, `rename`, `delete`, and `setCurrent`.
- `ProjectsRepository.delete` removes the project row, cascades to its notes, links, and chat entries through foreign keys, and deletes the notes' files.
- `seedDemoProject` writes a demo project and its notes.
- Opens bottom sheets, pushes `/settings` from the header, and shows toasts.

## Verification

- Run: `flutter analyze && flutter test`
