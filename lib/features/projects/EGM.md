# Projects

## Overview

Project selection and creation. It holds the header used by every tab, the project switcher sheet, and the first-run welcome screen mounted at `/welcome` by `lib/app/router.dart`.

## Interface

- `project_header.dart`
  - `HeaderActionButton({required IconData icon, required String label, required VoidCallback? onTap, String? semanticLabel, String? tooltip, Color? iconColor})`: header action showing a 48 dp tall `SolidSurface` pill (`FikraRadius.full`, 18 dp icon, `FikraSpace.s8` gap, `context.text.chip` label in one horizontal line) when `ProjectHeader` has room, or a 48×48 dp circular `SolidSurface` with a 24 dp icon otherwise; always >= 48×48 dp.
  - `ProjectHeader({required String title, Widget? trailing, Widget? leading})`: `ConsumerWidget`.
  - `Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref)`.
  - `Future<String?> askProjectName(BuildContext context, {required String title, required String action, String initial = '', String? hint})`. `hint` defaults to `projectNameHint`.
  - `String deleteProjectMessage(AppLocalizations, ProjectDeleteImpact)` (`({int notes, int files, int links, bool chat})` from `repositories.dart`), `@visibleForTesting`.
- `welcome_screen.dart`
  - `WelcomeScreen`: `ConsumerStatefulWidget` with no parameters.
- Consumes `selectedProjectProvider`, `projectsProvider`, `projectsRepoProvider`, and `notesRepoProvider` from `lib/app/providers.dart`, and `seedDemoProject` from `lib/data/demo/demo_seed.dart`.

## Invariants

- `askProjectName` returns a trimmed, non-blank name of at most 40 characters, or `null` when cancelled.
- `ProjectHeader` places the screen title (and optional `leading`) at the start of Row 1 and trailing action(s) + Settings (`header-settings`) at the end, with at least `FikraSpace.s12` gap. When `textScaler <= 1.6` and labelled pills fit beside the title, `HeaderActionButton` renders as a horizontal pill; otherwise it collapses to a 48 dp icon-only circle.
- If even the 48 dp icon-only controls cannot fit beside the single-line title, controls occupy a separate row below the title with `FikraSpace.s8` vertical gap. Title text only wraps (up to 2 lines with ellipsis) if the heading alone exceeds row width.
- Row 2 places the project chip on its own line below the title at the start side with its natural width (up to the row width, ellipsizing long names) and a 48 dp touch target.
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

- `test/project_header_test.dart` loads the actual fonts and covers Arabic Add title regression, every tab header in both directions at 320/390 dp and text scales 1/1.3, wrapped action fallback, >= 48 dp settings pill navigation to `/settings`, Row 2 project chip alignment and ellipsis, 360 dp / 2.0x icon-only collapse without overflow, RTL edge alignment, and `boldText`/letter-word spacing accessibility overrides around the collapse threshold.
- `test/screenshots/headers_test.dart` renders eight dark header galleries plus light-mode Notes header captures (`notes_light`) under `build/screenshots/headers/{ar,en}/`.

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
- `ProjectHeader` renders its Settings control (`header-settings`) and `HeaderActionButton` trailing actions as horizontal `SolidSurface` pills (icon + label) via `_HeaderLabelScope` when `textScaler <= 1.6` and Row 1 width fits them; otherwise labels drop cleanly to 48 dp icon-only circles (24 dp icon) without shrinking touch targets or changing TalkBack labels. `HeaderActionButton` nests optional `Tooltip` inside `Pressable` so the button's `Semantics` node stays at the widget root. Label room is measured only for a bare `HeaderActionButton` trailing; any other trailing widget is wrapped in `_HeaderLabelScope(showLabel: false)`, so a button inside it is icon-only and cannot overflow. The project switcher chip sits in Row 2 on its own line below the title.

`project_switcher.dart` (re-exported by `project_header.dart`) holds `showProjectSwitcher`, `_projectActions`, `deleteProjectMessage`, and `askProjectName` so `project_header.dart` stays focused on `HeaderActionButton` and `ProjectHeader`.

## Finishing (redesign phase 8)

`ProjectHeader` marks its screen `title` with `Semantics(header: true)`.
