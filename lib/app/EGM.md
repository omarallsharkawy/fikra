# lib/app

## Overview

Composition root of the FIKRA Flutter app. This package reads the build mode,
wires `lib/data` implementations into Riverpod providers, defines the go_router
route table and its redirects, and builds the root `MaterialApp.router` and the
four-branch shell with three visible tabs and a floating Add button. Feature screens live in `lib/features` and are only referenced
here as route targets; the local transcription adapter is also wired here behind the data engine interface. Floating controls live in [tab_bar](tab_bar/EGM.md).

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
| `/links` | `LinksLibraryScreen` | Shell branch 2 |
| `/links/graph` | `LinksScreen` | Pushed on branch 2 |
| `/links/note/:id` | `NoteConnectionsScreen` | Pushed on branch 2 |
| `/ask` | `AskScreen` | Shell branch 3 |
| `/settings` | `SettingsScreen` | Top level, `pageBuilder:` via `_pushed` |
| `/note/:id` | `NoteDetailsScreen` | Top level, `pageBuilder:` via `_pushed` |
| `/note/:id/pdf/:attachmentId` | `PdfViewerScreen` | Child of `/note/:id`, `pageBuilder:` via `_pushed` |
| `/note/:id/edit` | `EditNoteScreen` | Child of `/note/:id`, `pageBuilder:` via `_pushed` |

`/note/:id` accepts an optional `extra` of type `Note`, used as the screen's
`initial` value so it can draw on the first frame.

### `shell.dart`: tab shell and transition

- `class AppShell extends StatefulWidget`: takes a `StatefulNavigationShell`
  (`shell`). Hosts the static Pearl background, full-height body and floating controls.
  Supplies `NavigationInset` (92 dp plus bottom safe area, zero with the IME).
- `class ShellBackground extends InheritedWidget`: exposes the background
  `GlobalKey` through `ShellBackground.maybeOf(context)`.
- `FikraNavBar` is re-exported from [tab_bar/sliding_tab_bar.dart](tab_bar/sliding_tab_bar.dart):
  `items`, visible `index` (-1 for Add), `onSelect(index, reselect)`, `enabled`.
  Keys `nav-0..2` refer to Notes/Links/Ask; `nav-add` identifies the separate button.
- `FloatingNavigation`: maps visible tabs to unchanged branch IDs 1..3; Add is 0.
  Receives `keyboardOpen` from above Scaffold, which strips body viewInsets.
- `class FikraBranchContainer extends StatefulWidget`: `index`, `children`.
  Passed to `StatefulShellRoute.navigatorContainerBuilder`.
- `class TabVeil extends LeafRenderObjectWidget` (`@visibleForTesting`):
  `opacity`, `palette`, `anchor`, `screen`.
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
- `/note/:id/pdf/:attachmentId` passes note and attachment IDs. The viewer resolves its file from `noteProvider` plus `noteAttachmentsProvider`; query parameters and `extra` cannot supply a file path.
- The `extra` on `/note/:id` is used only when it is a `Note` whose `id` matches
  the path parameter. Otherwise `initial` is `null`, as for deep links.

### Shell

- Branch IDs remain add=0, notes=1, links=2, ask=3. The visible tab order is
  notes, links, ask, mirrored in RTL; Add sits at the logical trailing side.
  Startup still redirects to Notes. Add remains mounted with its draft state.
- There is no bottomNavigationBar slot: content extends under the controls.
  One NavigationInset supplies bar (72), gap (12), lens overhang (8) and safe area.
  Notes/Add add it to scroll padding; Ask/Links keep fixed tools above it;
  FillScroll uses it for empty/error states and Notes offsets its selection footer.
  The shell-local SnackBarTheme adds the same clearance to toast margins so
  existing Undo actions and tab taps stay reachable.
- Keyboard changes disable input/semantics immediately and fade/slide both controls
  in 100 ms. Reduce Motion removes the slide.
- The `nav-$i` keys are used by `test/support/app_harness.dart` and
  `integration_test/stress_test.dart`.
- Tapping the current tab calls `goBranch` with `initialLocation: true`, which
  returns that branch to its initial location. Tapping another tab keeps that
  branch's state.
- `FikraBranchContainer` keeps every navigator in its original slot. Unselected
  branches are `Offstage`, have `TickerMode` disabled, and are wrapped in
  `ExcludeFocus`. Each branch has its own `RepaintBoundary`.
- The tab transition is a veil in the Pearl canvas that clears over the
  new tab. It must not scale or fade the tab itself. Per the comment in
  `FikraBranchContainer.build`, rescaling re-rasterised the tab's text every
  frame on GLES (for example Adreno 650) and missed the 144 Hz budget on about
  20% of frames.
