# lib/app

## Overview

Composition root of the FIKRA Flutter app. This package reads the build mode,
wires `lib/data` implementations into Riverpod providers, defines the go_router
route table and its redirects, and builds the root `MaterialApp.router` and the
four-tab shell. Feature screens live in `lib/features` and are only referenced
here as route targets. This directory has no subdirectories.

## Interface

### `app_config.dart`: build mode

- `enum AppMode { demo, connected }`
- `final AppMode appMode`: parsed from `--dart-define=FIKRA_MODE`, default `demo`.
- `bool get isDemo`: true when `appMode == AppMode.demo`. Drives the demo labels
  in the UI.

### `app.dart`: root widget

- `class FikraApp extends ConsumerWidget`: builds `MaterialApp.router` with
  `routerProvider`, the light and dark themes from `buildFikraTheme`, and the
  saved theme mode and language. Watches `startupMaintenanceProvider`.

### `providers.dart`: dependency wiring

Re-exports `isDemo` from `app_config.dart`, and `AppTheme`, `AppLanguage`, and
`WipeFilesException` from `lib/data/settings_repository.dart`.

| Group | Provider | Type |
| --- | --- | --- |
| Services | `databaseProvider` | `Provider<FikraDatabase>` |
| Services | `projectsRepoProvider` | `Provider<ProjectsRepository>` |
| Services | `notesRepoProvider` | `Provider<NotesRepository>` |
| Services | `chatRepoProvider` | `Provider<ChatRepository>` |
| Services | `settingsRepoProvider` | `Provider<SettingsRepository>` |
| Services | `attachmentStoreProvider` | `Provider<AttachmentStore>` |
| Services | `appThemeProvider` | `StreamProvider<AppTheme>` |
| Backend seam | `aiServiceProvider` | `Provider<AiService>` |
| Services | `fileOpenerProvider` | `Provider<FileOpener>` |
| Services | `noteProcessorProvider` | `Provider<NoteProcessor>` |
| Startup | `startupMaintenanceProvider` | `FutureProvider<void>` |
| Projects | `projectsProvider` | `StreamProvider<List<ProjectSummary>>` |
| Projects | `selectedProjectProvider` | `Provider<Project?>` |
| Per project (family by id) | `notesOfProjectProvider` | `StreamProvider.autoDispose.family<List<Note>, String>` |
| Per project (family by id) | `linksOfProjectProvider` | `StreamProvider.autoDispose.family<List<NoteLink>, String>` |
| Per project (family by id) | `chatOfProjectProvider` | `StreamProvider.autoDispose.family<List<ChatEntry>, String>` |
| Single note (family by id) | `noteProvider` | `StreamProvider.autoDispose.family<Note?, String>` |
| Selected project | `selectedNotesProvider` | `Provider.autoDispose<AsyncValue<List<Note>>>` |
| Selected project | `selectedLinksProvider` | `Provider.autoDispose<AsyncValue<List<NoteLink>>>` |
| Selected project | `selectedChatProvider` | `Provider.autoDispose<AsyncValue<List<ChatEntry>>>` |

### `router.dart`: navigation

- `routerProvider`: `Provider<GoRouter>`, initial location `/splash`.

| Path | Screen | Placement |
| --- | --- | --- |
| `/splash` | `ColoredBox` in the screen color | Top level, `builder:` |
| `/welcome` | `WelcomeScreen` | Top level, `builder:` |
| `/storage-error` | `StorageErrorScreen` | Top level, `builder:` |
| `/add` | `AddScreen` | Shell branch 0 |
| `/notes` | `NotesScreen` | Shell branch 1 |
| `/links` | `LinksScreen` | Shell branch 2 |
| `/ask` | `AskScreen` | Shell branch 3 |
| `/settings` | `SettingsScreen` | Top level, `pageBuilder:` via `_pushed` |
| `/note/:id` | `NoteDetailsScreen` | Top level, `pageBuilder:` via `_pushed` |
| `/note/:id/pdf` | `PdfViewerScreen` | Child of `/note/:id`, `pageBuilder:` via `_pushed` |
| `/note/:id/edit` | `EditNoteScreen` | Child of `/note/:id`, `pageBuilder:` via `_pushed` |

