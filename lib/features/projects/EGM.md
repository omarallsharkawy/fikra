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
- `ProjectHeader` gives the title its natural width at the existing text size, with one line and a 12 dp minimum gap before the flexible project chip. The project name alone ellipsizes, retaining room for an initial character and ellipsis.
- When the remaining chip width is narrow, the header omits its redundant folder icon and reduces internal horizontal padding. Settings and the project switcher retain 48 dp touch targets.
- If even the minimum chip and actions cannot fit beside the title (for example Arabic Add at 320 dp and text scale 1.3), controls occupy a separate row with an 8 dp vertical gap. Title text never wraps or scales down.
- Project deletion requires `confirmDestructive`.
- Project writes run through `runAction`, so failures show a toast instead of throwing into the UI.
- `WelcomeScreen` does not navigate. `lib/app/router.dart` redirects when `projectsProvider` becomes non-empty.
- `_seed` returns while `_seeding` is true, and the create button is disabled during seeding.

## Side Effects

- Calls `ProjectsRepository.create`, `rename`, `delete`, and `setCurrent`.
- `ProjectsRepository.delete` removes the project row, cascades to its notes, links, and chat entries through foreign keys, and deletes the notes' files.
- `seedDemoProject` writes a demo project and its notes.
- Opens bottom sheets, pushes `/settings` from the header, and shows toasts.

## Localization

Header, sheets and welcome copy use `context.l10n`; project names remain stored user content. Welcome passes `appLocaleProvider` and `appClockProvider` to the sample seed. Asymmetric header/project-row padding mirrors for LTR.

## Verification

- Run: `flutter analyze && flutter test`

- `test/project_header_test.dart` loads the actual fonts and covers Arabic Add title regression plus every tab header in both directions at 320/390 dp and text scales 1/1.3, including Ask’s trailing action.
- `test/screenshots/headers_test.dart` renders eight dark header galleries under `build/screenshots/headers/{ar,en}/`, covering the same width/text-scale matrix.
