# lib

## Overview

All application source for FIKRA, a local-first Arabic and English notes app for Android. `main.dart` starts the app. The four subpackages split the code by role: `app` wires it together, `core` holds shared presentation code, `data` owns storage and the AI boundary, and `features` holds the screens.

## Interface

- `main.dart`: `main()`.
- [l10n](./l10n/EGM.md): Arabic/English ARB messages, generated `AppLocalizations`, context extension, and demo vocabulary.
- Subpackages:
  - [app](./app/EGM.md): `FikraApp`, `routerProvider`, the Riverpod providers, `AppShell`, `appMode`.
  - [core](./core/EGM.md): `Fmt`, theme tokens, motion tokens, shared widgets.
  - [data](./data/EGM.md): repository interfaces and their local implementations, `AiService`, `AttachmentStore`, `openWithSystem`, `NoteProcessor`, `FikraDatabase`.
  - [features](./features/EGM.md): one folder per screen group.

## Invariants

- [`main.dart:main`] throws `UnsupportedError` before `runApp` when `appMode == AppMode.connected`. Connected mode must not run on the demo services. This check must be removed when the backend is wired in.
- [`main.dart:main`] calls `initializeDateFormatting()` before `runApp`. `Fmt` date formatting depends on it.

## Side Effects

- [`main.dart:main`] loads date symbols for supported locales and starts the widget tree inside a `ProviderScope`.

## Verification

- Run: `flutter analyze && flutter test`

Attachment persistence is schema v5 (`NoteAttachments`). Add and Edit share the draft editor; copies precede atomic repository saves, and stored-file deletion follows commit. Cards share one per-project attachment stream. All files and recording operations remain local.