`/note/:id` accepts an optional `extra` of type `Note`, used as the screen's
`initial` value so it can draw on the first frame.

### `shell.dart`: tab shell and transition

- `class AppShell extends StatefulWidget`: takes a `StatefulNavigationShell`
  (`shell`). Hosts the gradient background and the nav bar.
- `class ShellBackground extends InheritedWidget`: exposes the background
  `GlobalKey` through `ShellBackground.maybeOf(context)`.
- `class FikraNavBar extends StatefulWidget`: `items`, `index`, `onTap`. Each
  item has the key `ValueKey('nav-$i')`.
- `class FikraBranchContainer extends StatefulWidget`: `index`, `children`.
  Passed to `StatefulShellRoute.navigatorContainerBuilder`.
- `class TabVeil extends LeafRenderObjectWidget` (`@visibleForTesting`):
  `opacity`, `gradient`, `anchor`, `screen`.
- `class RenderTabVeil extends RenderBox`: render object for `TabVeil`.

### `storage_error_screen.dart`: storage failure screen

- `class StorageErrorScreen extends ConsumerWidget`: shown when the local
  database can't be opened. Offers a retry button.

## Invariants

### Build mode

- `FIKRA_MODE` accepts only `demo` or `connected`. Any other value makes
  `_parse` throw `ArgumentError` on the first read of `appMode`.
- `connected` must not run on demo services. `lib/main.dart` throws
  `UnsupportedError` before `runApp`, and `aiServiceProvider` throws
  `UnimplementedError` in that mode. Wiring a real backend has to change both
  (see `docs/backend-integration.md`).

### Providers

- `providers.dart` only selects implementations. Implementations live in
  `lib/data`.
- `selectedProjectProvider` returns `null` only when there are no projects. If
  the saved id is missing or unknown, it returns the first project.
- `_forSelected` returns `AsyncData(empty)` when no project is selected, so the
  `selected*` providers never load in that state.
- Use the `selected*` providers for the project picked in the header. Use the
  `*OfProjectProvider` families with an explicit id, such as a note's own
  `projectId`.
- `startupMaintenanceProvider` uses `ref.read` for its dependencies, so a change
  in them does not re-run it. It runs `resumeInterrupted` first, then
  `sweepOrphans`. `FikraApp` discards its result, so a failure is not shown in
  the UI.
- Tests replace storage and file opening through `databaseProvider`,
  `attachmentStoreProvider`, and `fileOpenerProvider` overrides (`test/support/app_harness.dart`,
  `integration_test/stress_test.dart`).

### Root widget

- `FikraApp` renders `SizedBox.shrink` until the saved theme and language first resolve, so a
  restart never flashes the wrong appearance. Preference read errors fall back to system settings.
- Supported locales are `ar` and `en`, using `AppLocalizations.localizationsDelegates` and a localized application title.

### Routing

- `routerProvider` subscribes with `ref.listen` and reads `projectsProvider`
  with `ref.read` inside `redirect`. Redirects re-run through the
  `refreshListenable` counter, while the `GoRouter` instance stays the same.
- `redirect` evaluates these rules in order and stops at the first match. Each
  rule returns `null` if the location is already the target:

  1. `projectsProvider` has an error and no value: `/storage-error`.
  2. `projectsProvider` has no value: `/splash`.
  3. The project list is empty: `/welcome`, from every location.
  4. The project list is non-empty and the location is `/welcome`, `/splash`, or
     `/storage-error`: `/notes`.

- Routes pushed over another screen must use `_pushed` (`pageBuilder:`). With
  Flutter's own `MaterialApp`, go_router 18 falls back to `NoTransitionPage` for
  `builder:` routes, so a push made that way would jump in one frame. Routes that
  replace each other (splash, welcome, the shell) intentionally keep `builder:`.