- The tabs are transparent over the `AppShell` background, so the veil paints the
  two static blooms in the anchor box's rectangle, not its own. Without a usable anchor,
  `RenderTabVeil` assumes a `screen`-sized background at the view origin.
- `RenderTabVeil` never takes hits (`hitTestSelf` returns `false`), and the veil
  sits inside `IgnorePointer`.
- Reduced motion is respected. `FikraNavBar` tracks without scale and snaps on release instead of
  running its 420/24/mass-1 spring. `FikraBranchContainer` uses `FikraMotion.reducedFade` with
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
  network access. The tab bar calls selectionClick once per changed tab during touch.
  Position/fade controllers and the hover notifier are widget-owned and disposed.

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

`noteAttachmentsProvider(noteId)` streams ordered files for details/edit/viewer. `projectAttachmentsProvider(projectId)` shares one joined attachment query among all cards, avoiding per-card streams. Startup sweeping awaits database initialization/migration and uses every attachment-table path. Migration failures prevent maintenance from running; there is no legacy-column fallback.

## Recording ownership

`recordingActiveProvider` is app-scoped and persists across the offstage tab shell and pushed Edit. `RecordingActivity.claim(owner)` synchronously excludes a second recorder; only its owner can release. Native start/cancel/dispose completes before release, including failures and disposal during permission/start. `audioRecorderFactoryProvider` and `microphonePermissionProvider` inject the existing record/permission boundaries for lifecycle tests.

Local data services include `linksRepoProvider` (`Provider<LinksRepository>`) and `groupsRepoProvider` (`Provider<GroupsRepository>`), backed by the shared database. Existing screen providers and widgets are unchanged.

## Experimental voice to text route

`/settings/voice-text` pushes VoiceTextScreen with `_pushed` (MaterialPage), just like Settings and note pages. The feature owns its fakeable backend/controller providers; app providers supply the microphone lease, Whisper lease, saved-recording queue and settings repository. The real main entrypoint reaches it from Settings; no standalone test app remains.

## Saved recording transcription (phase 2)

whisperLockProvider supplies the process-wide lease; transcriptionEngineProvider is a replaceable asynchronous factory (local in both modes); transcriptionQueueProvider is app-scoped and schedules normal NoteProcessor.retry after success. Startup resumes attachment queued/running work next to NoteProcessor.resumeInterrupted before orphan maintenance. autoTranscribeProvider exposes the off-by-default persisted setting to draft chips and is invalidated after the voice-settings control changes it. transcriptionKeepAliveProvider supplies the queue's keep-alive (`AndroidTranscriptionKeepAlive`, notification text from `lookupAppLocalizations(appLocaleProvider)` at each call) and transcriptionNotificationPermissionProvider the Android 13+ notification permission (`PluginNotificationPermission`, permission_handler); tests override both. No connected AI/backend support or external transcription provider is added.

## User-added transcription (phase 3)

serviceKeysProvider, transcriptionServicesProvider/stateProvider, transcriptionTransportProvider and remoteAudioConverterProvider inject storage/HTTP/native conversion. localTranscriptionEngineProvider retains the local adapter; transcriptionEngineProvider reads the current selection and valid destination consent at job start, choosing local or a remote adapter. Credential reads are bound to the captured service origin/type. Queue construction, foreground service and launch crash-loop recovery are unchanged.

/settings/voice-text/service/new and /settings/voice-text/service/:id push ServiceFormScreen via _pushed/MaterialPage. Secrets are absent from routes, Riverpod service snapshots and SQLite. Tests override the transport/secure store and local factory, including selection tests, so native Whisper or real HTTP cannot run.

## Pearl foundation

Shell and pushed-page scaffolds use PearlCanvas (static warm/cool blooms).
The existing nav remains in bottomNavigationBar, with an opaque surface,
selected fill and accent labels. Layout, spring and branch state are unchanged.
App builder adds GlassDebugOverlay only when its opt-in provider is enabled
in debug/profile; release excludes it. No phase-2 navigation or Add control.

## Voice 2a

modelDiscoveryProvider supplies fakeable transport plus database-backed availability cache. transcriptCorrectionsProvider supplies the transactional correction service and normal processor callback. The pushed /note/:id/transcript/:attachmentId route uses _pushed/MaterialPage and looks up the live attachment within its note; no correction/audio is placed in navigation arguments.

## Links routes (redesign phase 3)

`/links` now mounts LinksLibraryScreen. Child routes `graph` (retained LinksScreen) and `note/:id` (NoteConnectionsScreen) use `_pushed` on the Links branch navigator. Both retain the floating bar; Back returns to the library/previous connections page. Full `/note/:id` stays on the root navigator. No shell branch indices or tab gestures change.
