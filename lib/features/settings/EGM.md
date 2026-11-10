# Settings

## Overview

The settings screen, pushed at `/settings` by `lib/app/router.dart`. It controls appearance and language, wipes local data, and shows what this build is.

## Interface

- `settings_screen.dart`
  - `SettingsScreen`: `ConsumerWidget` with no parameters.
- Consumes `appThemeProvider`, `appLanguageProvider`, `settingsRepoProvider`, `isDemo`, `AppTheme`, `AppLanguage`, and `WipeFilesException` from `lib/app/providers.dart`.

## Invariants

- `_themes` (`system`, `light`, `dark`) must stay in the same order as the `SegmentedPill` options.
- The theme shown is `AppTheme.system` until `appThemeProvider` has a value.
- A wipe requires `confirmDestructive`.
- `_wipe` captures the `ScaffoldMessenger` before awaiting `wipeAllData`, because the router redirects away from this screen when no projects remain.
- `WipeFilesException` means the database rows are gone but some files remain, and it has its own message, separate from a general failure.

## Side Effects

- Persists the theme through `SettingsRepository.setTheme`.
- `SettingsRepository.wipeAllData` deletes all chat entries, links, notes, projects, and the current-project setting, then purges attachments and temp recordings. The saved theme and language are kept.
- After a wipe, `lib/app/router.dart` redirects to `/welcome` because no projects remain.
- Pops the route and shows snack bars.

## Localization

Language uses the same `SegmentedPill` and persisted-stream pattern as appearance. `_languages` order is system, ar, en; the language names are endonyms in both UIs. Changes update `MaterialApp` immediately. Wiping data preserves both preferences; wipe messages are captured before awaiting the operation.

## Verification

- Run: `flutter analyze && flutter test`
- `test/app_flow_test.dart` imports `settings_screen.dart` directly.