- `/note/:id/pdf` passes only the note ID. The viewer resolves its file from `noteProvider`; query parameters and `extra` cannot supply a file path.
- The `extra` on `/note/:id` is used only when it is a `Note` whose `id` matches
  the path parameter. Otherwise `initial` is `null`, as for deep links.

### Shell

- The order of `AppShell._tabs` must match the order of the
  `StatefulShellBranch` list in `router.dart`: add, notes, links, ask.
- The `nav-$i` keys are used by `test/support/app_harness.dart` and
  `integration_test/stress_test.dart`.
- Tapping the current tab calls `goBranch` with `initialLocation: true`, which
  returns that branch to its initial location. Tapping another tab keeps that
  branch's state.
- `FikraBranchContainer` keeps every navigator in its original slot. Unselected
  branches are `Offstage`, have `TickerMode` disabled, and are wrapped in
  `ExcludeFocus`. Each branch has its own `RepaintBoundary`.
- The tab transition is a veil in the background gradient that clears over the
  new tab. It must not scale or fade the tab itself. Per the comment in
  `FikraBranchContainer.build`, rescaling re-rasterised the tab's text every
  frame on GLES (for example Adreno 650) and missed the 144 Hz budget on about
  20% of frames.
- The tabs are transparent over the `AppShell` background, so the veil paints the
  gradient in the anchor box's rectangle, not its own. Without a usable anchor,
  `RenderTabVeil` assumes a `screen`-sized background at the view origin.
- `RenderTabVeil` never takes hits (`hitTestSelf` returns `false`), and the veil
  sits inside `IgnorePointer`.
- Reduced motion is respected. `FikraNavBar` snaps to the new index instead of
  running its spring. `FikraBranchContainer` uses `FikraMotion.reducedFade` with
  a linear curve.
- `FikraNavBar` positions the selected pill from the right in RTL and from the
  left otherwise.

### Storage error screen

- `StorageErrorScreen` never deletes data. Retry only invalidates
  `databaseProvider` and `projectsProvider`.

## Side Effects

- `databaseProvider` constructs `FikraDatabase()`, whose default executor is
  `driftDatabase(name: 'fikra')`, and closes it on dispose.
- `startupMaintenanceProvider` runs at launch and has two effects:
  - `NoteProcessor.resumeInterrupted` re-dispatches, without awaiting, every note
    with `ProcessingStatus.processing`, which calls the `AiService`.
  - `AttachmentStore.sweepOrphans` deletes unreferenced attachment files and
    `rec_` temp recordings older than `sweepGrace` (one hour).
- The retry button on `StorageErrorScreen` disposes `databaseProvider`, which
  closes the current database. A new one is created on the next read.
- `routerProvider` disposes its `ValueNotifier` and `GoRouter` with the provider.
- `FikraApp` sets the system status bar and navigation bar styles through
  `AnnotatedRegion<SystemUiOverlayStyle>`.
- `app_config.dart`, `router.dart` redirects, and `shell.dart` perform no disk or
  network access.

## Locale and clock providers

- `appLanguageProvider` streams `SettingsRepository.watchLanguage`, exactly like appearance.
- `deviceLocaleProvider` observes platform locale changes; `appLocaleProvider` resolves `AppLanguage.system/ar/en` to Arabic or English. Device languages other than English resolve to Arabic.
- `aiServiceProvider` passes a callback reading the current resolved locale to `DemoAiService`. It does not recreate the AI or processing queue on language changes.
- Startup maintenance waits for the saved language before resuming interrupted analysis.
- `appClockProvider` defaults to `DateTime.now`; the welcome seed and date grouping use it. Tests override it for stable screenshots.
- Nav labels resolve during build. The nav pill and segmented controls already compute their positions from `Directionality`; page-transition direction remains unchanged.

## Verification

- Run: `flutter analyze && flutter test`
- Tests that exercise this package: `test/motion_test.dart` (shell and veil),
  `test/app_flow_test.dart`, and the shared harness in
  `test/support/app_harness.dart`.
