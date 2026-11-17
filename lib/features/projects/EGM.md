# Projects

## Overview

Project selection and creation. It holds the header used by every tab, the project switcher sheet, and the first-run welcome screen mounted at `/welcome` by `lib/app/router.dart`.

## Interface

- `project_header.dart`
  - `HeaderActionButton({required IconData icon, required String label, required VoidCallback? onTap, String? semanticLabel, String? tooltip, Color? iconColor})`: compact header action showing a 30 dp circular `SolidSurface` + 11 sp caption when `ProjectHeader` has room, or a 40 dp icon-only surface otherwise; always >= 48×48 dp.
  - `ProjectHeader({required String title, Widget? trailing, Widget? leading})`: `ConsumerWidget`.
  - `Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref)`.
  - `Future<String?> askProjectName(BuildContext context, {required String title, required String action, String initial = '', String? hint})`. `hint` defaults to `projectNameHint`.
  - `String deleteProjectMessage(AppLocalizations, ProjectDeleteImpact)` (`({int notes, int files, int links, bool chat})` from `repositories.dart`), `@visibleForTesting`.
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

## Links phase 3

- UX-16: "New project" (key `new-project`) closes the projects sheet first, then asks for the name from the caller's context (the header, which outlives the sheet) and creates with the caller's `ref`. Cancelling changes nothing. The sheet's own `Consumer` context and ref are named `sheetInner`/`sheetRef` so they are never used after the sheet closes. Rename and delete still open on top of the projects sheet (unchanged).
- UX-17: the welcome screen passes `firstProjectTitle` and `firstProjectNameHint` ("Project name, e.g. Study"); "New project" and "Rename" keep `projectNameHint` ("Project name").
- Delete reads `ProjectsRepository.deleteImpact` before confirming. `deleteProjectMessage` returns, for a project with no notes, `deleteProjectEmptyChatBody` when it has an Ask chat (the chat is deleted with it) or `deleteProjectEmptyBody` when it has none; otherwise `deleteProjectBody` with the non-zero counts (notes, files, links) joined by `Fmt.list`. If the count fails, a `genericError` toast and no dialog.
- Delete guards: a per-sheet `deleting` flag lets one delete flow run at a time (a second tap while counting does nothing) and is reset in `finally`, so cancelling allows another try. Before each dialog the flow checks the action sheet is still mounted and its route is current; a count that returns after the sheet was dismissed opens nothing.
- Stale numbers: after confirm, `deleteImpact` is read again. If the numbers changed while the dialog was open, the dialog is shown again with the new numbers instead of deleting. No transaction or schema change.
- The title `deleteProjectTitle` gets the name through `Fmt.isolate` (FSI/PDI) so a mixed name such as "2026 Work" keeps its order inside Arabic.
- Project rows come from `ProjectRow` in [shared](../shared/EGM.md).
- Verification: `test/project_moves_test.dart` (UX-16, UX-17, delete numbers, chat-only empty project, double tap and cancel reset, dismissed sheet, re-shown changed numbers, mixed-name bidi) and `test/repositories_test.dart` (`deleteImpact`, only the deleted project's files leave the disk); screenshots `39`–`41` in `test/screenshots/projects_test.dart`.

## Pearl foundation (redesign phase 1)

Reading content now uses opaque SolidSurface/surface or chip plus the line
hairline; all old gradient Glass call sites are migrated. Selected controls
use opaque selected fill with accent labels; primary/send actions use the
single Pearl Add gradient and onAccent. Typography, layout and springs remain.

## Ordering & IA (redesign phase 4)

- `showProjectSwitcher` orders rows via shared `orderProjects` (`project-row-<id>`): the currently selected project first, then remaining projects from most recent `Project.createdAt` descending.
- `ProjectHeader` renders its Settings control (`header-settings`) and `HeaderActionButton` trailing actions with visible short captions under the icon via `_HeaderLabelScope` when `textScaler <= 1.6` and horizontal space preserves `minimumChipWidth`; otherwise captions hide cleanly without shrinking 48 dp touch targets or changing TalkBack labels. `HeaderActionButton` nests optional `Tooltip` inside `Pressable` so the button's `Semantics` node stays at the widget root. Caption room is measured only for a bare `HeaderActionButton` trailing; any other trailing widget is wrapped in `_HeaderLabelScope(showLabel: false)`, so a button inside it is icon-only and cannot overflow.
